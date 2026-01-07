//
//  UserDTO.swift
//  GitBeek
//
//  Data transfer objects for User API responses
//

import Foundation

/// Current authenticated user response
struct CurrentUserDTO: Codable, Equatable, Sendable {
    let object: String  // "user"
    let id: String
    let displayName: String
    let email: String?
    let photoURL: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case displayName
        case email
        case photoURL = "photoUrl"
        case createdAt
        case updatedAt
    }
}

/// User reference in API responses (e.g., in members list)
struct UserReferenceDTO: Codable, Equatable, Sendable {
    let object: String  // "user"
    let id: String
    let displayName: String
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case displayName
        case photoURL = "photoUrl"
    }
}

/// Organization member
struct MemberDTO: Codable, Equatable, Sendable {
    let object: String  // "member"
    let id: String
    let role: MemberRole
    let user: UserReferenceDTO
    let createdAt: Date?
    let updatedAt: Date?

    enum MemberRole: String, Codable, Sendable {
        case admin
        case member = "create"
        case reader = "read"
        case guest
    }
}

/// List of members response
struct MembersListDTO: Codable, Sendable {
    let items: [MemberDTO]
    let next: NextPageDTO?
}

/// Pagination next page info
struct NextPageDTO: Codable, Sendable {
    let page: String?
}
