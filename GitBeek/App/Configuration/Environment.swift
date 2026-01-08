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
final class AppConfig: Sendable {
    static let shared = AppConfig()

    let environment: AppEnvironment = .development

    private init() {}

    var apiBaseURL: URL { environment.apiBaseURL }
    var gitbookClientId: String { environment.oauthClientID }
    var oauthRedirectUri: String { environment.oauthRedirectURI }
    var isDebugLoggingEnabled: Bool { environment.isDebugLoggingEnabled }

    /// GitBook OAuth authorization URL
    var oauthAuthorizationURL: URL {
        var components = URLComponents(string: "https://app.gitbook.com/oauth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: gitbookClientId),
            URLQueryItem(name: "redirect_uri", value: oauthRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "admin")
        ]
        return components.url!
    }
}
