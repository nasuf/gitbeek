//
//  PageDetailViewModelTests.swift
//  GitBeekTests
//
//  Tests for PageDetailViewModel
//

import XCTest
@testable import GitBeek

@MainActor
final class PageDetailViewModelTests: XCTestCase {

    private var viewModel: PageDetailViewModel!
    private var mockRepository: MockPageRepository!

    override func setUpWithError() throws {
        mockRepository = MockPageRepository()
        viewModel = PageDetailViewModel(pageRepository: mockRepository)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(viewModel.page)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.breadcrumbs.isEmpty)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertFalse(viewModel.hasMarkdown)
        XCTAssertFalse(viewModel.hasChildren)
        XCTAssertEqual(viewModel.displayTitle, "Page")
    }

    // MARK: - Load Page

    func testLoadPageSuccess() async {
        let page = makePage(id: "page1", title: "Test Page", markdown: "# Hello")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "page1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.page)
        XCTAssertEqual(viewModel.page?.id, "page1")
        XCTAssertEqual(viewModel.page?.title, "Test Page")
    }

    func testLoadPageFailure() async {
        mockRepository.shouldFail = true

        await viewModel.loadPage(spaceId: "space1", pageId: "page1")

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertNil(viewModel.page)
        XCTAssertTrue(viewModel.hasError)
    }

    // MARK: - Computed Properties

    func testDisplayTitleWithEmoji() async {
        let page = makePage(id: "1", title: "Getting Started", emoji: "🚀")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertEqual(viewModel.displayTitle, "🚀 Getting Started")
    }

    func testDisplayTitleWithoutEmoji() async {
        let page = makePage(id: "1", title: "Plain Title")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertEqual(viewModel.displayTitle, "Plain Title")
    }

    func testHasMarkdownTrue() async {
        let page = makePage(id: "1", title: "Doc", markdown: "# Content here")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertTrue(viewModel.hasMarkdown)
        XCTAssertEqual(viewModel.markdown, "# Content here")
    }

    func testHasMarkdownFalse() async {
        let page = makePage(id: "1", title: "Empty", markdown: nil)
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertFalse(viewModel.hasMarkdown)
        XCTAssertEqual(viewModel.markdown, "")
    }

    func testHasChildrenTrue() async {
        let child = makePage(id: "child", title: "Child Page")
        let parent = makePage(id: "parent", title: "Parent", children: [child])
        mockRepository.mockPage = parent

        await viewModel.loadPage(spaceId: "space1", pageId: "parent")

        XCTAssertTrue(viewModel.hasChildren)
        XCTAssertEqual(viewModel.children.count, 1)
        XCTAssertEqual(viewModel.children.first?.id, "child")
    }

    func testHasChildrenFalse() async {
        let page = makePage(id: "1", title: "Leaf Node")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertFalse(viewModel.hasChildren)
        XCTAssertTrue(viewModel.children.isEmpty)
    }

    // MARK: - Refresh

    func testRefresh() async {
        let page = makePage(id: "1", title: "Initial")
        mockRepository.mockPage = page

        await viewModel.loadPage(spaceId: "space1", pageId: "1")
        XCTAssertEqual(viewModel.page?.title, "Initial")

        let updated = makePage(id: "1", title: "Updated")
        mockRepository.mockPage = updated

        await viewModel.refresh(spaceId: "space1", pageId: "1")

        XCTAssertEqual(viewModel.page?.title, "Updated")
    }

    // MARK: - Clear Error

    func testClearError() async {
        mockRepository.shouldFail = true
        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    func testErrorMessage() async {
        mockRepository.shouldFail = true
        await viewModel.loadPage(spaceId: "space1", pageId: "1")

        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Test Helpers

    private func makePage(
        id: String,
        title: String,
        emoji: String? = nil,
        path: String = "/",
        markdown: String? = nil,
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
            markdown: markdown,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
    }
}

// MARK: - Mock Page Repository

private final class MockPageRepository: PageRepository, @unchecked Sendable {
    var mockPage: Page?
    var mockContentTree: [Page] = []
    var mockSearchResults: [SearchResult] = []
    var cachedPages: [Page] = []
    var shouldFail = false

    func getContentTree(spaceId: String) async throws -> [Page] {
        if shouldFail {
            throw MockPageError.failed
        }
        return mockContentTree
    }

    func getPage(spaceId: String, pageId: String) async throws -> Page {
        if shouldFail {
            throw MockPageError.failed
        }
        guard let page = mockPage else {
            throw MockPageError.notFound
        }
        return page
    }

    func getPageByPath(spaceId: String, path: String) async throws -> Page {
        if shouldFail {
            throw MockPageError.failed
        }
        guard let page = mockPage else {
            throw MockPageError.notFound
        }
        return page
    }

    func searchPages(spaceId: String, query: String) async throws -> [SearchResult] {
        if shouldFail {
            throw MockPageError.failed
        }
        return mockSearchResults
    }

    func createPage(
        spaceId: String,
        title: String,
        emoji: String?,
        markdown: String?,
        parentId: String?
    ) async throws -> Page {
        if shouldFail {
            throw MockPageError.failed
        }
        return mockPage ?? Page(
            id: "new",
            title: title,
            emoji: emoji,
            path: "/\(title.lowercased())",
            slug: nil,
            description: nil,
            type: .document,
            children: [],
            markdown: markdown,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
    }

    func updatePage(
        spaceId: String,
        pageId: String,
        title: String?,
        emoji: String?,
        markdown: String?
    ) async throws -> Page {
        if shouldFail {
            throw MockPageError.failed
        }
        guard let page = mockPage else {
            throw MockPageError.notFound
        }
        return page
    }

    func deletePage(spaceId: String, pageId: String) async throws {
        if shouldFail {
            throw MockPageError.failed
        }
    }

    func getCachedContentTree(spaceId: String) async -> [Page] {
        cachedPages
    }

    func clearCache() async {}
}

private enum MockPageError: Error {
    case failed
    case notFound
}
