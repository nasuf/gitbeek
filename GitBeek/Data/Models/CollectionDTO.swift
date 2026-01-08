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
