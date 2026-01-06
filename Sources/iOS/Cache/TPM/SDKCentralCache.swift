/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class SDKCentralCache: @unchecked Sendable {
  internal let memoryCache = MemoryCache<String, Any>("Central Cache")
  internal let diskCache: DiskCache<String, DynamicJSON>
  private lazy var syncQueue = DispatchQueue(label: "com.ahsdk.centralCache")

  private let cacheKey = "ahsdk"
  private var cachePath: URL?
  private(set) var isCacheDirty = false

  init(_ cacheDirectory: String?) {
    if let cacheDirectory {
      diskCache = DiskCache(cacheDirectory)
      cachePath = cacheFilePath(cacheDirectory)
    } else {
      diskCache = DiskCache()
      cachePath = cacheFilePath(nil)
    }
  }
}

extension SDKCentralCache: TypeSafeAPIWrapper {
  func integer(forKey key: SDKCentralCache.Keys) -> Int? {
    memoryCache.integer(forKey: key.rawValue)
  }

  func double(forKey key: SDKCentralCache.Keys) -> Double? {
    memoryCache.double(forKey: key.rawValue)
  }

  func bool(forKey key: SDKCentralCache.Keys) -> Bool? {
    memoryCache.bool(forKey: key.rawValue)
  }

  func string(forKey key: SDKCentralCache.Keys) -> String? {
    memoryCache.string(forKey: key.rawValue)
  }

  func json(forKey key: SDKCentralCache.Keys) -> DynamicJSON? {
    memoryCache.json(forKey: key.rawValue)
  }

  func date(forKey key: SDKCentralCache.Keys) -> Date? {
    memoryCache.date(forKey: key.rawValue)
  }

  func array<T>(forKey key: SDKCentralCache.Keys) -> [T]? where T: Decodable, T: Encodable {
    memoryCache.array(forKey: key.rawValue)
  }

  func dictionary<T>(forKey key: SDKCentralCache.Keys) -> [String: T]? where T: Decodable, T: Encodable {
    memoryCache.dictionary(forKey: key.rawValue)
  }

  @discardableResult
  func setInt(_ value: Int, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setInt(value, forKey: key.rawValue)
  }

  @discardableResult
  func setDouble(_ value: Double, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setDouble(value, forKey: key.rawValue)
  }

  @discardableResult
  func setBool(_ value: Bool, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setBool(value, forKey: key.rawValue)
  }

  @discardableResult
  func setString(_ value: String, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setString(value, forKey: key.rawValue)
  }

  @discardableResult
  func setJSON(_ value: DynamicJSON, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setJSON(value, forKey: key.rawValue)
  }

  @discardableResult
  func setDate(_ value: Date, forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.setDate(value, forKey: key.rawValue)
  }

  @discardableResult
  func setArray<T>(_ value: [T], forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError where T: Decodable, T: Encodable {
    isCacheDirty = true
    return memoryCache.setArray(value, forKey: key.rawValue)
  }

  @discardableResult
  func setDictionary<T>(_ value: [String: T], forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError where T: Decodable, T: Encodable {
    isCacheDirty = true
    return memoryCache.setDictionary(value, forKey: key.rawValue)
  }

  @discardableResult
  func removeObject(forKey key: SDKCentralCache.Keys) -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.removeObject(forKey: key.rawValue)
  }

  @discardableResult
  func removeAllObjects() -> TypeSafeAPIWrapperError {
    isCacheDirty = true
    return memoryCache.removeAllObjects()
  }
}

// MARK: - Dump

extension SDKCentralCache {
  func dump() -> DynamicJSON {
    let result: [String: Any] = memoryCache.dump()
    return DynamicJSON(value: result)
  }
}

// MARK: - Synchronization

extension SDKCentralCache {
  @discardableResult
  func synchronize(_ forceSync: Bool = false) -> Bool {
    // Skip writing to disk if the cache hasn't changed
    guard forceSync || isCacheDirty else {
      Log(.debug, message: "No changes in cache, skipping disk write.")
      return false
    }
    Log(.debug, message: "Cache sync started")
    // dump the memory cache
    let jsonCacheData = dump()
    let result = diskCache.set(jsonCacheData, forKey: "ahsdk")
    // Reset the dirty flag after the disk sync finishes.
    // Ignore the sync result
    isCacheDirty = false
    if case .None = result {
      Log(.debug, message: "Cache sync successful!")
      return true
    } else if case let .FailToSetValueForKey(key, nSError) = result {
      Log(.error, message: "Cache sync failed for key \(key): \(nSError.localizedDescription)")
      return false
    } else {
      Log(.error, message: "Cache sync failed!")
      return false
    }
  }

  func synchronize(_ forceSync: Bool = false, completion: (@Sendable (Bool) -> Void)?) {
    // Skip writing to disk if the cache hasn't changed
    guard forceSync || isCacheDirty else {
      Log(.debug, message: "No changes in cache, skipping disk write.")
      return
    }
    syncQueue.async {
      var result = false
      Perf.measure("Cache Synchronization") {
        result = self.synchronize()
      }
      completion?(result)
    }
  }
}

// MARK: - Warm up

extension SDKCentralCache {
  @discardableResult
  func performWarmup() -> DynamicJSON? {
    Log(.debug, message: "Start warming up the SDK central cache")
    if let config = warmup() {
      Log(.debug, message: "Finish warming up the SDK central cache")
      return config
    }
    Log(.error, message: "Error warming up the SDK central cache")
    return nil
  }

  internal func warmup() -> DynamicJSON? {
    guard let cachePath else {
      Log(.error, message: "The cache path is missing!")
      return nil
    }
    // Decode the data on the current thread.
    guard let data = try? Data(contentsOf: cachePath) else {
      Log(.error, message: "The cache path does not exist!")
      return nil
    }

    guard let config: DynamicJSON = try? data.decoded() else {
      Log(.error, message: "Decode the DynamicJSON data failed!")
      return nil
    }

    guard let json = config.dictionaryObject else {
      Log(.error, message: "Convert to dictionary object failed!")
      return nil
    }

    for (key, value) in json {
      if let json = value as? [String: Any] {
        memoryCache.set(DynamicJSON(value: json), forKey: key)
      } else {
        memoryCache.set(value, forKey: key)
      }
    }
    return config
  }
}

extension SDKCentralCache {
  private func cacheFilePath(_ cacheDir: String?) -> URL? {
    let fileManager = FileManager.default
    guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      Log(.error, message: "Failed to get the caches directory!")
      return nil
    }
    let directoryURL = cacheDirectory.appendingPathComponent(cacheDir ?? "ahsdk")
    return directoryURL.appendingPathComponent(cacheKey)
  }
}

extension SDKCentralCache: Logging {}
