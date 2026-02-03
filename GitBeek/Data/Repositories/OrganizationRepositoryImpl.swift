//
//  OrganizationRepositoryImpl.swift
//  GitBeek
//
//  Implementation of OrganizationRepository
//

import Foundation

/// Implementation of organization repository
actor OrganizationRepositoryImpl: OrganizationRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let store: SwiftDataStore

    // MARK: - Cache

    private var cachedOrganizations: [Organization]?

    // MARK: - Initialization

    init(apiService: GitBookAPIService, store: SwiftDataStore) {
        self.apiService = apiService
        self.store = store
    }

    // MARK: - OrganizationRepository

    func getOrganizations() async throws -> [Organization] {
        let dtos = try await apiService.getAllOrganizations()
        let organizations = dtos.map { Organization(from: $0) }

        // Cache organizations
        cachedOrganizations = organizations

        // Save to persistent storage
        await MainActor.run {
            for dto in dtos {
                _ = try? store.saveOrganization(dto)
            }
        }

        return organizations
    }

    func getOrganization(id: String) async throws -> Organization {
        let dto = try await apiService.getOrganization(orgId: id)
        return Organization(from: dto)
    }

    func getCachedOrganizations() async -> [Organization] {
        // Return in-memory cache if available
        if let orgs = cachedOrganizations {
            return orgs
        }

        // Try to load from persistent storage
        // Extract values on MainActor to avoid Sendable issues with SwiftData models
        let orgDataList: [(id: String, title: String, appURL: String?, publishedURL: String?, membersCount: Int?, spacesCount: Int?, createdAt: Date?, updatedAt: Date?)] = await MainActor.run {
            let cachedOrgs = (try? store.fetchOrganizations()) ?? []
            return cachedOrgs.map { cached in
                (
                    id: cached.id,
                    title: cached.title,
                    appURL: cached.appURL,
                    publishedURL: cached.publishedURL,
                    membersCount: cached.membersCount,
                    spacesCount: cached.spacesCount,
                    createdAt: cached.createdAt,
                    updatedAt: cached.updatedAt
                )
            }
        }

        let organizations = orgDataList.map { data in
            Organization(
                id: data.id,
                title: data.title,
                appURL: data.appURL.flatMap { URL(string: $0) },
                publishedURL: data.publishedURL.flatMap { URL(string: $0) },
                membersCount: data.membersCount,
                spacesCount: data.spacesCount,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt
            )
        }

        cachedOrganizations = organizations
        return organizations
    }

    func listMembers(organizationId: String) async throws -> [UserReference] {
        let dto = try await apiService.listMembers(orgId: organizationId)
        return dto.items.map { UserReference.from(dto: $0.user) }
    }

    func clearCache() async {
        cachedOrganizations = nil
    }
}
