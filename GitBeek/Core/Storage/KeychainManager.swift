//
//  KeychainManager.swift
//  GitBeek
//
//  Secure storage for sensitive data using Keychain Services
//

import Foundation
import Security

/// Errors that can occur during Keychain operations
enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToLoad(OSStatus)
    case unableToDelete(OSStatus)
    case unexpectedData
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to Keychain: \(status)"
        case .unableToLoad(let status):
            return "Unable to load from Keychain: \(status)"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain: \(status)"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        case .itemNotFound:
            return "Item not found in Keychain"
        }
    }
}

/// Manager for secure storage using Keychain
final class KeychainManager: @unchecked Sendable {
    // MARK: - Constants

    private enum Keys {
        static let accessToken = "com.gitbeek.accessToken"
        static let refreshToken = "com.gitbeek.refreshToken"
        static let tokenExpiry = "com.gitbeek.tokenExpiry"
        static let userId = "com.gitbeek.userId"
    }

    // MARK: - Properties

    private let serviceName: String
    private let accessGroup: String?
    private let lock = NSLock()

    // MARK: - Initialization

    init(serviceName: String = "com.gitbeek.app", accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    // MARK: - Shared Instance

    static let shared = KeychainManager()

    // MARK: - Token Management

    /// Save access token
    func saveAccessToken(_ token: String) throws {
        try save(key: Keys.accessToken, data: Data(token.utf8))
    }

    /// Get access token (sync version, use when not crossing actor boundaries)
    func getAccessToken() -> String? {
        guard let data = try? load(key: Keys.accessToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Get stored access token (explicitly named to avoid async ambiguity)
    func getStoredAccessToken() -> String? {
        guard let data = try? load(key: Keys.accessToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Save refresh token
    func saveRefreshToken(_ token: String) throws {
        try save(key: Keys.refreshToken, data: Data(token.utf8))
    }

    /// Get refresh token
    func getRefreshToken() -> String? {
        guard let data = try? load(key: Keys.refreshToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Save token expiry date
    func saveTokenExpiry(_ date: Date) throws {
        let data = try JSONEncoder().encode(date)
        try save(key: Keys.tokenExpiry, data: data)
    }

    /// Get token expiry date
    func getTokenExpiry() -> Date? {
        guard let data = try? load(key: Keys.tokenExpiry) else { return nil }
        return try? JSONDecoder().decode(Date.self, from: data)
    }

    /// Check if access token is expired
    func isTokenExpired() -> Bool {
        guard let expiry = getTokenExpiry() else { return true }
        return Date() >= expiry
    }

    /// Save user ID
    func saveUserId(_ userId: String) throws {
        try save(key: Keys.userId, data: Data(userId.utf8))
    }

    /// Get user ID
    func getUserId() -> String? {
        guard let data = try? load(key: Keys.userId) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Clear all auth tokens
    func clearTokens() {
        try? delete(key: Keys.accessToken)
        try? delete(key: Keys.refreshToken)
        try? delete(key: Keys.tokenExpiry)
    }

    /// Clear all stored data
    func clearAll() {
        clearTokens()
        try? delete(key: Keys.userId)
    }

    // MARK: - Generic Operations

    /// Save data to Keychain
    func save(key: String, data: Data) throws {
        lock.lock()
        defer { lock.unlock() }

        // Delete existing item first (use internal version to avoid deadlock)
        try? deleteUnlocked(key: key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }

    /// Load data from Keychain
    func load(key: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        var query = baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unableToLoad(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    /// Delete item from Keychain
    func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        try deleteUnlocked(key: key)
    }

    /// Internal delete without lock (for use within already-locked context)
    private func deleteUnlocked(key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }

    /// Check if item exists
    func exists(key: String) -> Bool {
        do {
            _ = try load(key: key)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - AuthInterceptor.TokenProvider Conformance

extension KeychainManager: AuthInterceptor.TokenProvider {
    func getAccessToken() async -> String? {
        // Call the synchronous version explicitly
        guard let data = try? load(key: "com.gitbeek.accessToken") else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Codable Storage Extension

extension KeychainManager {
    /// Save Codable object
    func save<T: Codable>(key: String, object: T) throws {
        let data = try JSONEncoder().encode(object)
        try save(key: key, data: data)
    }

    /// Load Codable object
    func load<T: Codable>(key: String, type: T.Type) throws -> T {
        let data = try load(key: key)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
