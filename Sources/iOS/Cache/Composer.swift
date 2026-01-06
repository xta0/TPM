/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension SyncCache {
  // SyncCache + SyncCache
  func compose<T: SyncCache>(_ cache: T) -> ComposableCache<T.Key, T.Value> where Key == T.Key, Value == T.Value {
    var composableCache = ComposableCache<Key, Value>()
    composableCache.syncGetImpl = { key in
      if let result = self.value(forKey: key) {
        return result
      }
      if let result = cache.value(forKey: key) {
        self.set(result, forKey: key)
        return result
      }
      return nil
    }
    composableCache.syncSetImpl = { value, key in
      let e1 = self.set(value, forKey: key)
      let e2 = cache.set(value, forKey: key)
      return CacheError<T.Key>.zip(error1: e1, error2: e2)
    }
    composableCache.syncRemoveImpl = { key in
      let e1 = self.removeValue(forKey: key)
      let e2 = cache.removeValue(forKey: key)
      return CacheError<T.Key>.zip(error1: e1, error2: e2)
    }
    composableCache.syncRemoveAllImpl = {
      let e1 = self.removeAll()
      let e2 = cache.removeAll()
      return CacheError<T.Key>.zip(error1: e1, error2: e2)
    }
    let syncGetImpl = composableCache.syncGetImpl
    composableCache.asyncGetImpl = { key, completion in
      if let result = syncGetImpl?(key) {
        completion?(.success(result))
      } else {
        completion?(.failure(.FailToGetValueForKey(key, ComposableCacheError.internalError.toNSError)))
      }
    }
    let syncSetImpl = composableCache.syncSetImpl
    composableCache.asyncSetImpl = { value, key, completion in
      if let result = syncSetImpl?(value, key) {
        if result == .None {
          completion?(.success(key))
        } else {
          completion?(.failure(result))
        }
      } else {
        completion?(.failure(.FailToSetValueForKey(key, ComposableCacheError.internalError.toNSError)))
      }
    }
    let syncRemoveImpl = composableCache.syncRemoveImpl
    composableCache.asyncRemoveImpl = { key, completion in
      if let result = syncRemoveImpl?(key) {
        if result == .None {
          completion?(.success(key))
        } else {
          completion?(.failure(result))
        }
      } else {
        completion?(.failure(.FailToRemoveValueForKey(key, ComposableCacheError.internalError.toNSError)))
      }
    }
    let syncRemoveAllImpl = composableCache.syncRemoveAllImpl
    composableCache.asyncRemoveAllImpl = { completion in
      if let error = syncRemoveAllImpl?() {
        completion?(error)
        return
      }
      completion?(.None)
    }
    return composableCache
  }

  // SyncCache + AsyncCache
  func compose<T: AsyncCache>(_ cache: T) -> ComposableCache<T.Key, T.Value> where Key == T.Key, Value == T.Value {
    var composableCache = ComposableCache<Key, Value>()
    composableCache.syncGetImpl = { key in
      if let result = self.value(forKey: key) {
        return result
      }
      cache.value(forKey: key) { result in
        if let value = try? result.get() {
          self.set(value, forKey: key)
        }
      }
      return nil
    }
    composableCache.syncSetImpl = { value, key in
      let e = self.set(value, forKey: key)
      cache.set(value, forKey: key, completion: nil)
      return e
    }
    composableCache.syncRemoveImpl = { key in
      let e = self.removeValue(forKey: key)
      cache.removeValue(forKey: key, completion: nil)
      return e
    }
    composableCache.syncRemoveAllImpl = {
      let e = self.removeAll()
      cache.removeAll(completion: nil)
      return e
    }
    composableCache.asyncGetImpl = { key, completion in
      if let result = self.value(forKey: key) {
        completion?(.success(result))
      } else {
        cache.value(forKey: key) { result in
          switch result {
          case let .success(value):
            self.set(value, forKey: key)
            completion?(.success(value))
          case let .failure(error):
            completion?(.failure(error))
          }
        }
      }
    }
    composableCache.asyncSetImpl = { value, key, completion in
      let e = self.set(value, forKey: key)
      if e != .None {
        completion?(.failure(e))
      } else {
        cache.set(value, forKey: key, completion: completion)
      }
    }
    composableCache.asyncRemoveImpl = { key, completion in
      let e = self.removeValue(forKey: key)
      if e != .None {
        completion?(.failure(e))
      } else {
        cache.removeValue(forKey: key, completion: completion)
      }
    }
    composableCache.asyncRemoveAllImpl = { completion in
      let e = self.removeAll()
      if e != .None {
        completion?(e)
      } else {
        cache.removeAll(completion: completion)
      }
    }
    return composableCache
  }
}

extension AsyncCache {
  // AsyncCache + AsyncCache
  // If we compose two async caches, the sync impls will be nil
  func compose<T: AsyncCache>(_ cache: T) -> ComposableCache<T.Key, T.Value> where Key == T.Key, Value == T.Value {
    var composableCache = ComposableCache<Key, Value>()
    composableCache.asyncGetImpl = { key, completion in
      self.value(forKey: key) { result in
        switch result {
        case let .success(value):
          completion?(.success(value))
        case .failure:
          cache.value(forKey: key) { result in
            switch result {
            case let .success(val):
              completion?(.success(val))
              self.set(val, forKey: key, completion: nil)
            case let .failure(error):
              completion?(.failure(error))
            }
          }
        }
      }
    }
    composableCache.asyncSetImpl = { value, key, completion in
      self.set(value, forKey: key) { result in
        switch result {
        case let .success(key):
          cache.set(value, forKey: key, completion: completion)
        case let .failure(error):
          completion?(.failure(error))
        }
      }
    }
    composableCache.asyncRemoveImpl = { key, completion in
      self.removeValue(forKey: key) { result in
        switch result {
        case let .success(key):
          cache.removeValue(forKey: key, completion: completion)
        case let .failure(error):
          completion?(.failure(error))
        }
      }
    }
    composableCache.asyncRemoveAllImpl = { completion in
      self.removeAll { error in
        if error == .None {
          cache.removeAll(completion: completion)
        } else {
          completion?(error)
        }
      }
    }
    return composableCache
  }
}
