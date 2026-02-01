//
//  SpaceListViewModel.swift
//  GitBeek
//
//  ViewModel for managing spaces with hierarchical display
//

import Foundation

/// View mode for space list display
enum SpaceListViewMode: String, CaseIterable {
    case hierarchy  // Show collections with nested children
    case flat       // Show all spaces in flat list

    var title: String {
        switch self {
        case .hierarchy: return "Hierarchy"
        case .flat: return "All Spaces"
        }
    }

    var icon: String {
        switch self {
        case .hierarchy: return "folder"
        case .flat: return "list.bullet"
        }
    }
}

/// ViewModel for space list with collection hierarchy
@MainActor
@Observable
final class SpaceListViewModel {
    // MARK: - State

    private(set) var allSpaces: [Space] = []
    private(set) var allCollections: [Collection] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    /// Collections with their child spaces
    private(set) var collections: [CollectionWithSpaces] = []

    /// Top-level spaces (not in any collection)
    private(set) var topLevelSpaces: [Space] = []

    /// Spaces in trash (deleted)
    private(set) var trashedSpaces: [Space] = []

    /// Currently expanded collection IDs
    var expandedCollections: Set<String> = []

    /// Current organization ID
    private(set) var organizationId: String?

    /// View mode (hierarchy or flat)
    var viewMode: SpaceListViewMode = .hierarchy

    /// Search query for filtering spaces
    var searchQuery = ""

    // MARK: - Types

    /// A collection with its child spaces and sub-collections
    struct CollectionWithSpaces: Identifiable, Equatable {
        let collection: Collection
        var children: [Space]
        var childCollections: [CollectionWithSpaces]

        var id: String { collection.id }
        var childCount: Int { children.count + childCollections.count }
        var displayTitle: String { collection.displayTitle }

        init(collection: Collection, children: [Space], childCollections: [CollectionWithSpaces] = []) {
            self.collection = collection
            self.children = children
            self.childCollections = childCollections
        }
    }

    // MARK: - Computed Properties

    var hasError: Bool { error != nil }

    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Active (non-deleted) spaces count
    var activeSpacesCount: Int {
        allSpaces.filter { !$0.isDeleted }.count
    }

    /// Trashed spaces count
    var trashedCount: Int {
        trashedSpaces.count
    }

    /// All active collections (flat list for pickers)
    var activeCollectionsList: [Collection] {
        allCollections
    }

    /// All active spaces for flat view mode (sorted alphabetically)
    var flatSpaces: [Space] {
        let spaces = allSpaces
            .filter { !$0.isDeleted }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        guard !searchQuery.isEmpty else { return spaces }
        return spaces.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }

    /// Whether to show hierarchy (collections with children) or flat list
    var showHierarchy: Bool {
        viewMode == .hierarchy
    }

    /// Filtered collections based on search query
    var filteredCollections: [CollectionWithSpaces] {
        guard !searchQuery.isEmpty else { return collections }

        return collections.compactMap { collection in
            // Filter children that match
            let matchingChildren = collection.children.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery)
            }

            // Include if collection title matches or has matching children
            if collection.collection.title.localizedCaseInsensitiveContains(searchQuery) || !matchingChildren.isEmpty {
                var updated = collection
                // If collection itself doesn't match, only show matching children
                if !collection.collection.title.localizedCaseInsensitiveContains(searchQuery) {
                    updated = CollectionWithSpaces(collection: collection.collection, children: matchingChildren)
                }
                return updated
            }
            return nil
        }
    }

    /// Filtered top-level spaces based on search query
    var filteredTopLevelSpaces: [Space] {
        guard !searchQuery.isEmpty else { return topLevelSpaces }
        return topLevelSpaces.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }

    /// Whether search is active
    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    /// Clear search query
    func clearSearch() {
        searchQuery = ""
    }

    // MARK: - Dependencies

    private let spaceRepository: SpaceRepository

    // MARK: - Initialization

    init(spaceRepository: SpaceRepository) {
        self.spaceRepository = spaceRepository
    }

    // MARK: - Actions

    /// Load spaces and collections for organization
    func loadSpaces(organizationId: String) async {
        self.organizationId = organizationId
        isLoading = true
        error = nil

        do {
            // Fetch both collections and spaces in parallel
            async let collectionsTask = spaceRepository.getCollections(organizationId: organizationId)
            async let spacesTask = spaceRepository.getSpaces(organizationId: organizationId)

            let (fetchedCollections, fetchedSpaces) = try await (collectionsTask, spacesTask)
            allCollections = fetchedCollections
            allSpaces = fetchedSpaces
            organizeHierarchy()
        } catch {
            self.error = error

            // Try cached data on failure
            let cached = await spaceRepository.getCachedSpaces(organizationId: organizationId)
            if !cached.isEmpty {
                allSpaces = cached
                organizeHierarchy()
                self.error = nil
            }
        }

        isLoading = false
    }

    /// Refresh spaces
    func refresh() async {
        guard let orgId = organizationId else { return }
        await loadSpaces(organizationId: orgId)
    }

    /// Create new space
    func createSpace(
        title: String,
        emoji: String?,
        visibility: Space.Visibility,
        parentId: String?
    ) async throws {
        guard let orgId = organizationId else {
            throw SpaceListError.noOrganization
        }

        isLoading = true
        error = nil

        do {
            let newSpace = try await spaceRepository.createSpace(
                organizationId: orgId,
                title: title,
                emoji: emoji,
                visibility: visibility,
                parentId: parentId
            )

            allSpaces.append(newSpace)
            organizeHierarchy()
        } catch {
            self.error = error
            throw error
        }

        isLoading = false
    }

    /// Create new collection
    func createCollection(
        title: String,
        parentId: String?
    ) async throws {
        guard let orgId = organizationId else {
            throw SpaceListError.noOrganization
        }

        isLoading = true
        error = nil

        do {
            let newCollection = try await spaceRepository.createCollection(
                organizationId: orgId,
                title: title,
                parentId: parentId
            )

            allCollections.append(newCollection)
            organizeHierarchy()
        } catch {
            self.error = error
            throw error
        }

        isLoading = false
    }

    /// Delete space (move to trash)
    func deleteSpace(id: String) async {
        isLoading = true
        error = nil

        do {
            try await spaceRepository.deleteSpace(id: id)

            // Remove from local list
            allSpaces.removeAll { $0.id == id }
            organizeHierarchy()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Restore space from trash
    func restoreSpace(id: String) async {
        isLoading = true
        error = nil

        do {
            let restored = try await spaceRepository.restoreSpace(id: id)

            // Update in local list
            if let index = allSpaces.firstIndex(where: { $0.id == id }) {
                allSpaces[index] = restored
            } else {
                allSpaces.append(restored)
            }
            organizeHierarchy()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Toggle collection expansion
    func toggleCollection(id: String) {
        if expandedCollections.contains(id) {
            expandedCollections.remove(id)
        } else {
            expandedCollections.insert(id)
        }
    }

    /// Check if collection is expanded
    func isExpanded(_ collectionId: String) -> Bool {
        expandedCollections.contains(collectionId)
    }

    /// Expand all collections
    func expandAll() {
        expandedCollections = Set(collections.map { $0.id })
    }

    /// Collapse all collections
    func collapseAll() {
        expandedCollections.removeAll()
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    /// Organize spaces into hierarchical structure
    private func organizeHierarchy() {
        // Separate active and deleted spaces
        let activeSpaces = allSpaces.filter { !$0.isDeleted }
        trashedSpaces = allSpaces.filter { $0.isDeleted }.sorted { $0.deletedAt ?? .distantPast > $1.deletedAt ?? .distantPast }

        // Build a set of collection IDs for quick lookup
        let collectionIds = Set(allCollections.map { $0.id })

        // Group spaces by their parent collection ID
        var collectionChildren: [String: [Space]] = [:]
        var orphanSpaces: [Space] = []

        for space in activeSpaces {
            if let parentId = space.parentId, collectionIds.contains(parentId) {
                collectionChildren[parentId, default: []].append(space)
            } else {
                orphanSpaces.append(space)
            }
        }

        // Group sub-collections by parent collection ID
        var subCollections: [String: [Collection]] = [:]
        var topLevelCollections: [Collection] = []

        for collection in allCollections {
            if let parentId = collection.parentId, collectionIds.contains(parentId) {
                subCollections[parentId, default: []].append(collection)
            } else {
                topLevelCollections.append(collection)
            }
        }

        // Recursively build collection tree
        func buildCollectionTree(_ collection: Collection) -> CollectionWithSpaces {
            let childSpaces = (collectionChildren[collection.id] ?? [])
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            let childCols = (subCollections[collection.id] ?? [])
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                .map { buildCollectionTree($0) }
            return CollectionWithSpaces(collection: collection, children: childSpaces, childCollections: childCols)
        }

        collections = topLevelCollections
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { buildCollectionTree($0) }

        // Top-level spaces: spaces without a parent or parent not in our collections
        topLevelSpaces = orphanSpaces
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

// MARK: - Errors

enum SpaceListError: LocalizedError {
    case noOrganization

    var errorDescription: String? {
        switch self {
        case .noOrganization:
            return "No organization selected"
        }
    }
}
