//
//  ChangeRequest.swift
//  GitBeek
//
//  Change Request domain entity
//

import Foundation

// MARK: - ChangeRequestStatus Extensions

extension ChangeRequestStatus {
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .open: return "Open"
        case .merged: return "Merged"
        case .archived: return "Archived"
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .open: return "circle"
        case .merged: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }

    var color: String {
        switch self {
        case .draft: return "gray"
        case .open: return "blue"
        case .merged: return "green"
        case .archived: return "purple"
        }
    }
}

/// Change Request entity
struct ChangeRequest: Identifiable, Equatable, Hashable, Sendable {
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
    let createdBy: UserReference?
    let urls: ChangeRequestURLs?

    var displayTitle: String {
        if let subject = subject, !subject.isEmpty {
            return subject
        }
        return "Change Request #\(number)"
    }

    var isActive: Bool {
        status == .open || status == .draft
    }

    var canMerge: Bool {
        status == .open
    }

    /// Returns a copy with the given status and updated timestamps
    func withStatus(_ newStatus: ChangeRequestStatus) -> ChangeRequest {
        ChangeRequest(
            id: id, number: number, subject: subject, status: newStatus,
            createdAt: createdAt, updatedAt: Date(),
            mergedAt: newStatus == .merged ? Date() : mergedAt,
            closedAt: newStatus == .archived ? Date() : closedAt,
            revision: revision, revisionInitial: revisionInitial,
            createdBy: createdBy, urls: urls
        )
    }

    struct ChangeRequestURLs: Equatable, Hashable, Sendable {
        let location: String?
        let app: String?
    }
}

/// Change type
enum ChangeType: String, Codable, Sendable {
    case added
    case modified
    case removed

    var displayName: String {
        switch self {
        case .added: return "Added"
        case .modified: return "Modified"
        case .removed: return "Removed"
        }
    }

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .removed: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .added: return "green"
        case .modified: return "orange"
        case .removed: return "red"
        }
    }
}

/// Document change
struct DocumentChange: Equatable, Hashable, Sendable {
    let before: String?
    let after: String?

    var hasChanges: Bool {
        before != after
    }
}

/// Single change in a change request
struct Change: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let type: ChangeType
    let path: String
    let title: String
    let isFile: Bool
    let fileName: String?
    let titleChange: DocumentChange?
    /// Whether the document content itself changed (has attributes.document)
    let hasDocumentChange: Bool
    /// Markdown content before (from main space) — loaded async
    var contentBefore: String?
    /// Markdown content after (from CR) — loaded async
    var contentAfter: String?
    /// Whether content has been loaded
    var contentLoaded: Bool

    var displayPath: String {
        path.replacingOccurrences(of: "/", with: " › ")
    }

    var displayTitle: String {
        if isFile {
            return fileName ?? title
        }
        return title
    }

    /// Whether this is a move/rename without content change
    var isMoveOnly: Bool {
        type == .modified && !hasDocumentChange && titleChange != nil
    }
}

/// Change request diff
struct ChangeRequestDiff: Equatable, Sendable {
    var changes: [Change]

    var hasChanges: Bool {
        !changes.isEmpty
    }

    var addedCount: Int {
        changes.filter { $0.type == .added }.count
    }

    var modifiedCount: Int {
        changes.filter { $0.type == .modified }.count
    }

    var removedCount: Int {
        changes.filter { $0.type == .removed }.count
    }

    var summary: String {
        var parts: [String] = []
        if addedCount > 0 {
            parts.append("\(addedCount) added")
        }
        if modifiedCount > 0 {
            parts.append("\(modifiedCount) modified")
        }
        if removedCount > 0 {
            parts.append("\(removedCount) removed")
        }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
}

// MARK: - DTO Mapping

extension ChangeRequest {
    static func from(dto: ChangeRequestDTO) -> ChangeRequest {
        ChangeRequest(
            id: dto.id,
            number: dto.number,
            subject: dto.subject,
            status: dto.status,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            mergedAt: dto.mergedAt,
            closedAt: dto.closedAt,
            revision: dto.revision,
            revisionInitial: dto.revisionInitial,
            createdBy: dto.createdBy.map { UserReference.from(dto: $0) },
            urls: dto.urls.map { ChangeRequestURLs(location: $0.location, app: $0.app) }
        )
    }
}

extension Change {
    static func from(dto: ChangeRequestDiffDTO.ChangeDTO) -> Change? {
        let changeType: ChangeType
        switch dto.type.lowercased() {
        case "page_created", "page_added", "file_created": changeType = .added
        case "page_edited": changeType = .modified
        case "page_removed", "page_deleted", "file_removed", "file_deleted": changeType = .removed
        default:
            print("⚠️ [Change] Unknown type '\(dto.type)', defaulting to modified")
            changeType = .modified
        }

        // Handle file changes
        if let file = dto.file {
            return Change(
                id: file.id,
                type: changeType,
                path: file.name,
                title: file.name,
                isFile: true,
                fileName: file.name,
                titleChange: nil,
                hasDocumentChange: false,
                contentBefore: nil,
                contentAfter: nil,
                contentLoaded: true
            )
        }

        // Handle page changes
        guard let page = dto.page else {
            print("⚠️ [Change] Skipping change with missing page and file")
            return nil
        }

        // Build title change from attributes
        let titleChange: DocumentChange?
        if let attributes = dto.attributes,
           let tc = attributes.title {
            titleChange = DocumentChange(
                before: tc.before,
                after: tc.after
            )
        } else {
            titleChange = nil
        }

        let hasDocumentChange = dto.attributes?.document != nil

        return Change(
            id: page.id,
            type: changeType,
            path: page.path,
            title: page.title,
            isFile: false,
            fileName: nil,
            titleChange: titleChange,
            hasDocumentChange: hasDocumentChange,
            contentBefore: nil,
            contentAfter: nil,
            contentLoaded: false
        )
    }
}

extension ChangeRequestDiff {
    static func from(dto: ChangeRequestDiffDTO) -> ChangeRequestDiff {
        ChangeRequestDiff(
            changes: dto.changes.compactMap { Change.from(dto: $0) }
        )
    }
}
