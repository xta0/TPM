/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum MemoryCacheKey: String, CaseIterable {
  case ExtInfoLastCheckTimeCacheKey = "com.ahsdk.extinfo.LastCheckTimeCacheKey"
  case ExtInfoLastEncodedInfoCacheKey = "com.ahsdk.extinfo.LastEncodedInfoCacheKey"
  case SysCtrlPreCPUCacheKey = "com.ahsdk.sysctrl.PreCPUCacheKey"
  case IsFirstTimeMinidumpProcess = "com.ahsdk.isFirstTimeMinidumpProcess"
  case HasSKANReporterStarted = "com.ahsdk.SKANReporterHasStarted"
  case CurrentDeviceInfoKey = "com.ahsdk.currentDeviceInfo"
}
