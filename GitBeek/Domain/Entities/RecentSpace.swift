//
//  RecentSpace.swift
//  GitBeek
//
//  Domain entity for recently visited spaces
//

import Foundation

/// Recently visited space item
struct RecentSpace: Identifiable, Equatable, Sendable, Codable {
    let id: String  // spaceId
    let organizationId: String?
    let title: String
    let emoji: String?
    let visibility: String
    let lastVisited: Date

    init(
        id: String,
        organizationId: String? = nil,
        title: String,
        emoji: String? = nil,
        visibility: String,
        lastVisited: Date = Date()
    ) {
        self.id = id
        self.organizationId = organizationId
        self.title = title
        self.emoji = emoji
        self.visibility = visibility
        self.lastVisited = lastVisited
    }

    /// Create from Space entity
    init(from space: Space) {
        self.id = space.id
        self.organizationId = space.organizationId
        self.title = space.title
        self.emoji = space.emoji
        self.visibility = space.visibility.rawValue
        self.lastVisited = Date()
    }

    /// Display title with optional emoji
    var displayTitle: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }

    /// Get visibility icon
    var visibilityIcon: String {
        switch visibility {
        case "public": return "globe"
        case "unlisted": return "eye.slash"
        case "private": return "lock"
        case "share-link-only": return "link"
        case "in-collection": return "folder"
        case "visitor": return "person"
        default: return "lock"
        }
    }
}
