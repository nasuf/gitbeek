//
//  CacheManager.swift
//  GitBeek
//
//  Content caching strategies and management
//

import Foundation
import SwiftUI

/// Cache policy for different types of content
enum CachePolicy: Sendable {
    /// Always fetch from network, ignore cache
    case networkOnly

    /// Use cache if available, otherwise fetch
    case cacheFirst

    /// Fetch from network, update cache
    case networkFirst

    /// Use cache if fresh, otherwise fetch
    case cacheIfFresh(maxAge: TimeInterval)

    /// Default cache duration in seconds
    static let defaultMaxAge: TimeInterval = 300  // 5 minutes
    static let longMaxAge: TimeInterval = 3600    // 1 hour
    static let shortMaxAge: TimeInterval = 60     // 1 minute
}

/// Result type for cache operations
enum CacheResult<T> {
    case cached(T, Date)      // Cached data with cache time
    case fetched(T)           // Freshly fetched data
    case stale(T, Date)       // Stale cached data (network failed)
    case empty                // No data available
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

    // MARK: - Image Cache

    /// Cache key for image URL
    func imageCacheKey(for url: URL) -> String {
        "image:\(url.absoluteString.hashValue)"
    }

    /// Save image to cache
    func saveImage(_ image: UIImage, for url: URL) throws {
        let key = imageCacheKey(for: url)

        // Save to memory cache
        saveToMemory(key: key, value: image, cost: Int(image.size.width * image.size.height * 4))

        // Save to file cache
        if let data = image.pngData() {
            try saveToFileCache(key: key, data: data)
        }
    }

    /// Load image from cache
    func loadImage(for url: URL) -> UIImage? {
        let key = imageCacheKey(for: url)

        // Check memory cache first
        if let (image, _): (UIImage, Date) = getFromMemory(key: key) {
            return image
        }

        // Check file cache
        if let data = loadFromFileCache(key: key),
           let image = UIImage(data: data) {
            // Populate memory cache
            saveToMemory(key: key, value: image, cost: Int(image.size.width * image.size.height * 4))
            return image
        }

        return nil
    }

    // MARK: - Cache Statistics

    struct CacheStats {
        let memoryCacheCount: Int
        let fileCacheSize: Int64
        let fileCacheCount: Int
    }

    /// Get cache statistics
    func getStats() -> CacheStats {
        var fileCacheSize: Int64 = 0
        var fileCacheCount = 0

        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            while let url = enumerator.nextObject() as? URL {
                if let attributes = try? url.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attributes.fileSize {
                    fileCacheSize += Int64(size)
                    fileCacheCount += 1
                }
            }
        }

        return CacheStats(
            memoryCacheCount: 0,  // NSCache doesn't expose count
            fileCacheSize: fileCacheSize,
            fileCacheCount: fileCacheCount
        )
    }

    /// Format cache size for display
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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
