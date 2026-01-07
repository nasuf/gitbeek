//
//  LoggingInterceptor.swift
//  GitBeek
//
//  Debug logging for network requests and responses
//

import Foundation
import OSLog

/// Interceptor that logs network requests and responses for debugging
final class LoggingInterceptor: RequestInterceptor, Sendable {
    // MARK: - Configuration

    enum LogLevel: Int, Sendable {
        case none = 0
        case basic = 1      // URL and status code only
        case headers = 2    // + headers
        case body = 3       // + body content
    }

    // MARK: - Properties

    private let logLevel: LogLevel
    private let logger: Logger

    // MARK: - Initialization

    init(logLevel: LogLevel = .basic) {
        self.logLevel = logLevel
        self.logger = Logger(subsystem: "com.gitbeek.app", category: "Network")
    }

    // MARK: - RequestInterceptor

    func intercept(request: inout URLRequest) async throws {
        guard logLevel != .none else { return }

        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"

        logger.debug("🌐 [\(method)] \(url)")

        if logLevel.rawValue >= LogLevel.headers.rawValue {
            logHeaders(request.allHTTPHeaderFields, prefix: "→")
        }

        if logLevel.rawValue >= LogLevel.body.rawValue {
            if let body = request.httpBody {
                logBody(body, prefix: "→")
            }
        }
    }

    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        guard logLevel != .none else {
            return (data, response)
        }

        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "?"
        let emoji = (200...299).contains(statusCode) ? "✅" : "❌"

        logger.debug("\(emoji) [\(statusCode)] \(url)")

        if logLevel.rawValue >= LogLevel.headers.rawValue {
            logHeaders(response.allHeaderFields as? [String: String], prefix: "←")
        }

        if logLevel.rawValue >= LogLevel.body.rawValue {
            logBody(data, prefix: "←")
        }

        return (data, response)
    }

    // MARK: - Private Methods

    private func logHeaders(_ headers: [String: String]?, prefix: String) {
        guard let headers = headers, !headers.isEmpty else { return }

        let sanitized = headers.map { key, value in
            let sanitizedValue = key.lowercased().contains("authorization") ? "***" : value
            return "   \(prefix) \(key): \(sanitizedValue)"
        }.joined(separator: "\n")

        logger.debug("\(sanitized)")
    }

    private func logBody(_ data: Data, prefix: String) {
        guard !data.isEmpty else { return }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            // Truncate long responses
            let maxLength = 2000
            let truncated = prettyString.count > maxLength
                ? String(prettyString.prefix(maxLength)) + "\n   ... (truncated)"
                : prettyString

            logger.debug("   \(prefix) Body:\n\(truncated)")
        } else if let string = String(data: data, encoding: .utf8) {
            let maxLength = 500
            let truncated = string.count > maxLength
                ? String(string.prefix(maxLength)) + "... (truncated)"
                : string

            logger.debug("   \(prefix) Body: \(truncated)")
        } else {
            logger.debug("   \(prefix) Body: <\(data.count) bytes>")
        }
    }
}

// MARK: - Network Activity Tracker

/// Tracks active network requests for UI indicators
@MainActor
@Observable
final class NetworkActivityTracker {
    static let shared = NetworkActivityTracker()

    private(set) var activeRequestCount: Int = 0

    var isLoading: Bool {
        activeRequestCount > 0
    }

    private init() {}

    func increment() {
        activeRequestCount += 1
    }

    func decrement() {
        activeRequestCount = max(0, activeRequestCount - 1)
    }
}

/// Interceptor that tracks network activity
final class NetworkActivityInterceptor: RequestInterceptor, Sendable {
    func intercept(request: inout URLRequest) async throws {
        await MainActor.run {
            NetworkActivityTracker.shared.increment()
        }
    }

    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        await MainActor.run {
            NetworkActivityTracker.shared.decrement()
        }
        return (data, response)
    }
}
