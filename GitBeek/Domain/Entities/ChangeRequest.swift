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
    let createdBy: UserReference?
    let urls: ChangeRequestURLs?

    var displayTitle: String {
        subject ?? "Change Request #\(number)"
    }

    var isActive: Bool {
        status == .open || status == .draft
    }

    var canMerge: Bool {
        status == .open
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
    var id: String { path }
    let type: ChangeType
    let path: String
    let document: DocumentChange?

    var displayPath: String {
        path.replacingOccurrences(of: "/", with: " › ")
    }
}

/// Change request diff
struct ChangeRequestDiff: Equatable, Sendable {
    let changes: [Change]

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
            createdBy: dto.createdBy.map { UserReference.from(dto: $0) },
            urls: dto.urls.map { ChangeRequestURLs(location: $0.location, app: $0.app) }
        )
    }
}

extension Change {
    static func from(dto: ChangeRequestDiffDTO.ChangeDTO) -> Change? {
        // page is required - if it's missing, return nil
        guard let page = dto.page else {
            print("⚠️ [Change] Skipping change with missing page")
            return nil
        }

        let changeType: ChangeType
        switch dto.type.lowercased() {
        case "page_added": changeType = .added
        case "page_edited": changeType = .modified
        case "page_removed": changeType = .removed
        default:
            print("⚠️ [Change] Unknown type '\(dto.type)', defaulting to modified")
            changeType = .modified
        }

        // Build document change from attributes
        let documentChange: DocumentChange?
        if let attributes = dto.attributes,
           let titleChange = attributes.title {
            documentChange = DocumentChange(
                before: titleChange.before,
                after: titleChange.after
            )
        } else {
            documentChange = nil
        }

        return Change(
            type: changeType,
            path: page.path,
            document: documentChange
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
