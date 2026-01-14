//
//  PageDetailViewModel.swift
//  GitBeek
//
//  ViewModel for page detail view
//

import Foundation

/// ViewModel for displaying page content
@MainActor
@Observable
final class PageDetailViewModel {
    // MARK: - State

    private(set) var page: Page?
    private(set) var breadcrumbs: [BreadcrumbItem] = []
    private(set) var isLoading = false
    private(set) var error: Error?

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

    /// Load page with content
    func loadPage(spaceId: String, pageId: String) async {
        isLoading = true
        error = nil

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
            
            page = fetchedPage

            // Add to recent pages
            let recentPage = RecentPage(from: fetchedPage, spaceId: spaceId)
            recentPagesManager.addRecentPage(recentPage)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refresh page content
    func refresh(spaceId: String, pageId: String) async {
        await loadPage(spaceId: spaceId, pageId: pageId)
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
