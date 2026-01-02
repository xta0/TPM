/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Vapor

actor ServerManager {
  static let shared = ServerManager()

  // Requirements
  private let photosRoot = URL(fileURLWithPath: "/Volumes/nas-4t/test", isDirectory: true)
  private let stateFile: URL

  private var app: Application!

  init() {
    stateFile = photosRoot.appendingPathComponent("_state/last_timestamp.json")
  }

  func start() async {
    do {
      app = try await Application.make()
      app.http.server.configuration.hostname = "127.0.0.1"
      app.http.server.configuration.port = 8787

      let store = MediaStore(
        photosRoot: photosRoot,
        stateStore: StateStore(stateFileURL: stateFile)
      )

      try Routes.register(app, store: store)
      print(ProcessInfo.processInfo.arguments)
      try await app.startup()

      app.logger.notice("Server started on 127.0.0.1:8787")
    } catch {
      Logger.log(.error, "Failed to start server: \(error)")
      await stop()
    }
  }

  func stop() async {
    do {
      try await app.asyncShutdown()
    } catch {
      Logger.log(.error, "Failed to stop server: \(error)")
    }
    Logger.log(.info, "Server stopped")
  }
}

extension ServerManager: Logging {}
