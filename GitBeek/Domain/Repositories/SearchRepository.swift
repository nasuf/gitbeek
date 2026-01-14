//
//  SearchRepository.swift
//  GitBeek
//
//  Protocol for search operations
//

import Foundation

/// Search history item
struct SearchHistoryItem: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let query: String
    let timestamp: Date

    init(id: String = UUID().uuidString, query: String, timestamp: Date = Date()) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
    }
}

/// Protocol defining search operations
protocol SearchRepository: Sendable {
    /// Search across organization
    func searchOrganization(orgId: String, query: String, page: String?) async throws -> [SearchResult]

    /// Search within space (delegates to PageRepository)
    func searchSpace(spaceId: String, query: String, page: String?) async throws -> [SearchResult]

    /// Get search history
    func getSearchHistory() async -> [SearchHistoryItem]

    /// Add item to search history
    func addToSearchHistory(query: String) async

    /// Clear search history
    func clearSearchHistory() async

    /// Remove specific history item
    func removeFromSearchHistory(id: String) async
}
