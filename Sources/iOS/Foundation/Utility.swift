/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// patternlint-disable-next-line cryptokit-over-commoncrypto
import CommonCrypto
import CryptoKit
import Foundation

struct Utility {}

extension Utility {

  // MARK: - JSON Utility

  static func data(
    withJSONObject jsonObject: Any,
    options: JSONSerialization.WritingOptions
  ) -> Data? {
    do {
      if JSONSerialization.isValidJSONObject(jsonObject) {
        return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
      }
    } catch _ {}
    Logger.log(.error, message: "jsonObject argument is invalid json: \(jsonObject)", fileName: #file, lineNumber: #line)
    return nil
  }

  static func jsonObject(
    withData data: Data,
    options: JSONSerialization.ReadingOptions
  ) -> Any? {
    do {
      return try JSONSerialization.jsonObject(with: data, options: options)
    } catch _ {}
    Logger.log(.error, message: "data argument is invalid json: \(data)", fileName: #file, lineNumber: #line)
    return nil
  }

  static func object(
    forJSONString string: String
  ) -> Any? {
    guard let data = string.data(using: String.Encoding.utf8) else {
      Logger.log(.error, message: "string argument is invalid json: \(string)", fileName: #file, lineNumber: #line)
      return nil
    }
    return jsonObject(withData: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed)
  }

  static func jsonString(forObject object: Any?) -> String? {
    guard let object else {
      Logger.log(.error, message: "object argument is nil and is therefore invalid json", fileName: #file, lineNumber: #line)
      return nil
    }
    if let data = data(withJSONObject: object, options: .prettyPrinted) {
      return String(data: data, encoding: .utf8)
    }
    Logger.log(.error, message: "object argument is invalid json: \(object)", fileName: #file, lineNumber: #line)
    return nil
  }

  static func jsonString(
    forObject object: Any
  ) -> String? {
    guard let data = data(withJSONObject: object, options: .prettyPrinted) else {
      Logger.log(.error, message: "object argument is invalid json: \(object)", fileName: #file, lineNumber: #line)
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  // MARK: - Basic Utility

  static func SHA256Hash(_ input: Any?) -> String? {
    var data: NSData?
    if input is String {
      data = (input as? String)?.data(using: .utf8) as? NSData
    } else if input is Data {
      data = input as? NSData
    }
    guard let data else {
      Logger.log(.error, message: "Unable to apply Sha 256 Hash to \(input ?? "nil")", fileName: #file, lineNumber: #line)
      return nil
    }

    return SHA256.hash(data: data).hexStr
  }

  static func isSHA256Hashed(_ data: String) -> Bool {
    let range = data.range(of: "[A-Fa-f0-9]{64}", options: .regularExpression)
    return (data.count == 64) && (range != nil)
  }
}

extension Digest {
  var bytes: [UInt8] { Array(makeIterator()) }
  var data: Data { Data(bytes) }

  var hexStr: String {
    bytes.map { String(format: "%02x", $0) }.joined()
  }
}

extension URL: Logging {
  var queryParams: [String: String]? {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      Log(.error, message: "Unable to get queryItems from url \(absoluteString)")
      return nil
    }
    var params = [String: String]()
    for item in queryItems {
      let decodedKey = item.name.replacingOccurrences(of: "+", with: " ")
      let decodedValue = item.value?.replacingOccurrences(of: "+", with: " ")
      params[decodedKey] = decodedValue
    }
    return params
  }
}
