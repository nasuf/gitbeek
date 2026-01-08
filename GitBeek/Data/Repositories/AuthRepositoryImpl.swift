//
//  AuthRepositoryImpl.swift
//  GitBeek
//
//  Implementation of AuthRepository
//

import Foundation

/// Implementation of authentication repository
actor AuthRepositoryImpl: AuthRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let keychainManager: KeychainManager
    private let userRepository: UserRepository

    // MARK: - State

    private var cachedAuthState: AuthState = .unknown

    // MARK: - Configuration

    private let clientId: String
    private let redirectUri: String

    // MARK: - Initialization

    init(
        apiService: GitBookAPIService,
        keychainManager: KeychainManager,
        userRepository: UserRepository,
        clientId: String = AppConfig.shared.gitbookClientId,
        redirectUri: String = AppConfig.shared.oauthRedirectUri
    ) {
        self.apiService = apiService
        self.keychainManager = keychainManager
        self.userRepository = userRepository
        self.clientId = clientId
        self.redirectUri = redirectUri
    }

    // MARK: - AuthRepository

    var authState: AuthState {
        get async {
            if case .unknown = cachedAuthState {
                await checkAuthState()
            }
            return cachedAuthState
        }
    }

    var isAuthenticated: Bool {
        get async {
            if case .authenticated = await authState {
                return true
            }
            return false
        }
    }

    func loginWithOAuth(code: String, redirectUri: String) async throws -> User {
        // Exchange code for token
        let tokenResponse = try await apiService.exchangeToken(
            code: code,
            redirectUri: redirectUri,
            clientId: clientId
        )

        // Save tokens
        try saveTokens(from: tokenResponse)

        // Set token on API service
        await apiService.setAuthToken(tokenResponse.accessToken)

        // Fetch user
        let user = try await userRepository.getCurrentUser()
        cachedAuthState = .authenticated(user)

        return user
    }

    func loginWithToken(_ token: String) async throws -> User {
        // Save token
        try keychainManager.saveAccessToken(token)

        // Set token on API service
        await apiService.setAuthToken(token)

        // Fetch user to validate token
        let user = try await userRepository.getCurrentUser()
        cachedAuthState = .authenticated(user)

        return user
    }

    func refreshToken() async throws {
        guard let refreshToken = keychainManager.getRefreshToken() else {
            throw AuthError.noRefreshToken
        }

        let tokenResponse = try await apiService.refreshToken(
            refreshToken: refreshToken,
            clientId: clientId
        )

        try saveTokens(from: tokenResponse)
        await apiService.setAuthToken(tokenResponse.accessToken)
    }

    func logout() async {
        // Clear tokens
        keychainManager.clearAll()

        // Clear API token
        await apiService.setAuthToken(nil)

        // Clear user cache
        await userRepository.clearCache()

        // Update state
        cachedAuthState = .unauthenticated
    }

    func getAccessToken() async -> String? {
        // Check if token is expired
        if keychainManager.isTokenExpired() {
            // Try to refresh
            do {
                try await refreshToken()
            } catch {
                return nil
            }
        }

        return keychainManager.getStoredAccessToken()
    }

    // MARK: - Private Methods

    private func checkAuthState() async {
        guard let token = keychainManager.getStoredAccessToken() else {
            cachedAuthState = .unauthenticated
            return
        }

        // Check if token is expired and try refresh
        if keychainManager.isTokenExpired() {
            do {
                try await refreshToken()
            } catch {
                cachedAuthState = .unauthenticated
                return
            }
        }

        // Set token on API service
        await apiService.setAuthToken(token)

        // Try to get user
        do {
            let user = try await userRepository.getCurrentUser()
            cachedAuthState = .authenticated(user)
        } catch {
            cachedAuthState = .unauthenticated
        }
    }

    private func saveTokens(from response: TokenResponseDTO) throws {
        try keychainManager.saveAccessToken(response.accessToken)

        if let refreshToken = response.refreshToken {
            try keychainManager.saveRefreshToken(refreshToken)
        }

        if let expiresIn = response.expiresIn {
            let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            try keychainManager.saveTokenExpiry(expiryDate)
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case noRefreshToken
    case tokenExpired
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available. Please log in again."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .invalidToken:
            return "Invalid authentication token."
        }
    }
}
