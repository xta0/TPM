/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct Endpoint<T>: Sendable {
  var method: Method
  var url: URL
  var contentType: ContentType? = .json
  var contentEncoding: ContentEncoding?
  var accept: ContentType?
  var body: Data?
  var headers: [String: String] = [:]
  var timeOutInterval: TimeInterval = 15
  /// set this to true if the endpoint needs to perform the exponential backoff
  var backoff = false
  var query: [String: String] = [:]
  /// This is used to (try to) parse a response into an `T`.
  var parse: @Sendable (Data?, URLResponse?, Error?) -> Result<T, NetworkError>
}

extension Endpoint {
  enum ContentType: String {
    case json = "application/json"
  }

  enum Method: String {
    case GET
    case POST
  }

  enum ContentEncoding: String {
    case gzip
  }
}

extension Endpoint {
  var request: URLRequest? {
    var requestUrl: URL?
    if query.isEmpty {
      requestUrl = url
    } else {
      if method == .GET {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: true)
        var queryItems = comps?.queryItems ?? []
        queryItems.append(contentsOf: query.sorted(by: <).map { URLQueryItem(name: $0.0, value: $0.1) })
        comps?.queryItems = queryItems
        requestUrl = comps?.url
      } else if method == .POST {
        requestUrl = url
      }
    }
    guard let requestUrl else {
      return nil
    }
    var request = URLRequest(url: requestUrl)
    if let accept {
      request.setValue(accept.rawValue, forHTTPHeaderField: "Accept")
    }

    if let contentType {
      request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
    }
    if let contentEncoding {
      request.setValue(contentEncoding.rawValue, forHTTPHeaderField: "Content-Encoding")
    }
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    request.timeoutInterval = timeOutInterval
    request.httpMethod = method.rawValue
    request.httpShouldHandleCookies = false
    // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
    request.httpBody = body
    return request
  }
}

// MARK: - CustomStringConvertible

extension Endpoint: CustomStringConvertible {
  var description: String {
    let data = request?.httpBody ?? Data()
    return "\(request?.httpMethod ?? "GET") \(request?.url?.absoluteString ?? "<no url>") \(String(data: data, encoding: .utf8) ?? "")"
  }
}

// MARK: - Logging

extension Endpoint: Logging {}
