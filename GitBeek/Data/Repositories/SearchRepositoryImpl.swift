//
//  SearchRepositoryImpl.swift
//  GitBeek
//
//  Implementation of SearchRepository
//

import Foundation

/// Implementation of search repository
actor SearchRepositoryImpl: SearchRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let store: SwiftDataStore

    // MARK: - Search History Storage

    private let historyKey = "searchHistory"
    private let maxHistoryItems = 50

    // MARK: - Initialization

    init(apiService: GitBookAPIService, store: SwiftDataStore) {
        self.apiService = apiService
        self.store = store
    }

    // MARK: - SearchRepository

    func searchOrganization(orgId: String, query: String, page: String?) async throws -> [SearchResult] {
        let response = try await apiService.searchOrganization(orgId: orgId, query: query, page: page)

        // Flatten the grouped structure into search results
        return response.items.flatMap { spaceGroup in
            spaceGroup.pages.map { pageResult in
                let snippet = pageResult.sections?.first?.body ?? ""

                return SearchResult(
                    id: pageResult.id,
                    title: pageResult.title ?? "Untitled",
                    emoji: nil,  // Search API doesn't return emoji
                    path: pageResult.path ?? "",
                    snippet: snippet.isEmpty ? nil : snippet,
                    spaceId: spaceGroup.id,
                    pageId: pageResult.id
                )
            }
        }
    }

    func searchSpace(spaceId: String, query: String, page: String?) async throws -> [SearchResult] {
        let dto = try await apiService.searchSpace(spaceId: spaceId, query: query, page: page)

        return dto.items.map { item in
            // Extract snippet from highlights
            let snippet = item.highlights?.first?.fragment

            return SearchResult(
                id: item.id,
                title: item.title,
                emoji: nil,  // Search API doesn't return emoji
                path: item.path ?? "",
                snippet: snippet,
                spaceId: spaceId,
                pageId: item.id
            )
        }
    }

    func getSearchHistory() async -> [SearchHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return []
        }

        // Return sorted by most recent
        return history.sorted { $0.timestamp > $1.timestamp }
    }

    func addToSearchHistory(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        var history = await getSearchHistory()

        // Remove duplicate if exists
        history.removeAll { $0.query.lowercased() == trimmedQuery.lowercased() }

        // Add new item at the beginning
        let newItem = SearchHistoryItem(query: trimmedQuery)
        history.insert(newItem, at: 0)

        // Keep only the most recent items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func clearSearchHistory() async {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func removeFromSearchHistory(id: String) async {
        var history = await getSearchHistory()
        history.removeAll { $0.id == id }

        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
