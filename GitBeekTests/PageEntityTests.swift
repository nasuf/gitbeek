//
//  PageEntityTests.swift
//  GitBeekTests
//
//  Tests for Page domain entity
//

import XCTest
@testable import GitBeek

final class PageEntityTests: XCTestCase {

    // MARK: - Basic Properties

    func testPageProperties() {
        let page = makePage(id: "p1", title: "Test Page", emoji: "📝")

        XCTAssertEqual(page.id, "p1")
        XCTAssertEqual(page.title, "Test Page")
        XCTAssertEqual(page.emoji, "📝")
        XCTAssertEqual(page.type, .document)
    }

    func testPageTypeProperties() {
        XCTAssertEqual(Page.PageType.document.displayName, "Document")
        XCTAssertEqual(Page.PageType.group.displayName, "Group")
        XCTAssertEqual(Page.PageType.link.displayName, "Link")

        XCTAssertEqual(Page.PageType.document.icon, "doc.text")
        XCTAssertEqual(Page.PageType.group.icon, "folder")
        XCTAssertEqual(Page.PageType.link.icon, "link")
    }

    // MARK: - Display Title

    func testDisplayTitleWithEmoji() {
        let page = makePage(id: "1", title: "Getting Started", emoji: "🚀")
        XCTAssertEqual(page.displayTitle, "🚀 Getting Started")
    }

    func testDisplayTitleWithoutEmoji() {
        let page = makePage(id: "1", title: "Plain Title")
        XCTAssertEqual(page.displayTitle, "Plain Title")
    }

    // MARK: - Children

    func testHasChildrenTrue() {
        let child = makePage(id: "c1", title: "Child")
        let parent = makePage(id: "p1", title: "Parent", children: [child])

        XCTAssertTrue(parent.hasChildren)
        XCTAssertEqual(parent.children.count, 1)
    }

    func testHasChildrenFalse() {
        let page = makePage(id: "1", title: "Leaf")
        XCTAssertFalse(page.hasChildren)
        XCTAssertTrue(page.children.isEmpty)
    }

    func testChildrenOptionalNil() {
        let page = makePage(id: "1", title: "Leaf")
        XCTAssertNil(page.childrenOptional)
    }

    func testChildrenOptionalNotNil() {
        let child = makePage(id: "c1", title: "Child")
        let parent = makePage(id: "p1", title: "Parent", children: [child])

        XCTAssertNotNil(parent.childrenOptional)
        XCTAssertEqual(parent.childrenOptional?.count, 1)
    }

    // MARK: - Page Type Checks

    func testIsGroupTrue() {
        let group = makePage(id: "g1", title: "Group", type: .group)
        XCTAssertTrue(group.isGroup)
        XCTAssertFalse(group.isLink)
    }

    func testIsGroupFalse() {
        let doc = makePage(id: "d1", title: "Doc", type: .document)
        XCTAssertFalse(doc.isGroup)
    }

    func testIsLinkTrue() {
        let link = makePage(id: "l1", title: "Link", type: .link)
        XCTAssertTrue(link.isLink)
        XCTAssertFalse(link.isGroup)
    }

    // MARK: - Breadcrumb Path

    func testBreadcrumbPathSimple() {
        let page = makePage(id: "1", title: "Page", path: "/docs")
        XCTAssertEqual(page.breadcrumbPath, ["docs"])
    }

    func testBreadcrumbPathNested() {
        let page = makePage(id: "1", title: "Page", path: "/docs/api/reference")
        XCTAssertEqual(page.breadcrumbPath, ["docs", "api", "reference"])
    }

    func testBreadcrumbPathEmpty() {
        let page = makePage(id: "1", title: "Page", path: "/")
        XCTAssertTrue(page.breadcrumbPath.isEmpty)
    }

    // MARK: - Descendant Count

    func testDescendantCountZero() {
        let page = makePage(id: "1", title: "Leaf")
        XCTAssertEqual(page.descendantCount, 0)
    }

    func testDescendantCountDirect() {
        let child1 = makePage(id: "c1", title: "Child 1")
        let child2 = makePage(id: "c2", title: "Child 2")
        let parent = makePage(id: "p1", title: "Parent", children: [child1, child2])

        XCTAssertEqual(parent.descendantCount, 2)
    }

    func testDescendantCountNested() {
        let grandchild = makePage(id: "gc", title: "Grandchild")
        let child = makePage(id: "c", title: "Child", children: [grandchild])
        let parent = makePage(id: "p", title: "Parent", children: [child])

        // 1 child + (1 grandchild) = 2
        XCTAssertEqual(parent.descendantCount, 2)
    }

    func testDescendantCountComplex() {
        let gc1 = makePage(id: "gc1", title: "GC1")
        let gc2 = makePage(id: "gc2", title: "GC2")
        let c1 = makePage(id: "c1", title: "C1", children: [gc1, gc2])
        let c2 = makePage(id: "c2", title: "C2")
        let parent = makePage(id: "p", title: "Parent", children: [c1, c2])

        // 2 children + (2 grandchildren + 0) = 4
        XCTAssertEqual(parent.descendantCount, 4)
    }

    // MARK: - Flatten

    func testFlattenSingle() {
        let page = makePage(id: "1", title: "Single")
        let flat = page.flatten()

        XCTAssertEqual(flat.count, 1)
        XCTAssertEqual(flat.first?.id, "1")
    }

    func testFlattenWithChildren() {
        let child1 = makePage(id: "c1", title: "Child 1")
        let child2 = makePage(id: "c2", title: "Child 2")
        let parent = makePage(id: "p", title: "Parent", children: [child1, child2])

        let flat = parent.flatten()

        XCTAssertEqual(flat.count, 3)
        XCTAssertEqual(flat[0].id, "p")  // Parent first
        XCTAssertTrue(flat.contains { $0.id == "c1" })
        XCTAssertTrue(flat.contains { $0.id == "c2" })
    }

    func testFlattenNested() {
        let grandchild = makePage(id: "gc", title: "Grandchild")
        let child = makePage(id: "c", title: "Child", children: [grandchild])
        let parent = makePage(id: "p", title: "Parent", children: [child])

        let flat = parent.flatten()

        XCTAssertEqual(flat.count, 3)
        XCTAssertEqual(flat.map { $0.id }, ["p", "c", "gc"])
    }

    // MARK: - Search Matching

    func testMatchesQueryByTitle() {
        let page = makePage(id: "1", title: "Getting Started Guide")

        XCTAssertTrue(page.matches(query: "getting"))
        XCTAssertTrue(page.matches(query: "STARTED"))
        XCTAssertTrue(page.matches(query: "Guide"))
        XCTAssertFalse(page.matches(query: "API"))
    }

    func testMatchesQueryByDescription() {
        let page = Page(
            id: "1",
            title: "Page",
            emoji: nil,
            path: "/",
            slug: nil,
            description: "This is about API integration",
            type: .document,
            children: [],
            markdown: nil,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )

        XCTAssertTrue(page.matches(query: "api"))
        XCTAssertTrue(page.matches(query: "INTEGRATION"))
    }

    func testMatchesQueryByPath() {
        let page = makePage(id: "1", title: "Reference", path: "/docs/api/reference")

        XCTAssertTrue(page.matches(query: "api"))
        XCTAssertTrue(page.matches(query: "docs"))
    }

    func testMatchesCaseInsensitive() {
        let page = makePage(id: "1", title: "API Reference")

        XCTAssertTrue(page.matches(query: "api"))
        XCTAssertTrue(page.matches(query: "API"))
        XCTAssertTrue(page.matches(query: "Api"))
    }

    // MARK: - WithMarkdown

    func testWithMarkdown() {
        let original = makePage(id: "1", title: "Page")
        let updated = original.withMarkdown("# New Content")

        XCTAssertNil(original.markdown)
        XCTAssertEqual(updated.markdown, "# New Content")
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.title, original.title)
    }

    func testWithMarkdownNil() {
        let original = Page(
            id: "1",
            title: "Page",
            emoji: nil,
            path: "/",
            slug: nil,
            description: nil,
            type: .document,
            children: [],
            markdown: "# Content",
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
        let updated = original.withMarkdown(nil)

        XCTAssertNil(updated.markdown)
    }

    // MARK: - WithChildren

    func testWithChildren() {
        let original = makePage(id: "p", title: "Parent")
        let child = makePage(id: "c", title: "Child")
        let updated = original.withChildren([child])

        XCTAssertTrue(original.children.isEmpty)
        XCTAssertEqual(updated.children.count, 1)
        XCTAssertEqual(updated.children.first?.id, "c")
    }

    func testWithChildrenEmpty() {
        let child = makePage(id: "c", title: "Child")
        let original = makePage(id: "p", title: "Parent", children: [child])
        let updated = original.withChildren([])

        XCTAssertEqual(original.children.count, 1)
        XCTAssertTrue(updated.children.isEmpty)
    }

    // MARK: - Link Target

    func testLinkTargetURL() {
        let target = Page.LinkTarget(
            kind: .url,
            url: "https://example.com",
            space: nil,
            page: nil
        )

        XCTAssertEqual(target.kind, .url)
        XCTAssertEqual(target.url, "https://example.com")
    }

    func testLinkTargetSpace() {
        let target = Page.LinkTarget(
            kind: .space,
            url: nil,
            space: "space123",
            page: nil
        )

        XCTAssertEqual(target.kind, .space)
        XCTAssertEqual(target.space, "space123")
    }

    func testLinkTargetPage() {
        let target = Page.LinkTarget(
            kind: .page,
            url: nil,
            space: nil,
            page: "page456"
        )

        XCTAssertEqual(target.kind, .page)
        XCTAssertEqual(target.page, "page456")
    }

    // MARK: - Equatable & Hashable

    func testPageEquatable() {
        let page1 = makePage(id: "1", title: "Page")
        let page2 = makePage(id: "1", title: "Page")
        let page3 = makePage(id: "2", title: "Page")

        XCTAssertEqual(page1, page2)
        XCTAssertNotEqual(page1, page3)
    }

    func testPageHashable() {
        let page1 = makePage(id: "1", title: "Page")
        let page2 = makePage(id: "1", title: "Page")

        var set = Set<Page>()
        set.insert(page1)
        set.insert(page2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Test Helpers

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
