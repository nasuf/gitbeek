//
//  CollectionDTO.swift
//  GitBeek
//
//  Data transfer objects for Collection API responses
//

import Foundation

/// Collection details from GitBook API
struct CollectionDTO: Codable, Equatable, Sendable, Identifiable {
    let object: String  // "collection"
    let id: String
    let title: String
    let emoji: String?
    let description: String?
    let createdAt: Date?
    let updatedAt: Date?
    let urls: CollectionURLsDTO?
    let organization: String?  // Organization ID
    let parent: String?  // Parent collection ID (for nested collections)
    let defaultLevel: String?

    struct CollectionURLsDTO: Codable, Equatable, Sendable {
        let location: String?
        let app: String?
    }
}

/// List of collections response
struct CollectionsListDTO: Codable, Sendable {
    let items: [CollectionDTO]
    let next: NextPageDTO?
}

/// Create collection request
struct CreateCollectionRequestDTO: Codable, Sendable {
    let title: String
    let parent: String?
}

/// Update collection request (PATCH)
struct UpdateCollectionRequestDTO: Codable, Sendable {
    let title: String
}

/// Move request (POST) for both spaces and collections.
/// Always encodes `parent` key (even when nil) so the API receives a valid body.
struct MoveParentRequestDTO: Encodable, Sendable {
    let parent: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parent, forKey: .parent)
    }

    private enum CodingKeys: String, CodingKey {
        case parent
    }
}
