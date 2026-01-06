/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Endpoint where T == DynamicJSON {
  enum NetworkConfigs {
    static let timeoutSeconds: TimeInterval = 15.0
    static let baseDelayInHours = 1
    static let maxJitterInHours = 3
    static func defaultHTTPHeaderFields() -> [String: String] {
      [
        "User-Agent": "TPMiOS.\(AppConfigs.version)",
      ]
    }

    static func defaultHTTPParams() -> [String: String] {
      [
        "format": "json",
        "platform": "ios",
        "include_headers": "false",
      ]
    }
  }
}
