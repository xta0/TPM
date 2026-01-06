/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Dictionary where Key == String {
  func bool(for key: String) -> Bool? {
    self[key] as? Bool
  }

  func string(for key: String) -> String? {
    self[key] as? String
  }

  func int(for key: String) -> Int? {
    self[key] as? Int
  }

  func double(for key: String) -> Double? {
    self[key] as? Double
  }
}
