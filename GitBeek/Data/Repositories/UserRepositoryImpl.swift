//
//  UserRepositoryImpl.swift
//  GitBeek
//
//  Implementation of UserRepository
//

import Foundation

/// Implementation of user repository
actor UserRepositoryImpl: UserRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let store: SwiftDataStore

    // MARK: - Cache

    private var cachedUser: User?

    // MARK: - Initialization

    init(apiService: GitBookAPIService, store: SwiftDataStore) {
        self.apiService = apiService
        self.store = store
    }

    // MARK: - UserRepository

    func getCurrentUser() async throws -> User {
        let dto = try await apiService.getCurrentUser()
        let user = User(from: dto)

        // Cache user
        cachedUser = user

        // Save to persistent storage
        await MainActor.run {
            _ = try? store.saveUser(dto)
        }

        return user
    }

    func getCachedUser() async -> User? {
        // Return in-memory cache if available
        if let user = cachedUser {
            return user
        }

        // Try to load from persistent storage
        // Extract values on MainActor to avoid Sendable issues with SwiftData models
        let userData: (id: String, displayName: String, email: String?, photoURL: String?, createdAt: Date?, updatedAt: Date?)? = await MainActor.run {
            guard let cached = try? store.fetchCurrentUser() else { return nil }
            return (
                id: cached.id,
                displayName: cached.displayName,
                email: cached.email,
                photoURL: cached.photoURL,
                createdAt: cached.createdAt,
                updatedAt: cached.updatedAt
            )
        }

        if let data = userData {
            let user = User(
                id: data.id,
                displayName: data.displayName,
                email: data.email,
                photoURL: data.photoURL.flatMap { URL(string: $0) },
                createdAt: data.createdAt,
                updatedAt: data.updatedAt
            )
            cachedUser = user
            return user
        }

        return nil
    }

    func clearCache() async {
        cachedUser = nil
    }
}

