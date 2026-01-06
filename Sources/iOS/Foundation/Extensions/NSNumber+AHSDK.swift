/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

extension NSNumber {
  var isBool: Bool {
    let objCType = String(cString: self.objCType)
    if (compare(trueNumber) == .orderedSame && objCType == trueObjCType) || (compare(falseNumber) == .orderedSame && objCType == falseObjCType) {
      return true
    } else {
      return false
    }
  }

  var isInt: Bool {
    let numberType = CFNumberGetType(self as CFNumber)
    return numberType == .charType ||
      numberType == .shortType ||
      numberType == .intType ||
      numberType == .longType ||
      numberType == .longLongType ||
      numberType == .sInt8Type ||
      numberType == .sInt16Type ||
      numberType == .sInt32Type ||
      numberType == .sInt64Type
  }

  var isFloat: Bool {
    let numberType = CFNumberGetType(self as CFNumber)
    return numberType == .floatType ||
      numberType == .float32Type ||
      numberType == .float64Type
  }

  var isDouble: Bool {
    let numberType = CFNumberGetType(self as CFNumber)
    return numberType == .doubleType
  }
}
