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

    private(set) var changeRequest: ChangeRequest?
    private(set) var diff: ChangeRequestDiff?

    private(set) var isLoading = false
    private(set) var isLoadingDiff = false
    private(set) var isMerging = false

    /// Track whether each section has been loaded at least once
    private(set) var hasLoadedOnce = false
    private(set) var hasLoadedDiff = false
    private(set) var hasLoadedReviews = false
    private(set) var hasLoadedComments = false

    private(set) var error: Error?

    var showMergeConfirmation = false
    var showArchiveConfirmation = false

    private(set) var isUpdatingStatus = false

    private(set) var reviews: [ChangeRequestReview] = []
    private(set) var requestedReviewers: [UserReference] = []
    private(set) var isLoadingReviews = false
    private(set) var isSubmittingReview = false

    var showApproveConfirmation = false
    var showRequestChangesConfirmation = false

    // MARK: - Comments State

    private(set) var comments: [Comment] = []
    private(set) var isLoadingComments = false
    private(set) var isPostingComment = false
    var newCommentText = ""
    private(set) var repliesByCommentId: [String: [CommentReply]] = [:]
    var expandedCommentIds: Set<String> = []
    var editingCommentId: String?
    var editingReplyId: String?
    var editText = ""
    var replyingToCommentId: String?
    var replyText = ""
    var deletingCommentId: String?
    var deletingReplyCommentId: String?
    var deletingReplyId: String?
    var showDeleteConfirmation = false

    private(set) var space: Space?
    private(set) var collectionName: String?

    // MARK: - Reviewer Picker State

    var showReviewerPicker = false
    private(set) var orgMembers: [UserReference] = []
    private(set) var isLoadingMembers = false
    private(set) var isRequestingReviewer = false

    // MARK: - Dependencies

    private let changeRequestRepository: ChangeRequestRepository
    private let spaceRepository: SpaceRepository
    private let organizationRepository: OrganizationRepository
    private let spaceId: String
    private let changeRequestId: String

    // MARK: - Computed Properties

    var hasError: Bool { error != nil }
    var errorMessage: String? { error?.localizedDescription }
    var canMerge: Bool { changeRequest?.canMerge ?? false }
    var canArchive: Bool { changeRequest?.isActive ?? false }
    var isDraft: Bool { changeRequest?.status == .draft }
    var isArchived: Bool { changeRequest?.status == .archived }

    /// Page titles affected by this CR
    var affectedPageTitles: [String] {
        diff?.changes.filter { !$0.isFile }.map { $0.title } ?? []
    }

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestId: String,
        changeRequestRepository: ChangeRequestRepository,
        spaceRepository: SpaceRepository,
        organizationRepository: OrganizationRepository
    ) {
        self.spaceId = spaceId
        self.changeRequestId = changeRequestId
        self.changeRequestRepository = changeRequestRepository
        self.spaceRepository = spaceRepository
        self.organizationRepository = organizationRepository
    }

    // MARK: - Actions

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

        // Load space info for display (non-blocking)
        do {
            let loadedSpace = try await spaceRepository.getSpace(id: spaceId)
            space = loadedSpace
            // Load parent collection name if space belongs to one
            if let parentId = loadedSpace.parentId, let orgId = loadedSpace.organizationId {
                let collections = try await spaceRepository.getCollections(organizationId: orgId)
                collectionName = collections.first(where: { $0.id == parentId })?.title
            }
        } catch {
            print("Error loading space info: \(error)")
        }

        isLoading = false
        hasLoadedOnce = true
    }

    func loadDiff() async {
        guard !isLoadingDiff else { return }

        isLoadingDiff = true
        error = nil

        do {
            var loadedDiff = try await changeRequestRepository.getChangeRequestDiff(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )

            #if DEBUG
            print("📋 Diff loaded: \(loadedDiff.changes.count) changes")
            for (i, change) in loadedDiff.changes.enumerated() {
                print("  [\(i)] type=\(change.type) title=\(change.title) isFile=\(change.isFile) isMoveOnly=\(change.isMoveOnly)")
            }
            #endif

            // Use revision-based content fetching for accurate diffs across all CR statuses
            let revisionInitial = changeRequest?.revisionInitial
            let crRevision = changeRequest?.revision

            // Load content for page changes in parallel
            await withTaskGroup(of: (Int, String?, String?).self) { group in
                for (index, change) in loadedDiff.changes.enumerated() {
                    guard !change.isFile && !change.contentLoaded && !change.isMoveOnly else { continue }

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

            diff = loadedDiff
        } catch {
            self.error = error
            print("❌ Error loading diff: \(error)")
        }

        isLoadingDiff = false
        hasLoadedDiff = true
    }

    func merge() async {
        guard canMerge else { return }

        isMerging = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.mergeChangeRequest(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
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

    func submitForReview() async {
        guard isDraft else { return }

        isUpdatingStatus = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.updateChangeRequestStatus(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                status: .open
            )
            NotificationCenter.default.post(
                name: .changeRequestStatusDidChange,
                object: ChangeRequestStatusChange(changeRequestId: changeRequestId, newStatus: .open)
            )
        } catch {
            self.error = error
            print("Error submitting for review: \(error)")
        }

        isUpdatingStatus = false
    }

    func reopen() async {
        guard isArchived else { return }

        isUpdatingStatus = true
        error = nil

        do {
            changeRequest = try await changeRequestRepository.updateChangeRequestStatus(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                status: .open
            )
            NotificationCenter.default.post(
                name: .changeRequestStatusDidChange,
                object: ChangeRequestStatusChange(changeRequestId: changeRequestId, newStatus: .open)
            )
        } catch {
            self.error = error
            print("Error reopening change request: \(error)")
        }

        isUpdatingStatus = false
    }

    func loadReviews() async {
        isLoadingReviews = true

        do {
            async let reviewsResult = changeRequestRepository.listReviews(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
            async let reviewersResult = changeRequestRepository.listRequestedReviewers(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )

            reviews = try await reviewsResult
            requestedReviewers = try await reviewersResult
        } catch {
            print("Error loading reviews: \(error)")
        }

        isLoadingReviews = false
        hasLoadedReviews = true
    }

    func approve() async {
        await submitReview(status: .approved)
    }

    func requestChanges() async {
        await submitReview(status: .changesRequested)
    }

    private func submitReview(status: ReviewStatus) async {
        isSubmittingReview = true
        error = nil

        do {
            let review = try await changeRequestRepository.submitReview(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                status: status
            )
            reviews.append(review)
        } catch {
            self.error = error
            print("Error submitting review: \(error)")
        }

        isSubmittingReview = false
    }

    func clearError() {
        error = nil
    }

    // MARK: - Reviewer Actions

    func loadOrgMembers() async {
        guard orgMembers.isEmpty else { return }

        // Try space's organizationId first, fall back to persisted selection
        let orgId = space?.organizationId
            ?? UserDefaults.standard.string(forKey: "selectedOrganizationId")
        guard let orgId else { return }

        isLoadingMembers = true
        do {
            orgMembers = try await organizationRepository.listMembers(organizationId: orgId)
        } catch {
            print("Error loading members: \(error)")
        }
        isLoadingMembers = false
    }

    /// Members available to be requested as reviewers (exclude already requested/reviewed)
    var availableReviewers: [UserReference] {
        let existingIds = Set(requestedReviewers.map(\.id))
            .union(reviews.map { $0.reviewer?.id ?? "" })
        return orgMembers.filter { !existingIds.contains($0.id) }
    }

    func requestReviewer(userId: String) async {
        isRequestingReviewer = true
        error = nil

        do {
            try await changeRequestRepository.requestReviewers(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                userIds: [userId]
            )
            // Add to local list
            if let member = orgMembers.first(where: { $0.id == userId }) {
                requestedReviewers.append(member)
            }
        } catch {
            self.error = error
            print("Error requesting reviewer: \(error)")
        }

        isRequestingReviewer = false
    }

    // MARK: - Comment Actions

    func loadComments() async {
        isLoadingComments = true
        do {
            comments = try await changeRequestRepository.listComments(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
        } catch {
            print("Error loading comments: \(error)")
        }
        isLoadingComments = false
        hasLoadedComments = true
    }

    func postComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isPostingComment = true
        do {
            let comment = try await changeRequestRepository.createComment(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                markdown: text
            )
            comments.append(comment)
            newCommentText = ""
        } catch {
            self.error = error
            print("Error posting comment: \(error)")
        }
        isPostingComment = false
    }

    func updateComment(commentId: String) async {
        let text = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let updated = try await changeRequestRepository.updateComment(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId,
                markdown: text
            )
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index] = updated
            }
            editingCommentId = nil
            editText = ""
        } catch {
            self.error = error
            print("Error updating comment: \(error)")
        }
    }

    func deleteComment(commentId: String) async {
        do {
            try await changeRequestRepository.deleteComment(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId
            )
            comments.removeAll { $0.id == commentId }
            repliesByCommentId.removeValue(forKey: commentId)
        } catch {
            self.error = error
            print("Error deleting comment: \(error)")
        }
    }

    func loadReplies(commentId: String) async {
        do {
            let replies = try await changeRequestRepository.listReplies(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId
            )
            repliesByCommentId[commentId] = replies
        } catch {
            print("Error loading replies: \(error)")
        }
    }

    func postReply(commentId: String) async {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let reply = try await changeRequestRepository.createReply(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId,
                markdown: text
            )
            repliesByCommentId[commentId, default: []].append(reply)
            replyingToCommentId = nil
            replyText = ""
            updateReplyCount(commentId: commentId, delta: 1)
        } catch {
            self.error = error
            print("Error posting reply: \(error)")
        }
    }

    func updateReply(commentId: String, replyId: String) async {
        let text = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let updated = try await changeRequestRepository.updateReply(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId,
                replyId: replyId,
                markdown: text
            )
            if var replies = repliesByCommentId[commentId],
               let index = replies.firstIndex(where: { $0.id == replyId }) {
                replies[index] = updated
                repliesByCommentId[commentId] = replies
            }
            editingReplyId = nil
            editText = ""
        } catch {
            self.error = error
            print("Error updating reply: \(error)")
        }
    }

    func deleteReply(commentId: String, replyId: String) async {
        do {
            try await changeRequestRepository.deleteReply(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                commentId: commentId,
                replyId: replyId
            )
            repliesByCommentId[commentId]?.removeAll { $0.id == replyId }
            updateReplyCount(commentId: commentId, delta: -1)
        } catch {
            self.error = error
            print("Error deleting reply: \(error)")
        }
    }

    private func updateReplyCount(commentId: String, delta: Int) {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
        let c = comments[index]
        comments[index] = Comment(
            id: c.id, body: c.body, postedAt: c.postedAt, editedAt: c.editedAt,
            postedBy: c.postedBy, replyCount: max(0, c.replyCount + delta),
            permissions: c.permissions, status: c.status
        )
    }

    func confirmDelete() async {
        if let commentId = deletingCommentId {
            await deleteComment(commentId: commentId)
            deletingCommentId = nil
        } else if let commentId = deletingReplyCommentId, let replyId = deletingReplyId {
            await deleteReply(commentId: commentId, replyId: replyId)
            deletingReplyCommentId = nil
            deletingReplyId = nil
        }
    }
}
