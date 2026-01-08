//
//  AuthRepository.swift
//  GitBeek
//
//  Protocol for authentication operations
//

import Foundation

/// Authentication state
enum AuthState: Equatable, Sendable {
    case unknown
    case authenticated(User)
    case unauthenticated
}

/// Protocol defining authentication operations
protocol AuthRepository: Sendable {
    /// Current authentication state
    var authState: AuthState { get async }

    /// Check if user is authenticated
    var isAuthenticated: Bool { get async }

    /// Login with OAuth authorization code
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User

    /// Login with API token
    func loginWithToken(_ token: String) async throws -> User

    /// Refresh the access token
    func refreshToken() async throws

    /// Logout and clear credentials
    func logout() async

    /// Get current access token (for API calls)
    func getAccessToken() async -> String?
}
