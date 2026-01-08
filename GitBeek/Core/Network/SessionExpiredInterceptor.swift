//
//  SessionExpiredInterceptor.swift
//  GitBeek
//
//  Interceptor that handles session expiration (401 errors)
//

import Foundation

/// Notification posted when session expires (401 error received)
extension Notification.Name {
    static let sessionExpired = Notification.Name("GitBeek.sessionExpired")
}

/// Interceptor that detects 401 errors and posts a session expiration notification
final class SessionExpiredInterceptor: RequestInterceptor, @unchecked Sendable {
    // MARK: - Singleton

    static let shared = SessionExpiredInterceptor()

    private init() {}

    // MARK: - RequestInterceptor

    func intercept(request: inout URLRequest) async throws {
        // No modification needed before request
    }

    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @Sendable @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        // Check for 401 Unauthorized
        if response.statusCode == 401 {
            // Post notification on main thread
            await MainActor.run {
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            }
        }

        return (data, response)
    }
}
