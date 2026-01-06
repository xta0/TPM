/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum DiskCacheConfigs {
  static let queueName = "com.ahsdk.disk_queue"
  static let cacheDiretory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
  static let sdkCacheDirectory = "ahsdk"
}

enum DiskCacheError: Int, Sendable {
  case EncodingFailed = 200
  case DecodingFailed
  case FileURLNotValid
  case WriteDataFailed
  case ReadDataFailed
  case InternalError
  case RemoveItemFailed
}

final class DiskCache<K: StringConvertible & Equatable & Sendable & Sendable, V: Codable & Sendable>: AsyncCache, @unchecked Sendable {

  typealias Key = K
  typealias Value = V

  private lazy var operationeQueue = DispatchQueue(label: "\(DiskCacheConfigs.queueName)")

  let cacheDirectory: String

  init(_ cacheDirectory: String = DiskCacheConfigs.sdkCacheDirectory) {
    self.cacheDirectory = (DiskCacheConfigs.cacheDiretory as NSString).appendingPathComponent(cacheDirectory)
    if !FileManager.default.fileExists(atPath: self.cacheDirectory) {
      do {
        try FileManager.default.createDirectory(atPath: self.cacheDirectory, withIntermediateDirectories: true)
      } catch {
        Log(.error, message: "Create disk cache diretory failed with error: \(error)")
      }
    }
  }
}

// MARK: - Async Cache APIs

extension DiskCache {

  func value(forKey key: K, completion: (@Sendable (Result<V, CacheError<K>>) -> Void)?) {
    operationeQueue.async { [weak self] in
      guard let result = self?._value(forKey: key) else {
        self?.Log(.error, message: "Fetching value from disk cache failed for key: \(key)")
        completion?(.failure(.FailToGetValueForKey(key, DiskCacheError.ReadDataFailed.toNSError)))
        return
      }
      completion?(result)
    }
  }

  func set(_ value: V, forKey key: K, completion: (@Sendable (Result<K, CacheError<K>>) -> Void)?) {
    operationeQueue.async { [weak self] in
      guard let error = self?.set(value, forKey: key) else {
        self?.Log(.error, message: "Setting value in disk cache failed for key: \(key)")
        completion?(.failure(.FailToSetValueForKey(key, DiskCacheError.InternalError.toNSError)))
        return
      }
      if error == .None {
        completion?(.success(key))
      } else {
        completion?(.failure(error))
      }
    }
  }

  func removeValue(forKey key: K, completion: (@Sendable (Result<K, CacheError<K>>) -> Void)?) {
    operationeQueue.async { [weak self] in
      guard let error = self?.removeValue(forKey: key) else {
        self?.Log(.error, message: "Remvoing value in disk cache failed for key: \(key)")
        completion?(.failure(.FailToRemoveValueForKey(key, DiskCacheError.InternalError.toNSError)))
        return
      }
      if error == .None {
        completion?(.success(key))
      } else {
        completion?(.failure(error))
      }
    }
  }

  func removeAll(completion: (@Sendable (CacheError<K>) -> Void)?) {
    operationeQueue.async { [weak self] in
      guard let error = self?.removeAll() else {
        self?.Log(.error, message: "Clearing all values from disk cache failed!")
        completion?(.FailToRemoveAllValues(DiskCacheError.InternalError.toNSError))
        return
      }
      if error == .None {
        completion?(.None)
      } else {
        completion?(error)
      }
    }
  }
}

// MARK: - Sync methods

extension DiskCache {
  func value(forKey key: K) -> V? {
    let result = _value(forKey: key)
    switch result {
    case .failure:
      return nil
    case let .success(value):
      return value
    }
  }

  func _value(forKey key: K) -> Result<V, CacheError<K>> {
    // Check if the path for the key exists
    guard let fileURL = pathForKey(key) else {
      return .failure(.FailToGetValueForKey(key, DiskCacheError.FileURLNotValid.toNSError))
    }
    do {
      let data = try Data(contentsOf: fileURL)
      let result = try JSONDecoder().decode(V.self, from: data)
      return .success(result)
    } catch let error as DecodingError {
      // If a DecodingError occurs, wrap it in an NSError and bubble it up
      let nsError = CacheErrorFactory.createDecodingNSError(description: error.localizedDescription)
      return .failure(.FailToGetValueForKey(key, nsError))
    } catch let error as NSError {
      // If a file read or other NSError occurs, bubble it up directly
      return .failure(.FailToGetValueForKey(key, error))
    } catch {
      return .failure(.FailToGetValueForKey(key, DiskCacheError.ReadDataFailed.toNSError))
    }
  }

  func set(_ value: V, forKey key: K) -> CacheError<K> {
    // Check if the path for the key exists
    guard let fileURL = pathForKey(key) else {
      return .FailToSetValueForKey(key, DiskCacheError.FileURLNotValid.toNSError)
    }
    do {
      let data = try value.encoded()
      try data.write(to: fileURL)
    } catch let error as EncodingError {
      // If encoding error occurs, convert it to NSError and bubble it up
      let nsError = CacheErrorFactory.createEncodingNSError(description: error.localizedDescription)
      return .FailToSetValueForKey(key, nsError)
    } catch let error as NSError {
      // If any other NSError occurs (e.g., file writing error), bubble it up directly
      return .FailToSetValueForKey(key, error)
    } catch {
      return .FailToSetValueForKey(key, DiskCacheError.WriteDataFailed.toNSError)
    }
    return .None
  }

  func removeValue(forKey key: K) -> CacheError<K> {
    guard let fileURL = pathForKey(key) else {
      return .FailToSetValueForKey(key, DiskCacheError.FileURLNotValid.toNSError)
    }
    do {
      try FileManager.default.removeItem(at: fileURL)
    } catch let error as NSError {
      return .FailToRemoveValueForKey(key, error)
    } catch {
      return .FailToRemoveValueForKey(key, DiskCacheError.RemoveItemFailed.toNSError)
    }
    return .None
  }

  func removeAll() -> CacheError<K> {
    let cachedItems = itemsInDirectory(cacheDirectory)
    for filePath in cachedItems {
      do {
        try FileManager.default.removeItem(atPath: filePath)
      } catch let error as NSError {
        return .FailToRemoveAllValues(error)
      } catch {
        return CacheError.FailToRemoveAllValues(DiskCacheError.InternalError.toNSError)
      }
    }
    return .None
  }
}

// MARK: - Internal methods

extension DiskCache {

  private func pathForKey(_ key: K) -> URL? {
    guard let fileName = key as? String else {
      Log(.error, message: "Casting fileName failed: \(key)")
      return nil
    }
    let filePath = (cacheDirectory as NSString).appendingPathComponent(fileName)
    return URL(fileURLWithPath: filePath)
  }

  private func itemsInDirectory(_ directory: String) -> [String] {
    var items: [String] = []
    do {
      items = try FileManager.default.contentsOfDirectory(atPath: directory).compactMap {
        (directory as NSString).appendingPathComponent($0)
      }
    } catch {
      Log(.error, message: "Getting items in directory \(directory) failed with error: \(error)")
    }
    return items
  }
}

extension DiskCacheError {
  var description: String {
    switch self {
    case .EncodingFailed:
      return "Failed to encode data."
    case .DecodingFailed:
      return "Failed to decode data."
    case .FileURLNotValid:
      return "File URL is not valid."
    case .WriteDataFailed:
      return "Failed to write data."
    case .ReadDataFailed:
      return "Failed to read data."
    case .InternalError:
      return "An internal error occurred."
    case .RemoveItemFailed:
      return "Failed to remove item."
    }
  }

  // A computed property that converts the enum to an NSError
  var toNSError: NSError {
    CacheErrorFactory.createGenericNSError(code: rawValue, description: description)
  }
}

extension DiskCache: Logging {}
