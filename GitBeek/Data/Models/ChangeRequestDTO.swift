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
    let revision: String?
    let revisionInitial: String?
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

/// Merge change request response
struct MergeChangeRequestResponseDTO: Codable, Sendable {
    let result: String
    let revision: String?
}

/// Change request diff/changes response
/// GitBook API returns an array of changes directly
struct ChangeRequestDiffDTO: Codable, Equatable, Sendable {
    let changes: [ChangeDTO]
    let more: Int?

    // Custom init to handle both array and object response formats
    init(from decoder: Decoder) throws {
        // Try to decode as an object with changes field first (actual API format)
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            do {
                self.changes = try container.decode([ChangeDTO].self, forKey: .changes)
            } catch {
                #if DEBUG
                print("⚠️ [ChangeRequestDiffDTO] Failed to decode changes array: \(error)")
                #endif
                self.changes = []
            }
            self.more = try? container.decodeIfPresent(Int.self, forKey: .more)
        } else if let changesArray = try? [ChangeDTO](from: decoder) {
            // Fallback: try to decode as an array directly
            self.changes = changesArray
            self.more = nil
        } else {
            self.changes = []
            self.more = nil
        }
    }

    init(changes: [ChangeDTO], more: Int? = nil) {
        self.changes = changes
        self.more = more
    }

    enum CodingKeys: String, CodingKey {
        case changes
        case more
    }

    struct ChangeDTO: Codable, Equatable, Sendable {
        let type: String  // "page_created", "page_edited", "page_removed", "file_created", "file_removed"
        let page: PageDTO?
        let file: FileDTO?
        let attributes: AttributesDTO?

        struct PageDTO: Codable, Equatable, Sendable {
            let id: String
            let type: String?
            let title: String
            let path: String
        }

        struct FileDTO: Codable, Equatable, Sendable {
            let id: String
            let name: String
            let contentType: String?
            let downloadURL: String?
        }

        struct AttributesDTO: Codable, Equatable, Sendable {
            let title: TitleChangeDTO?
            let document: DocumentReferenceDTO?

            struct TitleChangeDTO: Codable, Equatable, Sendable {
                let before: String?
                let after: String?
            }

            struct DocumentReferenceDTO: Codable, Equatable, Sendable {
                let before: String?  // Document revision ID
                let after: String?   // Document revision ID
            }
        }
    }
}

// MARK: - Change Request Review DTOs

/// Review status for a change request
enum ReviewStatus: String, Codable, Sendable {
    case approved
    case changesRequested = "changes-requested"
}

/// A review on a change request
struct ChangeRequestReviewDTO: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let reviewer: UserReferenceDTO?
    let status: ReviewStatus
    let outdated: Bool?
    let createdAt: Date?
}

/// List of reviews response
struct ChangeRequestReviewsListDTO: Codable, Sendable {
    let items: [ChangeRequestReviewDTO]
}

/// Request body for submitting a review
struct SubmitReviewRequestDTO: Codable, Sendable {
    let status: ReviewStatus
}

/// A requested reviewer
struct RequestedReviewerDTO: Codable, Equatable, Sendable {
    let user: UserReferenceDTO?
}

/// List of requested reviewers response
struct RequestedReviewersListDTO: Codable, Sendable {
    let items: [RequestedReviewerDTO]
}

struct RequestReviewersRequestDTO: Codable, Sendable {
    let users: [String]
}

// MARK: - Change Request Comment DTOs

/// Slate document body structure from GitBook API
struct CommentBodyDTO: Codable, Equatable, Sendable {
    let document: SlateDocumentDTO?

    struct SlateDocumentDTO: Codable, Equatable, Sendable {
        let nodes: [SlateNodeDTO]?
    }

    struct SlateNodeDTO: Codable, Equatable, Sendable {
        let object: String?  // "block", "inline", "text"
        let type: String?    // "paragraph", etc.
        let nodes: [SlateNodeDTO]?
        let leaves: [SlateLeafDTO]?
        let text: String?
    }

    struct SlateLeafDTO: Codable, Equatable, Sendable {
        let object: String?
        let text: String?
    }

    /// Recursively extract plain text from the Slate document
    var plainText: String {
        guard let nodes = document?.nodes else { return "" }
        return nodes.map { extractText(from: $0) }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractText(from node: SlateNodeDTO) -> String {
        if let text = node.text { return text }
        if let leaves = node.leaves { return leaves.compactMap { $0.text }.joined() }
        if let children = node.nodes { return children.map { extractText(from: $0) }.joined() }
        return ""
    }
}

struct CommentPermissionsDTO: Codable, Equatable, Sendable {
    let edit: Bool?
    let delete: Bool?
    let reply: Bool?
}

struct CommentDTO: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let postedAt: Date?
    let editedAt: Date?
    let postedBy: UserReferenceDTO?
    let replyCount: Int
    let body: CommentBodyDTO?
    let permissions: CommentPermissionsDTO?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, postedAt, editedAt, postedBy, replies, body, permissions, status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        postedAt = try container.decodeIfPresent(Date.self, forKey: .postedAt)
        editedAt = try container.decodeIfPresent(Date.self, forKey: .editedAt)
        postedBy = try container.decodeIfPresent(UserReferenceDTO.self, forKey: .postedBy)
        body = try container.decodeIfPresent(CommentBodyDTO.self, forKey: .body)
        permissions = try container.decodeIfPresent(CommentPermissionsDTO.self, forKey: .permissions)
        status = try container.decodeIfPresent(String.self, forKey: .status)

        // "replies" can be a number (create response) or an object with "count" (list response)
        if let count = try? container.decode(Int.self, forKey: .replies) {
            replyCount = count
        } else if let obj = try? container.decode(RepliesObject.self, forKey: .replies) {
            replyCount = obj.count ?? 0
        } else {
            replyCount = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(postedAt, forKey: .postedAt)
        try container.encodeIfPresent(editedAt, forKey: .editedAt)
        try container.encodeIfPresent(postedBy, forKey: .postedBy)
        try container.encode(replyCount, forKey: .replies)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(permissions, forKey: .permissions)
        try container.encodeIfPresent(status, forKey: .status)
    }

    private struct RepliesObject: Codable {
        let count: Int?
    }
}

struct CommentsListDTO: Codable, Sendable {
    let items: [CommentDTO]
}

struct CommentReplyDTO: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let postedAt: Date?
    let postedBy: UserReferenceDTO?
    let body: CommentBodyDTO?
    let permissions: CommentPermissionsDTO?
}

struct CommentRepliesListDTO: Codable, Sendable {
    let count: Int?
    let items: [CommentReplyDTO]
}

struct CommentRequestDTO: Codable, Sendable {
    let body: CommentBodyMarkdownDTO

    struct CommentBodyMarkdownDTO: Codable, Sendable {
        let markdown: String
    }

    init(markdown: String) {
        self.body = CommentBodyMarkdownDTO(markdown: markdown)
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
