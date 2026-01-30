//
//  ChangeRequestDetailViewModel.swift
//  GitBeek
//
//  ViewModel for Change Request details
//

import Foundation
import Observation

extension Notification.Name {
    static let changeRequestStatusDidChange = Notification.Name("changeRequestStatusDidChange")
}

struct ChangeRequestStatusChange {
    let changeRequestId: String
    let newStatus: ChangeRequestStatus
}

/// ViewModel for managing change request details
@MainActor
@Observable
final class ChangeRequestDetailViewModel {
    // MARK: - State

    /// Change request details
    private(set) var changeRequest: ChangeRequest?

    /// Change request diff
    private(set) var diff: ChangeRequestDiff?

    /// Loading states
    private(set) var isLoading = false
    private(set) var isLoadingDiff = false
    private(set) var isMerging = false

    /// Error state
    private(set) var error: Error?

    /// Show merge confirmation
    var showMergeConfirmation = false

    /// Show archive confirmation
    var showArchiveConfirmation = false

    /// Is updating status
    private(set) var isUpdatingStatus = false

    /// Did merge successfully
    private(set) var didMerge = false

    /// Did archive successfully
    private(set) var didArchive = false

    // MARK: - Dependencies

    private let changeRequestRepository: ChangeRequestRepository
    private let spaceId: String
    private let changeRequestId: String

    // MARK: - Computed Properties

    /// Has error
    var hasError: Bool {
        error != nil
    }

    /// Error message
    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Can merge
    var canMerge: Bool {
        changeRequest?.canMerge ?? false
    }

    /// Can archive (open or draft CRs)
    var canArchive: Bool {
        changeRequest?.isActive ?? false
    }

    /// Has diff loaded
    var hasDiff: Bool {
        diff != nil
    }

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestId: String,
        changeRequestRepository: ChangeRequestRepository
    ) {
        self.spaceId = spaceId
        self.changeRequestId = changeRequestId
        self.changeRequestRepository = changeRequestRepository
    }

    // MARK: - Actions

    /// Load change request details
    func load() async {
        isLoading = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.getChangeRequest(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
        } catch {
            self.error = error
            print("Error loading change request: \(error)")
        }

        isLoading = false
    }

    /// Load change request diff and fetch content for each change
    func loadDiff() async {
        guard !isLoadingDiff else { return }

        isLoadingDiff = true
        error = nil

        do {
            print("📋 [Diff] Loading diff for spaceId=\(spaceId) crId=\(changeRequestId)")
            print("📋 [Diff] CR revision=\(changeRequest?.revision ?? "nil") revisionInitial=\(changeRequest?.revisionInitial ?? "nil")")
            var loadedDiff = try await changeRequestRepository.getChangeRequestDiff(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )

            // Use revision-based content fetching for accurate diffs across all CR statuses
            let revisionInitial = changeRequest?.revisionInitial
            let crRevision = changeRequest?.revision

            // Load content for page changes in parallel
            await withTaskGroup(of: (Int, String?, String?).self) { group in
                for (index, change) in loadedDiff.changes.enumerated() {
                    guard !change.isFile && !change.contentLoaded else { continue }

                    group.addTask { [spaceId, changeRequestRepository] in
                        var before: String? = nil
                        var after: String? = nil

                        // Before: content at revisionInitial (base version before CR)
                        if change.type != .added, let revisionInitial {
                            before = try? await changeRequestRepository.getPageContentAtRevision(
                                spaceId: spaceId,
                                revisionId: revisionInitial,
                                pageId: change.id
                            )
                        }

                        // After: content at CR's current revision
                        if change.type != .removed, let crRevision {
                            after = try? await changeRequestRepository.getPageContentAtRevision(
                                spaceId: spaceId,
                                revisionId: crRevision,
                                pageId: change.id
                            )
                        }

                        return (index, before, after)
                    }
                }

                for await (index, before, after) in group {
                    loadedDiff.changes[index].contentBefore = before
                    loadedDiff.changes[index].contentAfter = after
                    loadedDiff.changes[index].contentLoaded = true
                }
            }

            print("📋 [Diff] Loaded \(loadedDiff.changes.count) changes")
            for (i, c) in loadedDiff.changes.enumerated() {
                print("  [\(i)] type=\(c.type) title=\(c.title) path=\(c.path) isFile=\(c.isFile) contentLoaded=\(c.contentLoaded)")
            }
            diff = loadedDiff
        } catch {
            self.error = error
            print("❌ Error loading diff: \(error)")
        }

        isLoadingDiff = false
    }

    /// Merge change request
    func merge() async {
        guard canMerge else { return }

        isMerging = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.mergeChangeRequest(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
            didMerge = true
            NotificationCenter.default.post(
                name: .changeRequestStatusDidChange,
                object: ChangeRequestStatusChange(changeRequestId: changeRequestId, newStatus: .merged)
            )
        } catch {
            self.error = error
            print("Error merging change request: \(error)")
        }

        isMerging = false
    }

    /// Archive/close change request
    func archive() async {
        guard canArchive else { return }

        isUpdatingStatus = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.updateChangeRequestStatus(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                status: .archived
            )
            didArchive = true
            NotificationCenter.default.post(
                name: .changeRequestStatusDidChange,
                object: ChangeRequestStatusChange(changeRequestId: changeRequestId, newStatus: .archived)
            )
        } catch {
            self.error = error
            print("Error archiving change request: \(error)")
        }

        isUpdatingStatus = false
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
