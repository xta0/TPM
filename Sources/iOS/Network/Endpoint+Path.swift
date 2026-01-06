/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum API: String, CaseIterable {
  case config = "ds/app/config/v1.0"
  case events = "ds/app/events/v1.0"
  case instrument = "ds/app/instrument/v1.0"
  case minidump = "ds/app/minidump/v1.0"
}

extension Endpoint where T == DynamicJSON {
  struct Path: RawRepresentable {
    let rawValue: String

    static var config: Path? {
      path(API.config.rawValue)
    }

    static var events: Path? {
      path(API.events.rawValue)
    }

    static var instrument: Path? {
      path(API.instrument.rawValue)
    }

    static var minidump: Path? {
      path(API.minidump.rawValue)
    }

    static var domain: String? {
      AppConfigs.serverDomain
    }

    private static func path(_ path: String) -> Path? {
      guard let sdkDomain = domain else {
        Logger.log(.error, message: "Domain is nil", fileName: #file)
        return nil
      }
      return Path(rawValue: "\(sdkDomain)/\(path)")
    }
  }
}
