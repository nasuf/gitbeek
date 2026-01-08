//
//  AuthViewModel.swift
//  GitBeek
//
//  ViewModel for authentication flow
//

import Foundation
import AuthenticationServices

/// ViewModel managing authentication state and flow
@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Published State

    private(set) var authState: AuthState = .unknown
    private(set) var isLoading = false
    private(set) var error: Error?

    // Input for API token login
    var apiToken = ""

    // MARK: - Dependencies

    private let authRepository: AuthRepository

    // MARK: - OAuth

    private var webAuthSession: ASWebAuthenticationSession?

    // MARK: - Initialization

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    // MARK: - Public Methods

    /// Check and restore authentication state
    func checkAuthState() async {
        isLoading = true
        error = nil

        authState = await authRepository.authState

        isLoading = false
    }

    /// Start OAuth login flow
    func startOAuthLogin(presentationContext: ASWebAuthenticationPresentationContextProviding) {
        isLoading = true
        error = nil

        let authURL = AppConfig.shared.oauthAuthorizationURL
        let callbackScheme = "gitbeek"

        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                await self?.handleOAuthCallback(callbackURL: callbackURL, error: error)
            }
        }

        webAuthSession?.presentationContextProvider = presentationContext
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.start()
    }

    /// Login with API token
    func loginWithToken() async {
        guard !apiToken.isEmpty else {
            error = ValidationError.emptyToken
            return
        }

        isLoading = true
        error = nil

        do {
            let user = try await authRepository.loginWithToken(apiToken)
            authState = .authenticated(user)
            apiToken = "" // Clear token input
        } catch let loginError {
            self.error = loginError
        }

        isLoading = false
    }

    /// Logout
    func logout() async {
        isLoading = true
        error = nil

        await authRepository.logout()
        authState = .unauthenticated

        isLoading = false
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func handleOAuthCallback(callbackURL: URL?, error: Error?) async {
        defer { isLoading = false }

        if let error = error {
            // User cancelled or other error
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                // User cancelled - not an error
                return
            }
            self.error = error
            return
        }

        guard let url = callbackURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            self.error = OAuthError.invalidCallback
            return
        }

        // Exchange code for token
        do {
            let user = try await authRepository.loginWithOAuth(
                code: code,
                redirectUri: AppConfig.shared.oauthRedirectUri
            )
            authState = .authenticated(user)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Validation Errors

extension AuthViewModel {
    enum ValidationError: LocalizedError {
        case emptyToken

        var errorDescription: String? {
            switch self {
            case .emptyToken:
                return "Please enter your API token."
            }
        }
    }
}

// MARK: - OAuth Errors

enum OAuthError: LocalizedError {
    case invalidCallback
    case missingCode

    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback received."
        case .missingCode:
            return "Authorization code not found in callback."
        }
    }
}

// MARK: - Convenience Properties

extension AuthViewModel {
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    var currentUser: User? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }

    var hasError: Bool {
        error != nil
    }

    var errorMessage: String? {
        error?.localizedDescription
    }
}
