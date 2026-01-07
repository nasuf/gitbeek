//
//  SwiftDataStore.swift
//  GitBeek
//
//  SwiftData models and store for local persistence
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

/// Cached organization
@Model
final class CachedOrganization {
    @Attribute(.unique) var id: String
    var title: String
    var appURL: String?
    var publishedURL: String?
    var membersCount: Int?
    var spacesCount: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var cachedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CachedSpace.organization)
    var spaces: [CachedSpace]?

    init(
        id: String,
        title: String,
        appURL: String? = nil,
        publishedURL: String? = nil,
        membersCount: Int? = nil,
        spacesCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.appURL = appURL
        self.publishedURL = publishedURL
        self.membersCount = membersCount
        self.spacesCount = spacesCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cachedAt = Date()
    }

    /// Update from DTO
    func update(from dto: OrganizationDTO) {
        self.title = dto.title
        self.appURL = dto.urls?.app
        self.publishedURL = dto.urls?.published
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.cachedAt = Date()
    }
}

/// Cached space
@Model
final class CachedSpace {
    @Attribute(.unique) var id: String
    var title: String
    var emoji: String?
    var visibility: String
    var spaceType: String?
    var appURL: String?
    var publishedURL: String?
    var parentId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var cachedAt: Date

    var organization: CachedOrganization?

    @Relationship(deleteRule: .cascade, inverse: \CachedPage.space)
    var pages: [CachedPage]?

    init(
        id: String,
        title: String,
        emoji: String? = nil,
        visibility: String,
        spaceType: String? = nil,
        appURL: String? = nil,
        publishedURL: String? = nil,
        parentId: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.visibility = visibility
        self.spaceType = spaceType
        self.appURL = appURL
        self.publishedURL = publishedURL
        self.parentId = parentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cachedAt = Date()
    }

    /// Update from DTO
    func update(from dto: SpaceDTO) {
        self.title = dto.title
        self.emoji = dto.emoji
        self.visibility = dto.visibility.rawValue
        self.spaceType = dto.type?.rawValue
        self.appURL = dto.urls?.app
        self.publishedURL = dto.urls?.published
        self.parentId = dto.parent?.id
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.cachedAt = Date()
    }
}

/// Cached page content
@Model
final class CachedPage {
    @Attribute(.unique) var id: String
    var spaceId: String
    var title: String
    var emoji: String?
    var path: String
    var slug: String?
    var pageDescription: String?
    var markdown: String?
    var parentId: String?
    var order: Int
    var createdAt: Date?
    var updatedAt: Date?
    var cachedAt: Date

    var space: CachedSpace?

    init(
        id: String,
        spaceId: String,
        title: String,
        emoji: String? = nil,
        path: String,
        slug: String? = nil,
        pageDescription: String? = nil,
        markdown: String? = nil,
        parentId: String? = nil,
        order: Int = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.spaceId = spaceId
        self.title = title
        self.emoji = emoji
        self.path = path
        self.slug = slug
        self.pageDescription = pageDescription
        self.markdown = markdown
        self.parentId = parentId
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cachedAt = Date()
    }
}

/// Cached user
@Model
final class CachedUser {
    @Attribute(.unique) var id: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var createdAt: Date?
    var updatedAt: Date?
    var cachedAt: Date

    init(
        id: String,
        displayName: String,
        email: String? = nil,
        photoURL: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cachedAt = Date()
    }

    /// Update from DTO
    func update(from dto: CurrentUserDTO) {
        self.displayName = dto.displayName
        self.email = dto.email
        self.photoURL = dto.photoURL
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.cachedAt = Date()
    }
}

/// Recent item for quick access
@Model
final class RecentItem {
    @Attribute(.unique) var compositeId: String  // type:id
    var itemType: String  // "space" or "page"
    var itemId: String
    var title: String
    var emoji: String?
    var spaceId: String?
    var path: String?
    var accessedAt: Date

    init(
        itemType: String,
        itemId: String,
        title: String,
        emoji: String? = nil,
        spaceId: String? = nil,
        path: String? = nil
    ) {
        self.compositeId = "\(itemType):\(itemId)"
        self.itemType = itemType
        self.itemId = itemId
        self.title = title
        self.emoji = emoji
        self.spaceId = spaceId
        self.path = path
        self.accessedAt = Date()
    }

    func updateAccessTime() {
        self.accessedAt = Date()
    }
}

// MARK: - SwiftData Store

/// Main SwiftData store for local persistence
@MainActor
final class SwiftDataStore {
    // MARK: - Properties

    static let shared = SwiftDataStore()

    let container: ModelContainer
    let context: ModelContext

    // MARK: - Initialization

    private init() {
        do {
            let schema = Schema([
                CachedOrganization.self,
                CachedSpace.self,
                CachedPage.self,
                CachedUser.self,
                RecentItem.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            container = try ModelContainer(for: schema, configurations: configuration)
            context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    // MARK: - Generic Operations

    func save() throws {
        try context.save()
    }

    func delete<T: PersistentModel>(_ object: T) {
        context.delete(object)
    }

    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        try context.delete(model: type)
    }

    // MARK: - Organization Operations

    func fetchOrganizations() throws -> [CachedOrganization] {
        let descriptor = FetchDescriptor<CachedOrganization>(
            sortBy: [SortDescriptor(\.title)]
        )
        return try context.fetch(descriptor)
    }

    func fetchOrganization(id: String) throws -> CachedOrganization? {
        let descriptor = FetchDescriptor<CachedOrganization>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func saveOrganization(_ dto: OrganizationDTO) throws -> CachedOrganization {
        if let existing = try fetchOrganization(id: dto.id) {
            existing.update(from: dto)
            return existing
        } else {
            let cached = CachedOrganization(
                id: dto.id,
                title: dto.title,
                appURL: dto.urls?.app,
                publishedURL: dto.urls?.published,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
            context.insert(cached)
            return cached
        }
    }

    // MARK: - Space Operations

    func fetchSpaces(organizationId: String? = nil) throws -> [CachedSpace] {
        var descriptor = FetchDescriptor<CachedSpace>(
            sortBy: [SortDescriptor(\.title)]
        )

        if let orgId = organizationId {
            descriptor.predicate = #Predicate { $0.organization?.id == orgId }
        }

        return try context.fetch(descriptor)
    }

    func fetchSpace(id: String) throws -> CachedSpace? {
        let descriptor = FetchDescriptor<CachedSpace>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func saveSpace(_ dto: SpaceDTO, organizationId: String?) throws -> CachedSpace {
        if let existing = try fetchSpace(id: dto.id) {
            existing.update(from: dto)
            return existing
        } else {
            let cached = CachedSpace(
                id: dto.id,
                title: dto.title,
                emoji: dto.emoji,
                visibility: dto.visibility.rawValue,
                spaceType: dto.type?.rawValue,
                appURL: dto.urls?.app,
                publishedURL: dto.urls?.published,
                parentId: dto.parent?.id,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )

            // Link to organization if available
            if let orgId = organizationId ?? dto.organization?.id,
               let org = try fetchOrganization(id: orgId) {
                cached.organization = org
            }

            context.insert(cached)
            return cached
        }
    }

    // MARK: - Page Operations

    func fetchPages(spaceId: String) throws -> [CachedPage] {
        let descriptor = FetchDescriptor<CachedPage>(
            predicate: #Predicate { $0.spaceId == spaceId },
            sortBy: [SortDescriptor(\.order)]
        )
        return try context.fetch(descriptor)
    }

    func fetchPage(id: String) throws -> CachedPage? {
        let descriptor = FetchDescriptor<CachedPage>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - User Operations

    func fetchCurrentUser() throws -> CachedUser? {
        let descriptor = FetchDescriptor<CachedUser>()
        return try context.fetch(descriptor).first
    }

    func saveUser(_ dto: CurrentUserDTO) throws -> CachedUser {
        if let existing = try fetchCurrentUser() {
            existing.update(from: dto)
            return existing
        } else {
            let cached = CachedUser(
                id: dto.id,
                displayName: dto.displayName,
                email: dto.email,
                photoURL: dto.photoURL,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
            context.insert(cached)
            return cached
        }
    }

    // MARK: - Recent Items

    func fetchRecentItems(limit: Int = 10) throws -> [RecentItem] {
        var descriptor = FetchDescriptor<RecentItem>(
            sortBy: [SortDescriptor(\.accessedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func addRecentItem(type: String, id: String, title: String, emoji: String? = nil, spaceId: String? = nil, path: String? = nil) throws {
        let compositeId = "\(type):\(id)"
        let descriptor = FetchDescriptor<RecentItem>(
            predicate: #Predicate { $0.compositeId == compositeId }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.updateAccessTime()
            existing.title = title
            existing.emoji = emoji
        } else {
            let recent = RecentItem(
                itemType: type,
                itemId: id,
                title: title,
                emoji: emoji,
                spaceId: spaceId,
                path: path
            )
            context.insert(recent)
        }

        // Limit to 50 recent items
        try trimRecentItems(keepCount: 50)
    }

    private func trimRecentItems(keepCount: Int) throws {
        let descriptor = FetchDescriptor<RecentItem>(
            sortBy: [SortDescriptor(\.accessedAt, order: .reverse)]
        )
        let allRecent = try context.fetch(descriptor)

        if allRecent.count > keepCount {
            for item in allRecent.dropFirst(keepCount) {
                context.delete(item)
            }
        }
    }

    // MARK: - Cache Invalidation

    /// Clear all cached data
    func clearAllCache() throws {
        try deleteAll(CachedOrganization.self)
        try deleteAll(CachedSpace.self)
        try deleteAll(CachedPage.self)
        try deleteAll(CachedUser.self)
        try deleteAll(RecentItem.self)
        try save()
    }

    /// Clear stale cache (older than specified duration)
    func clearStaleCache(olderThan duration: TimeInterval = 86400) throws {
        let cutoffDate = Date().addingTimeInterval(-duration)

        // This is a simplified version - ideally we'd use batch delete
        let orgDescriptor = FetchDescriptor<CachedOrganization>(
            predicate: #Predicate { $0.cachedAt < cutoffDate }
        )
        for org in try context.fetch(orgDescriptor) {
            context.delete(org)
        }

        let spaceDescriptor = FetchDescriptor<CachedSpace>(
            predicate: #Predicate { $0.cachedAt < cutoffDate }
        )
        for space in try context.fetch(spaceDescriptor) {
            context.delete(space)
        }

        let pageDescriptor = FetchDescriptor<CachedPage>(
            predicate: #Predicate { $0.cachedAt < cutoffDate }
        )
        for page in try context.fetch(pageDescriptor) {
            context.delete(page)
        }

        try save()
    }
}
