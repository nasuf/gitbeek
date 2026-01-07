//
//  SpaceDTO.swift
//  GitBeek
//
//  Data transfer objects for Space API responses
//

import Foundation

/// Space visibility
enum SpaceVisibility: String, Codable, Sendable {
    case `public`
    case unlisted
    case shareLinkOnly = "share-link-only"
    case visitor = "visitor-auth"
    case `internal` = "in-collection"
    case `private`
}

/// Space type
enum SpaceType: String, Codable, Sendable {
    case document
    case collection
}

/// Space details
struct SpaceDTO: Codable, Equatable, Sendable, Identifiable {
    let object: String  // "space"
    let id: String
    let title: String
    let emoji: String?
    let visibility: SpaceVisibility
    let type: SpaceType?
    let createdAt: Date?
    let updatedAt: Date?
    let urls: SpaceURLsDTO?
    let organization: OrganizationReferenceDTO?
    let parent: SpaceReferenceDTO?

    struct SpaceURLsDTO: Codable, Equatable, Sendable {
        let location: String?
        let app: String?
        let published: String?
    }
}

/// Organization reference in space response
struct OrganizationReferenceDTO: Codable, Equatable, Sendable {
    let object: String
    let id: String
    let title: String?
}

/// Space reference (for parent/child relationships)
struct SpaceReferenceDTO: Codable, Equatable, Sendable {
    let object: String
    let id: String
    let title: String?
    let emoji: String?
}

/// List of spaces response
struct SpacesListDTO: Codable, Sendable {
    let items: [SpaceDTO]
    let next: NextPageDTO?
}

/// Space with content tree
struct SpaceWithContentDTO: Codable, Equatable, Sendable {
    let space: SpaceDTO
    let pages: ContentTreeDTO?
}

/// Create/update space request
struct SpaceRequestDTO: Codable, Sendable {
    let title: String?
    let emoji: String?
    let visibility: SpaceVisibility?
    let parent: String?  // Parent space/collection ID

    init(title: String? = nil, emoji: String? = nil, visibility: SpaceVisibility? = nil, parent: String? = nil) {
        self.title = title
        self.emoji = emoji
        self.visibility = visibility
        self.parent = parent
    }
}
