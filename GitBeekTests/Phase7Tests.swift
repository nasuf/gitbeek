//
//  Phase7Tests.swift
//  GitBeekTests
//
//  Integration tests for Phase 7 Search & Discovery features
//

import XCTest
@testable import GitBeek

@MainActor
final class Phase7Tests: XCTestCase {

    // MARK: - RecentPagesManager Tests

    func testRecentPagesManagerAddPage() {
        // Clear before test
        RecentPagesManager.shared.clearRecentPages()

        let page = RecentPage(
            id: "test-page-1",
            spaceId: "test-space-1",
            title: "Test Page",
            emoji: "📄",
            path: "/test-page",
            lastVisited: Date()
        )

        RecentPagesManager.shared.addRecentPage(page)

        let pages = RecentPagesManager.shared.getRecentPages()
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages.first?.id, "test-page-1")
        XCTAssertEqual(pages.first?.title, "Test Page")

        // Cleanup
        RecentPagesManager.shared.clearRecentPages()
    }

    func testRecentPagesManagerDuplicateHandling() {
        RecentPagesManager.shared.clearRecentPages()

        let now = Date()
        let page1 = RecentPage(
            id: "page-1",
            spaceId: "space-1",
            title: "Page 1",
            emoji: nil,
            path: "/page1",
            lastVisited: now.addingTimeInterval(-10) // 10 seconds ago
        )

        let page2 = RecentPage(
            id: "page-2",
            spaceId: "space-1",
            title: "Page 2",
            emoji: nil,
            path: "/page2",
            lastVisited: now.addingTimeInterval(-5) // 5 seconds ago
        )

        let page1Updated = RecentPage(
            id: "page-1",
            spaceId: "space-1",
            title: "Page 1",
            emoji: nil,
            path: "/page1",
            lastVisited: now // Now (most recent)
        )

        RecentPagesManager.shared.addRecentPage(page1)
        RecentPagesManager.shared.addRecentPage(page2)
        RecentPagesManager.shared.addRecentPage(page1Updated) // Add page1 again with new timestamp

        let pages = RecentPagesManager.shared.getRecentPages()
        XCTAssertEqual(pages.count, 2, "Should not create duplicates")
        XCTAssertEqual(pages.first?.id, "page-1", "Most recent should be first")

        // Cleanup
        RecentPagesManager.shared.clearRecentPages()
    }

    func testFavoriteToggle() {
        RecentPagesManager.shared.clearFavorites()

        let page = FavoritePage(
            id: "fav-page-1",
            spaceId: "space-1",
            title: "Favorite Page",
            emoji: "⭐",
            path: "/favorite",
            addedAt: Date()
        )

        // Add to favorites
        RecentPagesManager.shared.toggleFavorite(page)
        XCTAssertTrue(RecentPagesManager.shared.isFavorite(id: "fav-page-1", spaceId: "space-1"))
        XCTAssertEqual(RecentPagesManager.shared.getFavoritePages().count, 1)

        // Remove from favorites
        RecentPagesManager.shared.toggleFavorite(page)
        XCTAssertFalse(RecentPagesManager.shared.isFavorite(id: "fav-page-1", spaceId: "space-1"))
        XCTAssertEqual(RecentPagesManager.shared.getFavoritePages().count, 0)

        // Cleanup
        RecentPagesManager.shared.clearFavorites()
    }

    // MARK: - SearchResult Entity Tests

    func testSearchResultCreation() {
        let result = SearchResult(
            id: "result-1",
            title: "Test Result",
            emoji: "📝",
            path: "/test/result",
            snippet: "This is a test snippet",
            spaceId: "space-1",
            pageId: "page-1"
        )

        XCTAssertEqual(result.id, "result-1")
        XCTAssertEqual(result.title, "Test Result")
        XCTAssertEqual(result.emoji, "📝")
        XCTAssertEqual(result.snippet, "This is a test snippet")
        XCTAssertEqual(result.spaceId, "space-1")
        XCTAssertEqual(result.pageId, "page-1")
    }

    func testSearchResultEquality() {
        let result1 = SearchResult(
            id: "result-1",
            title: "Test",
            emoji: nil,
            path: "/test",
            snippet: nil,
            spaceId: "space-1",
            pageId: "page-1"
        )

        let result2 = SearchResult(
            id: "result-1",
            title: "Test",
            emoji: nil,
            path: "/test",
            snippet: nil,
            spaceId: "space-1",
            pageId: "page-1"
        )

        XCTAssertEqual(result1.id, result2.id)
    }

    // MARK: - SearchHistoryItem Tests

    func testSearchHistoryItemCreation() {
        let item = SearchHistoryItem(query: "test query")

        XCTAssertFalse(item.id.isEmpty)
        XCTAssertEqual(item.query, "test query")
        XCTAssertNotNil(item.timestamp)
    }

    func testSearchHistoryItemIdentifiable() {
        let item1 = SearchHistoryItem(query: "query 1")
        let item2 = SearchHistoryItem(query: "query 2")

        XCTAssertNotEqual(item1.id, item2.id)
    }

    // MARK: - SearchScope Tests

    func testSearchScopeEnum() {
        XCTAssertEqual(SearchScope.organization.rawValue, "All")
        XCTAssertEqual(SearchScope.currentSpace.rawValue, "This Space")

        XCTAssertEqual(SearchScope.organization.icon, "globe")
        XCTAssertEqual(SearchScope.currentSpace.icon, "square.stack.3d.up")
    }

    func testSearchScopeIdentifiable() {
        XCTAssertEqual(SearchScope.organization.id, "All")
        XCTAssertEqual(SearchScope.currentSpace.id, "This Space")
    }

    // MARK: - RecentPage & FavoritePage Tests

    func testRecentPageCodable() throws {
        let page = RecentPage(
            id: "page-1",
            spaceId: "space-1",
            title: "Codable Test",
            emoji: "🧪",
            path: "/codable",
            lastVisited: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(page)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecentPage.self, from: data)

        XCTAssertEqual(decoded.id, page.id)
        XCTAssertEqual(decoded.title, page.title)
        XCTAssertEqual(decoded.emoji, page.emoji)
    }

    func testFavoritePageCodable() throws {
        let page = FavoritePage(
            id: "fav-1",
            spaceId: "space-1",
            title: "Favorite Codable",
            emoji: "⭐",
            path: "/favorite",
            addedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(page)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FavoritePage.self, from: data)

        XCTAssertEqual(decoded.id, page.id)
        XCTAssertEqual(decoded.title, page.title)
    }

    // MARK: - OrganizationSearchDTO Tests

    func testOrganizationSearchDTODecoding() throws {
        let json = """
        {
            "items": [
                {
                    "id": "space-1",
                    "title": "Test Space",
                    "pages": [
                        {
                            "id": "page-1",
                            "title": "Test Page",
                            "path": "/test"
                        }
                    ]
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationSearchResponseDTO.self, from: data)

        XCTAssertEqual(dto.items.count, 1)
        XCTAssertEqual(dto.items.first?.id, "space-1")
        XCTAssertEqual(dto.items.first?.pages.count, 1)
        XCTAssertEqual(dto.items.first?.pages.first?.id, "page-1")
    }

    func testPageSearchResultDTOWithSections() throws {
        let json = """
        {
            "id": "page-1",
            "title": "Test Page",
            "path": "/test",
            "sections": [
                {
                    "id": "section-1",
                    "title": "Section Title",
                    "body": "Section body text",
                    "path": "/test#section-1"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let dto = try decoder.decode(PageSearchResultDTO.self, from: data)

        XCTAssertEqual(dto.id, "page-1")
        XCTAssertEqual(dto.sections?.count, 1)
        XCTAssertEqual(dto.sections?.first?.body, "Section body text")
    }

    // MARK: - NavigationDestinationBuilder Tests

    func testNavigationDestinationBuilderCreatesViews() {
        // Test that builder can create views without crashing
        let destinations: [AppDestination] = [
            .spaceList(organizationId: "org-1"),
            .spaceDetail(spaceId: "space-1"),
            .pageDetail(spaceId: "space-1", pageId: "page-1"),
            .allChangeRequests,
            .changeRequestList(spaceId: "space-1"),
            .profile,
            .settings
        ]

        for destination in destinations {
            let view = NavigationDestinationBuilder.view(for: destination)
            XCTAssertNotNil(view, "Should create view for \(destination)")
        }
    }
}
