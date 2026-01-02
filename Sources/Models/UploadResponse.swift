/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Vapor

struct UploadResponse: Content {
  let storedPath: String
  let captureDateISO: String
  let lastTimestampMs: Int64
}
