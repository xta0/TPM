/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum CacheError<Key: Equatable & Sendable>: Error, Sendable {
  case None
  case FailToSetValueForKey(Key, NSError)
  case FailToGetValueForKey(Key, NSError)
  case FailToRemoveValueForKey(Key, NSError)
  case FailToRemoveAllValues(NSError)
}

enum CacheErrorFactory {
  static let SDKErrorDomain = "com.vizlab.cache"
  static func createGenericNSError(code: Int, description: String) -> NSError {
    NSError(domain: CacheErrorFactory.SDKErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
  }

  static func createDecodingNSError(description: String) -> NSError {
    NSError(domain: CacheErrorFactory.SDKErrorDomain, code: 1008, userInfo: [NSLocalizedDescriptionKey: description])
  }

  static func createEncodingNSError(description: String) -> NSError {
    NSError(domain: CacheErrorFactory.SDKErrorDomain, code: 1007, userInfo: [NSLocalizedDescriptionKey: description])
  }
}

// MARK: - Equatable

extension CacheError: Equatable {
  static func == (lhs: CacheError<Key>, rhs: CacheError<Key>) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None):
      return true
    case let (.FailToSetValueForKey(key1, error1), .FailToSetValueForKey(key2, error2)),
         let (.FailToGetValueForKey(key1, error1), .FailToGetValueForKey(key2, error2)),
         let (.FailToRemoveValueForKey(key1, error1), .FailToRemoveValueForKey(key2, error2)):
      return key1 == key2 && error1.domain == error2.domain && error1.code == error2.code
    case let (.FailToRemoveAllValues(error1), .FailToRemoveAllValues(error2)):
      return error1.domain == error2.domain && error1.code == error2.code
    default:
      return false
    }
  }
}

// MARK: - Cache Error

extension CacheError {
  static func zip<K>(error1: CacheError<K>, error2: CacheError<K>) -> CacheError<K> {
    if error1 != .None {
      return error1
    }
    if error2 != .None {
      return error2
    }
    return .None
  }
}

extension CacheError: CustomStringConvertible {
  var description: String {
    switch self {
    case .None:
      return "No error occurred."
    case let .FailToSetValueForKey(key, error):
      return "Failed to set value for key: \(key). Underlying error: \(error.localizedDescription) (Code: \(error.code))"
    case let .FailToGetValueForKey(key, error):
      return "Failed to get value for key: \(key). Underlying error: \(error.localizedDescription) (Code: \(error.code))"
    case let .FailToRemoveValueForKey(key, error):
      return "Failed to remove value for key: \(key). Underlying error: \(error.localizedDescription) (Code: \(error.code))"
    case let .FailToRemoveAllValues(error):
      return "Failed to remove all values. Underlying error: \(error.localizedDescription) (Code: \(error.code))"
    }
  }
}
