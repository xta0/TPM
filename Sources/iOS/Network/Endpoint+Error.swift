/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum NetworkError: Error {
  case DataSetIdNotFound
  case DomainNotFound
  case EndpointBackoff
  case EndpointNotFound
  case EndpointTimeout
  case FailedToCreateEndpoint(String)
  case HTTPResponseNotAvailable
  case HTTPResponseDataNotAvailable
  case NSURLError(Error)
  case ParseJSONFailed(Error)
  case RetryFailed(Int)
  case RetryWithOtherDomainsFailed(String)
  case SDKConfigNotFound
  case ServerInternalError
  case TenantIdNotFound
  case TooManyRequests
  case TypeCastingToJSONDictionaryFailed
  case Unknown
  case UnsuccessfulStatusCode(Int)
  case URLRequestNotAvailablle
  case VersionMismatch(String)

  var code: Int {
    switch self {
    case .DataSetIdNotFound:
      return 101
    case .DomainNotFound:
      return 102
    case .EndpointBackoff:
      return 103
    case .EndpointNotFound:
      return 104
    case .EndpointTimeout:
      return 105
    case .FailedToCreateEndpoint:
      return 106
    case .HTTPResponseNotAvailable:
      return 107
    case .HTTPResponseDataNotAvailable:
      return 108
    case .NSURLError:
      return 109
    case .ParseJSONFailed:
      return 110
    case .RetryFailed:
      return 111
    case .RetryWithOtherDomainsFailed:
      return 112
    case .SDKConfigNotFound:
      return 113
    case .ServerInternalError:
      return 114
    case .TenantIdNotFound:
      return 115
    case .TooManyRequests:
      return 116
    case .TypeCastingToJSONDictionaryFailed:
      return 117
    case .Unknown:
      return 118
    case .UnsuccessfulStatusCode:
      return 119
    case .URLRequestNotAvailablle:
      return 120
    case .VersionMismatch:
      return 121
    }
  }
}

extension NetworkError: Equatable {
  static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    switch (lhs, rhs) {
    case (.NSURLError, .NSURLError):
      return true
    case (.HTTPResponseNotAvailable, .HTTPResponseNotAvailable):
      return true
    case (.HTTPResponseDataNotAvailable, .HTTPResponseDataNotAvailable):
      return true
    case (.DomainNotFound, .DomainNotFound):
      return true
    case let (.RetryWithOtherDomainsFailed(str1), .RetryWithOtherDomainsFailed(str2)):
      return str1 == str2
    case let (.FailedToCreateEndpoint(str1), .FailedToCreateEndpoint(str2)):
      return str1 == str2
    case (.EndpointBackoff, .EndpointBackoff):
      return true
    case (.EndpointNotFound, .EndpointNotFound):
      return true
    case (.EndpointTimeout, .EndpointTimeout):
      return true
    case (.ParseJSONFailed, .ParseJSONFailed):
      return true
    case (.SDKConfigNotFound, .SDKConfigNotFound):
      return true
    case (.ServerInternalError, .ServerInternalError):
      return true
    case (.TooManyRequests, .TooManyRequests):
      return true
    case (.TypeCastingToJSONDictionaryFailed, .TypeCastingToJSONDictionaryFailed):
      return true
    case (.URLRequestNotAvailablle, .URLRequestNotAvailablle):
      return true
    case (.DataSetIdNotFound, .DataSetIdNotFound):
      return true
    case (.TenantIdNotFound, .TenantIdNotFound):
      return true
    case let (.UnsuccessfulStatusCode(code1), .UnsuccessfulStatusCode(code2)):
      return code1 == code2
    case let (.VersionMismatch(str1), .VersionMismatch(str2)):
      return str1 == str2
    default:
      return false
    }
  }
}

extension NetworkError: CustomStringConvertible {
  var description: String {
    switch self {
    case .DomainNotFound:
      return "Domain not found."
    case let .RetryWithOtherDomainsFailed(string):
      return "Retrying with other domain failed: \(string)"
    case let .FailedToCreateEndpoint(string):
      return "Failed to create endpoint: \(string)"
    case .EndpointBackoff:
      return "Endpoint backoff."
    case .EndpointNotFound:
      return "Endpoint not found."
    case .EndpointTimeout:
      return "Endpoint timeout."
    case .HTTPResponseNotAvailable:
      return "HTTP response not available."
    case .HTTPResponseDataNotAvailable:
      return "HTTP response data not available."
    case let .NSURLError(error):
      return "URL error: \(error.localizedDescription)"
    case let .ParseJSONFailed(error):
      return "JSON parsing failed: \(error.localizedDescription)"
    case let .RetryFailed(code):
      return "Retry failed with code: \(code)."
    case .SDKConfigNotFound:
      return "SDK config not found."
    case .ServerInternalError:
      return "Server internal error."
    case .TooManyRequests:
      return "Too many requests."
    case .TypeCastingToJSONDictionaryFailed:
      return "Type casting to JSON dictionary failed."
    case .URLRequestNotAvailablle:
      return "URL request not available."
    case .Unknown:
      return "Unknown error."
    case .DataSetIdNotFound:
      return "Dataset ID not found."
    case .TenantIdNotFound:
      return "Tenant ID not found."
    case let .UnsuccessfulStatusCode(statusCode):
      return "Unsuccessful HTTP status code: \(statusCode)"
    case let .VersionMismatch(error):
      return "SDK and Server mismatch: \(error)"
    }
  }
}

extension NetworkError: Sendable {}
