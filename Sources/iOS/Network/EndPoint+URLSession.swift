/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if swift(>=5.5) && canImport(Darwin)
@available(iOS 15, macOS 12.0, *)
extension URLSession {
  /// Loads the contents of a `Endpoint` and delivers the data asynchronously.
  func load<T>(_ e: Endpoint<T>) async throws -> T {
    guard let request = e.request else {
      throw NetworkError.URLRequestNotAvailablle
    }
    #if USE_AHSDK_DEBUG_APIS
    let (dateString, cacheKey, networkRequestInfo) = logRequest(request)
    #endif
    let (data, resp) = try await self.data(for: request)
    #if USE_AHSDK_DEBUG_APIS
    logResponse(resp as? HTTPURLResponse, responseData: data, dateString: dateString, cacheKey: cacheKey, networkRequestInfo: networkRequestInfo)
    #endif
    return try e.parse(data, resp, nil).get()
  }
}
#endif

// MARK: - Combine

#if canImport(Combine)
import Combine

extension URLSession {
  /// Returns a publisher that wraps a URL session data task for a given Endpoint.
  func load<T>(_ e: Endpoint<T>) -> AnyPublisher<T, Error> {
    guard let request = e.request else {
      return Fail(error: NetworkError.URLRequestNotAvailablle)
        .eraseToAnyPublisher()
    }
    #if USE_AHSDK_DEBUG_APIS
    let (dateString, cacheKey, networkRequestInfo) = logRequest(request)
    #endif
    return dataTaskPublisher(for: request)
      .tryMap { data, resp in
        #if USE_AHSDK_DEBUG_APIS
        self.logResponse(resp as? HTTPURLResponse, responseData: data, dateString: dateString, cacheKey: cacheKey, networkRequestInfo: networkRequestInfo)
        #endif
        return try e.parse(data, resp, nil).get()
      }
      .eraseToAnyPublisher()
  }
}
#endif

extension URLSession: Logging {
  var prefix: String {
    "🛜"
  }
}
