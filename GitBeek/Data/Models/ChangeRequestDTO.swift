//
//  ChangeRequestDTO.swift
//  GitBeek
//
//  Data transfer objects for Change Request API responses
//

import Foundation

/// Change request status
enum ChangeRequestStatus: String, Codable, Sendable {
    case draft
    case open
    case merged
    case closed
}

/// Change request details
struct ChangeRequestDTO: Codable, Equatable, Sendable, Identifiable {
    let object: String  // "change-request"
    let id: String
    let number: Int
    let subject: String?
    let status: ChangeRequestStatus
    let createdAt: Date?
    let updatedAt: Date?
    let mergedAt: Date?
    let closedAt: Date?
    let createdBy: UserReferenceDTO?
    let urls: ChangeRequestURLsDTO?

    struct ChangeRequestURLsDTO: Codable, Equatable, Sendable {
        let location: String?
        let app: String?
    }
}

/// List of change requests response
struct ChangeRequestsListDTO: Codable, Sendable {
    let items: [ChangeRequestDTO]
    let next: NextPageDTO?
}

/// Create change request request
struct CreateChangeRequestDTO: Codable, Sendable {
    let subject: String?

    init(subject: String? = nil) {
        self.subject = subject
    }
}

/// Update change request request
struct UpdateChangeRequestDTO: Codable, Sendable {
    let subject: String?
    let status: ChangeRequestStatus?

    init(subject: String? = nil, status: ChangeRequestStatus? = nil) {
        self.subject = subject
        self.status = status
    }
}

/// Change request diff
struct ChangeRequestDiffDTO: Codable, Equatable, Sendable {
    let object: String  // "revision-diff"
    let changes: [ChangeDTO]?

    struct ChangeDTO: Codable, Equatable, Sendable {
        let type: String  // "added", "modified", "removed"
        let path: String
        let document: DocumentChangeDTO?
    }

    struct DocumentChangeDTO: Codable, Equatable, Sendable {
        let before: String?
        let after: String?
    }
}

/// Search result
struct SearchResultDTO: Codable, Equatable, Sendable {
    let object: String  // "search-result"
    let id: String
    let title: String
    let path: String?
    let space: SpaceReferenceDTO?
    let highlights: [SearchHighlightDTO]?

    struct SearchHighlightDTO: Codable, Equatable, Sendable {
        let field: String
        let fragment: String
    }
}

/// Search results response
struct SearchResultsDTO: Codable, Sendable {
    let items: [SearchResultDTO]
    let next: NextPageDTO?
}
