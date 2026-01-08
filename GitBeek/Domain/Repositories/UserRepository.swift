//
//  UserRepository.swift
//  GitBeek
//
//  Protocol for user operations
//

import Foundation

/// Protocol defining user operations
protocol UserRepository: Sendable {
    /// Get current authenticated user
    func getCurrentUser() async throws -> User

    /// Get cached user (if available)
    func getCachedUser() async -> User?

    /// Clear cached user data
    func clearCache() async
}
