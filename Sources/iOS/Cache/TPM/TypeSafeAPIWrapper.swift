/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum TypeSafeAPIWrapperError {
  case None
  case Internal(Error?)
  case KeyIsMissing
  case TypeCastFailed
}

protocol TypeSafeAPIWrapper {
  associatedtype KeyType: Hashable

  func integer(forKey key: KeyType) -> Int?

  func double(forKey key: KeyType) -> Double?

  func bool(forKey key: KeyType) -> Bool?

  func string(forKey key: KeyType) -> String?

  func json(forKey key: KeyType) -> DynamicJSON?

  func date(forKey key: KeyType) -> Date?

  func array<T: Codable>(forKey key: KeyType) -> [T]?

  func dictionary<T: Codable>(forKey key: KeyType) -> [String: T]?

  @discardableResult
  func setInt(_ value: Int, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setDouble(_ value: Double, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setBool(_ value: Bool, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setString(_ value: String, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setJSON(_ value: DynamicJSON, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setDate(_ value: Date, forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setArray<T: Codable>(_ value: [T], forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func setDictionary<T: Codable>(_ value: [String: T], forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func removeObject(forKey key: KeyType) -> TypeSafeAPIWrapperError

  @discardableResult
  func removeAllObjects() -> TypeSafeAPIWrapperError
}

extension TypeSafeAPIWrapperError: Equatable {
  static func == (lhs: TypeSafeAPIWrapperError, rhs: TypeSafeAPIWrapperError) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None):
      return true
    case (.KeyIsMissing, .KeyIsMissing):
      return true
    case (.Internal, .Internal):
      return true
    case (.TypeCastFailed, .TypeCastFailed):
      return true
    default:
      return false
    }
  }
}
