/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import os.log

enum LogLevel: String {
  case debug
  case info
  case warning
  case error

  var osLogType: OSLogType {
    switch self {
    case .debug: return .debug
    case .info: return .info
    case .warning: return .default
    case .error: return .error
    }
  }
}

protocol Logging {
  var prefix: String { get }
}

extension Logging {
  var typeName: String {
    String(describing: type(of: self))
  }

  var prefix: String {
    ""
  }

  func log(
    _ level: LogLevel,
    _ message: String,
    file: String = #file,
    line: Int = #line
  ) {
    Logger.log(
      level,
      message,
      prefix: prefix,
      file: file,
      line: line
    )
  }
}

enum Logger {
  private static let subsystem = AppUtils.bundleID
  private static let category = "General"
  private static let osLog = OSLog(subsystem: subsystem, category: category)

  static func log(
    _ level: LogLevel,
    _ message: String,
    prefix: String = "",
    file: String = #file,
    line: Int = #line
  ) {
    let fileName = URL(fileURLWithPath: file)
      .deletingPathExtension()
      .lastPathComponent

    os_log(
      "[VGSE][%{public}@:%d]%{public}@ %{public}@",
      log: osLog,
      type: level.osLogType,
      fileName,
      line,
      prefix,
      message
    )
  }
}
