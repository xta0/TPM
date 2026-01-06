/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum Perf {
  // Use this function to measure the code execution time.
  static func measure(_ name: String, _ block: () -> Void) {
    #if DEBUG
    let startTime = CFAbsoluteTimeGetCurrent()
    block()
    let endTime = CFAbsoluteTimeGetCurrent()
    let timeElapsed = endTime - startTime
    Logger.log(.info, message: "⏰ | \(name) | Time elapsed: \(timeElapsed) seconds", fileName: #file)
    #else
    block()
    #endif
  }
}
