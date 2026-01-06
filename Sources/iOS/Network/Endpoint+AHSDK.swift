/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// MARK: - Parse response

extension Endpoint where T == DynamicJSON {
  @inline(never)
  @Sendable static func defaultParser(_ responseData: Data?, response: URLResponse?, error: Error?) -> Result<DynamicJSON, NetworkError> {
    // parse errors
    if let networkError = parseError(error) {
      Logger.log(.error, message: "Network error: \(networkError.description)", fileName: #file, lineNumber: #line)
      return .failure(networkError)
    }

    // sanity checks
    guard let httpResponse = response as? HTTPURLResponse else {
      Logger.log(.error, message: "The network response object is nil!", fileName: #file, lineNumber: #line)
      return .failure(.HTTPResponseNotAvailable)
    }
    guard let responseData else {
      Logger.log(.error, message: "The network response data is nil!", fileName: #file, lineNumber: #line)
      return .failure(.HTTPResponseDataNotAvailable)
    }

    // check status code
    let statusCode = httpResponse.statusCode
    if let statusError = parserStatusCode(statusCode) {
      Logger.log(.error, message: "Network request failed with status error: \(statusError.description)", fileName: #file, lineNumber: #line)
      return .failure(statusError)
    }

    // Parse network response
    do {
      guard let result = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
        return .failure(.TypeCastingToJSONDictionaryFailed)
      }
      // Log warnings to users
      if let info = result["info"] as? String {
        Logger.log(.info, message: info, fileName: #file)
      }
      return .success(DynamicJSON(value: result))
    } catch let serializationError {
      return .failure(NetworkError.ParseJSONFailed(serializationError))
    }
  }
}

// MARK: - Factory methods

extension Endpoint where T == DynamicJSON {
  @inline(never)
  static func GET(_ path: String?, query: [String: String]?) -> Result<Endpoint<DynamicJSON>, NetworkError> {
    guard let path else {
      return .failure(.FailedToCreateEndpoint("URL Path is nil"))
    }

    guard let url = URL(string: path.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      return .failure(.FailedToCreateEndpoint("Invalid URL: \(path)"))
    }
    let params = NetworkConfigs.defaultHTTPParams().merging(query ?? [:]) { _, new in new }
    return .success(Endpoint(
      method: .GET,
      url: url,
      accept: .json,
      body: nil,
      headers: NetworkConfigs.defaultHTTPHeaderFields(),
      timeOutInterval: NetworkConfigs.timeoutSeconds,
      query: params,
      parse: Endpoint.defaultParser
    ))
  }

  @inline(never)
  static func POST(_ path: String?, query: [String: Any]?, contentEncoding encoding: ContentEncoding? = nil) -> Result<Endpoint<DynamicJSON>, NetworkError> {
    guard let path else {
      return .failure(.FailedToCreateEndpoint("URL Path is nil"))
    }
    guard let url = URL(string: path.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      return .failure(.FailedToCreateEndpoint("Invalid URL: \(path)"))
    }
    var bodyParams: [String: Any] = NetworkConfigs.defaultHTTPParams()
    // There could be a chance that a query param might override the default param. Be careful.
    for (key, value) in query ?? [:] {
      bodyParams[key] = value
    }

    guard var bodyData = Utility.data(withJSONObject: bodyParams, options: .sortedKeys) else {
      return .failure(.FailedToCreateEndpoint("POST BodyParams is invalid json"))
    }

    var contentEncoding = encoding
    if contentEncoding == .gzip {
      if let gzipBody = try? bodyData.gzipped() {
        Logger.log(.info, message: "Gzip compressed data from \(bodyData.count) to \(gzipBody.count) bytes")
        bodyData = gzipBody
      } else {
        contentEncoding = nil
        Logger.log(.error, message: "Gzip failed", fileName: #file, lineNumber: #line)
      }
    }

    return .success(Endpoint(
      method: .POST,
      url: url,
      contentEncoding: contentEncoding,
      accept: .json,
      body: bodyData,
      headers: NetworkConfigs.defaultHTTPHeaderFields(),
      timeOutInterval: NetworkConfigs.timeoutSeconds,
      query: [:],
      parse: Endpoint.defaultParser
    ))
  }
}

// MARK: - Actions

extension Endpoint where T == DynamicJSON {
  @discardableResult
  static func start(_ e: Endpoint<T>) async throws(NetworkError) -> T {
    do {
      let response: T = try await URLSession.shared.load(e)
      return response
    } catch let error as NetworkError {
      throw error
    } catch let error as NSError {
      throw NetworkError.NSURLError(error)
    } catch {
      throw NetworkError.Unknown
    }
  }
}

// MARK: - Helper methods

extension Endpoint where T == DynamicJSON {
  static func parserStatusCode(_ statusCode: Int) -> NetworkError? {
    if 200 ..< 300 ~= statusCode {
      return nil
    } else if statusCode == 404 {
      return .EndpointNotFound
    } else if statusCode == 429 {
      return .TooManyRequests
    } else if 500 ..< 600 ~= statusCode {
      return .ServerInternalError
    } else if statusCode == 601 {
      return .SDKConfigNotFound
    } else if statusCode == 602 {
      return .DataSetIdNotFound
    } else if statusCode == 603 {
      return .TenantIdNotFound
    } else {
      return .UnsuccessfulStatusCode(statusCode)
    }
  }

  static func parseError(_ error: Error?) -> NetworkError? {
    guard let networkError = error as? NSError else {
      return nil
    }
    guard networkError.domain == NSURLErrorDomain else {
      return nil
    }
    let code = networkError.code
    if code == -1003 || code == -1004 {
      return .DomainNotFound
    } else if code == -1001 {
      return .EndpointTimeout
    } else {
      return .NSURLError(networkError)
    }
  }
}
