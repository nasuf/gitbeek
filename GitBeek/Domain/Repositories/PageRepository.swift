//
//  PageRepository.swift
//  GitBeek
//
//  Protocol for page/content operations
//

import Foundation

/// Search result item
struct SearchResult: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let emoji: String?
    let path: String
    let snippet: String?
    let spaceId: String
    let pageId: String
}

/// Protocol defining page/content operations
protocol PageRepository: Sendable {
    /// Get content tree for space
    func getContentTree(spaceId: String) async throws -> [Page]

    /// Get page by ID with content
    func getPage(spaceId: String, pageId: String) async throws -> Page

    /// Get page by path with content
    func getPageByPath(spaceId: String, path: String) async throws -> Page

    /// Search pages in space
    func searchPages(spaceId: String, query: String) async throws -> [SearchResult]

    /// Create new page
    func createPage(
        spaceId: String,
        title: String,
        emoji: String?,
        markdown: String?,
        parentId: String?
    ) async throws -> Page

    /// Update page
    func updatePage(
        spaceId: String,
        pageId: String,
        title: String?,
        emoji: String?,
        markdown: String?
    ) async throws -> Page

    /// Delete page
    func deletePage(spaceId: String, pageId: String) async throws

    /// Get cached content tree for space
    func getCachedContentTree(spaceId: String) async -> [Page]

    /// Clear page cache
    func clearCache() async
}
