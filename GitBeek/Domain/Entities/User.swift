//
//  User.swift
//  GitBeek
//
//  Domain entity for User
//

import Foundation

/// Domain model representing a user
struct User: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let email: String?
    let photoURL: URL?
    let createdAt: Date?
    let updatedAt: Date?

    /// Memberwise initializer
    init(
        id: String,
        displayName: String,
        email: String? = nil,
        photoURL: URL? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// User's initials for avatar placeholder
    var initials: String {
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

// MARK: - Mapping from DTO

extension User {
    init(from dto: CurrentUserDTO) {
        self.id = dto.id
        self.displayName = dto.displayName
        self.email = dto.email
        self.photoURL = dto.photoURL.flatMap { URL(string: $0) }
        self.createdAt = nil
        self.updatedAt = nil
    }
}

// MARK: - User Reference

/// Simplified user reference
struct UserReference: Equatable, Hashable, Sendable {
    let id: String
    let displayName: String
    let photoURL: String?

    static func from(dto: UserReferenceDTO) -> UserReference {
        UserReference(
            id: dto.id,
            displayName: dto.displayName,
            photoURL: dto.photoURL
        )
    }
}
