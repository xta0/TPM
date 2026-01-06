/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Represents a type that can be converted to a string
protocol StringConvertible {
  func toString() -> String
}

extension String: StringConvertible {
  func toString() -> String {
    self
  }
}

extension NSString: StringConvertible {
  func toString() -> String {
    self as String
  }
}

extension URL: StringConvertible {
  func toString() -> String {
    absoluteString
  }
}

extension SDKCentralCache.Keys: StringConvertible {
  func toString() -> String {
    return rawValue
  }
}
