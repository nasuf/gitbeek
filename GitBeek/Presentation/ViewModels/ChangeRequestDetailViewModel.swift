//
//  ChangeRequestDetailViewModel.swift
//  GitBeek
//
//  ViewModel for Change Request details
//

import Foundation
import Observation

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

    /// Did merge successfully
    private(set) var didMerge = false

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

    /// Load change request diff
    func loadDiff() async {
        guard !isLoadingDiff else { return }

        isLoadingDiff = true
        error = nil

        do {
            diff = try await changeRequestRepository.getChangeRequestDiff(
                spaceId: spaceId,
                changeRequestId: changeRequestId
            )
        } catch {
            self.error = error
            print("Error loading diff: \(error)")
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
        } catch {
            self.error = error
            print("Error merging change request: \(error)")
        }

        isMerging = false
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
