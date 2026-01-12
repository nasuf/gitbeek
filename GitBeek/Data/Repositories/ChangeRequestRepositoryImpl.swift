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
        let dto = try await apiService.mergeChangeRequest(spaceId: spaceId, changeRequestId: changeRequestId)
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
}
