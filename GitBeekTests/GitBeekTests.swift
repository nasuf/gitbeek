//
//  GitBeekTests.swift
//  GitBeekTests
//
//  Unit tests for GitBeek iOS app
//

import XCTest
@testable import GitBeek

final class GitBeekTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup code here
    }

    override func tearDownWithError() throws {
        // Teardown code here
    }

    // MARK: - Environment Configuration Tests

    func testDevelopmentEnvironmentConfiguration() throws {
        let env = AppEnvironment.development

        XCTAssertEqual(env.apiBaseURL.absoluteString, "https://api.gitbook.com/v1")
        XCTAssertEqual(env.oauthClientID, "gitbeek-dev")
        XCTAssertEqual(env.oauthRedirectURI, "gitbeek://oauth/callback")
        XCTAssertTrue(env.isDebugLoggingEnabled)
    }

    func testProductionEnvironmentConfiguration() throws {
        let env = AppEnvironment.production

        XCTAssertEqual(env.apiBaseURL.absoluteString, "https://api.gitbook.com/v1")
        XCTAssertEqual(env.oauthClientID, "gitbeek-prod")
        XCTAssertFalse(env.isDebugLoggingEnabled)
    }

    // MARK: - Spacing Tests

    func testSpacingValues() throws {
        XCTAssertEqual(AppSpacing.xxs, 4)
        XCTAssertEqual(AppSpacing.xs, 8)
        XCTAssertEqual(AppSpacing.sm, 12)
        XCTAssertEqual(AppSpacing.md, 16)
        XCTAssertEqual(AppSpacing.lg, 20)
        XCTAssertEqual(AppSpacing.xl, 24)
        XCTAssertEqual(AppSpacing.xxl, 32)
    }

    func testMinTouchTarget() throws {
        // Apple HIG recommends 44pt minimum touch target
        XCTAssertEqual(AppSpacing.minTouchTarget, 44)
    }

    // MARK: - Performance Tests

    func testAppStateCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = AppState()
            }
        }
    }
}
