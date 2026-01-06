/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import os.log

enum Level: String {
  case debug
  case info
  case error
  case fault
  case warning
}

protocol Logging {
  var prefix: String { get }
}

extension Logging {
  var fileName: String {
    String(describing: type(of: self))
  }

  var prefix: String {
    ""
  }

  func Log(_ level: Level, message: String, lineNumber: Int = #line, shouldCaptureTelemetrySignals: Bool = true) {
    Logger.log(level, message: message, fileName: fileName, prefix: prefix, lineNumber: lineNumber)
  }
}

extension OSLogType {
  static let warning = OSLogType(rawValue: 128)
}

struct Logger: Logging {
  private static let subsystem = "com.vizlab.tpmios"
  private static let category = "General"
  private static let sdkPrefix = "[AHSDK]"
  private static let osLog = OSLog(subsystem: subsystem, category: category)

  static func log(_ level: Level, message: String, fileName: String? = nil, prefix: String? = nil, lineNumber: Int = #line) {
    let type: OSLogType
    switch level {
    case .debug: type = .debug
    case .info: type = .info
    case .error: type = .error
    case .fault: type = .fault
    case .warning: type = .warning
    }
    let filePath = fileName ?? "Unknown File"
    let fileNameWithoutExtension = ((filePath as NSString).lastPathComponent as NSString).deletingPathExtension
    let thread = Thread.current.isMainThread ? "🟢" : "🟡"
    let message = "\(thread) \(sdkPrefix)[\(fileNameWithoutExtension): \(lineNumber)]\(prefix ?? "") \(message)"
    os_log("%{public}@", log: Logger.osLog, type: type, message)
  }
}
