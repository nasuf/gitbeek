//
//  PageDetailViewModel.swift
//  GitBeek
//
//  ViewModel for page detail view with Stale-While-Revalidate caching
//

import Foundation

/// ViewModel for displaying page content
/// Implements Stale-While-Revalidate strategy for optimal UX
@MainActor
@Observable
final class PageDetailViewModel {
    // MARK: - State

    private(set) var page: Page?
    private(set) var breadcrumbs: [BreadcrumbItem] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false  // Background refresh indicator
    private(set) var error: Error?
    private(set) var isFromCache = false   // Track if current data is from cache

    // MARK: - Computed Properties

    var hasError: Bool { error != nil }

    var errorMessage: String? {
        error?.localizedDescription
    }

    var displayTitle: String {
        page?.displayTitle ?? "Page"
    }

    var hasMarkdown: Bool {
        page?.markdown != nil
    }

    var markdown: String {
        page?.markdown ?? ""
    }

    var hasChildren: Bool {
        page?.hasChildren ?? false
    }

    var children: [Page] {
        page?.children ?? []
    }

    // MARK: - Dependencies

    private let pageRepository: PageRepository
    private let recentPagesManager = RecentPagesManager.shared

    // MARK: - Initialization

    init(pageRepository: PageRepository) {
        self.pageRepository = pageRepository
    }

    // MARK: - Actions

    /// Load page with Stale-While-Revalidate strategy
    /// 1. If cache exists, show immediately
    /// 2. Fetch from network in background
    /// 3. Update UI when network returns
    func loadPage(spaceId: String, pageId: String) async {
        error = nil

        // Step 1: Try to show cached content immediately
        if let cachedPage = await pageRepository.getCachedPage(spaceId: spaceId, pageId: pageId) {
            page = cachedPage
            isFromCache = true

            // If cache is fresh, we can skip network request
            if await pageRepository.isCacheFresh(pageId: pageId) {
                // Add to recent pages
                let recentPage = RecentPage(from: cachedPage, spaceId: spaceId)
                recentPagesManager.addRecentPage(recentPage)
                return
            }

            // Cache exists but stale - refresh in background
            isRefreshing = true
        } else {
            // No cache - show loading
            isLoading = true
        }

        // Step 2: Fetch from network
        do {
            var fetchedPage = try await pageRepository.getPage(spaceId: spaceId, pageId: pageId)

            // If API response has no children, try to find them in the content tree
            if fetchedPage.children.isEmpty {
                if let contentTree = try? await pageRepository.getContentTree(spaceId: spaceId) {
                    if let pageInTree = findPage(id: pageId, in: contentTree) {
                        fetchedPage = fetchedPage.withChildren(pageInTree.children)
                    }
                }
            }

            // Step 3: Update UI with fresh data
            page = fetchedPage
            isFromCache = false

            // Add to recent pages
            let recentPage = RecentPage(from: fetchedPage, spaceId: spaceId)
            recentPagesManager.addRecentPage(recentPage)
        } catch {
            // Only show error if we don't have cached content
            if page == nil {
                self.error = error
            }
            // If we have cached content, silently fail (user sees stale data)
        }

        isLoading = false
        isRefreshing = false
    }

    /// Force refresh from network (ignores cache)
    func refresh(spaceId: String, pageId: String) async {
        isRefreshing = true
        error = nil

        do {
            var fetchedPage = try await pageRepository.getPage(spaceId: spaceId, pageId: pageId)

            if fetchedPage.children.isEmpty {
                if let contentTree = try? await pageRepository.getContentTree(spaceId: spaceId) {
                    if let pageInTree = findPage(id: pageId, in: contentTree) {
                        fetchedPage = fetchedPage.withChildren(pageInTree.children)
                    }
                }
            }

            page = fetchedPage
            isFromCache = false
        } catch {
            self.error = error
        }

        isRefreshing = false
    }

    /// Update breadcrumbs
    func updateBreadcrumbs(_ items: [BreadcrumbItem]) {
        self.breadcrumbs = items
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func findPage(id: String, in pages: [Page]) -> Page? {
        for page in pages {
            if page.id == id {
                return page
            }
            if let found = findPage(id: id, in: page.children) {
                return found
            }
        }
        return nil
    }
}
