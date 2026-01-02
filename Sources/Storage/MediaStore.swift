/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AVFoundation
import Foundation
import ImageIO
import Vapor

final class MediaStore {
  let photosRoot: URL
  let stateStore: StateStore

  private let allowedImageExts: Set<String> = ["heic", "heif", "jpg", "jpeg", "png"]
  private let allowedVideoExts: Set<String> = ["mov", "mp4", "m4v"]

  init(photosRoot: URL, stateStore: StateStore) {
    self.photosRoot = photosRoot
    self.stateStore = stateStore
  }

  func ingestStreamedUpload(req: Request, originalFilename: String) async throws -> UploadResponse {
    let ext = (originalFilename as NSString).pathExtension.lowercased()
    let isImage = allowedImageExts.contains(ext)
    let isVideo = allowedVideoExts.contains(ext)

    guard isImage || isVideo else {
      throw Abort(.unsupportedMediaType, reason: "Unsupported extension: .\(ext)")
    }

    // Temp file
    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("photo_ingress_\(UUID().uuidString).tmp")
    FileManager.default.createFile(atPath: tmpURL.path, contents: nil)
    let fh = try FileHandle(forWritingTo: tmpURL)

    // Create a promise we can await
    let donePromise = req.eventLoop.makePromise(of: Void.self)
    // Stream body to disk. Vapor’s streaming body uses req.body.drain. :contentReference[oaicite:4]{index=4}
    // Start draining (returns Void in your Vapor)
    req.body.drain { part in
      switch part {
      case var .buffer(buffer):
        do {
          if let data = buffer.readData(length: buffer.readableBytes) {
            try fh.write(contentsOf: data)
          }
          return req.eventLoop.makeSucceededFuture(())
        } catch {
          // Fail the promise and stop the chain
          donePromise.fail(error)
          return req.eventLoop.makeFailedFuture(error)
        }

      case let .error(error):
        donePromise.fail(error)
        return req.eventLoop.makeFailedFuture(error)

      case .end:
        // All bytes delivered
        do { try fh.close() } catch { /* close failure is rare; treat as error if you want */ }
        donePromise.succeed(())
        return req.eventLoop.makeSucceededFuture(())
      }
    }
    // ✅ Wait until `.end` (or an error)
    do {
      try await donePromise.futureResult.get()
    } catch {
      try? fh.close()
      try? FileManager.default.removeItem(at: tmpURL)
      throw error
    }
    // Extract capture date
    let captureDate = extractCaptureDate(fileURL: tmpURL, ext: ext) ?? Date()

    // Folder /YYYY/MM
    let (yyyy, mm) = yearMonth(captureDate)
    let destDir = photosRoot
      .appendingPathComponent(String(yyyy), isDirectory: true)
      .appendingPathComponent(String(format: "%02d", mm), isDirectory: true)

    try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

    // Rename to timestamp
    let base = timestampBaseName(captureDate) // yyyyMMdd_HHmmss_SSS
    let finalURL = uniqueURL(in: destDir, base: base, ext: ext.isEmpty ? (isImage ? "jpg" : "mov") : ext)

    try FileManager.default.moveItem(at: tmpURL, to: finalURL)

    // Update last-timestamp state file
    let lastMs = Int64(captureDate.timeIntervalSince1970 * 1000.0)
    let iso = ISO8601DateFormatter().string(from: captureDate)
    try stateStore.writeState(lastTimestampMs: lastMs, lastCaptureDateISO: iso, lastStoredPath: finalURL.path)

    return UploadResponse(storedPath: finalURL.path, captureDateISO: iso, lastTimestampMs: lastMs)
  }

  // MARK: helpers

  private func yearMonth(_ date: Date) -> (Int, Int) {
    let cal = Calendar.current
    return (cal.component(.year, from: date), cal.component(.month, from: date))
  }

  private func timestampBaseName(_ date: Date) -> String {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone.current
    df.dateFormat = "yyyyMMdd_HHmmss_SSS"
    return df.string(from: date)
  }

  private func uniqueURL(in dir: URL, base: String, ext: String) -> URL {
    var url = dir.appendingPathComponent("\(base).\(ext)")
    var i = 1
    while FileManager.default.fileExists(atPath: url.path) {
      url = dir.appendingPathComponent("\(base)_\(i).\(ext)")
      i += 1
    }
    return url
  }

  private func extractCaptureDate(fileURL: URL, ext: String) -> Date? {
    if allowedImageExts.contains(ext) { return extractImageDate(fileURL) }
    if allowedVideoExts.contains(ext) { return extractVideoDate(fileURL) }
    return nil
  }

  private func extractImageDate(_ url: URL) -> Date? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
    else { return nil }

    let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
    let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

    let s =
      (exif?[kCGImagePropertyExifDateTimeOriginal] as? String) ??
      (exif?[kCGImagePropertyExifDateTimeDigitized] as? String) ??
      (tiff?[kCGImagePropertyTIFFDateTime] as? String)

    guard let s else { return nil }

    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone.current
    df.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return df.date(from: s)
  }

  private func extractVideoDate(_ url: URL) -> Date? {
    let asset = AVURLAsset(url: url)
    if let d = asset.creationDate?.dateValue { return d }

    // fallback: try common metadata "creationDate"
    for item in asset.commonMetadata {
      if item.commonKey?.rawValue == "creationDate",
         let value = item.value as? String,
         let d = ISO8601DateFormatter().date(from: value) {
        return d
      }
    }
    return nil
  }
}
