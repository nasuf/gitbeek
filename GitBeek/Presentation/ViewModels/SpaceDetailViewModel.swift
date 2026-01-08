//
//  SpaceDetailViewModel.swift
//  GitBeek
//
//  ViewModel for space detail view with content tree
//

import Foundation

/// ViewModel for space detail with page navigation
@MainActor
@Observable
final class SpaceDetailViewModel {
    // MARK: - State

    private(set) var space: Space?
    private(set) var contentTree: [Page] = []
    private(set) var isLoading = false
    private(set) var isLoadingContent = false
    private(set) var error: Error?

    /// Search query for filtering pages
    var searchQuery = ""

    /// Currently expanded page IDs (for groups)
    var expandedPageIds: Set<String> = []

    /// Current space ID
    private(set) var spaceId: String?

    // MARK: - Computed Properties

    var hasError: Bool { error != nil }

    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Filtered pages based on search query
    var filteredPages: [Page] {
        guard !searchQuery.isEmpty else {
            return contentTree
        }

        return filterPages(contentTree, query: searchQuery)
    }

    /// Total page count
    var totalPageCount: Int {
        contentTree.reduce(0) { $0 + 1 + $1.descendantCount }
    }

    /// Flat list of all pages for search
    var allPagesFlat: [Page] {
        contentTree.flatMap { $0.flatten() }
    }

    /// Display title (with emoji if available)
    var displayTitle: String {
        space?.displayTitle ?? "Space"
    }

    // MARK: - Dependencies

    private let spaceRepository: SpaceRepository
    private let pageRepository: PageRepository

    // MARK: - Initialization

    init(spaceRepository: SpaceRepository, pageRepository: PageRepository) {
        self.spaceRepository = spaceRepository
        self.pageRepository = pageRepository
    }

    // MARK: - Actions

    /// Load space details
    func loadSpace(spaceId: String) async {
        self.spaceId = spaceId
        isLoading = true
        error = nil

        do {
            space = try await spaceRepository.getSpace(id: spaceId)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Load content tree for current space
    func loadContentTree() async {
        guard let spaceId = spaceId else { return }

        isLoadingContent = true
        error = nil

        do {
            contentTree = try await pageRepository.getContentTree(spaceId: spaceId)
        } catch {
            self.error = error

            // Try cached content on failure
            let cached = await pageRepository.getCachedContentTree(spaceId: spaceId)
            if !cached.isEmpty {
                contentTree = cached
                self.error = nil
            }
        }

        isLoadingContent = false
    }

    /// Load both space and content tree
    func loadAll(spaceId: String) async {
        self.spaceId = spaceId
        isLoading = true
        error = nil

        do {
            // Load in parallel
            async let spaceTask = spaceRepository.getSpace(id: spaceId)
            async let contentTask = pageRepository.getContentTree(spaceId: spaceId)

            let (fetchedSpace, fetchedContent) = try await (spaceTask, contentTask)
            space = fetchedSpace
            contentTree = fetchedContent
        } catch {
            self.error = error

            // Try cached data
            let cached = await pageRepository.getCachedContentTree(spaceId: spaceId)
            if !cached.isEmpty {
                contentTree = cached
            }
        }

        isLoading = false
    }

    /// Refresh space and content
    func refresh() async {
        guard let spaceId = spaceId else { return }
        await loadAll(spaceId: spaceId)
    }

    /// Update space settings
    func updateSpace(
        title: String?,
        emoji: String?,
        visibility: Space.Visibility?
    ) async throws {
        guard let spaceId = spaceId else {
            throw SpaceDetailError.noSpace
        }

        isLoading = true
        error = nil

        do {
            space = try await spaceRepository.updateSpace(
                id: spaceId,
                title: title,
                emoji: emoji,
                visibility: visibility,
                parentId: nil
            )
        } catch {
            self.error = error
            throw error
        }

        isLoading = false
    }

    /// Toggle page expansion (for groups)
    func togglePage(id: String) {
        if expandedPageIds.contains(id) {
            expandedPageIds.remove(id)
        } else {
            expandedPageIds.insert(id)
        }
    }

    /// Check if page is expanded
    func isExpanded(_ pageId: String) -> Bool {
        expandedPageIds.contains(pageId)
    }

    /// Expand all groups
    func expandAll() {
        let allGroupIds = allPagesFlat.filter { $0.isGroup }.map { $0.id }
        expandedPageIds = Set(allGroupIds)
    }

    /// Collapse all groups
    func collapseAll() {
        expandedPageIds.removeAll()
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    /// Clear search
    func clearSearch() {
        searchQuery = ""
    }

    // MARK: - Private Methods

    /// Recursively filter pages that match query
    private func filterPages(_ pages: [Page], query: String) -> [Page] {
        var result: [Page] = []

        for page in pages {
            let matchingChildren = filterPages(page.children, query: query)

            if page.matches(query: query) || !matchingChildren.isEmpty {
                // Include this page with filtered children
                let filteredPage = page.withChildren(matchingChildren)
                result.append(filteredPage)

                // Auto-expand pages with matching children
                if !matchingChildren.isEmpty {
                    expandedPageIds.insert(page.id)
                }
            }
        }

        return result
    }
}

// MARK: - Errors

enum SpaceDetailError: LocalizedError {
    case noSpace

    var errorDescription: String? {
        switch self {
        case .noSpace:
            return "No space loaded"
        }
    }
}
