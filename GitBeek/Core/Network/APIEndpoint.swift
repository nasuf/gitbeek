//
//  APIEndpoint.swift
//  GitBeek
//
//  Protocol and types for defining API endpoints
//

import Foundation

/// HTTP methods supported by the API
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Content types for request/response bodies
enum ContentType: String {
    case json = "application/json"
    case formURLEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
}

/// Protocol defining an API endpoint
protocol APIEndpoint {
    /// The path component of the URL (e.g., "/orgs/{orgId}/spaces")
    var path: String { get }

    /// HTTP method for the request
    var method: HTTPMethod { get }

    /// Query parameters
    var queryParameters: [String: String]? { get }

    /// Request body (will be encoded to JSON)
    var body: Encodable? { get }

    /// Additional headers for this specific request
    var headers: [String: String]? { get }

    /// Content type for the request body
    var contentType: ContentType { get }

    /// Whether this endpoint requires authentication
    var requiresAuth: Bool { get }

    /// Timeout interval for this specific request (nil uses default)
    var timeout: TimeInterval? { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
    var queryParameters: [String: String]? { nil }
    var body: Encodable? { nil }
    var headers: [String: String]? { nil }
    var contentType: ContentType { .json }
    var requiresAuth: Bool { true }
    var timeout: TimeInterval? { nil }
}

// MARK: - Request Building

extension APIEndpoint {
    /// Build a URLRequest from this endpoint
    func buildRequest(baseURL: URL, authToken: String?) throws -> URLRequest {
        // Construct URL with path
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)

        // Add query parameters
        if let params = queryParameters, !params.isEmpty {
            urlComponents?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Set content type
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Set auth header if required and token available
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Set custom headers
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Set timeout
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        // Encode body
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(error)
            }
        }

        return request
    }
}

// MARK: - Type-Erased Encodable Wrapper

/// Wrapper to allow encoding any Encodable type
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        encodeClosure = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

// MARK: - Pagination

/// Pagination parameters for list endpoints
struct PaginationParams {
    let page: Int
    let limit: Int

    init(page: Int = 1, limit: Int = 20) {
        self.page = page
        self.limit = limit
    }

    var queryItems: [String: String] {
        [
            "page": String(page),
            "limit": String(limit)
        ]
    }
}

/// Response wrapper for paginated results
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let next: NextPage?

    struct NextPage: Decodable {
        let page: String?
    }

    var hasNextPage: Bool {
        next?.page != nil
    }

    var nextPageToken: String? {
        next?.page
    }
}
