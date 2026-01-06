/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol SyncCache: Sendable {
  associatedtype Key: Equatable
  associatedtype Value

  func value(forKey key: Key) -> Value?

  @discardableResult
  func set(_ value: Value, forKey key: Key) -> CacheError<Key>

  @discardableResult
  func removeValue(forKey key: Key) -> CacheError<Key>

  @discardableResult
  func removeAll() -> CacheError<Key>
}

protocol AsyncCache: Sendable {
  associatedtype Key: Equatable
  associatedtype Value

  func value(forKey key: Key, completion: (@Sendable (Result<Value, CacheError<Key>>) -> Void)?)
  func set(_ value: Value, forKey key: Key, completion: (@Sendable (Result<Key, CacheError<Key>>) -> Void)?)
  func removeValue(forKey key: Key, completion: (@Sendable (Result<Key, CacheError<Key>>) -> Void)?)
  func removeAll(completion: (@Sendable (CacheError<Key>) -> Void)?)
}

// MARK: - Subscription

extension SyncCache {
  subscript(key: Key) -> Value? {
    get { value(forKey: key) }
    set {
      guard let value = newValue else {
        removeValue(forKey: key)
        return
      }
      set(value, forKey: key)
    }
  }
}
