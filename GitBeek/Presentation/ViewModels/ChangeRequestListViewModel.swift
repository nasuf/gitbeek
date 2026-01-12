//
//  ChangeRequestListViewModel.swift
//  GitBeek
//
//  ViewModel for Change Request list
//

import Foundation
import Observation

/// ViewModel for managing the list of change requests
@MainActor
@Observable
final class ChangeRequestListViewModel {
    // MARK: - State

    /// List of change requests
    private(set) var changeRequests: [ChangeRequest] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error state
    private(set) var error: Error?

    /// Currently selected filter
    var selectedStatus: ChangeRequestStatus? = nil

    // MARK: - Dependencies

    private let changeRequestRepository: ChangeRequestRepository
    private let spaceId: String

    // MARK: - Computed Properties

    /// Filtered change requests based on selected status
    var filteredChangeRequests: [ChangeRequest] {
        if let status = selectedStatus {
            return changeRequests.filter { $0.status == status }
        }
        return changeRequests
    }

    /// Count by status
    var openCount: Int {
        changeRequests.filter { $0.status == .open }.count
    }

    var draftCount: Int {
        changeRequests.filter { $0.status == .draft }.count
    }

    var mergedCount: Int {
        changeRequests.filter { $0.status == .merged }.count
    }

    var archivedCount: Int {
        changeRequests.filter { $0.status == .archived }.count
    }

    /// Has error
    var hasError: Bool {
        error != nil
    }

    /// Error message
    var errorMessage: String? {
        error?.localizedDescription
    }

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestRepository: ChangeRequestRepository
    ) {
        self.spaceId = spaceId
        self.changeRequestRepository = changeRequestRepository
    }

    // MARK: - Actions

    /// Load change requests
    func load() async {
        isLoading = true
        error = nil

        do {
            changeRequests = try await changeRequestRepository.listChangeRequests(
                spaceId: spaceId,
                page: nil
            )
        } catch {
            self.error = error
            print("Error loading change requests: \(error)")
        }

        isLoading = false
    }

    /// Refresh change requests
    func refresh() async {
        await load()
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    /// Set filter status
    func setFilter(_ status: ChangeRequestStatus?) {
        selectedStatus = status
    }
}
