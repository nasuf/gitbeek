//
//  CacheManager.swift
//  GitBeek
//
//  Content caching strategies and management
//

import Foundation
import SDWebImage

/// Cache duration constants
enum CachePolicy: Sendable {
    /// Default cache duration in seconds
    static let defaultMaxAge: TimeInterval = 300  // 5 minutes
    static let longMaxAge: TimeInterval = 3600    // 1 hour
    static let shortMaxAge: TimeInterval = 60     // 1 minute
}

/// Manager for content caching strategies
@MainActor
final class CacheManager {
    // MARK: - Properties

    static let shared = CacheManager()

    private let store: SwiftDataStore
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    /// In-memory cache for frequently accessed items
    private var memoryCache = NSCache<NSString, CacheEntry>()

    // MARK: - Initialization

    private init() {
        self.store = SwiftDataStore.shared

        // Set up file cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("GitBeekCache", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache limits
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
    }

    // MARK: - Cache Entry

    final class CacheEntry: @unchecked Sendable {
        let data: Any
        let timestamp: Date
        let cost: Int

        init(data: Any, cost: Int = 0) {
            self.data = data
            self.timestamp = Date()
            self.cost = cost
        }

        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }

        func isFresh(maxAge: TimeInterval) -> Bool {
            age < maxAge
        }
    }

    // MARK: - Memory Cache

    /// Get item from memory cache
    func getFromMemory<T>(key: String) -> (T, Date)? {
        guard let entry = memoryCache.object(forKey: key as NSString),
              let data = entry.data as? T else {
            return nil
        }
        return (data, entry.timestamp)
    }

    /// Save item to memory cache
    func saveToMemory<T>(key: String, value: T, cost: Int = 0) {
        let entry = CacheEntry(data: value, cost: cost)
        memoryCache.setObject(entry, forKey: key as NSString, cost: cost)
    }

    /// Check if memory cache item is fresh
    func isMemoryCacheFresh(key: String, maxAge: TimeInterval) -> Bool {
        guard let entry = memoryCache.object(forKey: key as NSString) else {
            return false
        }
        return entry.isFresh(maxAge: maxAge)
    }

    /// Remove item from memory cache
    func removeFromMemory(key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - File Cache

    /// Get file cache URL for key
    private func fileCacheURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent(safeKey)
    }

    /// Save data to file cache
    func saveToFileCache(key: String, data: Data) throws {
        let url = fileCacheURL(for: key)
        try data.write(to: url)
    }

    /// Load data from file cache
    func loadFromFileCache(key: String) -> Data? {
        let url = fileCacheURL(for: key)
        return try? Data(contentsOf: url)
    }

    /// Check if file cache exists and is fresh
    func isFileCacheFresh(key: String, maxAge: TimeInterval) -> Bool {
        let url = fileCacheURL(for: key)
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return false
        }
        return Date().timeIntervalSince(modificationDate) < maxAge
    }

    /// Remove file from cache
    func removeFromFileCache(key: String) {
        let url = fileCacheURL(for: key)
        try? fileManager.removeItem(at: url)
    }

    /// Clear all file cache
    func clearFileCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Image Cache Key

    /// Cache key for image URL (used for statistics)
    func imageCacheKey(for url: URL) -> String {
        "image:\(url.absoluteString.hashValue)"
    }

    // MARK: - Cache Statistics

    struct CacheStats {
        let memoryCacheCount: Int
        let fileCacheSize: Int64
        let fileCacheCount: Int
        let imageCacheSize: Int64
        let imageCacheCount: Int
        let sdWebImageCacheSize: Int64  // SDWebImage disk cache
        let swiftDataSize: Int64
        let organizationCount: Int
        let spaceCount: Int
        let pageCount: Int

        var totalSize: Int64 {
            fileCacheSize + swiftDataSize + sdWebImageCacheSize
        }

        var totalImageCacheSize: Int64 {
            imageCacheSize + sdWebImageCacheSize
        }
    }

    /// Get cache statistics
    func getStats() -> CacheStats {
        var fileCacheSize: Int64 = 0
        var fileCacheCount = 0
        var imageCacheSize: Int64 = 0
        var imageCacheCount = 0

        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            while let url = enumerator.nextObject() as? URL {
                if let attributes = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attributes.fileSize {
                    fileCacheSize += Int64(size)
                    fileCacheCount += 1

                    // Count image cache separately
                    if url.lastPathComponent.hasPrefix("image:") {
                        imageCacheSize += Int64(size)
                        imageCacheCount += 1
                    }
                }
            }
        }

        // Get SDWebImage cache size
        let sdWebImageSize = getSDWebImageCacheSize()

        // Get SwiftData stats
        let swiftDataStats = getSwiftDataStats()

        return CacheStats(
            memoryCacheCount: 0,  // NSCache doesn't expose count
            fileCacheSize: fileCacheSize,
            fileCacheCount: fileCacheCount,
            imageCacheSize: imageCacheSize,
            imageCacheCount: imageCacheCount,
            sdWebImageCacheSize: sdWebImageSize,
            swiftDataSize: swiftDataStats.size,
            organizationCount: swiftDataStats.organizationCount,
            spaceCount: swiftDataStats.spaceCount,
            pageCount: swiftDataStats.pageCount
        )
    }

    /// Get SDWebImage disk cache size
    private func getSDWebImageCacheSize() -> Int64 {
        let cache = SDImageCache.shared
        return Int64(cache.totalDiskSize())
    }

    /// Get SwiftData statistics
    private func getSwiftDataStats() -> (size: Int64, organizationCount: Int, spaceCount: Int, pageCount: Int) {
        // Get SwiftData file size
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        var swiftDataSize: Int64 = 0

        // SwiftData stores in Application Support/default.store
        let storeURL = applicationSupport.appendingPathComponent("default.store")
        if let enumerator = fileManager.enumerator(at: storeURL, includingPropertiesForKeys: [.fileSizeKey]) {
            while let url = enumerator.nextObject() as? URL {
                if let attributes = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attributes.fileSize {
                    swiftDataSize += Int64(size)
                }
            }
        }

        // Also check for SQLite files directly
        if fileManager.fileExists(atPath: storeURL.path) {
            if let attributes = try? fileManager.attributesOfItem(atPath: storeURL.path),
               let size = attributes[.size] as? Int64 {
                swiftDataSize = max(swiftDataSize, size)
            }
        }

        // Get record counts from SwiftDataStore
        let orgCount = (try? store.fetchOrganizations().count) ?? 0
        let spaceCount = (try? store.fetchSpaces().count) ?? 0
        let pageCount = getPageCount()

        return (swiftDataSize, orgCount, spaceCount, pageCount)
    }

    /// Get total page count
    private func getPageCount() -> Int {
        // Get all spaces and sum their pages
        guard let spaces = try? store.fetchSpaces() else { return 0 }
        var count = 0
        for space in spaces {
            count += (try? store.fetchPages(spaceId: space.id).count) ?? 0
        }
        return count
    }

    /// Format cache size for display
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Selective Cache Clearing

    /// Clear only image cache (including SDWebImage)
    func clearImageCache() {
        // Clear our custom image cache
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) {
            while let url = enumerator.nextObject() as? URL {
                if url.lastPathComponent.hasPrefix("image:") {
                    try? fileManager.removeItem(at: url)
                }
            }
        }

        // Clear SDWebImage cache
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)

        // Also clear memory cache images
        clearMemoryCache()
    }

    /// Clear only content cache (SwiftData)
    func clearContentCache() {
        try? store.clearAllCache()
    }

    // MARK: - Cleanup

    /// Clear all caches
    func clearAllCaches() {
        clearMemoryCache()
        clearFileCache()
        try? store.clearAllCache()
    }

    /// Clear stale caches
    func clearStaleCaches(maxAge: TimeInterval = 86400) {
        // Clear stale file cache
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            let cutoffDate = Date().addingTimeInterval(-maxAge)

            while let url = enumerator.nextObject() as? URL {
                if let attributes = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modificationDate = attributes.contentModificationDate,
                   modificationDate < cutoffDate {
                    try? fileManager.removeItem(at: url)
                }
            }
        }

        // Clear stale database cache
        try? store.clearStaleCache(olderThan: maxAge)
    }
}
