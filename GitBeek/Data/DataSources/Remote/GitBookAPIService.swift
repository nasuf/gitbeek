//
//  GitBookAPIService.swift
//  GitBeek
//
//  GitBook API service with typed methods
//

import Foundation

/// Service for interacting with the GitBook API
actor GitBookAPIService {
    // MARK: - Properties

    private let client: APIClient

    // MARK: - Initialization

    init(client: APIClient) {
        self.client = client
    }

    /// Create a configured API service instance
    static func create(environment: AppEnvironment = .development) -> GitBookAPIService {
        let client = APIClient(
            baseURL: environment.apiBaseURL,
            interceptors: [
                LoggingInterceptor(logLevel: environment.isDebugLoggingEnabled ? .body : .none),
                RetryInterceptor(),
                NetworkActivityInterceptor(),
                SessionExpiredInterceptor.shared
            ]
        )

        return GitBookAPIService(client: client)
    }

    // MARK: - Auth Token Management

    func setAuthToken(_ token: String?) async {
        await client.setAuthToken(token)
    }

    func getAuthToken() async -> String? {
        await client.getAuthToken()
    }

    // MARK: - Authentication

    /// Exchange authorization code for access token
    func exchangeToken(code: String, redirectUri: String, clientId: String) async throws -> TokenResponseDTO {
        try await client.request(
            GitBookEndpoint.exchangeToken(code: code, redirectUri: redirectUri, clientId: clientId)
        )
    }

    /// Refresh access token
    func refreshToken(refreshToken: String, clientId: String) async throws -> TokenResponseDTO {
        try await client.request(
            GitBookEndpoint.refreshToken(refreshToken: refreshToken, clientId: clientId)
        )
    }

    // MARK: - User

    /// Get current authenticated user
    func getCurrentUser() async throws -> CurrentUserDTO {
        try await client.request(GitBookEndpoint.getCurrentUser)
    }

    // MARK: - Organizations

    /// List organizations for current user
    func listOrganizations(page: String? = nil) async throws -> OrganizationsListDTO {
        try await client.request(GitBookEndpoint.listOrganizations(page: page))
    }

    /// Get all organizations (handles pagination)
    func getAllOrganizations() async throws -> [OrganizationDTO] {
        var allOrgs: [OrganizationDTO] = []
        var nextPage: String? = nil

        repeat {
            let response: OrganizationsListDTO = try await listOrganizations(page: nextPage)
            allOrgs.append(contentsOf: response.items)
            nextPage = response.next?.page
        } while nextPage != nil

        return allOrgs
    }

    /// Get organization by ID
    func getOrganization(orgId: String) async throws -> OrganizationDetailDTO {
        try await client.request(GitBookEndpoint.getOrganization(orgId: orgId))
    }

    /// List organization members
    func listMembers(orgId: String, page: String? = nil) async throws -> MembersListDTO {
        try await client.request(GitBookEndpoint.listMembers(orgId: orgId, page: page))
    }

    // MARK: - Collections

    /// List collections in organization
    func listCollections(orgId: String, page: String? = nil) async throws -> CollectionsListDTO {
        try await client.request(GitBookEndpoint.listCollections(orgId: orgId, page: page))
    }

    /// Get all collections in organization (handles pagination)
    func getAllCollections(orgId: String) async throws -> [CollectionDTO] {
        var allCollections: [CollectionDTO] = []
        var nextPage: String? = nil

        repeat {
            let response: CollectionsListDTO = try await listCollections(orgId: orgId, page: nextPage)
            allCollections.append(contentsOf: response.items)
            nextPage = response.next?.page
        } while nextPage != nil

        return allCollections
    }

    /// Get collection by ID
    func getCollection(collectionId: String) async throws -> CollectionDTO {
        try await client.request(GitBookEndpoint.getCollection(collectionId: collectionId))
    }

    // MARK: - Spaces

    /// List spaces in organization
    func listSpaces(orgId: String, page: String? = nil) async throws -> SpacesListDTO {
        try await client.request(GitBookEndpoint.listSpaces(orgId: orgId, page: page))
    }

    /// Get all spaces in organization (handles pagination)
    func getAllSpaces(orgId: String) async throws -> [SpaceDTO] {
        var allSpaces: [SpaceDTO] = []
        var nextPage: String? = nil

        repeat {
            let response: SpacesListDTO = try await listSpaces(orgId: orgId, page: nextPage)
            allSpaces.append(contentsOf: response.items)
            nextPage = response.next?.page
        } while nextPage != nil

        return allSpaces
    }

    /// Get space by ID
    func getSpace(spaceId: String) async throws -> SpaceDTO {
        try await client.request(GitBookEndpoint.getSpace(spaceId: spaceId))
    }

    /// Create new space or collection
    func createSpace(orgId: String, title: String, emoji: String? = nil, visibility: SpaceVisibility = .private, type: SpaceType? = nil, parent: String? = nil) async throws -> SpaceDTO {
        let request = SpaceRequestDTO(title: title, emoji: emoji, visibility: visibility, type: type, parent: parent)
        return try await client.request(GitBookEndpoint.createSpace(orgId: orgId, request: request))
    }

    /// Update space
    func updateSpace(spaceId: String, title: String? = nil, emoji: String? = nil, visibility: SpaceVisibility? = nil) async throws -> SpaceDTO {
        let request = SpaceRequestDTO(title: title, emoji: emoji, visibility: visibility)
        return try await client.request(GitBookEndpoint.updateSpace(spaceId: spaceId, request: request))
    }

    /// Delete space (soft delete - moves to trash)
    func deleteSpace(spaceId: String) async throws {
        try await client.requestVoid(GitBookEndpoint.deleteSpace(spaceId: spaceId))
    }

    /// Restore deleted space from trash
    func restoreSpace(spaceId: String) async throws -> SpaceDTO {
        try await client.request(GitBookEndpoint.restoreSpace(spaceId: spaceId))
    }

    // MARK: - Content

    /// Get content tree for space
    func getContent(spaceId: String) async throws -> ContentTreeDTO {
        try await client.request(GitBookEndpoint.getContent(spaceId: spaceId))
    }

    /// Get page by path
    func getPageByPath(spaceId: String, path: String) async throws -> PageContentDTO {
        try await client.request(GitBookEndpoint.getPageByPath(spaceId: spaceId, path: path))
    }

    /// Get page by ID
    func getPage(spaceId: String, pageId: String) async throws -> PageContentDTO {
        try await client.request(GitBookEndpoint.getPage(spaceId: spaceId, pageId: pageId))
    }

    /// Create page
    func createPage(spaceId: String, title: String, emoji: String? = nil, markdown: String? = nil, parent: String? = nil) async throws -> ContentNodeDTO {
        let request = PageRequestDTO(title: title, emoji: emoji, markdown: markdown, parent: parent)
        return try await client.request(GitBookEndpoint.createPage(spaceId: spaceId, request: request))
    }

    /// Update page
    func updatePage(spaceId: String, pageId: String, title: String? = nil, emoji: String? = nil, markdown: String? = nil) async throws -> PageContentDTO {
        let request = PageRequestDTO(title: title, emoji: emoji, markdown: markdown)
        return try await client.request(GitBookEndpoint.updatePage(spaceId: spaceId, pageId: pageId, request: request))
    }

    /// Delete page
    func deletePage(spaceId: String, pageId: String) async throws {
        try await client.requestVoid(GitBookEndpoint.deletePage(spaceId: spaceId, pageId: pageId))
    }

    // MARK: - Change Requests

    /// List change requests for space
    func listChangeRequests(spaceId: String, status: String? = nil, page: String? = nil) async throws -> ChangeRequestsListDTO {
        try await client.request(GitBookEndpoint.listChangeRequests(spaceId: spaceId, status: status, page: page))
    }

    /// Get change request by ID
    func getChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDTO {
        try await client.request(GitBookEndpoint.getChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId))
    }

    /// Create change request
    func createChangeRequest(spaceId: String, subject: String? = nil) async throws -> ChangeRequestDTO {
        let request = CreateChangeRequestDTO(subject: subject)
        return try await client.request(GitBookEndpoint.createChangeRequest(spaceId: spaceId, request: request))
    }

    /// Update change request
    func updateChangeRequest(spaceId: String, changeRequestId: String, subject: String? = nil, status: ChangeRequestStatus? = nil) async throws -> ChangeRequestDTO {
        let request = UpdateChangeRequestDTO(subject: subject, status: status)
        return try await client.request(GitBookEndpoint.updateChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId, request: request))
    }

    /// Merge change request
    func mergeChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDTO {
        try await client.request(GitBookEndpoint.mergeChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId))
    }

    /// Get change request diff
    func getChangeRequestDiff(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDiffDTO {
        try await client.request(GitBookEndpoint.getChangeRequestDiff(spaceId: spaceId, changeRequestId: changeRequestId))
    }

    // MARK: - Search

    /// Search in organization (returns grouped by space)
    func searchOrganization(orgId: String, query: String, page: String? = nil) async throws -> OrganizationSearchResponseDTO {
        try await client.request(GitBookEndpoint.searchOrganization(orgId: orgId, query: query, page: page))
    }

    /// Search in space
    func searchSpace(spaceId: String, query: String, page: String? = nil) async throws -> SearchResultsDTO {
        try await client.request(GitBookEndpoint.searchSpace(spaceId: spaceId, query: query, page: page))
    }
}

// MARK: - Shared Instance

extension GitBookAPIService {
    /// Shared API service instance
    @MainActor
    static let shared: GitBookAPIService = {
        create(environment: AppConfig.shared.environment)
    }()
}
