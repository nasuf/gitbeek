//
//  RecentSpacesManager.swift
//  GitBeek
//
//  Manager for tracking recently visited spaces
//

import Foundation

/// Manager for tracking recently visited spaces
@MainActor
final class RecentSpacesManager {
    // MARK: - Singleton

    static let shared = RecentSpacesManager()

    // MARK: - Constants

    private let recentSpacesKey = "recentSpaces"
    private let maxRecentSpaces = 20

    // MARK: - Private Init

    private init() {}

    // MARK: - Recent Spaces

    /// Get recent spaces, optionally filtered by organization
    func getRecentSpaces(organizationId: String? = nil) -> [RecentSpace] {
        guard let data = UserDefaults.standard.data(forKey: recentSpacesKey),
              let spaces = try? JSONDecoder().decode([RecentSpace].self, from: data) else {
            return []
        }

        var result = spaces.sorted { $0.lastVisited > $1.lastVisited }

        // Filter by organization if specified
        if let orgId = organizationId {
            result = result.filter { $0.organizationId == orgId }
        }

        return result
    }

    /// Add space to recent history
    func addRecentSpace(_ space: RecentSpace) {
        var spaces = getRecentSpaces()

        // Remove if already exists
        spaces.removeAll { $0.id == space.id }

        // Add at the beginning
        spaces.insert(space, at: 0)

        // Keep only the most recent items
        if spaces.count > maxRecentSpaces {
            spaces = Array(spaces.prefix(maxRecentSpaces))
        }

        // Save
        if let data = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(data, forKey: recentSpacesKey)
        }
    }

    /// Add space from Space entity
    func addRecentSpace(from space: Space) {
        let recentSpace = RecentSpace(from: space)
        addRecentSpace(recentSpace)
    }

    /// Clear all recent spaces
    func clearRecentSpaces() {
        UserDefaults.standard.removeObject(forKey: recentSpacesKey)
    }

    /// Remove specific recent space
    func removeRecentSpace(id: String) {
        var spaces = getRecentSpaces()
        spaces.removeAll { $0.id == id }

        if let data = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(data, forKey: recentSpacesKey)
        }
    }
}
