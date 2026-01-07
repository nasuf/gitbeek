//
//  APIError.swift
//  GitBeek
//
//  Network error types for API communication
//

import Foundation

/// Represents all possible API errors
enum APIError: LocalizedError, Equatable {
    // MARK: - Network Errors

    /// No internet connection
    case noConnection

    /// Request timed out
    case timeout

    /// Server is unreachable
    case serverUnreachable

    /// SSL/TLS certificate error
    case sslError

    // MARK: - HTTP Errors

    /// Bad request (400)
    case badRequest(message: String?)

    /// Unauthorized - token invalid or expired (401)
    case unauthorized

    /// Forbidden - insufficient permissions (403)
    case forbidden(message: String?)

    /// Resource not found (404)
    case notFound(resource: String?)

    /// Method not allowed (405)
    case methodNotAllowed

    /// Conflict - resource already exists (409)
    case conflict(message: String?)

    /// Unprocessable entity - validation error (422)
    case validationError(errors: [ValidationError])

    /// Rate limited (429)
    case rateLimited(retryAfter: TimeInterval?)

    /// Internal server error (500)
    case serverError(message: String?)

    /// Service unavailable (503)
    case serviceUnavailable

    // MARK: - Client Errors

    /// Failed to encode request body
    case encodingError(Error)

    /// Failed to decode response
    case decodingError(Error)

    /// Invalid URL
    case invalidURL

    /// Invalid response format
    case invalidResponse

    /// Cancelled by user
    case cancelled

    /// Unknown error
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverUnreachable:
            return "Unable to reach the server. Please try again later."
        case .sslError:
            return "A secure connection could not be established."
        case .badRequest(let message):
            return message ?? "The request was invalid."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden(let message):
            return message ?? "You don't have permission to perform this action."
        case .notFound(let resource):
            if let resource = resource {
                return "The \(resource) could not be found."
            }
            return "The requested resource could not be found."
        case .methodNotAllowed:
            return "This action is not allowed."
        case .conflict(let message):
            return message ?? "A conflict occurred. The resource may already exist."
        case .validationError(let errors):
            let messages = errors.map { $0.message }.joined(separator: ", ")
            return "Validation failed: \(messages)"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return message ?? "An internal server error occurred."
        case .serviceUnavailable:
            return "The service is temporarily unavailable. Please try again later."
        case .encodingError:
            return "Failed to prepare the request."
        case .decodingError:
            return "Failed to process the server response."
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .cancelled:
            return "The request was cancelled."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    // MARK: - Equatable

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.serverUnreachable, .serverUnreachable),
             (.sslError, .sslError),
             (.unauthorized, .unauthorized),
             (.methodNotAllowed, .methodNotAllowed),
             (.serviceUnavailable, .serviceUnavailable),
             (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.cancelled, .cancelled):
            return true
        case (.badRequest(let lm), .badRequest(let rm)),
             (.forbidden(let lm), .forbidden(let rm)),
             (.notFound(let lm), .notFound(let rm)),
             (.conflict(let lm), .conflict(let rm)),
             (.serverError(let lm), .serverError(let rm)):
            return lm == rm
        case (.rateLimited(let lt), .rateLimited(let rt)):
            return lt == rt
        default:
            return false
        }
    }

    // MARK: - Helpers

    /// Whether the error is recoverable through retry
    var isRetryable: Bool {
        switch self {
        case .timeout, .serverUnreachable, .serverError, .serviceUnavailable:
            return true
        case .rateLimited:
            return true
        default:
            return false
        }
    }

    /// Whether the error requires re-authentication
    var requiresReauth: Bool {
        switch self {
        case .unauthorized:
            return true
        default:
            return false
        }
    }

    /// Create an APIError from an HTTP status code
    static func from(statusCode: Int, data: Data?) -> APIError {
        let message = data.flatMap { try? JSONDecoder().decode(ErrorResponse.self, from: $0) }?.message

        switch statusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(resource: nil)
        case 405:
            return .methodNotAllowed
        case 409:
            return .conflict(message: message)
        case 422:
            if let data = data,
               let validationResponse = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
                return .validationError(errors: validationResponse.errors)
            }
            return .validationError(errors: [])
        case 429:
            // TODO: Parse Retry-After header
            return .rateLimited(retryAfter: nil)
        case 500...599:
            if statusCode == 503 {
                return .serviceUnavailable
            }
            return .serverError(message: message)
        default:
            return .invalidResponse
        }
    }

    /// Create an APIError from a URLError
    static func from(urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost:
            return .serverUnreachable
        case .serverCertificateUntrusted, .secureConnectionFailed:
            return .sslError
        case .cancelled:
            return .cancelled
        default:
            return .unknown(urlError)
        }
    }
}

// MARK: - Supporting Types

/// Represents a single validation error
struct ValidationError: Codable, Equatable {
    let field: String
    let message: String
    let code: String?

    init(field: String, message: String, code: String? = nil) {
        self.field = field
        self.message = message
        self.code = code
    }
}

/// Response structure for error messages
struct ErrorResponse: Codable {
    let message: String
    let code: String?
    let details: [String: String]?
}

/// Response structure for validation errors
struct ValidationErrorResponse: Codable {
    let message: String
    let errors: [ValidationError]
}
