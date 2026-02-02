//
//  ChangeRequestRepositoryImpl.swift
//  GitBeek
//
//  Implementation of ChangeRequestRepository
//

import Foundation

/// Implementation of ChangeRequestRepository using GitBook API
final class ChangeRequestRepositoryImpl: ChangeRequestRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService

    // MARK: - Initialization

    init(apiService: GitBookAPIService) {
        self.apiService = apiService
    }

    // MARK: - ChangeRequestRepository

    func listChangeRequests(spaceId: String, page: String? = nil) async throws -> [ChangeRequest] {
        // GitBook API 不支持 "all" 状态，需要分别获取各个状态的 change requests
        // 有效的状态值：draft, open, archived, merged
        let statuses = ["draft", "open", "archived", "merged"]
        var allChangeRequests: [ChangeRequest] = []

        // 分别获取每个状态的 change requests
        for status in statuses {
            do {
                let response = try await apiService.listChangeRequests(spaceId: spaceId, status: status, page: page)
                let changeRequests = response.items.map { ChangeRequest.from(dto: $0) }
                allChangeRequests.append(contentsOf: changeRequests)
            } catch {
                // 如果某个状态获取失败，记录错误但继续处理其他状态
                #if DEBUG
                print("⚠️ 获取 \(status) 状态的 Change Requests 失败: \(error)")
                #endif
            }
        }

        // 按更新时间倒序排序（最新的在前）
        return allChangeRequests.sorted { ($0.updatedAt ?? $0.createdAt ?? Date.distantPast) > ($1.updatedAt ?? $1.createdAt ?? Date.distantPast) }
    }

    func getChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        let dto = try await apiService.getChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId)
        return ChangeRequest.from(dto: dto)
    }

    func getChangeRequestDiff(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDiff {
        let dto = try await apiService.getChangeRequestDiff(spaceId: spaceId, changeRequestId: changeRequestId)
        return ChangeRequestDiff.from(dto: dto)
    }

    func mergeChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        // Merge returns a simple result, not a full ChangeRequestDTO
        _ = try await apiService.mergeChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId)
        // Re-fetch the CR to get the updated state
        let dto = try await apiService.getChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId)
        return ChangeRequest.from(dto: dto)
    }

    func updateChangeRequestStatus(
        spaceId: String,
        changeRequestId: String,
        status: ChangeRequestStatus
    ) async throws -> ChangeRequest {
        let dto = try await apiService.updateChangeRequest(
            spaceId: spaceId,
            changeRequestId: changeRequestId,
            subject: nil,
            status: status
        )
        return ChangeRequest.from(dto: dto)
    }

    func updateChangeRequestSubject(
        spaceId: String,
        changeRequestId: String,
        subject: String
    ) async throws -> ChangeRequest {
        let dto = try await apiService.updateChangeRequest(
            spaceId: spaceId,
            changeRequestId: changeRequestId,
            subject: subject,
            status: nil
        )
        return ChangeRequest.from(dto: dto)
    }

    func getPageContent(spaceId: String, pageId: String) async throws -> String? {
        do {
            let dto = try await apiService.getPage(spaceId: spaceId, pageId: pageId)
            return dto.markdown
        } catch {
            return nil
        }
    }

    func getChangeRequestPageContent(spaceId: String, changeRequestId: String, pageId: String) async throws -> String? {
        do {
            let dto = try await apiService.getChangeRequestPageContent(spaceId: spaceId, changeRequestId: changeRequestId, pageId: pageId)
            return dto.markdown
        } catch {
            return nil
        }
    }

    func getPageContentAtRevision(spaceId: String, revisionId: String, pageId: String) async throws -> String? {
        do {
            let dto = try await apiService.getPageAtRevision(spaceId: spaceId, revisionId: revisionId, pageId: pageId)
            return dto.markdown
        } catch {
            return nil
        }
    }

    func listReviews(spaceId: String, changeRequestId: String) async throws -> [ChangeRequestReview] {
        let dto = try await apiService.listChangeRequestReviews(spaceId: spaceId, changeRequestId: changeRequestId)
        return dto.items.map { ChangeRequestReview.from(dto: $0) }
    }

    func submitReview(spaceId: String, changeRequestId: String, status: ReviewStatus) async throws -> ChangeRequestReview {
        let dto = try await apiService.submitChangeRequestReview(spaceId: spaceId, changeRequestId: changeRequestId, status: status)
        return ChangeRequestReview.from(dto: dto)
    }

    func listRequestedReviewers(spaceId: String, changeRequestId: String) async throws -> [UserReference] {
        let dto = try await apiService.listRequestedReviewers(spaceId: spaceId, changeRequestId: changeRequestId)
        return dto.items.compactMap { $0.user.map { UserReference.from(dto: $0) } }
    }

    // MARK: - Comments

    func listComments(spaceId: String, changeRequestId: String) async throws -> [Comment] {
        let dto = try await apiService.listComments(spaceId: spaceId, changeRequestId: changeRequestId)
        return dto.items.map { Comment.from(dto: $0) }
    }

    func createComment(spaceId: String, changeRequestId: String, markdown: String) async throws -> Comment {
        let dto = try await apiService.createComment(spaceId: spaceId, changeRequestId: changeRequestId, markdown: markdown)
        return Comment.from(dto: dto)
    }

    func updateComment(spaceId: String, changeRequestId: String, commentId: String, markdown: String) async throws -> Comment {
        let dto = try await apiService.updateComment(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId, markdown: markdown)
        return Comment.from(dto: dto)
    }

    func deleteComment(spaceId: String, changeRequestId: String, commentId: String) async throws {
        try await apiService.deleteComment(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId)
    }

    func listReplies(spaceId: String, changeRequestId: String, commentId: String) async throws -> [CommentReply] {
        let dto = try await apiService.listReplies(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId)
        return dto.items.map { CommentReply.from(dto: $0) }
    }

    func createReply(spaceId: String, changeRequestId: String, commentId: String, markdown: String) async throws -> CommentReply {
        let dto = try await apiService.createReply(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId, markdown: markdown)
        return CommentReply.from(dto: dto)
    }

    func updateReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String, markdown: String) async throws -> CommentReply {
        let dto = try await apiService.updateReply(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId, replyId: replyId, markdown: markdown)
        return CommentReply.from(dto: dto)
    }

    func deleteReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String) async throws {
        try await apiService.deleteReply(spaceId: spaceId, changeRequestId: changeRequestId, commentId: commentId, replyId: replyId)
    }
}
