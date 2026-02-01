//
//  SpaceRepositoryImpl.swift
//  GitBeek
//
//  Implementation of SpaceRepository
//

import Foundation

/// Implementation of space repository with dual-layer caching
actor SpaceRepositoryImpl: SpaceRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let store: SwiftDataStore

    // MARK: - Cache

    private var cachedSpaces: [String: [Space]] = [:]  // organizationId -> spaces
    private var cachedCollections: [String: [Collection]] = [:]  // organizationId -> collections

    // MARK: - Initialization

    init(apiService: GitBookAPIService, store: SwiftDataStore) {
        self.apiService = apiService
        self.store = store
    }

    // MARK: - SpaceRepository

    func getCollections(organizationId: String) async throws -> [Collection] {
        let dtos = try await apiService.getAllCollections(orgId: organizationId)
        let collections = dtos.map { Collection(from: $0) }

        // Cache collections
        cachedCollections[organizationId] = collections

        return collections
    }

    func getSpaces(organizationId: String) async throws -> [Space] {
        let dtos = try await apiService.getAllSpaces(orgId: organizationId)
        let spaces = dtos.map { Space(from: $0) }

        // Cache spaces
        cachedSpaces[organizationId] = spaces

        // Save to persistent storage
        await MainActor.run {
            for dto in dtos {
                _ = try? store.saveSpace(dto, organizationId: organizationId)
            }
        }

        return spaces
    }

    func getSpace(id: String) async throws -> Space {
        let dto = try await apiService.getSpace(spaceId: id)
        return Space(from: dto)
    }

    func createSpace(
        organizationId: String,
        title: String,
        emoji: String?,
        visibility: Space.Visibility,
        parentId: String?
    ) async throws -> Space {
        let apiVisibility = SpaceVisibility(rawValue: visibility.rawValue) ?? .private

        let dto = try await apiService.createSpace(
            orgId: organizationId,
            title: title,
            emoji: emoji,
            visibility: apiVisibility,
            parent: parentId
        )

        let space = Space(from: dto)

        // Update cache
        if var spaces = cachedSpaces[organizationId] {
            spaces.append(space)
            cachedSpaces[organizationId] = spaces
        }

        // Save to persistent storage
        await MainActor.run {
            _ = try? store.saveSpace(dto, organizationId: organizationId)
        }

        return space
    }

    func createCollection(
        organizationId: String,
        title: String,
        parentId: String?
    ) async throws -> Collection {
        let dto = try await apiService.createCollection(
            orgId: organizationId,
            title: title,
            parent: parentId
        )

        let collection = Collection(from: dto)

        // Update cache
        if var collections = cachedCollections[organizationId] {
            collections.append(collection)
            cachedCollections[organizationId] = collections
        }

        return collection
    }

    func updateSpace(
        id: String,
        title: String?,
        emoji: String?,
        visibility: Space.Visibility?,
        parentId: String?
    ) async throws -> Space {
        let apiVisibility = visibility.flatMap { SpaceVisibility(rawValue: $0.rawValue) }

        let dto = try await apiService.updateSpace(
            spaceId: id,
            title: title,
            emoji: emoji,
            visibility: apiVisibility
        )

        let space = Space(from: dto)

        // Update cache - find and replace
        for (orgId, var spaces) in cachedSpaces {
            if let index = spaces.firstIndex(where: { $0.id == id }) {
                spaces[index] = space
                cachedSpaces[orgId] = spaces
                break
            }
        }

        // Save to persistent storage
        await MainActor.run {
            _ = try? store.saveSpace(dto, organizationId: nil)
        }

        return space
    }

    func deleteSpace(id: String) async throws {
        try await apiService.deleteSpace(spaceId: id)

        // Remove from cache
        for (orgId, var spaces) in cachedSpaces {
            if let index = spaces.firstIndex(where: { $0.id == id }) {
                spaces.remove(at: index)
                cachedSpaces[orgId] = spaces
                break
            }
        }
    }

    func restoreSpace(id: String) async throws -> Space {
        let dto = try await apiService.restoreSpace(spaceId: id)
        let space = Space(from: dto)

        // Update cache - re-add to appropriate organization
        if let orgId = space.organizationId {
            if var spaces = cachedSpaces[orgId] {
                // Remove old version if exists, add new
                spaces.removeAll { $0.id == id }
                spaces.append(space)
                cachedSpaces[orgId] = spaces
            }
        }

        // Save to persistent storage
        await MainActor.run {
            _ = try? store.saveSpace(dto, organizationId: space.organizationId)
        }

        return space
    }

    func getCachedSpaces(organizationId: String) async -> [Space] {
        // Return in-memory cache if available
        if let spaces = cachedSpaces[organizationId] {
            return spaces
        }

        // Try to load from persistent storage
        let spaceDataList: [(
            id: String,
            title: String,
            emoji: String?,
            visibility: String,
            spaceType: String?,
            appURL: String?,
            publishedURL: String?,
            parentId: String?,
            createdAt: Date?,
            updatedAt: Date?,
            deletedAt: Date?
        )] = await MainActor.run {
            let cachedSpaces = (try? store.fetchSpaces(organizationId: organizationId)) ?? []
            return cachedSpaces.map { cached in
                (
                    id: cached.id,
                    title: cached.title,
                    emoji: cached.emoji,
                    visibility: cached.visibility,
                    spaceType: cached.spaceType,
                    appURL: cached.appURL,
                    publishedURL: cached.publishedURL,
                    parentId: cached.parentId,
                    createdAt: cached.createdAt,
                    updatedAt: cached.updatedAt,
                    deletedAt: cached.deletedAt
                )
            }
        }

        let spaces = spaceDataList.map { data in
            Space(
                id: data.id,
                title: data.title,
                emoji: data.emoji,
                visibility: Space.Visibility(rawValue: data.visibility) ?? .private,
                type: data.spaceType.flatMap { Space.SpaceType(rawValue: $0) },
                appURL: data.appURL.flatMap { URL(string: $0) },
                publishedURL: data.publishedURL.flatMap { URL(string: $0) },
                parentId: data.parentId,
                organizationId: organizationId,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt,
                deletedAt: data.deletedAt
            )
        }

        cachedSpaces[organizationId] = spaces
        return spaces
    }

    func clearCache() async {
        cachedSpaces.removeAll()
    }
}
