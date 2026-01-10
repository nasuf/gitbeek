//
//  APIClient.swift
//  GitBeek
//
//  Generic HTTP client using async/await and URLSession
//

import Foundation

/// Protocol for request interception
protocol RequestInterceptor: Sendable {
    /// Called before the request is sent
    func intercept(request: inout URLRequest) async throws

    /// Called after a response is received (can retry)
    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @Sendable @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse)
}

// Default implementation
extension RequestInterceptor {
    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @Sendable @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        return (data, response)
    }
}

/// Main API client for making network requests
actor APIClient {
    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var interceptors: [any RequestInterceptor]
    private var authToken: String?

    // MARK: - Initialization

    init(
        baseURL: URL,
        session: URLSession = .shared,
        interceptors: [any RequestInterceptor] = []
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors

        self.decoder = JSONDecoder()
        // GitBook API returns ISO8601 dates with fractional seconds
        // Use custom strategy to support multiple ISO8601 formats
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try with fractional seconds first
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFractional.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601 without fractional seconds
            let formatterStandard = ISO8601DateFormatter()
            formatterStandard.formatOptions = [.withInternetDateTime]
            if let date = formatterStandard.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string '\(dateString)'. Expected ISO8601 format (with or without fractional seconds)."
            )
        }
        // GitBook API uses camelCase, not snake_case

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        // GitBook API expects camelCase
    }

    // MARK: - Configuration

    /// Set the authentication token
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    /// Get the current auth token
    func getAuthToken() -> String? {
        return authToken
    }

    /// Add an interceptor
    func addInterceptor(_ interceptor: any RequestInterceptor) {
        interceptors.append(interceptor)
    }

    // MARK: - Request Execution

    /// Execute a request and decode the response
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let (data, _) = try await executeRequest(endpoint)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Execute a request without expecting a response body
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let (_, response) = try await executeRequest(endpoint)

        // Accept 2xx and 204 No Content
        guard (200...299).contains(response.statusCode) else {
            throw APIError.from(statusCode: response.statusCode, data: nil)
        }
    }

    /// Execute a request and return raw data
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        let (data, _) = try await executeRequest(endpoint)
        return data
    }

    // MARK: - Private Methods

    private func executeRequest(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        // Build the initial request
        var request = try endpoint.buildRequest(baseURL: baseURL, authToken: authToken)

        // Apply interceptors (before request)
        for interceptor in interceptors {
            try await interceptor.intercept(request: &request)
        }

        // Log request in debug mode
        #if DEBUG
        logRequest(request)
        #endif

        // Execute the request
        let (data, httpResponse) = try await performRequest(request)

        // Log response in debug mode
        #if DEBUG
        logResponse(httpResponse, data: data)
        #endif

        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.from(statusCode: httpResponse.statusCode, data: data)
        }

        // Apply interceptors (after response)
        var finalData = data
        var finalResponse = httpResponse

        // Capture request by value for sendable closure
        let capturedRequest = request

        for interceptor in interceptors {
            (finalData, finalResponse) = try await interceptor.intercept(
                response: finalResponse,
                data: finalData,
                request: capturedRequest
            ) { [capturedRequest] in
                try await self.performRequest(capturedRequest)
            }
        }

        return (finalData, finalResponse)
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            return (data, httpResponse)
        } catch let error as URLError {
            throw APIError.from(urlError: error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(error)
        }
    }

    // MARK: - Logging

    #if DEBUG
    private nonisolated func logRequest(_ request: URLRequest) {
        print("🌐 [\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "?")")

        if let headers = request.allHTTPHeaderFields {
            let sanitizedHeaders = headers.mapValues { key, value in
                key == "Authorization" ? "Bearer ***" : value
            }
            print("   Headers: \(sanitizedHeaders)")
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            let truncated = bodyString.prefix(500)
            print("   Body: \(truncated)\(bodyString.count > 500 ? "..." : "")")
        }
    }

    private nonisolated func logResponse(_ response: HTTPURLResponse, data: Data) {
        let statusEmoji = (200...299).contains(response.statusCode) ? "✅" : "❌"
        print("\(statusEmoji) [\(response.statusCode)] \(response.url?.absoluteString ?? "?")")

        if let bodyString = String(data: data, encoding: .utf8) {
            let truncated = bodyString.prefix(500)
            print("   Response: \(truncated)\(bodyString.count > 500 ? "..." : "")")
        }
    }
    #endif
}

// MARK: - Dictionary Extension for Logging

private extension Dictionary where Key == String, Value == String {
    func mapValues(_ transform: (Key, Value) -> Value) -> [Key: Value] {
        var result = [Key: Value]()
        for (key, value) in self {
            result[key] = transform(key, value)
        }
        return result
    }
}

