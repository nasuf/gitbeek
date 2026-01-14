//
//  SearchViewModel.swift
//  GitBeek
//
//  ViewModel for search functionality
//

import Foundation

/// Search scope enum
enum SearchScope: String, CaseIterable, Identifiable {
    case organization = "All"
    case currentSpace = "This Space"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .organization: return "globe"
        case .currentSpace: return "square.stack.3d.up"
        }
    }
}

/// ViewModel for search
@MainActor
@Observable
final class SearchViewModel {
    // MARK: - State

    private(set) var searchResults: [SearchResult] = []
    private(set) var searchHistory: [SearchHistoryItem] = []
    private(set) var recentPages: [RecentPage] = []
    private(set) var favoritePages: [FavoritePage] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    /// Current search query
    var searchQuery = "" {
        didSet {
            if searchQuery != oldValue {
                Task {
                    await performSearch()
                }
            }
        }
    }

    /// Current search scope
    var searchScope: SearchScope = .organization

    /// Current organization ID (for organization-wide search)
    private(set) var organizationId: String?

    /// Current space ID (for space-specific search)
    private(set) var spaceId: String?

    /// Available spaces for search
    private(set) var availableSpaces: [Space] = []

    /// Selected space name (for display)
    var selectedSpaceName: String {
        guard let spaceId = spaceId,
              let space = availableSpaces.first(where: { $0.id == spaceId }) else {
            return "Select Space"
        }
        return space.title
    }

    /// Recent pages manager (public for access from views)
    let recentPagesManager = RecentPagesManager.shared

    // MARK: - Dependencies

    private let searchRepository: SearchRepository
    private let organizationRepository: OrganizationRepository
    private let spaceRepository: SpaceRepository

    // MARK: - Debounce

    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var hasError: Bool { error != nil }

    var errorMessage: String? {
        error?.localizedDescription
    }

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasResults: Bool {
        !searchResults.isEmpty
    }

    var showEmptyState: Bool {
        isSearching && !isLoading && !hasResults && !hasError
    }

    /// Get search suggestions based on history
    var searchSuggestions: [String] {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return searchHistory
            .map { $0.query }
            .filter { $0.lowercased().contains(query) && $0.lowercased() != query }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Initialization

    init(
        searchRepository: SearchRepository,
        organizationRepository: OrganizationRepository,
        spaceRepository: SpaceRepository
    ) {
        self.searchRepository = searchRepository
        self.organizationRepository = organizationRepository
        self.spaceRepository = spaceRepository
    }

    // MARK: - Public Methods

    /// Load initial data (organization, search history, recent pages, favorites)
    func load() async {
        await loadOrganization()
        await loadSpaces()
        await loadSearchHistory()
        loadRecentPages()
        loadFavoritePages()
    }

    /// Set current space for space-specific search
    func setCurrentSpace(spaceId: String) {
        self.spaceId = spaceId
        if searchScope == .currentSpace {
            Task {
                await performSearch()
            }
        }
    }

    /// Set selected space and switch to space search mode
    func selectSpace(_ space: Space) {
        self.spaceId = space.id
        self.searchScope = .currentSpace
        Task {
            await performSearch()
        }
    }

    /// Perform search with current query
    func performSearch() async {
        // Cancel any existing search task
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // Debounce search by 300ms
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            await executeSearch(query: query)
        }
    }

    /// Execute search with given query
    private func executeSearch(query: String) async {
        isLoading = true
        error = nil

        do {
            switch searchScope {
            case .organization:
                guard let orgId = organizationId else {
                    throw NSError(
                        domain: "SearchViewModel",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No organization selected"]
                    )
                }
                searchResults = try await searchRepository.searchOrganization(
                    orgId: orgId,
                    query: query,
                    page: nil
                )

            case .currentSpace:
                guard let spaceId = spaceId else {
                    throw NSError(
                        domain: "SearchViewModel",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No space selected"]
                    )
                }
                searchResults = try await searchRepository.searchSpace(
                    spaceId: spaceId,
                    query: query,
                    page: nil
                )
            }

            // Add to search history
            await searchRepository.addToSearchHistory(query: query)
            await loadSearchHistory()

        } catch {
            if !(Task.isCancelled || (error as? URLError)?.code == .cancelled) {
                self.error = error
                searchResults = []
            }
        }

        isLoading = false
    }

    /// Load search history
    func loadSearchHistory() async {
        searchHistory = await searchRepository.getSearchHistory()
    }

    /// Select search history item
    func selectHistoryItem(_ item: SearchHistoryItem) {
        searchQuery = item.query
    }

    /// Remove search history item
    func removeHistoryItem(_ item: SearchHistoryItem) async {
        await searchRepository.removeFromSearchHistory(id: item.id)
        await loadSearchHistory()
    }

    /// Clear all search history
    func clearSearchHistory() async {
        await searchRepository.clearSearchHistory()
        await loadSearchHistory()
    }

    /// Clear current search
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        error = nil
    }

    // MARK: - Recent Pages

    /// Load recent pages
    func loadRecentPages() {
        recentPages = recentPagesManager.getRecentPages()
    }

    /// Clear recent pages
    func clearRecentPages() {
        recentPagesManager.clearRecentPages()
        loadRecentPages()
    }

    // MARK: - Favorites

    /// Load favorite pages
    func loadFavoritePages() {
        favoritePages = recentPagesManager.getFavoritePages()
    }

    /// Toggle favorite status
    func toggleFavorite(pageId: String, spaceId: String, title: String, emoji: String?, path: String) {
        let favorite = FavoritePage(
            id: pageId,
            spaceId: spaceId,
            title: title,
            emoji: emoji,
            path: path
        )
        recentPagesManager.toggleFavorite(favorite)
        loadFavoritePages()
    }

    /// Check if page is favorited
    func isFavorite(pageId: String, spaceId: String) -> Bool {
        recentPagesManager.isFavorite(id: pageId, spaceId: spaceId)
    }

    // MARK: - Private Methods

    private func loadOrganization() async {
        do {
            let organizations = try await organizationRepository.getOrganizations()
            organizationId = organizations.first?.id
        } catch {
            // Silently fail - user can still search within space
        }
    }

    private func loadSpaces() async {
        guard let orgId = organizationId else { return }
        do {
            availableSpaces = try await spaceRepository.getSpaces(organizationId: orgId)
        } catch {
            // Silently fail
        }
    }
}
