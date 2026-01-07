//
//  Environment.swift
//  GitBeek
//
//  Environment configuration for dev/staging/prod
//

import Foundation

/// Application environment configuration
enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    /// GitBook API base URL
    var apiBaseURL: URL {
        switch self {
        case .development, .staging:
            return URL(string: "https://api.gitbook.com/v1")!
        case .production:
            return URL(string: "https://api.gitbook.com/v1")!
        }
    }

    /// OAuth client ID
    var oauthClientID: String {
        switch self {
        case .development:
            return "gitbeek-dev"
        case .staging:
            return "gitbeek-staging"
        case .production:
            return "gitbeek-prod"
        }
    }

    /// OAuth redirect URI
    var oauthRedirectURI: String {
        "gitbeek://oauth/callback"
    }

    /// Whether debug logging is enabled
    var isDebugLoggingEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }

    /// Network request timeout interval
    var requestTimeout: TimeInterval {
        30.0
    }
}

/// App configuration singleton
@MainActor
final class AppConfig {
    static let shared = AppConfig()

    private(set) var environment: AppEnvironment = .development

    private init() {}

    func configure(for environment: AppEnvironment) {
        self.environment = environment
    }

    var apiBaseURL: URL { environment.apiBaseURL }
    var oauthClientID: String { environment.oauthClientID }
    var oauthRedirectURI: String { environment.oauthRedirectURI }
    var isDebugLoggingEnabled: Bool { environment.isDebugLoggingEnabled }
}
