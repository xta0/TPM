/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum CacheProvider {
  // A non-composable cache to store shared data in Memory
  static let sharedMemoryCache = MemoryCache<String, Any>("Memory Cache")
  // A non-composable cache to store SDK settings and configs
  static let sharedCentralCache = SDKCentralCache(nil)
}

extension CacheProvider {
  static func warmup() {
    Perf.measure("Cache Warmup") {
      CacheProvider.sharedCentralCache.performWarmup()
    }
  }

  static func synchronize(_ forceSync: Bool = false) {
    CacheProvider.sharedCentralCache.synchronize(forceSync, completion: nil)
  }
}
