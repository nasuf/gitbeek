//
//  Collection.swift
//  GitBeek
//
//  Domain entity for Collection (organizational container for spaces)
//

import Foundation

/// Domain model representing a collection (container for spaces)
struct Collection: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let emoji: String?
    let description: String?
    let appURL: URL?
    let parentId: String?  // Parent collection ID for nested collections
    let organizationId: String?
    let createdAt: Date?
    let updatedAt: Date?

    /// Display title with optional emoji
    var displayTitle: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }
}

// MARK: - Mapping from DTO

extension Collection {
    init(from dto: CollectionDTO) {
        self.id = dto.id
        self.title = dto.title
        self.emoji = dto.emoji?.asEmoji  // Convert hex code to emoji character
        self.description = dto.description
        self.appURL = dto.urls?.app.flatMap { URL(string: $0) }
        self.parentId = dto.parent
        self.organizationId = dto.organization
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}
