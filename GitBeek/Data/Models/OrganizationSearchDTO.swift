//
//  OrganizationSearchDTO.swift
//  GitBeek
//
//  Data transfer objects for Organization Search API
//

import Foundation

/// Organization search response (grouped by spaces)
struct OrganizationSearchResponseDTO: Codable, Sendable {
    let items: [SpaceSearchGroupDTO]
    let next: NextPageDTO?
}

/// Search results grouped by space
struct SpaceSearchGroupDTO: Codable, Sendable {
    let id: String  // Space ID
    let title: String  // Space title
    let pages: [PageSearchResultDTO]
}

/// Page search result within a space
struct PageSearchResultDTO: Codable, Sendable {
    let id: String  // Page ID
    let title: String?
    let path: String?
    // Note: ancestors field is omitted as it can be either [String] or [Dictionary]
    // and we don't use it in the UI
    let urls: PageSearchURLsDTO?
    let sections: [PageSectionResultDTO]?
}

/// URLs for page search result
struct PageSearchURLsDTO: Codable, Sendable {
    let app: String?
}

/// Section within a page that matches the search
struct PageSectionResultDTO: Codable, Sendable {
    let id: String
    let title: String?
    let body: String?  // Excerpt/snippet
    let path: String
    let score: Double?
    let urls: SectionURLsDTO?
}

/// URLs for section result
struct SectionURLsDTO: Codable, Sendable {
    let app: String?
}
