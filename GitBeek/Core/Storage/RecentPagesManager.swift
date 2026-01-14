//
//  RecentPagesManager.swift
//  GitBeek
//
//  Manager for recent pages and favorites
//

import Foundation

/// Manager for tracking recent pages and favorites
@MainActor
final class RecentPagesManager {
    // MARK: - Singleton

    static let shared = RecentPagesManager()

    // MARK: - Constants

    private let recentPagesKey = "recentPages"
    private let favoritePagesKey = "favoritePages"
    private let maxRecentPages = 50

    // MARK: - Private Init

    private init() {}

    // MARK: - Recent Pages

    /// Get recent pages
    func getRecentPages() -> [RecentPage] {
        guard let data = UserDefaults.standard.data(forKey: recentPagesKey),
              let pages = try? JSONDecoder().decode([RecentPage].self, from: data) else {
            return []
        }

        return pages.sorted { $0.lastVisited > $1.lastVisited }
    }

    /// Add page to recent history
    func addRecentPage(_ page: RecentPage) {
        var pages = getRecentPages()

        // Remove if already exists
        pages.removeAll { $0.id == page.id && $0.spaceId == page.spaceId }

        // Add at the beginning
        pages.insert(page, at: 0)

        // Keep only the most recent items
        if pages.count > maxRecentPages {
            pages = Array(pages.prefix(maxRecentPages))
        }

        // Save
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: recentPagesKey)
        }
    }

    /// Clear all recent pages
    func clearRecentPages() {
        UserDefaults.standard.removeObject(forKey: recentPagesKey)
    }

    /// Remove specific recent page
    func removeRecentPage(id: String, spaceId: String) {
        var pages = getRecentPages()
        pages.removeAll { $0.id == id && $0.spaceId == spaceId }

        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: recentPagesKey)
        }
    }

    // MARK: - Favorites

    /// Get favorite pages
    func getFavoritePages() -> [FavoritePage] {
        guard let data = UserDefaults.standard.data(forKey: favoritePagesKey),
              let pages = try? JSONDecoder().decode([FavoritePage].self, from: data) else {
            return []
        }

        return pages.sorted { $0.addedAt > $1.addedAt }
    }

    /// Add page to favorites
    func addFavorite(_ page: FavoritePage) {
        var pages = getFavoritePages()

        // Don't add if already exists
        guard !pages.contains(where: { $0.id == page.id && $0.spaceId == page.spaceId }) else {
            return
        }

        pages.insert(page, at: 0)

        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: favoritePagesKey)
        }
    }

    /// Remove page from favorites
    func removeFavorite(id: String, spaceId: String) {
        var pages = getFavoritePages()
        pages.removeAll { $0.id == id && $0.spaceId == spaceId }

        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: favoritePagesKey)
        }
    }

    /// Check if page is favorited
    func isFavorite(id: String, spaceId: String) -> Bool {
        let pages = getFavoritePages()
        return pages.contains { $0.id == id && $0.spaceId == spaceId }
    }

    /// Toggle favorite status
    func toggleFavorite(_ page: FavoritePage) {
        if isFavorite(id: page.id, spaceId: page.spaceId) {
            removeFavorite(id: page.id, spaceId: page.spaceId)
        } else {
            addFavorite(page)
        }
    }

    /// Clear all favorites
    func clearFavorites() {
        UserDefaults.standard.removeObject(forKey: favoritePagesKey)
    }
}
