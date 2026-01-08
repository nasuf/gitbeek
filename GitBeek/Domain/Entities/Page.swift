//
//  Page.swift
//  GitBeek
//
//  Domain entity for Page/Content node
//

import Foundation

/// Domain model representing a page or group in the content tree
struct Page: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let emoji: String?
    let path: String
    let slug: String?
    let description: String?
    let type: PageType
    let children: [Page]
    let markdown: String?
    let createdAt: Date?
    let updatedAt: Date?
    let linkTarget: LinkTarget?

    /// Page type
    enum PageType: String, Sendable {
        case document
        case group
        case link

        var displayName: String {
            switch self {
            case .document: return "Document"
            case .group: return "Group"
            case .link: return "Link"
            }
        }

        var icon: String {
            switch self {
            case .document: return "doc.text"
            case .group: return "folder"
            case .link: return "link"
            }
        }
    }

    /// Link target for link-type pages
    struct LinkTarget: Equatable, Hashable, Sendable {
        let kind: LinkKind
        let url: String?
        let space: String?
        let page: String?

        enum LinkKind: String, Sendable {
            case url
            case space
            case page
        }
    }

    // MARK: - Computed Properties

    /// Display title with optional emoji
    var displayTitle: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }

    /// Whether this page has children
    var hasChildren: Bool {
        !children.isEmpty
    }

    /// Whether this is a group (folder)
    var isGroup: Bool {
        type == .group
    }

    /// Whether this is a link
    var isLink: Bool {
        type == .link
    }

    /// Optional children for OutlineGroup compatibility
    var childrenOptional: [Page]? {
        hasChildren ? children : nil
    }

    /// Get breadcrumb path components
    var breadcrumbPath: [String] {
        path.split(separator: "/").map(String.init)
    }

    /// Count of all descendant pages (recursive)
    var descendantCount: Int {
        children.reduce(0) { $0 + 1 + $1.descendantCount }
    }
}

// MARK: - Mapping from ContentNodeDTO

extension Page {
    init(from dto: ContentNodeDTO) {
        self.id = dto.id
        self.title = dto.title
        self.emoji = dto.emoji?.asEmoji
        self.path = dto.path
        self.slug = dto.slug
        self.description = dto.description
        self.type = PageType(rawValue: dto.type?.rawValue ?? dto.object) ?? .document
        self.children = dto.pages?.map { Page(from: $0) } ?? []
        self.markdown = nil  // Not available in tree node
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt

        // Map link target
        if let target = dto.target {
            self.linkTarget = LinkTarget(
                kind: LinkTarget.LinkKind(rawValue: target.kind) ?? .url,
                url: target.url,
                space: target.space,
                page: target.page
            )
        } else {
            self.linkTarget = nil
        }
    }
}

// MARK: - Mapping from PageContentDTO

extension Page {
    init(from dto: PageContentDTO) {
        self.id = dto.id
        self.title = dto.title
        self.emoji = dto.emoji?.asEmoji
        self.path = dto.path
        self.slug = dto.slug
        self.description = dto.description
        self.type = .document  // PageContentDTO is always a document
        self.children = dto.pages?.map { Page(from: $0) } ?? []
        self.markdown = dto.markdown
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.linkTarget = nil
    }

    /// Create a page with updated markdown content
    func withMarkdown(_ markdown: String?) -> Page {
        Page(
            id: id,
            title: title,
            emoji: emoji,
            path: path,
            slug: slug,
            description: description,
            type: type,
            children: children,
            markdown: markdown,
            createdAt: createdAt,
            updatedAt: updatedAt,
            linkTarget: linkTarget
        )
    }

    /// Create a page with updated children
    func withChildren(_ children: [Page]) -> Page {
        Page(
            id: id,
            title: title,
            emoji: emoji,
            path: path,
            slug: slug,
            description: description,
            type: type,
            children: children,
            markdown: markdown,
            createdAt: createdAt,
            updatedAt: updatedAt,
            linkTarget: linkTarget
        )
    }
}

// MARK: - Search Support

extension Page {
    /// Flatten the page tree into a list for searching
    func flatten() -> [Page] {
        [self] + children.flatMap { $0.flatten() }
    }

    /// Check if the page matches a search query
    func matches(query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        return title.lowercased().contains(lowercasedQuery)
            || (description?.lowercased().contains(lowercasedQuery) ?? false)
            || path.lowercased().contains(lowercasedQuery)
    }
}
