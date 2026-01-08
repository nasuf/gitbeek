//
//  Organization.swift
//  GitBeek
//
//  Domain entity for Organization
//

import Foundation

/// Domain model representing an organization
struct Organization: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let appURL: URL?
    let publishedURL: URL?
    let membersCount: Int?
    let spacesCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    /// Memberwise initializer
    init(
        id: String,
        title: String,
        appURL: URL? = nil,
        publishedURL: URL? = nil,
        membersCount: Int? = nil,
        spacesCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.appURL = appURL
        self.publishedURL = publishedURL
        self.membersCount = membersCount
        self.spacesCount = spacesCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Display name (same as title)
    var displayName: String { title }

    /// Organization's initials for avatar placeholder
    var initials: String {
        let components = title.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(title.prefix(2)).uppercased()
    }
}

// MARK: - Mapping from DTO

extension Organization {
    init(from dto: OrganizationDTO) {
        self.id = dto.id
        self.title = dto.title
        self.appURL = dto.urls?.app.flatMap { URL(string: $0) }
        self.publishedURL = dto.urls?.published.flatMap { URL(string: $0) }
        self.membersCount = nil
        self.spacesCount = nil
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }

    init(from dto: OrganizationDetailDTO) {
        self.id = dto.id
        self.title = dto.title
        self.appURL = dto.urls?.app.flatMap { URL(string: $0) }
        self.publishedURL = dto.urls?.published.flatMap { URL(string: $0) }
        self.membersCount = dto.counts?.members
        self.spacesCount = dto.counts?.spaces
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }
}
