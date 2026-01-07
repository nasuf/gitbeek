//
//  AuthInterceptor.swift
//  GitBeek
//
//  Handles authentication token injection and refresh
//

import Foundation

/// Interceptor that handles authentication and token refresh
actor AuthInterceptorState {
    var isRefreshing = false

    func setRefreshing(_ value: Bool) {
        isRefreshing = value
    }

    func getRefreshing() -> Bool {
        isRefreshing
    }
}

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    // MARK: - Properties

    private let tokenProvider: TokenProvider
    private let tokenRefresher: TokenRefresher?
    private let state = AuthInterceptorState()

    // MARK: - Protocols

    /// Protocol for providing the current access token
    protocol TokenProvider: Sendable {
        func getAccessToken() async -> String?
    }

    /// Protocol for refreshing expired tokens
    protocol TokenRefresher: Sendable {
        func refreshToken() async throws -> String
    }

    // MARK: - Initialization

    init(tokenProvider: TokenProvider, tokenRefresher: TokenRefresher? = nil) {
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
    }

    // MARK: - RequestInterceptor

    func intercept(request: inout URLRequest) async throws {
        // Get current token
        if let token = await tokenProvider.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @Sendable @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        // Check for 401 Unauthorized
        guard response.statusCode == 401 else {
            return (data, response)
        }

        // Try to refresh token if we have a refresher
        guard let refresher = tokenRefresher else {
            throw APIError.unauthorized
        }

        // Prevent multiple simultaneous refresh attempts
        if await state.getRefreshing() {
            // Wait a bit and retry with potentially new token
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            return try await retry()
        }

        await state.setRefreshing(true)

        defer {
            Task { await state.setRefreshing(false) }
        }

        do {
            // Attempt to refresh the token
            _ = try await refresher.refreshToken()

            // Retry the original request with new token
            return try await retry()
        } catch {
            // Refresh failed, propagate unauthorized error
            throw APIError.unauthorized
        }
    }
}

// MARK: - Simple Token Provider

/// A simple token provider that stores the token in memory using actor isolation
actor InMemoryTokenProvider: AuthInterceptor.TokenProvider {
    private var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func getAccessToken() async -> String? {
        token
    }

    func setAccessToken(_ token: String?) {
        self.token = token
    }
}
