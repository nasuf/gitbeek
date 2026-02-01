//
//  SpaceRepository.swift
//  GitBeek
//
//  Protocol for space and collection operations
//

import Foundation

/// Protocol defining space and collection operations
protocol SpaceRepository: Sendable {
    /// Get all collections for organization
    func getCollections(organizationId: String) async throws -> [Collection]

    /// Get all spaces for organization (including deleted)
    func getSpaces(organizationId: String) async throws -> [Space]

    /// Get space by ID
    func getSpace(id: String) async throws -> Space

    /// Create new space
    func createSpace(
        organizationId: String,
        title: String,
        emoji: String?,
        visibility: Space.Visibility,
        parentId: String?
    ) async throws -> Space

    /// Create new collection
    func createCollection(
        organizationId: String,
        title: String,
        parentId: String?
    ) async throws -> Collection

    /// Update space
    func updateSpace(
        id: String,
        title: String?,
        emoji: String?,
        visibility: Space.Visibility?,
        parentId: String?
    ) async throws -> Space

    /// Delete space (soft delete - moves to trash)
    func deleteSpace(id: String) async throws

    /// Restore deleted space from trash
    func restoreSpace(id: String) async throws -> Space

    /// Get cached spaces for organization
    func getCachedSpaces(organizationId: String) async -> [Space]

    /// Clear space cache
    func clearCache() async
}
