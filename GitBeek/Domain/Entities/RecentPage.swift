//
//  RecentPage.swift
//  GitBeek
//
//  Domain entities for recent pages and favorites
//

import Foundation

/// Recently viewed page item
struct RecentPage: Identifiable, Equatable, Sendable, Codable {
    let id: String  // pageId
    let spaceId: String
    let title: String
    let emoji: String?
    let path: String
    let lastVisited: Date

    init(
        id: String,
        spaceId: String,
        title: String,
        emoji: String? = nil,
        path: String,
        lastVisited: Date = Date()
    ) {
        self.id = id
        self.spaceId = spaceId
        self.title = title
        self.emoji = emoji
        self.path = path
        self.lastVisited = lastVisited
    }

    /// Create from Page entity
    init(from page: Page, spaceId: String) {
        self.id = page.id
        self.spaceId = spaceId
        self.title = page.title
        self.emoji = page.emoji
        self.path = page.path
        self.lastVisited = Date()
    }
}

/// Favorite/bookmarked page item
struct FavoritePage: Identifiable, Equatable, Sendable, Codable {
    let id: String  // pageId
    let spaceId: String
    let title: String
    let emoji: String?
    let path: String
    let addedAt: Date

    init(
        id: String,
        spaceId: String,
        title: String,
        emoji: String? = nil,
        path: String,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.spaceId = spaceId
        self.title = title
        self.emoji = emoji
        self.path = path
        self.addedAt = addedAt
    }

    /// Create from Page entity
    init(from page: Page, spaceId: String) {
        self.id = page.id
        self.spaceId = spaceId
        self.title = page.title
        self.emoji = page.emoji
        self.path = page.path
        self.addedAt = Date()
    }
}
