//
//  CacheManagerTests.swift
//  GitBeekTests
//
//  Tests for CacheManager functionality
//

import XCTest
@testable import GitBeek

@MainActor
final class CacheManagerTests: XCTestCase {

    // MARK: - Memory Cache Tests

    func testMemoryCacheSaveAndRetrieve() {
        let cacheManager = CacheManager.shared
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "Hello, Cache!"

        // Save to memory cache
        cacheManager.saveToMemory(key: testKey, value: testValue)

        // Retrieve from memory cache
        let result: (String, Date)? = cacheManager.getFromMemory(key: testKey)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, testValue)
    }

    func testMemoryCacheReturnsNilForMissingKey() {
        let cacheManager = CacheManager.shared
        let result: (String, Date)? = cacheManager.getFromMemory(key: "nonexistent_key")
        XCTAssertNil(result)
    }

    func testMemoryCacheRemove() {
        let cacheManager = CacheManager.shared
        let testKey = "test_key_remove_\(UUID().uuidString)"
        let testValue = "To be removed"

        cacheManager.saveToMemory(key: testKey, value: testValue)
        cacheManager.removeFromMemory(key: testKey)

        let result: (String, Date)? = cacheManager.getFromMemory(key: testKey)
        XCTAssertNil(result)
    }

    func testMemoryCacheFreshness() {
        let cacheManager = CacheManager.shared
        let testKey = "test_key_fresh_\(UUID().uuidString)"

        cacheManager.saveToMemory(key: testKey, value: "Fresh data")

        // Should be fresh with a long max age
        XCTAssertTrue(cacheManager.isMemoryCacheFresh(key: testKey, maxAge: 3600))

        // Should be fresh with a very short max age (just cached)
        XCTAssertTrue(cacheManager.isMemoryCacheFresh(key: testKey, maxAge: 1))
    }

    func testMemoryCacheClearAll() {
        let cacheManager = CacheManager.shared
        let testKey1 = "test_key_clear1_\(UUID().uuidString)"
        let testKey2 = "test_key_clear2_\(UUID().uuidString)"

        cacheManager.saveToMemory(key: testKey1, value: "Value 1")
        cacheManager.saveToMemory(key: testKey2, value: "Value 2")

        cacheManager.clearMemoryCache()

        let result1: (String, Date)? = cacheManager.getFromMemory(key: testKey1)
        let result2: (String, Date)? = cacheManager.getFromMemory(key: testKey2)
        XCTAssertNil(result1)
        XCTAssertNil(result2)
    }

    // MARK: - File Cache Tests

    func testFileCacheSaveAndLoad() throws {
        let cacheManager = CacheManager.shared
        let testKey = "test_file_\(UUID().uuidString)"
        let testData = "File cache data".data(using: .utf8)!

        // Save to file cache
        try cacheManager.saveToFileCache(key: testKey, data: testData)

        // Load from file cache
        let loadedData = cacheManager.loadFromFileCache(key: testKey)
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData, testData)

        // Cleanup
        cacheManager.removeFromFileCache(key: testKey)
    }

    func testFileCacheReturnsNilForMissingFile() {
        let cacheManager = CacheManager.shared
        let result = cacheManager.loadFromFileCache(key: "nonexistent_file_key")
        XCTAssertNil(result)
    }

    func testFileCacheRemove() throws {
        let cacheManager = CacheManager.shared
        let testKey = "test_file_remove_\(UUID().uuidString)"
        let testData = "To be removed".data(using: .utf8)!

        try cacheManager.saveToFileCache(key: testKey, data: testData)
        cacheManager.removeFromFileCache(key: testKey)

        let result = cacheManager.loadFromFileCache(key: testKey)
        XCTAssertNil(result)
    }

    func testFileCacheFreshness() throws {
        let cacheManager = CacheManager.shared
        let testKey = "test_file_fresh_\(UUID().uuidString)"
        let testData = "Fresh file".data(using: .utf8)!

        try cacheManager.saveToFileCache(key: testKey, data: testData)

        // Should be fresh with a long max age
        XCTAssertTrue(cacheManager.isFileCacheFresh(key: testKey, maxAge: 3600))

        // Cleanup
        cacheManager.removeFromFileCache(key: testKey)
    }

    func testFileCacheNotFreshForMissingFile() {
        let cacheManager = CacheManager.shared
        XCTAssertFalse(cacheManager.isFileCacheFresh(key: "nonexistent", maxAge: 3600))
    }

    // MARK: - Cache Stats Tests

    func testCacheStatsReturnsValidData() {
        let cacheManager = CacheManager.shared
        let stats = cacheManager.getStats()

        // Stats should have non-negative values
        XCTAssertGreaterThanOrEqual(stats.fileCacheSize, 0)
        XCTAssertGreaterThanOrEqual(stats.fileCacheCount, 0)
        XCTAssertGreaterThanOrEqual(stats.imageCacheSize, 0)
        XCTAssertGreaterThanOrEqual(stats.imageCacheCount, 0)
        XCTAssertGreaterThanOrEqual(stats.swiftDataSize, 0)
        XCTAssertGreaterThanOrEqual(stats.organizationCount, 0)
        XCTAssertGreaterThanOrEqual(stats.spaceCount, 0)
        XCTAssertGreaterThanOrEqual(stats.pageCount, 0)
    }

    func testCacheStatsTotalSize() {
        let cacheManager = CacheManager.shared
        let stats = cacheManager.getStats()

        // Total size should be sum of file cache and SwiftData
        XCTAssertEqual(stats.totalSize, stats.fileCacheSize + stats.swiftDataSize)
    }

    func testCacheStatsImageCountLessThanOrEqualToFileCount() {
        let cacheManager = CacheManager.shared
        let stats = cacheManager.getStats()

        // Image count should be <= total file count
        XCTAssertLessThanOrEqual(stats.imageCacheCount, stats.fileCacheCount)
        XCTAssertLessThanOrEqual(stats.imageCacheSize, stats.fileCacheSize)
    }

    // MARK: - Format Bytes Tests

    func testFormatBytesZero() {
        let formatted = CacheManager.formatBytes(0)
        XCTAssertEqual(formatted, "Zero KB")
    }

    func testFormatBytesKilobytes() {
        let formatted = CacheManager.formatBytes(1024)
        XCTAssertTrue(formatted.contains("KB") || formatted.contains("kB"))
    }

    func testFormatBytesMegabytes() {
        let formatted = CacheManager.formatBytes(1024 * 1024)
        XCTAssertTrue(formatted.contains("MB"))
    }

    func testFormatBytesGigabytes() {
        let formatted = CacheManager.formatBytes(1024 * 1024 * 1024)
        XCTAssertTrue(formatted.contains("GB"))
    }

    // MARK: - Image Cache Key Tests

    func testImageCacheKeyConsistency() {
        let cacheManager = CacheManager.shared
        let url = URL(string: "https://example.com/image.png")!

        let key1 = cacheManager.imageCacheKey(for: url)
        let key2 = cacheManager.imageCacheKey(for: url)

        XCTAssertEqual(key1, key2)
    }

    func testImageCacheKeyDifferentForDifferentURLs() {
        let cacheManager = CacheManager.shared
        let url1 = URL(string: "https://example.com/image1.png")!
        let url2 = URL(string: "https://example.com/image2.png")!

        let key1 = cacheManager.imageCacheKey(for: url1)
        let key2 = cacheManager.imageCacheKey(for: url2)

        XCTAssertNotEqual(key1, key2)
    }

    func testImageCacheKeyStartsWithImagePrefix() {
        let cacheManager = CacheManager.shared
        let url = URL(string: "https://example.com/test.png")!

        let key = cacheManager.imageCacheKey(for: url)
        XCTAssertTrue(key.hasPrefix("image:"))
    }

    // MARK: - Cache Policy Tests

    func testCachePolicyDefaultMaxAge() {
        XCTAssertEqual(CachePolicy.defaultMaxAge, 300) // 5 minutes
    }

    func testCachePolicyLongMaxAge() {
        XCTAssertEqual(CachePolicy.longMaxAge, 3600) // 1 hour
    }

    func testCachePolicyShortMaxAge() {
        XCTAssertEqual(CachePolicy.shortMaxAge, 60) // 1 minute
    }

    // MARK: - Clear Cache Tests

    func testClearFileCacheCreatesNewDirectory() throws {
        let cacheManager = CacheManager.shared

        // Save a file first
        let testKey = "test_clear_\(UUID().uuidString)"
        try cacheManager.saveToFileCache(key: testKey, data: "Test".data(using: .utf8)!)

        // Clear file cache
        cacheManager.clearFileCache()

        // Old file should be gone
        let result = cacheManager.loadFromFileCache(key: testKey)
        XCTAssertNil(result)

        // Should be able to save new files (directory recreated)
        try cacheManager.saveToFileCache(key: testKey, data: "New".data(using: .utf8)!)
        let newResult = cacheManager.loadFromFileCache(key: testKey)
        XCTAssertNotNil(newResult)

        // Cleanup
        cacheManager.removeFromFileCache(key: testKey)
    }

    // MARK: - Cache Entry Tests

    func testCacheEntryAge() throws {
        let entry = CacheManager.CacheEntry(data: "Test", cost: 0)

        // Just created, age should be very small
        XCTAssertLessThan(entry.age, 1.0)

        // Should be fresh with reasonable max age
        XCTAssertTrue(entry.isFresh(maxAge: 60))
    }

    func testCacheEntryIsFreshWithLongMaxAge() {
        let entry = CacheManager.CacheEntry(data: "Test", cost: 0)
        XCTAssertTrue(entry.isFresh(maxAge: 3600))
    }
}
