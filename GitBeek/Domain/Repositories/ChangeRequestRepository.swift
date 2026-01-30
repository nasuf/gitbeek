//
//  ChangeRequestRepository.swift
//  GitBeek
//
//  Repository protocol for Change Request operations
//

import Foundation

/// Repository for managing change requests
protocol ChangeRequestRepository: Sendable {
    /// List all change requests for a space
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - page: Optional pagination cursor
    /// - Returns: List of change requests
    func listChangeRequests(spaceId: String, page: String?) async throws -> [ChangeRequest]

    /// Get a specific change request
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    /// - Returns: Change request details
    func getChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest

    /// Get diff for a change request
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    /// - Returns: Diff showing all changes
    func getChangeRequestDiff(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDiff

    /// Merge a change request
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    /// - Returns: Updated change request
    func mergeChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest

    /// Update change request status (close/reopen)
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    ///   - status: New status
    /// - Returns: Updated change request
    func updateChangeRequestStatus(
        spaceId: String,
        changeRequestId: String,
        status: ChangeRequestStatus
    ) async throws -> ChangeRequest

    /// Update change request subject
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    ///   - subject: New subject
    /// - Returns: Updated change request
    func updateChangeRequestSubject(
        spaceId: String,
        changeRequestId: String,
        subject: String
    ) async throws -> ChangeRequest

    /// Get page markdown content from the main space (before version)
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - pageId: Page identifier
    /// - Returns: Markdown content string, or nil if page doesn't exist
    func getPageContent(spaceId: String, pageId: String) async throws -> String?

    /// Get page markdown content from a change request (after version)
    /// - Parameters:
    ///   - spaceId: Space identifier
    ///   - changeRequestId: Change request identifier
    ///   - pageId: Page identifier
    /// - Returns: Markdown content string, or nil if page doesn't exist
    func getChangeRequestPageContent(spaceId: String, changeRequestId: String, pageId: String) async throws -> String?

    /// Get page markdown content at a specific revision
    func getPageContentAtRevision(spaceId: String, revisionId: String, pageId: String) async throws -> String?
}
