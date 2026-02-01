//
//  SpaceListViewModelTests.swift
//  GitBeekTests
//
//  Tests for SpaceListViewModel
//

import XCTest
@testable import GitBeek

@MainActor
final class SpaceListViewModelTests: XCTestCase {

    private var viewModel: SpaceListViewModel!
    private var mockRepository: MockSpaceRepository!

    override func setUpWithError() throws {
        mockRepository = MockSpaceRepository()
        viewModel = SpaceListViewModel(spaceRepository: mockRepository)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(viewModel.allSpaces.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.collections.isEmpty)
        XCTAssertTrue(viewModel.topLevelSpaces.isEmpty)
        XCTAssertTrue(viewModel.trashedSpaces.isEmpty)
        XCTAssertTrue(viewModel.expandedCollections.isEmpty)
    }

    // MARK: - Load Spaces

    func testLoadSpacesSuccess() async {
        let spaces = [
            makeSpace(id: "1", title: "Space 1"),
            makeSpace(id: "2", title: "Space 2")
        ]
        mockRepository.mockSpaces = spaces

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.allSpaces.count, 2)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 2)
    }

    func testLoadSpacesFailure() async {
        mockRepository.shouldFail = true

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadSpacesUsesCachedDataOnFailure() async {
        let cachedSpaces = [makeSpace(id: "cached", title: "Cached Space")]
        mockRepository.cachedSpaces = cachedSpaces
        mockRepository.shouldFail = true

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.allSpaces.count, 1)
        XCTAssertEqual(viewModel.allSpaces.first?.id, "cached")
    }

    // MARK: - Hierarchy Organization

    func testOrganizesCollectionsWithChildren() async {
        let collection = makeCollection(id: "col1", title: "Collection")
        let child1 = makeSpace(id: "child1", title: "Child 1", parentId: "col1")
        let child2 = makeSpace(id: "child2", title: "Child 2", parentId: "col1")
        let topLevel = makeSpace(id: "top1", title: "Top Level")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = [child1, child2, topLevel]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.collections.first?.children.count, 2)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)
        XCTAssertEqual(viewModel.topLevelSpaces.first?.id, "top1")
    }

    func testSeparatesDeletedSpaces() async {
        let activeSpace = makeSpace(id: "active", title: "Active")
        let deletedSpace = makeSpace(id: "deleted", title: "Deleted", deletedAt: Date())

        mockRepository.mockSpaces = [activeSpace, deletedSpace]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)
        XCTAssertEqual(viewModel.topLevelSpaces.first?.id, "active")
        XCTAssertEqual(viewModel.trashedSpaces.count, 1)
        XCTAssertEqual(viewModel.trashedSpaces.first?.id, "deleted")
    }

    // MARK: - Create Space

    func testCreateSpaceSuccess() async throws {
        let newSpace = makeSpace(id: "new", title: "New Space")
        mockRepository.createdSpace = newSpace

        await viewModel.loadSpaces(organizationId: "org1")

        try await viewModel.createSpace(
            title: "New Space",
            emoji: nil,
            visibility: .private,
            parentId: nil
        )

        XCTAssertEqual(viewModel.allSpaces.count, 1)
        XCTAssertEqual(viewModel.allSpaces.first?.title, "New Space")
    }

    func testCreateSpaceWithoutOrganizationThrows() async {
        do {
            try await viewModel.createSpace(
                title: "Test",
                emoji: nil,
                visibility: .private,
                parentId: nil
            )
            XCTFail("Expected error to be thrown")
        } catch let error as SpaceListError {
            XCTAssertEqual(error, .noOrganization)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    // MARK: - Delete Space

    func testDeleteSpaceSuccess() async {
        let space = makeSpace(id: "1", title: "To Delete")
        mockRepository.mockSpaces = [space]

        await viewModel.loadSpaces(organizationId: "org1")
        XCTAssertEqual(viewModel.allSpaces.count, 1)

        await viewModel.deleteSpace(id: "1")

        XCTAssertTrue(viewModel.allSpaces.isEmpty)
    }

    // MARK: - Restore Space

    func testRestoreSpaceSuccess() async {
        let deletedSpace = makeSpace(id: "deleted", title: "Deleted", deletedAt: Date())
        mockRepository.mockSpaces = [deletedSpace]

        let restoredSpace = makeSpace(id: "deleted", title: "Deleted", deletedAt: nil)
        mockRepository.restoredSpace = restoredSpace

        await viewModel.loadSpaces(organizationId: "org1")
        XCTAssertEqual(viewModel.trashedSpaces.count, 1)

        await viewModel.restoreSpace(id: "deleted")

        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)
        XCTAssertEqual(viewModel.trashedSpaces.count, 0)
    }

    // MARK: - Collection Toggle

    func testToggleCollectionExpansion() {
        XCTAssertFalse(viewModel.isExpanded("col1"))

        viewModel.toggleCollection(id: "col1")
        XCTAssertTrue(viewModel.isExpanded("col1"))

        viewModel.toggleCollection(id: "col1")
        XCTAssertFalse(viewModel.isExpanded("col1"))
    }

    func testExpandAll() async {
        let col1 = makeCollection(id: "col1", title: "Collection 1")
        let col2 = makeCollection(id: "col2", title: "Collection 2")
        mockRepository.mockCollections = [col1, col2]

        await viewModel.loadSpaces(organizationId: "org1")

        viewModel.expandAll()

        XCTAssertTrue(viewModel.isExpanded("col1"))
        XCTAssertTrue(viewModel.isExpanded("col2"))
    }

    func testCollapseAll() async {
        let col1 = makeCollection(id: "col1", title: "Collection 1")
        mockRepository.mockCollections = [col1]

        await viewModel.loadSpaces(organizationId: "org1")
        viewModel.expandAll()

        viewModel.collapseAll()

        XCTAssertFalse(viewModel.isExpanded("col1"))
    }

    // MARK: - Computed Properties

    func testActiveSpacesCount() async {
        let active1 = makeSpace(id: "1", title: "Active 1")
        let active2 = makeSpace(id: "2", title: "Active 2")
        let deleted = makeSpace(id: "3", title: "Deleted", deletedAt: Date())
        mockRepository.mockSpaces = [active1, active2, deleted]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.activeSpacesCount, 2)
    }

    func testTrashedCount() async {
        let deleted1 = makeSpace(id: "1", title: "Deleted 1", deletedAt: Date())
        let deleted2 = makeSpace(id: "2", title: "Deleted 2", deletedAt: Date())
        mockRepository.mockSpaces = [deleted1, deleted2]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.trashedCount, 2)
    }

    func testActiveCollections() async {
        let col1 = makeCollection(id: "col1", title: "Collection 1")
        let col2 = makeCollection(id: "col2", title: "Collection 2")
        mockRepository.mockCollections = [col1, col2]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.activeCollectionsList.count, 2)
        XCTAssertEqual(viewModel.activeCollectionsList.first?.id, "col1")
    }

    // MARK: - View Mode

    func testDefaultViewModeIsHierarchy() {
        XCTAssertEqual(viewModel.viewMode, .hierarchy)
        XCTAssertTrue(viewModel.showHierarchy)
    }

    func testViewModeCanBeChanged() {
        viewModel.viewMode = .flat
        XCTAssertEqual(viewModel.viewMode, .flat)
        XCTAssertFalse(viewModel.showHierarchy)

        viewModel.viewMode = .hierarchy
        XCTAssertEqual(viewModel.viewMode, .hierarchy)
        XCTAssertTrue(viewModel.showHierarchy)
    }

    func testFlatSpacesReturnsSortedActiveSpaces() async {
        let space1 = makeSpace(id: "1", title: "Zebra Space")
        let space2 = makeSpace(id: "2", title: "Alpha Space")
        let deleted = makeSpace(id: "3", title: "Deleted", deletedAt: Date())
        mockRepository.mockSpaces = [space1, space2, deleted]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.flatSpaces.count, 2)
        XCTAssertEqual(viewModel.flatSpaces[0].title, "Alpha Space")
        XCTAssertEqual(viewModel.flatSpaces[1].title, "Zebra Space")
    }

    // MARK: - Collection Hierarchy

    func testCollectionsWithChildSpaces() async {
        // Create a collection with child spaces
        let collection = makeCollection(id: "col1", title: "My Collection")
        let child1 = makeSpace(id: "child1", title: "Child 1", parentId: "col1")
        let child2 = makeSpace(id: "child2", title: "Child 2", parentId: "col1")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = [child1, child2]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.collections.first?.collection.id, "col1")
        XCTAssertEqual(viewModel.collections.first?.children.count, 2)
        XCTAssertTrue(viewModel.topLevelSpaces.isEmpty)
    }

    func testSpacesWithoutCollectionAreTopLevel() async {
        let space1 = makeSpace(id: "1", title: "Space 1", type: nil)
        let space2 = makeSpace(id: "2", title: "Space 2", type: nil)

        mockRepository.mockSpaces = [space1, space2]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertTrue(viewModel.collections.isEmpty)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 2)
    }

    func testOrphanSpacesAreTopLevel() async {
        // A space with a parentId that doesn't exist in our collections
        let orphan = makeSpace(id: "orphan", title: "Orphan", parentId: "nonexistent")
        mockRepository.mockSpaces = [orphan]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertTrue(viewModel.collections.isEmpty)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)
        XCTAssertEqual(viewModel.topLevelSpaces.first?.id, "orphan")
    }

    // MARK: - Clear Error

    func testClearError() async {
        mockRepository.shouldFail = true
        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    // MARK: - Refresh

    func testRefresh() async {
        mockRepository.mockSpaces = [makeSpace(id: "1", title: "Space")]

        await viewModel.loadSpaces(organizationId: "org1")
        XCTAssertEqual(viewModel.allSpaces.count, 1)

        mockRepository.mockSpaces = [
            makeSpace(id: "1", title: "Space"),
            makeSpace(id: "2", title: "New Space")
        ]

        await viewModel.refresh()

        XCTAssertEqual(viewModel.allSpaces.count, 2)
    }

    // MARK: - CollectionWithSpaces Model Tests

    func testCollectionWithSpacesChildCount() async {
        let collection = makeCollection(id: "col1", title: "Test Collection")
        let child1 = makeSpace(id: "child1", title: "Child 1", parentId: "col1")
        let child2 = makeSpace(id: "child2", title: "Child 2", parentId: "col1")
        let child3 = makeSpace(id: "child3", title: "Child 3", parentId: "col1")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = [child1, child2, child3]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.first?.childCount, 3)
    }

    func testCollectionWithSpacesDisplayTitle() async {
        let collectionWithEmoji = Collection(
            id: "col1",
            title: "My Collection",
            emoji: "📚",
            description: nil,
            appURL: nil,
            parentId: nil,
            organizationId: "org1",
            createdAt: nil,
            updatedAt: nil
        )

        mockRepository.mockCollections = [collectionWithEmoji]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.first?.displayTitle, "📚 My Collection")
    }

    func testCollectionWithSpacesDisplayTitleWithoutEmoji() async {
        let collection = makeCollection(id: "col1", title: "Plain Collection")

        mockRepository.mockCollections = [collection]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.first?.displayTitle, "Plain Collection")
    }

    func testCollectionWithSpacesId() async {
        let collection = makeCollection(id: "unique-id-123", title: "Test")

        mockRepository.mockCollections = [collection]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.first?.id, "unique-id-123")
    }

    func testEmptyCollectionHasZeroChildCount() async {
        let collection = makeCollection(id: "empty", title: "Empty Collection")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = []

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.first?.childCount, 0)
        XCTAssertTrue(viewModel.collections.first?.children.isEmpty ?? false)
    }

    func testCollectionChildrenAreSortedAlphabetically() async {
        let collection = makeCollection(id: "col1", title: "Collection")
        let childZ = makeSpace(id: "z", title: "Zebra", parentId: "col1")
        let childA = makeSpace(id: "a", title: "Alpha", parentId: "col1")
        let childM = makeSpace(id: "m", title: "Middle", parentId: "col1")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = [childZ, childA, childM]

        await viewModel.loadSpaces(organizationId: "org1")

        let children = viewModel.collections.first?.children ?? []
        XCTAssertEqual(children.count, 3)
        XCTAssertEqual(children[0].title, "Alpha")
        XCTAssertEqual(children[1].title, "Middle")
        XCTAssertEqual(children[2].title, "Zebra")
    }

    func testCollectionsAreSortedAlphabetically() async {
        let colZ = makeCollection(id: "z", title: "Zebra Collection")
        let colA = makeCollection(id: "a", title: "Alpha Collection")
        let colM = makeCollection(id: "m", title: "Middle Collection")

        mockRepository.mockCollections = [colZ, colA, colM]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.collections.count, 3)
        XCTAssertEqual(viewModel.collections[0].collection.title, "Alpha Collection")
        XCTAssertEqual(viewModel.collections[1].collection.title, "Middle Collection")
        XCTAssertEqual(viewModel.collections[2].collection.title, "Zebra Collection")
    }

    func testTopLevelSpacesAreSortedAlphabetically() async {
        let spaceZ = makeSpace(id: "z", title: "Zebra Space")
        let spaceA = makeSpace(id: "a", title: "Alpha Space")
        let spaceM = makeSpace(id: "m", title: "Middle Space")

        mockRepository.mockSpaces = [spaceZ, spaceA, spaceM]

        await viewModel.loadSpaces(organizationId: "org1")

        XCTAssertEqual(viewModel.topLevelSpaces.count, 3)
        XCTAssertEqual(viewModel.topLevelSpaces[0].title, "Alpha Space")
        XCTAssertEqual(viewModel.topLevelSpaces[1].title, "Middle Space")
        XCTAssertEqual(viewModel.topLevelSpaces[2].title, "Zebra Space")
    }

    // MARK: - View Mode Integration Tests

    func testViewModeDoesNotAffectDataOrganization() async {
        let collection = makeCollection(id: "col1", title: "Collection")
        let childSpace = makeSpace(id: "child", title: "Child", parentId: "col1")
        let topSpace = makeSpace(id: "top", title: "Top Level")

        mockRepository.mockCollections = [collection]
        mockRepository.mockSpaces = [childSpace, topSpace]

        await viewModel.loadSpaces(organizationId: "org1")

        // In hierarchy mode
        viewModel.viewMode = .hierarchy
        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)

        // Switch to flat mode - data organization should remain the same
        viewModel.viewMode = .flat
        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.topLevelSpaces.count, 1)

        // flatSpaces should include all active spaces
        XCTAssertEqual(viewModel.flatSpaces.count, 2)
    }

    func testSingleCollectionToggleDoesNotAffectOthers() async {
        let col1 = makeCollection(id: "col1", title: "Collection 1")
        let col2 = makeCollection(id: "col2", title: "Collection 2")
        let col3 = makeCollection(id: "col3", title: "Collection 3")

        mockRepository.mockCollections = [col1, col2, col3]

        await viewModel.loadSpaces(organizationId: "org1")

        // Initially all collapsed
        XCTAssertFalse(viewModel.isExpanded("col1"))
        XCTAssertFalse(viewModel.isExpanded("col2"))
        XCTAssertFalse(viewModel.isExpanded("col3"))

        // Expand only col2
        viewModel.toggleCollection(id: "col2")

        XCTAssertFalse(viewModel.isExpanded("col1"))
        XCTAssertTrue(viewModel.isExpanded("col2"))
        XCTAssertFalse(viewModel.isExpanded("col3"))
    }

    // MARK: - Test Helpers

    private func makeSpace(
        id: String,
        title: String,
        type: Space.SpaceType? = .document,
        parentId: String? = nil,
        deletedAt: Date? = nil
    ) -> Space {
        Space(
            id: id,
            title: title,
            emoji: nil,
            visibility: .private,
            type: type,
            appURL: nil,
            publishedURL: nil,
            parentId: parentId,
            organizationId: "org1",
            createdAt: nil,
            updatedAt: nil,
            deletedAt: deletedAt
        )
    }

    private func makeCollection(
        id: String,
        title: String
    ) -> Collection {
        Collection(
            id: id,
            title: title,
            emoji: nil,
            description: nil,
            appURL: nil,
            parentId: nil,
            organizationId: "org1",
            createdAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Mock Space Repository

private final class MockSpaceRepository: SpaceRepository, @unchecked Sendable {
    var mockSpaces: [Space] = []
    var mockCollections: [Collection] = []
    var cachedSpaces: [Space] = []
    var createdSpace: Space?
    var restoredSpace: Space?
    var shouldFail = false

    func getCollections(organizationId: String) async throws -> [Collection] {
        if shouldFail {
            throw MockError.failed
        }
        return mockCollections
    }

    func getSpaces(organizationId: String) async throws -> [Space] {
        if shouldFail {
            throw MockError.failed
        }
        return mockSpaces
    }

    func getSpace(id: String) async throws -> Space {
        if shouldFail {
            throw MockError.failed
        }
        guard let space = mockSpaces.first(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        return space
    }

    func createSpace(
        organizationId: String,
        title: String,
        emoji: String?,
        visibility: Space.Visibility,
        parentId: String?
    ) async throws -> Space {
        if shouldFail {
            throw MockError.failed
        }
        return createdSpace ?? Space(
            id: "new",
            title: title,
            emoji: emoji,
            visibility: visibility,
            type: .document,
            appURL: nil,
            publishedURL: nil,
            parentId: parentId,
            organizationId: organizationId,
            createdAt: nil,
            updatedAt: nil,
            deletedAt: nil
        )
    }

    func createCollection(
        organizationId: String,
        title: String,
        parentId: String?
    ) async throws -> Collection {
        throw MockError.failed
    }

    func updateSpace(
        id: String,
        title: String?,
        emoji: String?,
        visibility: Space.Visibility?,
        parentId: String?
    ) async throws -> Space {
        if shouldFail {
            throw MockError.failed
        }
        guard let space = mockSpaces.first(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        return space
    }

    func deleteSpace(id: String) async throws {
        if shouldFail {
            throw MockError.failed
        }
    }

    func restoreSpace(id: String) async throws -> Space {
        if shouldFail {
            throw MockError.failed
        }
        return restoredSpace ?? mockSpaces.first { $0.id == id }!
    }

    func getCachedSpaces(organizationId: String) async -> [Space] {
        cachedSpaces
    }

    func clearCache() async {}
}

private enum MockError: Error {
    case failed
    case notFound
}
