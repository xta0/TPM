/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension String {
  var boolValue: Bool {
    return (self as NSString).boolValue
  }

  var doublelValue: Double {
    return (self as NSString).doubleValue
  }

  var intValue: Int {
    return (self as NSString).integerValue
  }

  var prefixedWithHttps: String {
    if hasPrefix("http://") || hasPrefix("https://") {
      return self
    } else {
      return "https://" + self
    }
  }

  var nonEmptyString: String? {
    return isEmpty ? nil : self
  }
}
