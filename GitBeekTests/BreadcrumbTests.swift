//
//  BreadcrumbTests.swift
//  GitBeekTests
//
//  Tests for BreadcrumbItem and BreadcrumbNavigationView
//

import XCTest
@testable import GitBeek

final class BreadcrumbTests: XCTestCase {

    // MARK: - BreadcrumbItem Tests

    func testBreadcrumbItemProperties() {
        let item = BreadcrumbItem(id: "p1", title: "Getting Started", emoji: "🚀")

        XCTAssertEqual(item.id, "p1")
        XCTAssertEqual(item.title, "Getting Started")
        XCTAssertEqual(item.emoji, "🚀")
    }

    func testBreadcrumbItemWithoutEmoji() {
        let item = BreadcrumbItem(id: "p1", title: "Plain Title", emoji: nil)

        XCTAssertEqual(item.id, "p1")
        XCTAssertEqual(item.title, "Plain Title")
        XCTAssertNil(item.emoji)
    }

    func testBreadcrumbItemEquatable() {
        let item1 = BreadcrumbItem(id: "p1", title: "Title", emoji: nil)
        let item2 = BreadcrumbItem(id: "p1", title: "Title", emoji: nil)
        let item3 = BreadcrumbItem(id: "p2", title: "Title", emoji: nil)

        XCTAssertEqual(item1, item2)
        XCTAssertNotEqual(item1, item3)
    }

    func testBreadcrumbItemIdentifiable() {
        let item = BreadcrumbItem(id: "unique-id", title: "Test", emoji: nil)
        XCTAssertEqual(item.id, "unique-id")
    }

    // MARK: - Building Breadcrumbs from Page Tree

    func testBuildBreadcrumbsFromFlatTree() {
        let pages = [
            makePage(id: "p1", title: "Page 1"),
            makePage(id: "p2", title: "Page 2")
        ]

        let breadcrumbs = buildBreadcrumbs(from: pages, to: "p1")

        XCTAssertEqual(breadcrumbs.count, 1)
        XCTAssertEqual(breadcrumbs[0].id, "p1")
    }

    func testBuildBreadcrumbsFromNestedTree() {
        let grandchild = makePage(id: "gc", title: "Deep Page", emoji: "📄")
        let child = makePage(id: "c", title: "Child", emoji: "📁", children: [grandchild])
        let parent = makePage(id: "p", title: "Parent", emoji: "🏠", children: [child])
        let pages = [parent]

        let breadcrumbs = buildBreadcrumbs(from: pages, to: "gc")

        XCTAssertEqual(breadcrumbs.count, 3)

        XCTAssertEqual(breadcrumbs[0].id, "p")
        XCTAssertEqual(breadcrumbs[0].title, "Parent")
        XCTAssertEqual(breadcrumbs[0].emoji, "🏠")

        XCTAssertEqual(breadcrumbs[1].id, "c")
        XCTAssertEqual(breadcrumbs[1].title, "Child")
        XCTAssertEqual(breadcrumbs[1].emoji, "📁")

        XCTAssertEqual(breadcrumbs[2].id, "gc")
        XCTAssertEqual(breadcrumbs[2].title, "Deep Page")
        XCTAssertEqual(breadcrumbs[2].emoji, "📄")
    }

    func testBuildBreadcrumbsNotFound() {
        let pages = [makePage(id: "p1", title: "Page 1")]

        let breadcrumbs = buildBreadcrumbs(from: pages, to: "nonexistent")

        XCTAssertTrue(breadcrumbs.isEmpty)
    }

    func testBuildBreadcrumbsEmptyTree() {
        let breadcrumbs = buildBreadcrumbs(from: [], to: "any")
        XCTAssertTrue(breadcrumbs.isEmpty)
    }

    func testBuildBreadcrumbsWithSiblings() {
        let sibling1 = makePage(id: "s1", title: "Sibling 1")
        let sibling2 = makePage(id: "s2", title: "Sibling 2")
        let parent = makePage(id: "p", title: "Parent", children: [sibling1, sibling2])
        let pages = [parent]

        let breadcrumbs1 = buildBreadcrumbs(from: pages, to: "s1")
        XCTAssertEqual(breadcrumbs1.count, 2)
        XCTAssertEqual(breadcrumbs1[0].id, "p")
        XCTAssertEqual(breadcrumbs1[1].id, "s1")

        let breadcrumbs2 = buildBreadcrumbs(from: pages, to: "s2")
        XCTAssertEqual(breadcrumbs2.count, 2)
        XCTAssertEqual(breadcrumbs2[0].id, "p")
        XCTAssertEqual(breadcrumbs2[1].id, "s2")
    }

    func testBuildBreadcrumbsWithMultipleToplevel() {
        let child1 = makePage(id: "c1", title: "Child 1")
        let child2 = makePage(id: "c2", title: "Child 2")
        let parent1 = makePage(id: "p1", title: "Parent 1", children: [child1])
        let parent2 = makePage(id: "p2", title: "Parent 2", children: [child2])
        let pages = [parent1, parent2]

        let breadcrumbs1 = buildBreadcrumbs(from: pages, to: "c1")
        XCTAssertEqual(breadcrumbs1.count, 2)
        XCTAssertEqual(breadcrumbs1[0].id, "p1")
        XCTAssertEqual(breadcrumbs1[1].id, "c1")

        let breadcrumbs2 = buildBreadcrumbs(from: pages, to: "c2")
        XCTAssertEqual(breadcrumbs2.count, 2)
        XCTAssertEqual(breadcrumbs2[0].id, "p2")
        XCTAssertEqual(breadcrumbs2[1].id, "c2")
    }

    func testBuildBreadcrumbsDeepNesting() {
        let level4 = makePage(id: "l4", title: "Level 4")
        let level3 = makePage(id: "l3", title: "Level 3", children: [level4])
        let level2 = makePage(id: "l2", title: "Level 2", children: [level3])
        let level1 = makePage(id: "l1", title: "Level 1", children: [level2])
        let pages = [level1]

        let breadcrumbs = buildBreadcrumbs(from: pages, to: "l4")

        XCTAssertEqual(breadcrumbs.count, 4)
        XCTAssertEqual(breadcrumbs.map { $0.id }, ["l1", "l2", "l3", "l4"])
    }

    // MARK: - Test Helpers

    private func makePage(
        id: String,
        title: String,
        emoji: String? = nil,
        children: [Page] = []
    ) -> Page {
        Page(
            id: id,
            title: title,
            emoji: emoji,
            path: "/\(id)",
            slug: nil,
            description: nil,
            type: .document,
            children: children,
            markdown: nil,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
    }

    /// Helper function to build breadcrumbs (mirrors PageDetailViewModel logic)
    private func buildBreadcrumbs(from contentTree: [Page], to pageId: String) -> [BreadcrumbItem] {
        var path: [BreadcrumbItem] = []

        func findPath(in pages: [Page], target: String) -> Bool {
            for page in pages {
                if page.id == target {
                    path.append(BreadcrumbItem(id: page.id, title: page.title, emoji: page.emoji))
                    return true
                }

                if !page.children.isEmpty {
                    path.append(BreadcrumbItem(id: page.id, title: page.title, emoji: page.emoji))
                    if findPath(in: page.children, target: target) {
                        return true
                    }
                    path.removeLast()
                }
            }
            return false
        }

        _ = findPath(in: contentTree, target: pageId)
        return path
    }
}
