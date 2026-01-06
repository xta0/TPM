/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

final class MemoryCache<K: Hashable & Equatable & Sendable, V: Any>: SyncCache, @unchecked Sendable {

  typealias Key = K
  typealias Value = V

  private var cache: [Key: Value] = [:]
  private let lock = NSLock()
  private var name = ""

  init(_ name: String) {
    self.name = name
    observeMemoryWarning()
  }
}

// MARK: - Sync Cache APIs

extension MemoryCache {

  func value(forKey key: K) -> V? {
    Log(.debug, message: "Read value for key: \(key)")
    return lock.with {
      cache[key]
    }
  }

  @discardableResult
  func set(_ value: V, forKey key: K) -> CacheError<K> {
    Log(.debug, message: "Set value for key: \(key)")
    lock.with {
      cache[key] = value
    }
    return .None
  }

  @discardableResult
  func removeValue(forKey key: K) -> CacheError<K> {
    Log(.debug, message: "Remove value for key: \(key)")
    lock.with {
      cache.removeValue(forKey: key)
    }
    return .None
  }

  @discardableResult
  func removeAll() -> CacheError<K> {
    Log(.debug, message: "Remove all values")
    lock.with {
      cache.removeAll()
    }
    return .None
  }

  @discardableResult
  func dump() -> [K: V] {
    lock.with {
      cache
    }
  }
}

// MARK: - Keys

extension MemoryCache {
  var synchronizedKeys: Set<Key> {
    lock.with {
      Set(cache.keys)
    }
  }

  func iterateKeys(_ block: (_ key: Key) throws -> Void) rethrows {
    let keysCopy = synchronizedKeys
    try keysCopy.forEach { key in
      try block(key)
    }
  }
}

// MARK: - Memory Warnings

extension MemoryCache where MemoryCache: AnyObject {
  private func observeMemoryWarning() {
    NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: OperationQueue.main) { _ in
      self.onReceiveMemoryWarning()
    }
  }

  private func onReceiveMemoryWarning() {
    Log(.info, message: "Receiving memory warning!")
    // Don't do anything yet
  }
}

extension MemoryCache: Logging {
  var prefix: String {
    "🔔 | \(name) |"
  }
}
