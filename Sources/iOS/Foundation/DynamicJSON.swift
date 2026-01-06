/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// MARK: - JSON Types

// Supported JSON types
enum JSONType: Int {
  case number
  case bool
  case string
  case array
  case dictionary
  case null
  case unknown
}

struct DynamicJSON: RandomAccessCollection, Sendable {
  // a static null representation of DynamicJSON
  static var null: DynamicJSON { return DynamicJSON(value: NSNull()) }

  var startIndex: Int { arrayValue.startIndex }
  var endIndex: Int { arrayValue.endIndex }

  init?(string jsonString: String) {
    guard let data = jsonString.data(using: .utf8) else {
      Logger.log(.error, message: "jsonString is invalid json: \(jsonString)", fileName: #file, lineNumber: #line)
      return nil
    }
    self.init(data: data)
  }

  init?(data: Data, options opt: JSONSerialization.ReadingOptions = .allowFragments) {
    guard let object = try? JSONSerialization.jsonObject(with: data, options: opt) else {
      Log(.error, message: "data is invalid json: \(data)")
      return nil
    }
    value = object
  }

  init(value: Any) {
    self.value = value
  }

  // JSON types
  private(set) var type: JSONType = .null

  // private raw values
  private(set) var rawNumber: NSNumber = 0
  private(set) var rawString = ""
  private(set) var rawBool = false
  private(set) var rawArray: [any Sendable] = []
  private(set) var rawDictionary: [String: any Sendable] = [:]
  private(set) var rawNull = NSNull()

  // setters & getters
  private(set) var value: Any {
    get {
      switch type {
      case .array: return rawArray
      case .dictionary: return rawDictionary
      case .string: return rawString
      case .number: return rawNumber
      case .bool: return rawBool
      default: return rawNull
      }
    }
    set {
      switch _unWrap(newValue) {
      case let number as NSNumber:
        if number.isBool {
          type = .bool
          rawBool = number.boolValue
        } else {
          type = .number
          rawNumber = number
        }
      case let string as String:
        type = .string
        rawString = string
      case _ as NSNull:
        type = .null
      case Optional<Any>.none:
        type = .null
      case let array as [any Sendable]:
        type = .array
        rawArray = array
      case let dictionary as [String: any Sendable]:
        type = .dictionary
        rawDictionary = dictionary
      default:
        type = .unknown
      }
    }
  }
}

// MARK: - Bool

extension DynamicJSON {
  /// Optional<Bool>
  var bool: Bool? {
    switch type {
    case .bool: return rawBool
    default: return nil
    }
  }

  /// Non-optional<Bool>
  var boolValue: Bool {
    switch type {
    case .bool: return rawBool
    case .number: return rawNumber.boolValue
    case .string: return ["true", "y", "t", "yes", "1"].contains { rawString.caseInsensitiveCompare($0) == .orderedSame }
    default: return false
    }
  }
}

// MARK: - Number

extension DynamicJSON {
  /// Optional<NSNumber>
  var number: NSNumber? {
    switch type {
    case .number: return rawNumber
    case .bool: return NSNumber(value: rawBool ? 1 : 0)
    default: return nil
    }
  }

  /// Non-optional<NSNumber>
  var numberValue: NSNumber {
    switch type {
    case .string:
      let decimal = NSDecimalNumber(string: value as? String)
      return decimal == .notANumber ? .zero : decimal
    case .number: return value as? NSNumber ?? NSNumber(value: 0)
    case .bool: return NSNumber(value: rawBool ? 1 : 0)
    default: return NSNumber(value: 0.0)
    }
  }
}

// MARK: - Null

extension DynamicJSON {
  var null: NSNull? {
    switch type {
    case .null: return rawNull
    default: return nil
    }
  }
}

// MARK: - Int, Double, Float

extension DynamicJSON {

  var double: Double? {
    number?.doubleValue
  }

  var doubleValue: Double {
    numberValue.doubleValue
  }

  var float: Float? {
    number?.floatValue
  }

  var floatValue: Float {
    numberValue.floatValue
  }

  var int: Int? {
    number?.intValue
  }

  var intValue: Int {
    numberValue.intValue
  }
}

// MARK: - String

extension DynamicJSON {
  var string: String? {
    switch type {
    case .string: return rawString
    default: return nil
    }
  }

  var stringValue: String {
    switch type {
    case .string: return value as? String ?? ""
    case .number: return rawNumber.stringValue
    case .bool: return (value as? Bool).map { String($0) } ?? ""
    default: return ""
    }
  }
}

// MARK: - Array

extension DynamicJSON {
  // Optional [String: DynamicJSON]
  var array: [DynamicJSON]? {
    return type == .array ? rawArray.map { DynamicJSON(value: $0) } : nil
  }

  // Non-optional [DynamicJSON]
  var arrayValue: [DynamicJSON] {
    array ?? []
  }

  // Optional [Any]
  var arrayObject: [Any]? {
    switch type {
    case .array: return rawArray
    default: return nil
    }
  }
}

// MARK: - Dictionary

extension DynamicJSON {
  // Optional [String: DynamicJSON]
  var dictionary: [String: DynamicJSON]? {
    if type == .dictionary {
      var d = [String: DynamicJSON](minimumCapacity: rawDictionary.count)
      rawDictionary.forEach { pair in
        d[pair.key] = DynamicJSON(value: pair.value)
      }
      return d
    } else {
      Log(.error, message: "DynamicJSON type is not dictionary")
      return nil
    }
  }

  // Non-optional [String: DynamicJSON]
  var dictionaryValue: [String: DynamicJSON] {
    dictionary ?? [:]
  }

  // Optional [String: Any]
  var dictionaryObject: [String: any Sendable]? {
    switch type {
    case .dictionary: return rawDictionary
    default: return nil
    }
  }
}

// MARK: - RandomAccess

extension DynamicJSON {
  // Array subscription
  subscript(index: Int) -> DynamicJSON {
    if type == .array, rawArray.indices.contains(index) {
      return DynamicJSON(value: rawArray[index])
    }
    return DynamicJSON.null
  }

  // dictionary subscription
  subscript(key: String) -> DynamicJSON {
    if type == .dictionary, let object = rawDictionary[key] {
      return DynamicJSON(value: object)
    }
    return DynamicJSON.null
  }
}

// MARK: - Unwrap

extension DynamicJSON {
  /// Unwrap the value recursively.
  /// The result type is `Optional<Any>`
  func unWrap() -> Any {
    _unWrap(value)
  }

  private func _unWrap(_ value: Any) -> Any {
    switch value {
    case let json as DynamicJSON:
      return _unWrap(json.value)
    case let array as [Any]:
      return array.map(_unWrap)
    case let dictionary as [String: Any]:
      let d = dictionary.reduce(into: [String: Any]()) { result, pair in
        result[pair.key] = _unWrap(pair.value)
      }
      return d
    default:
      return value
    }
  }

  /// Unwrap the value to commonly used concrete dictionary types
  /// Extend this function to support more types when needed
  func unWrapDictionary<K: Hashable, T>(toType: [K: T].Type) -> [K: T]? {
    if K.self != String.self {
      Log(.error, message: "Only the `String` key type is support when unwrapping as a dictionary!")
      return nil
    }
    switch T.self {
    /// Optional<[String: String]>
    case is String.Type:
      return dictionary?.compactMapValues { $0.string as? T } as? [K: T]
    /// Optional<[String: Int]>
    case is Int.Type:
      return dictionary?.compactMapValues { $0.int as? T } as? [K: T]
    /// Optional<[String: Double]>
    case is Double.Type:
      return dictionary?.compactMapValues { $0.double as? T } as? [K: T]
    /// Optional<[String: Bool]>
    case is Bool.Type:
      return dictionary?.compactMapValues { $0.bool as? T } as? [K: T]
    /// Optional<[String: [Any]]>
    case is [Any].Type:
      return dictionary?.compactMapValues { $0.array?.compactMap { $0.value } as? T } as? [K: T]
    /// Optional<[String: [String]]>
    case is [String].Type:
      return dictionary?.compactMapValues { $0.array?.compactMap { $0.string } as? T } as? [K: T]
    /// Optional<[String: [String: String]]>
    case is [String: String].Type:
      return dictionary?.compactMapValues { $0.dictionary?.compactMapValues { $0.string } as? T } as? [K: T]
    /// Optional<[String: [String: Any]]>
    case is [String: Any].Type:
      return dictionary?.compactMapValues { $0.dictionary?.compactMapValues { $0.value } as? T } as? [K: T]
    /// Optional<[String: [[String: Any]]]>
    case is [[String: Any]].Type:
      return dictionary?.compactMapValues { $0.array?.compactMap { $0.dictionary?.compactMapValues { $0.value } } as? T } as? [K: T]
    default:
      Log(.error, message: "Unable to unwrap the value as a dictionary: \(T.self)")
      return nil
    }
  }

  /// Unwrap the value to commonly used concrete array types
  /// Extend this function to support more types when needed
  func unWrapArray<T>(toType: [T].Type) -> [T]? {
    switch T.self {
    /// Optional<[String]>
    case is String.Type:
      return array?.compactMap { $0.string as? T }
    /// Optional<[Int]>
    case is Int.Type:
      return array?.compactMap { $0.int as? T }
    /// Optional<[Double]>
    case is Double.Type:
      return array?.compactMap { $0.double as? T }
    /// Optional<[Bool]>
    case is Bool.Type:
      return array?.compactMap { $0.bool as? T }
    /// Optional<[[Any]]>
    case is [Any].Type:
      return array?.compactMap { $0.array?.compactMap { $0.value } as? T }
    /// Optional<[[String]]>
    case is [String].Type:
      return array?.compactMap { $0.array?.compactMap { $0.string } as? T }
    /// Optional<[[Int]]>
    case is [Int].Type:
      return array?.compactMap { $0.array?.compactMap { $0.int } as? T }
    /// Optional<[[Double]]>
    case is [Double].Type:
      return array?.compactMap { $0.array?.compactMap { $0.double } as? T }
    /// Optional<[[Bool]]>
    case is [Bool].Type:
      return array?.compactMap { $0.array?.compactMap { $0.bool } as? T }
    /// Optional<[[String: Any]]>
    case is [String: Any].Type:
      return array?.compactMap { $0.dictionary?.compactMapValues { $0.value } as? T }
    /// Optional<[[String: String]]>
    case is [String: String].Type:
      return array?.compactMap { $0.dictionary?.compactMapValues { $0.string } as? T }
    default:
      Log(.error, message: "Unable to unwrap the value as an array: \(T.self)")
      return nil
    }
  }
}

extension DynamicJSON: Logging {}

// MARK: - Equatable

extension DynamicJSON: Equatable {
  static func == (lhs: DynamicJSON, rhs: DynamicJSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber == rhs.rawNumber
    case (.string, .string): return lhs.rawString == rhs.rawString
    case (.bool, .bool): return lhs.rawBool == rhs.rawBool
    case (.array, .array): return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null): return true
    default: return false
    }
  }
}

// MARK: - Codable

extension DynamicJSON: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      value = NSNull()
      return
    }
    if let bool = try? container.decode(Bool.self) {
      value = bool
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let double = try? container.decode(Double.self) {
      value = double
    } else if let string = try? container.decode(String.self) {
      value = string
    } else if let array = try? container.decode([DynamicJSON].self) {
      value = array
    } else if let dict = try? container.decode([String: DynamicJSON].self) {
      value = dict
    } else {
      Log(.error, message: "Value is decoded as NSNull")
      value = NSNull()
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if value is NSNull {
      try container.encodeNil()
      return
    }
    switch _unWrap(value) {
    case let string as String:
      try container.encode(string)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let bool as Bool:
      try container.encode(bool)
    case is [Any]:
      let array = array ?? []
      try container.encode(array)
    case is [String: Any]:
      let dict = dictionary ?? [:]
      try container.encode(dict)
    default:
      break
    }
  }
}
