//
//  TokenResponse.swift
//  GitBeek
//
//  Data transfer objects for OAuth token responses
//

import Foundation

/// OAuth token response
struct TokenResponseDTO: Codable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

/// Token refresh request
struct TokenRefreshRequestDTO: Codable, Sendable {
    let grantType: String
    let refreshToken: String
    let clientId: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case clientId = "client_id"
    }

    init(refreshToken: String, clientId: String) {
        self.grantType = "refresh_token"
        self.refreshToken = refreshToken
        self.clientId = clientId
    }
}

/// OAuth authorization code exchange request
struct TokenExchangeRequestDTO: Codable, Sendable {
    let grantType: String
    let code: String
    let redirectUri: String
    let clientId: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case code
        case redirectUri = "redirect_uri"
        case clientId = "client_id"
    }

    init(code: String, redirectUri: String, clientId: String) {
        self.grantType = "authorization_code"
        self.code = code
        self.redirectUri = redirectUri
        self.clientId = clientId
    }
}
