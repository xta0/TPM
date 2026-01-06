/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum ComposableCacheType {
  case sync(any SyncCache)
  case async(any AsyncCache)
}

enum ComposableCacheError: Int {
  case MissingSyncImpl = 500
  case MissingAsyncImpl
  case internalError
}

struct ComposableCache<K: Equatable & Sendable, V: Sendable>: SyncCache, AsyncCache, @unchecked Sendable {
  typealias Key = K
  typealias Value = V

  var syncGetImpl: (@Sendable (_ key: K) -> V?)?
  var syncSetImpl: (@Sendable (_ value: V, _ key: K) -> CacheError<K>)?
  var syncRemoveImpl: (@Sendable (_ key: K) -> CacheError<K>)?
  var syncRemoveAllImpl: (@Sendable () -> CacheError<K>)?

  var asyncGetImpl: (@Sendable (_ key: K, (@Sendable (Result<V, CacheError<K>>) -> Void)?) -> Void)?
  var asyncSetImpl: (@Sendable (_ value: V, _ key: K, (@Sendable (Result<K, CacheError<K>>) -> Void)?) -> Void)?
  var asyncRemoveImpl: (@Sendable (_ key: K, (@Sendable (Result<K, CacheError<K>>) -> Void)?) -> Void)?
  var asyncRemoveAllImpl: (@Sendable ((@Sendable (CacheError<K>) -> Void)?) -> Void)?

  func value(forKey key: K) -> V? {
    return syncGetImpl?(key)
  }

  @discardableResult
  func set(_ value: V, forKey key: K) -> CacheError<K> {
    guard let impl = syncSetImpl else {
      return .FailToSetValueForKey(key, ComposableCacheError.MissingSyncImpl.toNSError)
    }
    return impl(value, key)
  }

  @discardableResult
  func removeValue(forKey key: K) -> CacheError<K> {
    guard let impl = syncRemoveImpl else {
      return .FailToRemoveValueForKey(key, ComposableCacheError.MissingSyncImpl.toNSError)
    }
    return impl(key)
  }

  @discardableResult
  func removeAll() -> CacheError<K> {
    guard let impl = syncRemoveAllImpl else {
      return .FailToRemoveAllValues(ComposableCacheError.MissingSyncImpl.toNSError)
    }
    return impl()
  }

  func value(forKey key: K, completion: (@Sendable (Result<V, CacheError<K>>) -> Void)?) {
    guard let impl = asyncGetImpl else {
      completion?(.failure(.FailToGetValueForKey(key, ComposableCacheError.MissingAsyncImpl.toNSError)))
      return
    }
    impl(key, completion)
  }

  func set(_ value: V, forKey key: K, completion: (@Sendable (Result<K, CacheError<K>>) -> Void)?) {
    guard let impl = asyncSetImpl else {
      completion?(.failure(.FailToSetValueForKey(key, ComposableCacheError.MissingAsyncImpl.toNSError)))
      return
    }
    impl(value, key, completion)
  }

  func removeValue(forKey key: K, completion: (@Sendable (Result<K, CacheError<K>>) -> Void)?) {
    guard let impl = asyncRemoveImpl else {
      completion?(.failure(.FailToRemoveValueForKey(key, ComposableCacheError.MissingAsyncImpl.toNSError)))
      return
    }
    impl(key, completion)
  }

  func removeAll(completion: (@Sendable (CacheError<K>) -> Void)?) {
    guard let impl = asyncRemoveAllImpl else {
      completion?(.FailToRemoveAllValues(ComposableCacheError.MissingAsyncImpl.toNSError))
      return
    }
    impl(completion)
  }
}

extension ComposableCacheError: CustomStringConvertible {
  var description: String {
    switch self {
    case .MissingSyncImpl:
      return "Missing synchronous implementation."
    case .MissingAsyncImpl:
      return "Missing asynchronous implementation."
    case .internalError:
      return "An internal error occurred."
    }
  }

  var toNSError: NSError {
    CacheErrorFactory.createGenericNSError(code: rawValue, description: description)
  }
}
