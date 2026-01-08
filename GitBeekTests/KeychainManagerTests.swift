//
//  KeychainManagerTests.swift
//  GitBeekTests
//
//  Tests for KeychainManager - particularly the deadlock fix
//

import XCTest
@testable import GitBeek

final class KeychainManagerTests: XCTestCase {

    // Use a unique service name for each test to avoid conflicts
    private var keychainManager: KeychainManager!
    private var testServiceName: String!

    override func setUpWithError() throws {
        testServiceName = "com.gitbeek.test.\(UUID().uuidString)"
        keychainManager = KeychainManager(serviceName: testServiceName)
    }

    override func tearDownWithError() throws {
        // Clean up all test data
        keychainManager.clearAll()
        keychainManager = nil
    }

    // MARK: - Basic Token Operations

    func testSaveAndLoadAccessToken() throws {
        let token = "test_access_token_12345"

        try keychainManager.saveAccessToken(token)
        let loadedToken = keychainManager.getAccessToken()

        XCTAssertEqual(loadedToken, token)
    }

    func testSaveAndLoadRefreshToken() throws {
        let token = "test_refresh_token_67890"

        try keychainManager.saveRefreshToken(token)
        let loadedToken = keychainManager.getRefreshToken()

        XCTAssertEqual(loadedToken, token)
    }

    func testSaveAndLoadUserId() throws {
        let userId = "user_abc123"

        try keychainManager.saveUserId(userId)
        let loadedUserId = keychainManager.getUserId()

        XCTAssertEqual(loadedUserId, userId)
    }

    // MARK: - Token Overwrite (Deadlock Fix Test)

    /// This test verifies the deadlock fix - saving a token when one already exists
    /// Previously this would deadlock because save() called delete() while holding the lock
    func testOverwriteExistingToken() throws {
        let originalToken = "original_token"
        let newToken = "new_token"

        // Save original token
        try keychainManager.saveAccessToken(originalToken)
        XCTAssertEqual(keychainManager.getAccessToken(), originalToken)

        // Overwrite with new token - this would have caused a deadlock before the fix
        try keychainManager.saveAccessToken(newToken)
        XCTAssertEqual(keychainManager.getAccessToken(), newToken)
    }

    /// Test multiple consecutive overwrites
    func testMultipleConsecutiveOverwrites() throws {
        for i in 1...10 {
            let token = "token_iteration_\(i)"
            try keychainManager.saveAccessToken(token)
            XCTAssertEqual(keychainManager.getAccessToken(), token)
        }
    }

    // MARK: - Concurrent Access (Thread Safety)

    /// Test concurrent save operations don't cause deadlock or data corruption
    func testConcurrentSaveOperations() throws {
        let expectation = XCTestExpectation(description: "Concurrent saves completed")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for i in 1...10 {
            queue.async {
                do {
                    try self.keychainManager.saveAccessToken("concurrent_token_\(i)")
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent save failed: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify we can still read the token (one of them should have won)
        XCTAssertNotNil(keychainManager.getAccessToken())
    }

    /// Test concurrent read and write operations
    func testConcurrentReadWrite() throws {
        // First save a token
        try keychainManager.saveAccessToken("initial_token")

        let expectation = XCTestExpectation(description: "Concurrent read/write completed")
        expectation.expectedFulfillmentCount = 20

        let queue = DispatchQueue(label: "test.concurrent.rw", attributes: .concurrent)

        // 10 readers
        for _ in 1...10 {
            queue.async {
                _ = self.keychainManager.getAccessToken()
                expectation.fulfill()
            }
        }

        // 10 writers
        for i in 1...10 {
            queue.async {
                do {
                    try self.keychainManager.saveAccessToken("token_\(i)")
                    expectation.fulfill()
                } catch {
                    XCTFail("Write failed: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Token Expiry

    func testTokenExpiryFuture() throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        try keychainManager.saveTokenExpiry(futureDate)

        XCTAssertFalse(keychainManager.isTokenExpired())
    }

    func testTokenExpiryPast() throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago

        try keychainManager.saveTokenExpiry(pastDate)

        XCTAssertTrue(keychainManager.isTokenExpired())
    }

    func testTokenExpiryWithNoExpiry() throws {
        // No expiry saved should be treated as expired
        XCTAssertTrue(keychainManager.isTokenExpired())
    }

    // MARK: - Clear Operations

    func testClearTokens() throws {
        try keychainManager.saveAccessToken("access")
        try keychainManager.saveRefreshToken("refresh")
        try keychainManager.saveTokenExpiry(Date())
        try keychainManager.saveUserId("user123")

        keychainManager.clearTokens()

        XCTAssertNil(keychainManager.getAccessToken())
        XCTAssertNil(keychainManager.getRefreshToken())
        XCTAssertNil(keychainManager.getTokenExpiry())
        // User ID should NOT be cleared by clearTokens
        XCTAssertEqual(keychainManager.getUserId(), "user123")
    }

    func testClearAll() throws {
        try keychainManager.saveAccessToken("access")
        try keychainManager.saveRefreshToken("refresh")
        try keychainManager.saveUserId("user123")

        keychainManager.clearAll()

        XCTAssertNil(keychainManager.getAccessToken())
        XCTAssertNil(keychainManager.getRefreshToken())
        XCTAssertNil(keychainManager.getUserId())
    }

    // MARK: - Edge Cases

    func testEmptyToken() throws {
        let emptyToken = ""

        try keychainManager.saveAccessToken(emptyToken)
        XCTAssertEqual(keychainManager.getAccessToken(), emptyToken)
    }

    func testLongToken() throws {
        // Test with a very long token (e.g., JWT-like)
        let longToken = String(repeating: "a", count: 10000)

        try keychainManager.saveAccessToken(longToken)
        XCTAssertEqual(keychainManager.getAccessToken(), longToken)
    }

    func testSpecialCharactersInToken() throws {
        let specialToken = "token!@#$%^&*()_+-=[]{}|;':\",./<>?"

        try keychainManager.saveAccessToken(specialToken)
        XCTAssertEqual(keychainManager.getAccessToken(), specialToken)
    }

    func testUnicodeToken() throws {
        let unicodeToken = "token_中文_日本語_한국어_🔐🔑"

        try keychainManager.saveAccessToken(unicodeToken)
        XCTAssertEqual(keychainManager.getAccessToken(), unicodeToken)
    }

    // MARK: - Exists Check

    func testExistsForExistingKey() throws {
        try keychainManager.saveAccessToken("test_token")

        XCTAssertTrue(keychainManager.exists(key: "com.gitbeek.accessToken"))
    }

    func testExistsForNonExistingKey() {
        XCTAssertFalse(keychainManager.exists(key: "com.gitbeek.nonexistent"))
    }

    // MARK: - Generic Codable Storage

    func testSaveAndLoadCodable() throws {
        struct TestData: Codable, Equatable {
            let id: String
            let value: Int
        }

        let testData = TestData(id: "test123", value: 42)
        let key = "com.gitbeek.test.codable"

        try keychainManager.save(key: key, object: testData)
        let loaded: TestData = try keychainManager.load(key: key, type: TestData.self)

        XCTAssertEqual(loaded, testData)
    }

    // MARK: - Performance

    func testSavePerformance() throws {
        measure {
            for i in 0..<100 {
                try? keychainManager.saveAccessToken("perf_token_\(i)")
            }
        }
    }

    func testLoadPerformance() throws {
        try keychainManager.saveAccessToken("perf_token")

        measure {
            for _ in 0..<100 {
                _ = keychainManager.getAccessToken()
            }
        }
    }
}
