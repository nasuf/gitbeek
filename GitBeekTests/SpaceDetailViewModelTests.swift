//
//  SpaceDetailViewModelTests.swift
//  GitBeekTests
//
//  Tests for SpaceDetailViewModel
//

import XCTest
@testable import GitBeek

@MainActor
final class SpaceDetailViewModelTests: XCTestCase {

    private var viewModel: SpaceDetailViewModel!
    private var mockSpaceRepository: MockSpaceRepositoryForDetail!
    private var mockPageRepository: MockPageRepositoryForDetail!

    override func setUpWithError() throws {
        mockSpaceRepository = MockSpaceRepositoryForDetail()
        mockPageRepository = MockPageRepositoryForDetail()
        viewModel = SpaceDetailViewModel(
            spaceRepository: mockSpaceRepository,
            pageRepository: mockPageRepository
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockSpaceRepository = nil
        mockPageRepository = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(viewModel.space)
        XCTAssertTrue(viewModel.contentTree.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingContent)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertTrue(viewModel.expandedPageIds.isEmpty)
        XCTAssertNil(viewModel.spaceId)
        XCTAssertEqual(viewModel.displayTitle, "Space")
    }

    // MARK: - Load Space

    func testLoadSpaceSuccess() async {
        let space = makeSpace(id: "space1", title: "My Space")
        mockSpaceRepository.mockSpace = space

        await viewModel.loadSpace(spaceId: "space1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.space)
        XCTAssertEqual(viewModel.space?.id, "space1")
        XCTAssertEqual(viewModel.spaceId, "space1")
    }

    func testLoadSpaceFailure() async {
        mockSpaceRepository.shouldFail = true

        await viewModel.loadSpace(spaceId: "space1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertNil(viewModel.space)
        XCTAssertTrue(viewModel.hasError)
    }

    // MARK: - Load Content Tree

    func testLoadContentTreeSuccess() async {
        let pages = [
            makePage(id: "p1", title: "Page 1"),
            makePage(id: "p2", title: "Page 2")
        ]
        mockPageRepository.mockContentTree = pages

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        XCTAssertFalse(viewModel.isLoadingContent)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.contentTree.count, 2)
    }

    func testLoadContentTreeFailure() async {
        await viewModel.loadSpace(spaceId: "space1")
        mockPageRepository.shouldFail = true

        await viewModel.loadContentTree()

        XCTAssertFalse(viewModel.isLoadingContent)
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadContentTreeUsesCacheOnFailure() async {
        let cachedPages = [makePage(id: "cached", title: "Cached Page")]
        mockPageRepository.cachedPages = cachedPages

        await viewModel.loadSpace(spaceId: "space1")
        mockPageRepository.shouldFail = true

        await viewModel.loadContentTree()

        XCTAssertFalse(viewModel.isLoadingContent)
        XCTAssertNil(viewModel.error) // Error cleared when cache used
        XCTAssertEqual(viewModel.contentTree.count, 1)
        XCTAssertEqual(viewModel.contentTree.first?.id, "cached")
    }

    func testLoadContentTreeWithoutSpaceIdDoesNothing() async {
        let pages = [makePage(id: "p1", title: "Page 1")]
        mockPageRepository.mockContentTree = pages

        await viewModel.loadContentTree()

        XCTAssertTrue(viewModel.contentTree.isEmpty)
        XCTAssertFalse(viewModel.isLoadingContent)
    }

    // MARK: - Load All

    func testLoadAllSuccess() async {
        let space = makeSpace(id: "space1", title: "Test Space")
        let pages = [makePage(id: "p1", title: "Page 1")]
        mockSpaceRepository.mockSpace = space
        mockPageRepository.mockContentTree = pages

        await viewModel.loadAll(spaceId: "space1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.space?.id, "space1")
        XCTAssertEqual(viewModel.contentTree.count, 1)
    }

    func testLoadAllFailureUsesCachedContent() async {
        let cachedPages = [makePage(id: "cached", title: "Cached")]
        mockPageRepository.cachedPages = cachedPages
        mockSpaceRepository.shouldFail = true

        await viewModel.loadAll(spaceId: "space1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.contentTree.count, 1)
    }

    // MARK: - Update Space

    func testUpdateSpaceSuccess() async throws {
        let space = makeSpace(id: "space1", title: "Original")
        mockSpaceRepository.mockSpace = space

        await viewModel.loadSpace(spaceId: "space1")

        let updatedSpace = makeSpace(id: "space1", title: "Updated")
        mockSpaceRepository.mockSpace = updatedSpace

        try await viewModel.updateSpace(title: "Updated", emoji: nil, visibility: nil)

        XCTAssertEqual(viewModel.space?.title, "Updated")
    }

    func testUpdateSpaceWithoutSpaceThrowsError() async {
        do {
            try await viewModel.updateSpace(title: "Test", emoji: nil, visibility: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as SpaceDetailError {
            XCTAssertEqual(error, .noSpace)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testUpdateSpaceFailure() async {
        let space = makeSpace(id: "space1", title: "Original")
        mockSpaceRepository.mockSpace = space

        await viewModel.loadSpace(spaceId: "space1")
        mockSpaceRepository.shouldFail = true

        do {
            try await viewModel.updateSpace(title: "Will Fail", emoji: nil, visibility: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(viewModel.error)
        }
    }

    // MARK: - Page Expansion

    func testTogglePageExpansion() {
        XCTAssertFalse(viewModel.isExpanded("page1"))

        viewModel.togglePage(id: "page1")
        XCTAssertTrue(viewModel.isExpanded("page1"))

        viewModel.togglePage(id: "page1")
        XCTAssertFalse(viewModel.isExpanded("page1"))
    }

    func testExpandAll() async {
        let group1 = makePage(id: "g1", title: "Group 1", type: .group)
        let group2 = makePage(id: "g2", title: "Group 2", type: .group)
        let doc = makePage(id: "d1", title: "Document", type: .document)
        mockPageRepository.mockContentTree = [group1, group2, doc]

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        viewModel.expandAll()

        XCTAssertTrue(viewModel.isExpanded("g1"))
        XCTAssertTrue(viewModel.isExpanded("g2"))
        XCTAssertFalse(viewModel.isExpanded("d1")) // Documents don't expand
    }

    func testCollapseAll() async {
        let group = makePage(id: "g1", title: "Group", type: .group)
        mockPageRepository.mockContentTree = [group]

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        viewModel.expandAll()
        XCTAssertTrue(viewModel.isExpanded("g1"))

        viewModel.collapseAll()
        XCTAssertFalse(viewModel.isExpanded("g1"))
    }

    // MARK: - Search / Filter

    func testFilteredPagesReturnsAllWhenNoQuery() async {
        let pages = [
            makePage(id: "p1", title: "First Page"),
            makePage(id: "p2", title: "Second Page")
        ]
        mockPageRepository.mockContentTree = pages

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        XCTAssertEqual(viewModel.filteredPages.count, 2)
    }

    func testFilteredPagesMatchesQuery() async {
        let pages = [
            makePage(id: "p1", title: "Getting Started"),
            makePage(id: "p2", title: "API Reference")
        ]
        mockPageRepository.mockContentTree = pages

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        viewModel.searchQuery = "API"

        XCTAssertEqual(viewModel.filteredPages.count, 1)
        XCTAssertEqual(viewModel.filteredPages.first?.id, "p2")
    }

    func testFilteredPagesIncludesMatchingChildren() async {
        let child = makePage(id: "child", title: "API Docs")
        let parent = makePage(id: "parent", title: "Reference", children: [child])
        mockPageRepository.mockContentTree = [parent]

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        viewModel.searchQuery = "API"

        XCTAssertEqual(viewModel.filteredPages.count, 1)
        XCTAssertEqual(viewModel.filteredPages.first?.children.count, 1)
        XCTAssertTrue(viewModel.isExpanded("parent")) // Auto-expanded
    }

    func testClearSearch() async {
        let pages = [makePage(id: "p1", title: "Page")]
        mockPageRepository.mockContentTree = pages

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        viewModel.searchQuery = "nonexistent"
        XCTAssertTrue(viewModel.filteredPages.isEmpty)

        viewModel.clearSearch()

        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertEqual(viewModel.filteredPages.count, 1)
    }

    // MARK: - Computed Properties

    func testTotalPageCount() async {
        let grandchild = makePage(id: "gc", title: "Grandchild")
        let child = makePage(id: "c", title: "Child", children: [grandchild])
        let parent = makePage(id: "p", title: "Parent", children: [child])
        mockPageRepository.mockContentTree = [parent]

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        XCTAssertEqual(viewModel.totalPageCount, 3)
    }

    func testAllPagesFlat() async {
        let child = makePage(id: "c", title: "Child")
        let parent = makePage(id: "p", title: "Parent", children: [child])
        mockPageRepository.mockContentTree = [parent]

        await viewModel.loadSpace(spaceId: "space1")
        await viewModel.loadContentTree()

        let flat = viewModel.allPagesFlat
        XCTAssertEqual(flat.count, 2)
        XCTAssertTrue(flat.contains { $0.id == "p" })
        XCTAssertTrue(flat.contains { $0.id == "c" })
    }

    func testDisplayTitleWithSpace() async {
        let space = makeSpace(id: "space1", title: "My Documentation", emoji: "📚")
        mockSpaceRepository.mockSpace = space

        await viewModel.loadSpace(spaceId: "space1")

        XCTAssertEqual(viewModel.displayTitle, "📚 My Documentation")
    }

    // MARK: - Refresh

    func testRefresh() async {
        let space = makeSpace(id: "space1", title: "Initial")
        let pages = [makePage(id: "p1", title: "Page 1")]
        mockSpaceRepository.mockSpace = space
        mockPageRepository.mockContentTree = pages

        await viewModel.loadAll(spaceId: "space1")
        XCTAssertEqual(viewModel.contentTree.count, 1)

        let newPages = [
            makePage(id: "p1", title: "Page 1"),
            makePage(id: "p2", title: "Page 2")
        ]
        mockPageRepository.mockContentTree = newPages

        await viewModel.refresh()

        XCTAssertEqual(viewModel.contentTree.count, 2)
    }

    func testRefreshWithoutSpaceIdDoesNothing() async {
        await viewModel.refresh()
        XCTAssertTrue(viewModel.contentTree.isEmpty)
    }

    // MARK: - Clear Error

    func testClearError() async {
        mockSpaceRepository.shouldFail = true
        await viewModel.loadSpace(spaceId: "space1")

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    func testErrorMessage() async {
        mockSpaceRepository.shouldFail = true
        await viewModel.loadSpace(spaceId: "space1")

        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Test Helpers

    private func makeSpace(
        id: String,
        title: String,
        emoji: String? = nil,
        visibility: Space.Visibility = .private
    ) -> Space {
        Space(
            id: id,
            title: title,
            emoji: emoji,
            visibility: visibility,
            type: .document,
            appURL: nil,
            publishedURL: nil,
            parentId: nil,
            organizationId: "org1",
            createdAt: nil,
            updatedAt: nil,
            deletedAt: nil
        )
    }

    private func makePage(
        id: String,
        title: String,
        emoji: String? = nil,
        path: String = "/",
        children: [Page] = [],
        type: Page.PageType = .document
    ) -> Page {
        Page(
            id: id,
            title: title,
            emoji: emoji,
            path: path,
            slug: nil,
            description: nil,
            type: type,
            children: children,
            markdown: nil,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
    }
}

// MARK: - Mock Repositories

private final class MockSpaceRepositoryForDetail: SpaceRepository, @unchecked Sendable {
    var mockSpace: Space?
    var shouldFail = false

    func getCollections(organizationId: String) async throws -> [Collection] {
        []
    }

    func getSpaces(organizationId: String) async throws -> [Space] {
        if let space = mockSpace {
            return [space]
        }
        return []
    }

    func getSpace(id: String) async throws -> Space {
        if shouldFail {
            throw MockDetailError.failed
        }
        guard let space = mockSpace else {
            throw MockDetailError.notFound
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
        throw MockDetailError.failed
    }

    func createCollection(
        organizationId: String,
        title: String,
        parentId: String?
    ) async throws -> Collection {
        throw MockDetailError.failed
    }

    func updateSpace(
        id: String,
        title: String?,
        emoji: String?,
        visibility: Space.Visibility?,
        parentId: String?
    ) async throws -> Space {
        if shouldFail {
            throw MockDetailError.failed
        }
        guard let space = mockSpace else {
            throw MockDetailError.notFound
        }
        return space
    }

    func moveSpace(id: String, parentId: String?) async throws {
        if shouldFail { throw MockDetailError.failed }
    }

    func deleteSpace(id: String) async throws {
        if shouldFail {
            throw MockDetailError.failed
        }
    }

    func restoreSpace(id: String) async throws -> Space {
        if shouldFail {
            throw MockDetailError.failed
        }
        guard let space = mockSpace else {
            throw MockDetailError.notFound
        }
        return space
    }

    func renameCollection(id: String, title: String) async throws -> Collection {
        throw MockDetailError.failed
    }

    func deleteCollection(id: String) async throws {
        throw MockDetailError.failed
    }

    func moveCollection(id: String, parentId: String?) async throws {
        throw MockDetailError.failed
    }

    func getCachedSpaces(organizationId: String) async -> [Space] {
        []
    }

    func clearCache() async {}
}

private final class MockPageRepositoryForDetail: PageRepository, @unchecked Sendable {
    var mockContentTree: [Page] = []
    var mockPage: Page?
    var cachedPages: [Page] = []
    var shouldFail = false

    func getContentTree(spaceId: String) async throws -> [Page] {
        if shouldFail {
            throw MockDetailError.failed
        }
        return mockContentTree
    }

    func getPage(spaceId: String, pageId: String) async throws -> Page {
        if shouldFail {
            throw MockDetailError.failed
        }
        guard let page = mockPage else {
            throw MockDetailError.notFound
        }
        return page
    }

    func getPageByPath(spaceId: String, path: String) async throws -> Page {
        if shouldFail {
            throw MockDetailError.failed
        }
        guard let page = mockPage else {
            throw MockDetailError.notFound
        }
        return page
    }

    func searchPages(spaceId: String, query: String) async throws -> [SearchResult] {
        []
    }

    func createPage(
        spaceId: String,
        title: String,
        emoji: String?,
        markdown: String?,
        parentId: String?
    ) async throws -> Page {
        throw MockDetailError.failed
    }

    func updatePage(
        spaceId: String,
        pageId: String,
        title: String?,
        emoji: String?,
        markdown: String?
    ) async throws -> Page {
        throw MockDetailError.failed
    }

    func deletePage(spaceId: String, pageId: String) async throws {
        throw MockDetailError.failed
    }

    func getCachedContentTree(spaceId: String) async -> [Page] {
        cachedPages
    }

    func getCachedPage(spaceId: String, pageId: String) async -> Page? {
        nil
    }

    func isCacheFresh(pageId: String) async -> Bool {
        false
    }

    func clearCache() async {}
}

private enum MockDetailError: Error {
    case failed
    case notFound
}
