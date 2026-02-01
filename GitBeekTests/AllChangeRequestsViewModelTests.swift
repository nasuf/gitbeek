//
//  AllChangeRequestsViewModelTests.swift
//  GitBeekTests
//
//  Tests for AllChangeRequestsViewModel
//

import XCTest
@testable import GitBeek

@MainActor
final class AllChangeRequestsViewModelTests: XCTestCase {

    private var viewModel: AllChangeRequestsViewModel!
    private var mockChangeRequestRepository: MockChangeRequestRepository!
    private var mockSpaceRepository: MockSpaceRepository!
    private var mockOrganizationRepository: MockOrganizationRepository!

    override func setUpWithError() throws {
        mockChangeRequestRepository = MockChangeRequestRepository()
        mockSpaceRepository = MockSpaceRepository()
        mockOrganizationRepository = MockOrganizationRepository()

        viewModel = AllChangeRequestsViewModel(
            changeRequestRepository: mockChangeRequestRepository,
            spaceRepository: mockSpaceRepository,
            organizationRepository: mockOrganizationRepository
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockChangeRequestRepository = nil
        mockSpaceRepository = nil
        mockOrganizationRepository = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.changeRequests.isEmpty, "Initial changeRequests should be empty")
        XCTAssertTrue(viewModel.allSpaces.isEmpty, "Initial allSpaces should be empty")
        XCTAssertTrue(viewModel.allCollections.isEmpty, "Initial allCollections should be empty")
        XCTAssertFalse(viewModel.isLoading, "Initial isLoading should be false")
        XCTAssertNil(viewModel.error, "Initial error should be nil")
        XCTAssertNil(viewModel.selectedStatus, "Initial selectedStatus should be nil (All)")
        XCTAssertFalse(viewModel.hasLoadedData, "Initial hasLoadedData should be false")
        XCTAssertNil(viewModel.lastRefreshTime, "Initial lastRefreshTime should be nil")
    }

    // MARK: - Load Tests

    func testLoadSuccess() async {
        // Setup mock data
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space1 = makeSpace(id: "space1", title: "Space 1")
        let space2 = makeSpace(id: "space2", title: "Space 2")
        let collection = makeCollection(id: "coll1", title: "Collection 1")
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .draft)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space1, space2]
        mockSpaceRepository.mockCollections = [collection]
        mockChangeRequestRepository.mockChangeRequests = [
            "space1": [cr1],
            "space2": [cr2]
        ]

        await viewModel.load()

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after load")
        XCTAssertTrue(viewModel.hasLoadedData, "hasLoadedData should be true after load")
        XCTAssertEqual(viewModel.changeRequests.count, 2, "Should have 2 change requests")
        XCTAssertEqual(viewModel.allSpaces.count, 2, "Should have 2 spaces")
        XCTAssertEqual(viewModel.allCollections.count, 1, "Should have 1 collection")
        XCTAssertNotNil(viewModel.lastRefreshTime, "lastRefreshTime should be set")
    }

    func testLoadWithCaching() async {
        // First load
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")
        let cr = makeChangeRequest(id: "cr1", number: 1, status: .open)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr]]

        await viewModel.load()

        let firstLoadCount = mockChangeRequestRepository.listCallCount
        XCTAssertTrue(viewModel.hasLoadedData, "Should have loaded data")

        // Second load should use cache
        await viewModel.load()

        XCTAssertEqual(mockChangeRequestRepository.listCallCount, firstLoadCount,
                      "Should not make new API calls when using cache")
    }

    func testLoadWithForceRefresh() async {
        // First load
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr1]]

        await viewModel.load()

        XCTAssertEqual(viewModel.changeRequests.count, 1, "Should have 1 change request")

        // Update mock data
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .draft)
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr1, cr2]]

        // Force refresh
        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.changeRequests.count, 2, "Should have 2 change requests after refresh")
    }

    func testLoadError() async {
        mockOrganizationRepository.shouldThrowError = true

        await viewModel.load()

        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after error")
        XCTAssertNotNil(viewModel.error, "error should be set")
        XCTAssertFalse(viewModel.hasLoadedData, "hasLoadedData should be false after error")
    }

    // MARK: - Refresh Tests

    func testRefreshResetsFilter() async {
        // Set a filter
        viewModel.setFilter(.open)
        XCTAssertEqual(viewModel.selectedStatus, .open, "Filter should be set to open")

        // Setup mock data
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")
        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = [:]

        await viewModel.refresh()

        // Small delay to allow background task to start
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertNil(viewModel.selectedStatus, "Filter should be reset to All after refresh")
    }

    func testRefreshWhileLoadingDoesNotInterrupt() async {
        // Setup slow loading mock
        mockOrganizationRepository.mockOrganizations = [makeOrganization(id: "org1", title: "Org 1")]
        mockSpaceRepository.mockSpaces = [makeSpace(id: "space1", title: "Space 1")]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = [:]
        mockChangeRequestRepository.delayInSeconds = 0.5

        // Start first load
        Task {
            await viewModel.load(forceRefresh: true)
        }

        // Wait a bit to ensure loading has started
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(viewModel.isLoading, "Should be loading")

        // Try to refresh while loading
        await viewModel.refresh()

        // Should return immediately without interrupting
        XCTAssertTrue(viewModel.isLoading, "Should still be loading after refresh attempt")
    }

    // MARK: - Filter Tests

    func testFilteredChangeRequests() async {
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .draft)
        let cr3 = makeChangeRequest(id: "cr3", number: 3, status: .merged)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr1, cr2, cr3]]

        await viewModel.load()

        // Test All filter
        viewModel.setFilter(nil)
        XCTAssertEqual(viewModel.filteredChangeRequests.count, 3, "All filter should show all 3")

        // Test Open filter
        viewModel.setFilter(.open)
        XCTAssertEqual(viewModel.filteredChangeRequests.count, 1, "Open filter should show 1")
        XCTAssertEqual(viewModel.filteredChangeRequests.first?.changeRequest.status, .open)

        // Test Draft filter
        viewModel.setFilter(.draft)
        XCTAssertEqual(viewModel.filteredChangeRequests.count, 1, "Draft filter should show 1")
        XCTAssertEqual(viewModel.filteredChangeRequests.first?.changeRequest.status, .draft)

        // Test Merged filter
        viewModel.setFilter(.merged)
        XCTAssertEqual(viewModel.filteredChangeRequests.count, 1, "Merged filter should show 1")
        XCTAssertEqual(viewModel.filteredChangeRequests.first?.changeRequest.status, .merged)
    }

    func testStatusCounts() async {
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .open)
        let cr3 = makeChangeRequest(id: "cr3", number: 3, status: .draft)
        let cr4 = makeChangeRequest(id: "cr4", number: 4, status: .merged)
        let cr5 = makeChangeRequest(id: "cr5", number: 5, status: .archived)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr1, cr2, cr3, cr4, cr5]]

        await viewModel.load()

        XCTAssertEqual(viewModel.openCount, 2, "Should have 2 open")
        XCTAssertEqual(viewModel.draftCount, 1, "Should have 1 draft")
        XCTAssertEqual(viewModel.mergedCount, 1, "Should have 1 merged")
        XCTAssertEqual(viewModel.archivedCount, 1, "Should have 1 archived")
    }

    // MARK: - Hierarchy Tests

    func testCollectionGroups() async {
        let org = makeOrganization(id: "org1", title: "Org 1")
        let collection = makeCollection(id: "coll1", title: "Collection 1")
        let space1 = makeSpace(id: "space1", title: "Space 1", parentId: "coll1")
        let space2 = makeSpace(id: "space2", title: "Space 2", parentId: "coll1")
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .open)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space1, space2]
        mockSpaceRepository.mockCollections = [collection]
        mockChangeRequestRepository.mockChangeRequests = [
            "space1": [cr1],
            "space2": [cr2]
        ]

        await viewModel.load()

        let groups = viewModel.collectionGroups
        XCTAssertEqual(groups.count, 1, "Should have 1 collection group")
        XCTAssertEqual(groups[0].collection.id, "coll1", "Collection group should be coll1")
        XCTAssertEqual(groups[0].changeRequests.count, 2, "Collection should have 2 change requests")
    }

    func testTopLevelSpaceGroups() async {
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space1 = makeSpace(id: "space1", title: "Space 1")  // No parent
        let space2 = makeSpace(id: "space2", title: "Space 2", parentId: "coll1")  // Has parent
        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .open)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space1, space2]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = [
            "space1": [cr1],
            "space2": [cr2]
        ]

        await viewModel.load()

        let groups = viewModel.topLevelSpaceGroups
        XCTAssertEqual(groups.count, 1, "Should have 1 top-level space group")
        XCTAssertEqual(groups[0].space.id, "space1", "Top-level space should be space1")
    }

    func testExpandCollectionToggle() {
        let collectionId = "coll1"

        XCTAssertFalse(viewModel.isExpanded(collectionId), "Collection should not be expanded initially")

        viewModel.toggleCollection(collectionId)
        XCTAssertTrue(viewModel.isExpanded(collectionId), "Collection should be expanded after toggle")

        viewModel.toggleCollection(collectionId)
        XCTAssertFalse(viewModel.isExpanded(collectionId), "Collection should be collapsed after second toggle")
    }

    func testDisplayModeToggle() {
        let collectionId = "coll1"

        XCTAssertEqual(viewModel.getDisplayMode(for: collectionId), .groupedBySpaces,
                      "Default display mode should be groupedBySpaces")

        viewModel.toggleDisplayMode(for: collectionId)
        XCTAssertEqual(viewModel.getDisplayMode(for: collectionId), .flatByTime,
                      "Display mode should be flatByTime after toggle")

        viewModel.toggleDisplayMode(for: collectionId)
        XCTAssertEqual(viewModel.getDisplayMode(for: collectionId), .groupedBySpaces,
                      "Display mode should be groupedBySpaces after second toggle")
    }

    // MARK: - Sort Tests

    func testChangeRequestsSortedByUpdatedDate() async {
        let org = makeOrganization(id: "org1", title: "Org 1")
        let space = makeSpace(id: "space1", title: "Space 1")

        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let date3 = Date(timeIntervalSince1970: 3000)

        let cr1 = makeChangeRequest(id: "cr1", number: 1, status: .open, updatedAt: date1)
        let cr2 = makeChangeRequest(id: "cr2", number: 2, status: .open, updatedAt: date3)
        let cr3 = makeChangeRequest(id: "cr3", number: 3, status: .open, updatedAt: date2)

        mockOrganizationRepository.mockOrganizations = [org]
        mockSpaceRepository.mockSpaces = [space]
        mockSpaceRepository.mockCollections = []
        mockChangeRequestRepository.mockChangeRequests = ["space1": [cr1, cr2, cr3]]

        await viewModel.load()

        // Should be sorted by updated date (newest first)
        XCTAssertEqual(viewModel.changeRequests[0].changeRequest.id, "cr2", "First should be cr2 (newest)")
        XCTAssertEqual(viewModel.changeRequests[1].changeRequest.id, "cr3", "Second should be cr3")
        XCTAssertEqual(viewModel.changeRequests[2].changeRequest.id, "cr1", "Third should be cr1 (oldest)")
    }

    // MARK: - Error Tests

    func testClearError() async {
        // Trigger an error by loading with a failing repository
        mockOrganizationRepository.shouldThrowError = true
        await viewModel.load()
        XCTAssertTrue(viewModel.hasError, "Should have error")

        viewModel.clearError()
        XCTAssertFalse(viewModel.hasError, "Error should be cleared")
        XCTAssertNil(viewModel.error, "Error should be nil")
    }

    // MARK: - Helper Methods

    private func makeOrganization(id: String, title: String) -> Organization {
        Organization(
            id: id,
            title: title,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeSpace(id: String, title: String, parentId: String? = nil) -> Space {
        Space(
            id: id,
            title: title,
            emoji: nil,
            visibility: .private,
            type: nil,
            appURL: nil,
            publishedURL: nil,
            parentId: parentId,
            organizationId: "org1",
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )
    }

    private func makeCollection(id: String, title: String) -> Collection {
        Collection(
            id: id,
            title: title,
            emoji: nil,
            description: nil,
            appURL: nil,
            parentId: nil,
            organizationId: "org1",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeChangeRequest(
        id: String,
        number: Int,
        status: ChangeRequestStatus,
        updatedAt: Date? = Date()
    ) -> ChangeRequest {
        ChangeRequest(
            id: id,
            number: number,
            subject: "Subject \(number)",
            status: status,
            createdAt: Date(),
            updatedAt: updatedAt,
            mergedAt: nil,
            closedAt: nil,
            revision: nil,
            revisionInitial: nil,
            createdBy: nil,
            urls: nil
        )
    }
}

// MARK: - Mock Repositories

private final class MockChangeRequestRepository: ChangeRequestRepository, @unchecked Sendable {
    var mockChangeRequests: [String: [ChangeRequest]] = [:]
    var shouldThrowError = false
    var listCallCount = 0
    var delayInSeconds: Double = 0

    func listChangeRequests(spaceId: String, page: String?) async throws -> [ChangeRequest] {
        listCallCount += 1

        if delayInSeconds > 0 {
            try await Task.sleep(for: .seconds(delayInSeconds))
        }

        if shouldThrowError {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }

        return mockChangeRequests[spaceId] ?? []
    }

    func getChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        throw NSError(domain: "test", code: 1)
    }

    func getChangeRequestDiff(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDiff {
        throw NSError(domain: "test", code: 1)
    }

    func mergeChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        throw NSError(domain: "test", code: 1)
    }

    func updateChangeRequestStatus(spaceId: String, changeRequestId: String, status: ChangeRequestStatus) async throws -> ChangeRequest {
        throw NSError(domain: "test", code: 1)
    }

    func updateChangeRequestSubject(spaceId: String, changeRequestId: String, subject: String) async throws -> ChangeRequest {
        throw NSError(domain: "test", code: 1)
    }

    func getPageContent(spaceId: String, pageId: String) async throws -> String? {
        return nil
    }

    func getChangeRequestPageContent(spaceId: String, changeRequestId: String, pageId: String) async throws -> String? {
        return nil
    }

    func getPageContentAtRevision(spaceId: String, revisionId: String, pageId: String) async throws -> String? {
        return nil
    }

    func listReviews(spaceId: String, changeRequestId: String) async throws -> [ChangeRequestReview] {
        return []
    }

    func submitReview(spaceId: String, changeRequestId: String, status: ReviewStatus) async throws -> ChangeRequestReview {
        throw NSError(domain: "test", code: 1)
    }

    func listRequestedReviewers(spaceId: String, changeRequestId: String) async throws -> [UserReference] {
        return []
    }
}

private final class MockOrganizationRepository: OrganizationRepository, @unchecked Sendable {
    var mockOrganizations: [Organization] = []
    var shouldThrowError = false

    func getOrganizations() async throws -> [Organization] {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockOrganizations
    }

    func getOrganization(id: String) async throws -> Organization {
        throw NSError(domain: "test", code: 1)
    }

    func getCachedOrganizations() async -> [Organization] {
        return mockOrganizations
    }

    func clearCache() async {}
}

private final class MockSpaceRepository: SpaceRepository, @unchecked Sendable {
    var mockSpaces: [Space] = []
    var mockCollections: [Collection] = []

    func getCollections(organizationId: String) async throws -> [Collection] {
        return mockCollections
    }

    func getSpaces(organizationId: String) async throws -> [Space] {
        return mockSpaces
    }

    func getSpace(id: String) async throws -> Space {
        guard let space = mockSpaces.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: 1)
        }
        return space
    }

    func createSpace(organizationId: String, title: String, emoji: String?, visibility: Space.Visibility, parentId: String?) async throws -> Space {
        throw NSError(domain: "test", code: 1)
    }

    func createCollection(organizationId: String, title: String, parentId: String?) async throws -> Collection {
        throw NSError(domain: "test", code: 1)
    }

    func updateSpace(id: String, title: String?, emoji: String?, visibility: Space.Visibility?, parentId: String?) async throws -> Space {
        throw NSError(domain: "test", code: 1)
    }

    func deleteSpace(id: String) async throws {}

    func restoreSpace(id: String) async throws -> Space {
        throw NSError(domain: "test", code: 1)
    }

    func getCachedSpaces(organizationId: String) async -> [Space] {
        return mockSpaces
    }

    func clearCache() async {}
}
