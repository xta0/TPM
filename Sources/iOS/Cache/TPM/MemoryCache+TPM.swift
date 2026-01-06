/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension MemoryCache: TypeSafeAPIWrapper where K == String, V == Any {
  func integer(forKey key: String) -> Int? {
    _value(forKey: key)
  }

  func double(forKey key: String) -> Double? {
    _value(forKey: key)
  }

  func bool(forKey key: String) -> Bool? {
    _value(forKey: key)
  }

  func string(forKey key: String) -> String? {
    _value(forKey: key)
  }

  func json(forKey key: String) -> DynamicJSON? {
    _value(forKey: key)
  }

  func date(forKey key: String) -> Date? {
    if let dateInSeconds = double(forKey: key) {
      return Date(timeIntervalSince1970: dateInSeconds)
    }
    return nil
  }

  func array<T: Any>(forKey key: String) -> [T]? {
    _value(forKey: key)
  }

  func dictionary<T: Any>(forKey key: String) -> [String: T]? {
    _value(forKey: key)
  }

  @discardableResult
  func setInt(_ value: Int, forKey key: String) -> TypeSafeAPIWrapperError {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setDouble(_ value: Double, forKey key: String) -> TypeSafeAPIWrapperError {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setBool(_ value: Bool, forKey key: String) -> TypeSafeAPIWrapperError {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setString(_ value: String, forKey key: String) -> TypeSafeAPIWrapperError {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setJSON(_ value: DynamicJSON, forKey key: String) -> TypeSafeAPIWrapperError {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setDate(_ value: Date, forKey key: String) -> TypeSafeAPIWrapperError {
    let dateInSeconds = value.timeIntervalSince1970
    return setDouble(dateInSeconds, forKey: key)
  }

  @discardableResult
  func setArray<T>(_ value: [T], forKey key: String) -> TypeSafeAPIWrapperError where T: Any {
    return _set(value, forKey: key)
  }

  @discardableResult
  func setDictionary<T>(_ value: [String: T], forKey key: String) -> TypeSafeAPIWrapperError where T: Any {
    return _set(value, forKey: key)
  }

  @discardableResult
  func removeObject(forKey key: String) -> TypeSafeAPIWrapperError {
    let error = removeValue(forKey: key)
    return error == .None ? .None : .Internal(error)
  }

  @discardableResult
  func removeAllObjects() -> TypeSafeAPIWrapperError {
    let error = removeAll()
    return error == .None ? .None : .Internal(error)
  }
}

extension MemoryCache where K == String, V == Any {
  private func _value<T>(forKey key: String) -> T? {
    value(forKey: key) as? T
  }

  private func _set<T>(_ value: T, forKey key: String) -> TypeSafeAPIWrapperError {
    let error = set(value, forKey: key)
    return .Internal(error)
  }
}
