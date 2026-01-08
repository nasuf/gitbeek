//
//  PageRepositoryImpl.swift
//  GitBeek
//
//  Implementation of PageRepository
//

import Foundation

/// Implementation of page repository with dual-layer caching
actor PageRepositoryImpl: PageRepository {
    // MARK: - Dependencies

    private let apiService: GitBookAPIService
    private let store: SwiftDataStore

    // MARK: - Cache

    private var cachedContentTrees: [String: [Page]] = [:]  // spaceId -> pages
    private var cachedPages: [String: Page] = [:]  // pageId -> page with content

    // MARK: - Initialization

    init(apiService: GitBookAPIService, store: SwiftDataStore) {
        self.apiService = apiService
        self.store = store
    }

    // MARK: - PageRepository

    func getContentTree(spaceId: String) async throws -> [Page] {
        let dto = try await apiService.getContent(spaceId: spaceId)
        let pages = dto.pages.map { Page(from: $0) }

        // Cache content tree
        cachedContentTrees[spaceId] = pages

        // Save to persistent storage
        await saveContentTreeToStore(pages, spaceId: spaceId)

        return pages
    }

    func getPage(spaceId: String, pageId: String) async throws -> Page {
        let dto = try await apiService.getPage(spaceId: spaceId, pageId: pageId)
        let page = Page(from: dto)

        // Cache page with content
        cachedPages[pageId] = page

        // Save to persistent storage
        await savePageToStore(dto, spaceId: spaceId)

        return page
    }

    func getPageByPath(spaceId: String, path: String) async throws -> Page {
        let dto = try await apiService.getPageByPath(spaceId: spaceId, path: path)
        let page = Page(from: dto)

        // Cache page with content
        cachedPages[page.id] = page

        // Save to persistent storage
        await savePageToStore(dto, spaceId: spaceId)

        return page
    }

    func searchPages(spaceId: String, query: String) async throws -> [SearchResult] {
        let dto = try await apiService.searchSpace(spaceId: spaceId, query: query)

        return dto.items.map { item in
            // Extract snippet from highlights if available
            let snippet = item.highlights?.first?.fragment

            return SearchResult(
                id: item.id,
                title: item.title,
                emoji: nil,  // Search results don't include emoji
                path: item.path ?? "",
                snippet: snippet,
                spaceId: spaceId,
                pageId: item.id
            )
        }
    }

    func createPage(
        spaceId: String,
        title: String,
        emoji: String?,
        markdown: String?,
        parentId: String?
    ) async throws -> Page {
        let dto = try await apiService.createPage(
            spaceId: spaceId,
            title: title,
            emoji: emoji,
            markdown: markdown,
            parent: parentId
        )

        let page = Page(from: dto)

        // Invalidate content tree cache for this space
        cachedContentTrees.removeValue(forKey: spaceId)

        return page
    }

    func updatePage(
        spaceId: String,
        pageId: String,
        title: String?,
        emoji: String?,
        markdown: String?
    ) async throws -> Page {
        let dto = try await apiService.updatePage(
            spaceId: spaceId,
            pageId: pageId,
            title: title,
            emoji: emoji,
            markdown: markdown
        )

        let page = Page(from: dto)

        // Update cache
        cachedPages[pageId] = page

        // Invalidate content tree cache (structure might have changed)
        cachedContentTrees.removeValue(forKey: spaceId)

        // Save to persistent storage
        await savePageToStore(dto, spaceId: spaceId)

        return page
    }

    func deletePage(spaceId: String, pageId: String) async throws {
        try await apiService.deletePage(spaceId: spaceId, pageId: pageId)

        // Remove from cache
        cachedPages.removeValue(forKey: pageId)

        // Invalidate content tree cache
        cachedContentTrees.removeValue(forKey: spaceId)

        // Remove from persistent storage
        await MainActor.run {
            try? store.deletePage(pageId)
        }
    }

    func getCachedContentTree(spaceId: String) async -> [Page] {
        // Return in-memory cache if available
        if let pages = cachedContentTrees[spaceId] {
            return pages
        }

        // Try to load from persistent storage
        let pageDataList: [(
            id: String,
            title: String,
            emoji: String?,
            path: String,
            slug: String?,
            description: String?,
            pageType: String,
            markdown: String?,
            parentId: String?,
            createdAt: Date?,
            updatedAt: Date?
        )] = await MainActor.run {
            let cachedPages = (try? store.fetchPages(spaceId: spaceId)) ?? []
            return cachedPages.map { cached in
                (
                    id: cached.id,
                    title: cached.title,
                    emoji: cached.emoji,
                    path: cached.path,
                    slug: cached.slug,
                    description: cached.pageDescription,
                    pageType: cached.pageType,
                    markdown: cached.markdown,
                    parentId: cached.parentId,
                    createdAt: cached.createdAt,
                    updatedAt: cached.updatedAt
                )
            }
        }

        // Build page tree from flat list
        let pages = buildPageTree(from: pageDataList)
        cachedContentTrees[spaceId] = pages
        return pages
    }

    func clearCache() async {
        cachedContentTrees.removeAll()
        cachedPages.removeAll()
    }

    // MARK: - Private Helpers

    private func saveContentTreeToStore(_ pages: [Page], spaceId: String) async {
        let flatPages = pages.flatMap { $0.flatten() }
        await MainActor.run {
            for page in flatPages {
                _ = try? store.savePage(page, spaceId: spaceId)
            }
        }
    }

    private func savePageToStore(_ dto: PageContentDTO, spaceId: String) async {
        await MainActor.run {
            _ = try? store.savePageContent(dto, spaceId: spaceId)
        }
    }

    private func buildPageTree(from flatList: [(
        id: String,
        title: String,
        emoji: String?,
        path: String,
        slug: String?,
        description: String?,
        pageType: String,
        markdown: String?,
        parentId: String?,
        createdAt: Date?,
        updatedAt: Date?
    )]) -> [Page] {
        // Create pages from flat list
        var pageMap: [String: Page] = [:]
        var rootPages: [Page] = []

        // First pass: create all pages
        for data in flatList {
            let page = Page(
                id: data.id,
                title: data.title,
                emoji: data.emoji,
                path: data.path,
                slug: data.slug,
                description: data.description,
                type: Page.PageType(rawValue: data.pageType) ?? .document,
                children: [],
                markdown: data.markdown,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt,
                linkTarget: nil
            )
            pageMap[data.id] = page
        }

        // Second pass: build tree structure
        for data in flatList {
            if let parentId = data.parentId, let parentPage = pageMap[parentId] {
                // Add as child of parent
                if let page = pageMap[data.id] {
                    pageMap[parentId] = parentPage.withChildren(parentPage.children + [page])
                }
            } else {
                // Root level page
                if let page = pageMap[data.id] {
                    rootPages.append(page)
                }
            }
        }

        return rootPages
    }
}
