//
//  AllChangeRequestsViewModel.swift
//  GitBeek
//
//  ViewModel for all change requests across all spaces
//

import Foundation
import Observation

/// Display mode for change requests within a collection
enum CollectionDisplayMode {
    /// Group by spaces
    case groupedBySpaces
    /// Flat list sorted by time (newest first)
    case flatByTime
}

/// ViewModel for managing all change requests across all spaces
@MainActor
@Observable
final class AllChangeRequestsViewModel {
    // MARK: - State

    /// List of all change requests with their space info
    private(set) var changeRequests: [(space: Space, changeRequest: ChangeRequest)] = []

    /// All spaces (for building hierarchy)
    private(set) var allSpaces: [Space] = []

    /// All collections (for building hierarchy)
    private(set) var allCollections: [Collection] = []

    /// Expanded collection IDs
    private(set) var expandedCollectionIds: Set<String> = []

    /// Display mode for each collection (collectionId -> displayMode)
    private(set) var collectionDisplayModes: [String: CollectionDisplayMode] = [:]

    /// Global loading state (for initial load)
    private(set) var isLoading = false

    /// Error state
    private(set) var error: Error?

    /// Currently selected filter (defaults to All)
    var selectedStatus: ChangeRequestStatus? = nil

    /// Data loaded flag (to prevent reloading on every appear)
    private(set) var hasLoadedData = false

    /// Last refresh time
    private(set) var lastRefreshTime: Date?

    /// Current loading task (for cancellation)
    private var loadingTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let changeRequestRepository: ChangeRequestRepository
    private let spaceRepository: SpaceRepository
    private let organizationRepository: OrganizationRepository

    // MARK: - Computed Properties

    /// Filtered change requests based on selected status
    var filteredChangeRequests: [(space: Space, changeRequest: ChangeRequest)] {
        if let status = selectedStatus {
            return changeRequests.filter { $0.changeRequest.status == status }
        }
        return changeRequests
    }

    /// Count by status
    var openCount: Int {
        changeRequests.filter { $0.changeRequest.status == .open }.count
    }

    var draftCount: Int {
        changeRequests.filter { $0.changeRequest.status == .draft }.count
    }

    var mergedCount: Int {
        changeRequests.filter { $0.changeRequest.status == .merged }.count
    }

    var archivedCount: Int {
        changeRequests.filter { $0.changeRequest.status == .archived }.count
    }

    /// Has error
    var hasError: Bool {
        error != nil
    }

    /// Error message
    var errorMessage: String? {
        error?.localizedDescription
    }


    // MARK: - Hierarchy Support

    /// Grouped change requests by collection
    struct CollectionGroup: Identifiable {
        let id: String
        let collection: Collection
        var changeRequests: [(space: Space, changeRequest: ChangeRequest)]

        var count: Int { changeRequests.count }
    }

    /// Grouped change requests (no parent collection)
    struct SpaceGroup: Identifiable {
        let id: String
        let space: Space
        var changeRequests: [ChangeRequest]

        var count: Int { changeRequests.count }
    }

    /// Collections with change requests
    var collectionGroups: [CollectionGroup] {
        let filtered = filteredChangeRequests

        // Group by collection
        var groups: [String: CollectionGroup] = [:]

        for (space, cr) in filtered {
            // Check if space belongs to a collection
            if let parentId = space.parentId,
               let collection = allCollections.first(where: { $0.id == parentId }) {
                if var existingGroup = groups[collection.id] {
                    existingGroup.changeRequests.append((space, cr))
                    groups[collection.id] = existingGroup
                } else {
                    groups[collection.id] = CollectionGroup(
                        id: collection.id,
                        collection: collection,
                        changeRequests: [(space, cr)]
                    )
                }
            }
        }

        return Array(groups.values).sorted { $0.collection.title < $1.collection.title }
    }

    /// Top-level space groups (not in any collection)
    var topLevelSpaceGroups: [SpaceGroup] {
        let filtered = filteredChangeRequests

        // Filter spaces without parent (not in collection)
        var groups: [String: SpaceGroup] = [:]

        for (space, cr) in filtered {
            if space.parentId == nil {
                if var existingGroup = groups[space.id] {
                    existingGroup.changeRequests.append(cr)
                    groups[space.id] = existingGroup
                } else {
                    groups[space.id] = SpaceGroup(
                        id: space.id,
                        space: space,
                        changeRequests: [cr]
                    )
                }
            }
        }

        return Array(groups.values).sorted { $0.space.title < $1.space.title }
    }

    /// Check if collection is expanded
    func isExpanded(_ collectionId: String) -> Bool {
        expandedCollectionIds.contains(collectionId)
    }

    /// Toggle collection expanded state
    func toggleCollection(_ collectionId: String) {
        if expandedCollectionIds.contains(collectionId) {
            expandedCollectionIds.remove(collectionId)
        } else {
            expandedCollectionIds.insert(collectionId)
        }
    }

    /// Get display mode for collection (default: groupedBySpaces)
    func getDisplayMode(for collectionId: String) -> CollectionDisplayMode {
        return collectionDisplayModes[collectionId] ?? .groupedBySpaces
    }

    /// Toggle display mode for collection
    func toggleDisplayMode(for collectionId: String) {
        let currentMode = getDisplayMode(for: collectionId)
        collectionDisplayModes[collectionId] = currentMode == .groupedBySpaces ? .flatByTime : .groupedBySpaces
    }

    // MARK: - Initialization

    init(
        changeRequestRepository: ChangeRequestRepository,
        spaceRepository: SpaceRepository,
        organizationRepository: OrganizationRepository
    ) {
        self.changeRequestRepository = changeRequestRepository
        self.spaceRepository = spaceRepository
        self.organizationRepository = organizationRepository
    }

    // MARK: - Actions

    func load(forceRefresh: Bool = false) async {
        if hasLoadedData && !forceRefresh {
            return
        }

        if forceRefresh {
            loadingTask?.cancel()
            loadingTask = nil
        }

        if isLoading && !forceRefresh {
            return
        }

        isLoading = true
        error = nil

        if forceRefresh {
            changeRequests = []
            allSpaces = []
            allCollections = []
            hasLoadedData = false
        }

        loadingTask = Task { @MainActor in
            await performLoad()
        }

        await loadingTask?.value

        isLoading = false
        loadingTask = nil
    }

    private func performLoad() async {
        do {
            guard !Task.isCancelled else { return }

            let organizations = try await organizationRepository.getOrganizations()
            guard !Task.isCancelled else { return }

            for org in organizations {
                guard !Task.isCancelled else { return }

                let spaces = try await spaceRepository.getSpaces(organizationId: org.id)
                allSpaces.append(contentsOf: spaces)

                let collections = try await spaceRepository.getCollections(organizationId: org.id)
                allCollections.append(contentsOf: collections)
            }

            guard !Task.isCancelled else { return }

            for space in allSpaces {
                guard !Task.isCancelled else { return }

                do {
                    let crs = try await changeRequestRepository.listChangeRequests(
                        spaceId: space.id,
                        page: nil
                    )
                    let pairs = crs.map { (space: space, changeRequest: $0) }
                    changeRequests.append(contentsOf: pairs)
                } catch {
                    if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                        return
                    }
                }
            }

            guard !Task.isCancelled else { return }

            changeRequests.sort { lhs, rhs in
                guard let lhsDate = lhs.changeRequest.updatedAt,
                      let rhsDate = rhs.changeRequest.updatedAt else {
                    return false
                }
                return lhsDate > rhsDate
            }

            hasLoadedData = true
            lastRefreshTime = Date()
        } catch {
            if !(Task.isCancelled || (error as? URLError)?.code == .cancelled || error.localizedDescription.lowercased().contains("cancel")) {
                self.error = error
            }
        }
    }

    func refresh() async {
        selectedStatus = nil

        if isLoading {
            try? await Task.sleep(for: .milliseconds(100))
            return
        }

        Task { @MainActor in
            await load(forceRefresh: true)
        }

        try? await Task.sleep(for: .milliseconds(100))
    }

    /// Update a change request's status locally (no API call)
    func updateLocalStatus(changeRequestId: String, newStatus: ChangeRequestStatus) {
        guard let index = changeRequests.firstIndex(where: { $0.changeRequest.id == changeRequestId }) else { return }
        let old = changeRequests[index]
        changeRequests[index] = (space: old.space, changeRequest: old.changeRequest.withStatus(newStatus))
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
