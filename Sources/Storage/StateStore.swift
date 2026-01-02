/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Vapor

final class StateStore {
  struct StateResponse: Content {
    var lastTimestampMs: Int64?
    var lastCaptureDateISO: String?
    var lastStoredPath: String?
    var updatedAtISO: String?
  }

  private let url: URL
  private let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.outputFormatting = [.prettyPrinted, .sortedKeys]
    return e
  }()

  private let decoder = JSONDecoder()

  init(stateFileURL: URL) {
    url = stateFileURL
  }

  func readState() throws -> StateResponse {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return .init(lastTimestampMs: nil, lastCaptureDateISO: nil, lastStoredPath: nil, updatedAtISO: nil)
    }
    let data = try Data(contentsOf: url)
    return try decoder.decode(StateResponse.self, from: data)
  }

  func writeState(lastTimestampMs: Int64, lastCaptureDateISO: String, lastStoredPath: String) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let state = StateResponse(
      lastTimestampMs: lastTimestampMs,
      lastCaptureDateISO: lastCaptureDateISO,
      lastStoredPath: lastStoredPath,
      updatedAtISO: ISO8601DateFormatter().string(from: Date())
    )
    let data = try encoder.encode(state)

    let tmp = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + ".tmp")
    try data.write(to: tmp, options: [.atomic])
    _ = try? FileManager.default.removeItem(at: url)
    try FileManager.default.moveItem(at: tmp, to: url)
  }
}
