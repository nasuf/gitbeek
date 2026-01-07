//
//  OrganizationDTO.swift
//  GitBeek
//
//  Data transfer objects for Organization API responses
//

import Foundation

/// Organization details
struct OrganizationDTO: Codable, Equatable, Sendable, Identifiable {
    let object: String  // "organization"
    let id: String
    let title: String
    let createdAt: Date?
    let updatedAt: Date?
    let urls: OrganizationURLsDTO?

    struct OrganizationURLsDTO: Codable, Equatable, Sendable {
        let location: String?
        let app: String?
        let published: String?
    }
}

/// List of organizations response
struct OrganizationsListDTO: Codable, Sendable {
    let items: [OrganizationDTO]
    let next: NextPageDTO?
}

/// Organization with additional stats
struct OrganizationDetailDTO: Codable, Equatable, Sendable {
    let object: String
    let id: String
    let title: String
    let createdAt: Date?
    let updatedAt: Date?
    let urls: OrganizationDTO.OrganizationURLsDTO?
    let counts: OrganizationCountsDTO?

    struct OrganizationCountsDTO: Codable, Equatable, Sendable {
        let members: Int?
        let spaces: Int?
        let collections: Int?
    }
}
