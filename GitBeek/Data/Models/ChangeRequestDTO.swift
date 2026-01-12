//
//  ChangeRequestDTO.swift
//  GitBeek
//
//  Data transfer objects for Change Request API responses
//

import Foundation

/// Change request status
/// GitBook API 支持的状态值: draft, open, merged, archived
enum ChangeRequestStatus: String, Codable, Sendable {
    case draft
    case open
    case merged
    case archived
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

/// Change request diff/changes response
/// GitBook API returns an array of changes directly
struct ChangeRequestDiffDTO: Codable, Equatable, Sendable {
    let changes: [ChangeDTO]

    // Custom init to handle array response
    init(from decoder: Decoder) throws {
        // Try to decode as an array directly
        if let changesArray = try? [ChangeDTO](from: decoder) {
            self.changes = changesArray
        } else {
            // Fallback: try to decode as an object with changes field
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.changes = try container.decode([ChangeDTO].self, forKey: .changes)
        }
    }

    init(changes: [ChangeDTO]) {
        self.changes = changes
    }

    enum CodingKeys: String, CodingKey {
        case changes
    }

    struct ChangeDTO: Codable, Equatable, Sendable {
        let type: String  // "page_edited", "page_added", "page_removed"
        let page: PageDTO?
        let attributes: AttributesDTO?

        struct PageDTO: Codable, Equatable, Sendable {
            let id: String
            let type: String
            let title: String
            let path: String
        }

        struct AttributesDTO: Codable, Equatable, Sendable {
            let title: TitleChangeDTO?
            let document: DocumentReferenceDTO?

            struct TitleChangeDTO: Codable, Equatable, Sendable {
                let before: String?
                let after: String?
            }

            struct DocumentReferenceDTO: Codable, Equatable, Sendable {
                let before: String?  // Document ID
                let after: String?   // Document ID
            }
        }
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
