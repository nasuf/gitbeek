//
//  Space.swift
//  GitBeek
//
//  Domain entity for Space
//

import Foundation

/// Domain model representing a space (documentation site)
struct Space: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let emoji: String?
    let visibility: Visibility
    let type: SpaceType?
    let appURL: URL?
    let publishedURL: URL?
    let parentId: String?
    let organizationId: String?
    let createdAt: Date?
    let updatedAt: Date?

    /// Space visibility options
    enum Visibility: String, Sendable {
        case `public`
        case unlisted
        case `private`
        case shareLinkOnly = "share-link-only"
        case inCollection = "in-collection"
        case visitor

        var displayName: String {
            switch self {
            case .public: return "Public"
            case .unlisted: return "Unlisted"
            case .private: return "Private"
            case .shareLinkOnly: return "Share Link Only"
            case .inCollection: return "In Collection"
            case .visitor: return "Visitor"
            }
        }

        var icon: String {
            switch self {
            case .public: return "globe"
            case .unlisted: return "eye.slash"
            case .private: return "lock"
            case .shareLinkOnly: return "link"
            case .inCollection: return "folder"
            case .visitor: return "person"
            }
        }
    }

    /// Space type
    enum SpaceType: String, Sendable {
        case document
        case collection

        var displayName: String {
            switch self {
            case .document: return "Document"
            case .collection: return "Collection"
            }
        }
    }

    /// Whether this is a collection
    var isCollection: Bool {
        type == .collection
    }

    /// Display title with optional emoji
    var displayTitle: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }
}

// MARK: - Mapping from DTO

extension Space {
    init(from dto: SpaceDTO) {
        self.id = dto.id
        self.title = dto.title
        self.emoji = dto.emoji
        self.visibility = Visibility(rawValue: dto.visibility.rawValue) ?? .private
        self.type = dto.type.flatMap { SpaceType(rawValue: $0.rawValue) }
        self.appURL = dto.urls?.app.flatMap { URL(string: $0) }
        self.publishedURL = dto.urls?.published.flatMap { URL(string: $0) }
        self.parentId = dto.parent?.id
        self.organizationId = dto.organization?.id
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}
