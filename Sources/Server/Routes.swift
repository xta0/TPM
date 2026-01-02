/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Vapor

enum Routes {
  static func register(_ app: Application, store: MediaStore) throws {

    app.get("v1", "health") { _ in "OK" }

    app.get("v1", "state") { _ async throws -> StateStore.StateResponse in
      try store.stateStore.readState()
    }

    // Streamed upload: one file per request.
    // Vapor: when body is streamed, you must use req.body.drain. :contentReference[oaicite:3]{index=3}
    app.on(.POST, "v1", "upload", body: .stream) { req async throws -> UploadResponse in
      let filename = req.headers.first(name: "X-Filename") ?? "upload.bin"
      return try await store.ingestStreamedUpload(req: req, originalFilename: filename)
    }
  }
}
