//
//  SessionExpiredInterceptorTests.swift
//  GitBeekTests
//
//  Tests for SessionExpiredInterceptor
//

import XCTest
@testable import GitBeek

@MainActor
final class SessionExpiredInterceptorTests: XCTestCase {

    private var interceptor: SessionExpiredInterceptor!
    private var notificationExpectation: XCTestExpectation?
    private var notificationObserver: NSObjectProtocol?

    override func setUpWithError() throws {
        interceptor = SessionExpiredInterceptor.shared
    }

    override func tearDownWithError() throws {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObserver = nil
        notificationExpectation = nil
    }

    // MARK: - Singleton

    func testSingletonInstance() {
        let instance1 = SessionExpiredInterceptor.shared
        let instance2 = SessionExpiredInterceptor.shared
        XCTAssertTrue(instance1 === instance2, "Singleton should return same instance")
    }

    // MARK: - 401 Unauthorized Detection

    func testInterceptPosts401NotificationOnUnauthorized() async throws {
        // Setup notification expectation
        notificationExpectation = expectation(description: "Session expired notification")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notificationExpectation?.fulfill()
        }

        // Create 401 response
        let url = URL(string: "https://api.gitbook.com/v1/user")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // Call interceptor
        let _ = try await interceptor.intercept(
            response: response,
            data: data,
            request: request,
            retry: { fatalError("Retry should not be called") }
        )

        // Wait for notification
        await fulfillment(of: [notificationExpectation!], timeout: 1.0)
    }

    // MARK: - Non-401 Status Codes

    func testInterceptDoesNotPostNotificationOn200() async throws {
        try await assertNoNotificationPosted(forStatusCode: 200)
    }

    func testInterceptDoesNotPostNotificationOn403() async throws {
        try await assertNoNotificationPosted(forStatusCode: 403)
    }

    func testInterceptDoesNotPostNotificationOn404() async throws {
        try await assertNoNotificationPosted(forStatusCode: 404)
    }

    func testInterceptDoesNotPostNotificationOn500() async throws {
        try await assertNoNotificationPosted(forStatusCode: 500)
    }

    // MARK: - Helper

    private func assertNoNotificationPosted(forStatusCode statusCode: Int) async throws {
        var notificationReceived = false

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        let url = URL(string: "https://api.gitbook.com/v1/user")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        let _ = try await interceptor.intercept(
            response: response,
            data: Data(),
            request: request,
            retry: { fatalError("Retry should not be called") }
        )

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertFalse(notificationReceived, "Notification should not be posted for \(statusCode) status")
    }

    // MARK: - Data Passthrough

    func testInterceptReturnsOriginalDataAndResponse() async throws {
        let url = URL(string: "https://api.gitbook.com/v1/user")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        let originalData = "{\"id\": \"123\", \"name\": \"Test\"}".data(using: .utf8)!

        let (resultData, resultResponse) = try await interceptor.intercept(
            response: response,
            data: originalData,
            request: request,
            retry: { fatalError("Retry should not be called") }
        )

        XCTAssertEqual(resultData, originalData)
        XCTAssertEqual(resultResponse.statusCode, 200)
        XCTAssertEqual(resultResponse.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testInterceptReturnsDataEvenOn401() async throws {
        // Setup to receive notification
        notificationExpectation = expectation(description: "Session expired notification")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notificationExpectation?.fulfill()
        }

        let url = URL(string: "https://api.gitbook.com/v1/user")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let errorData = "{\"error\": \"Unauthorized\"}".data(using: .utf8)!

        let (resultData, resultResponse) = try await interceptor.intercept(
            response: response,
            data: errorData,
            request: request,
            retry: { fatalError("Retry should not be called") }
        )

        // Verify data is still returned even on 401
        XCTAssertEqual(resultData, errorData)
        XCTAssertEqual(resultResponse.statusCode, 401)

        await fulfillment(of: [notificationExpectation!], timeout: 1.0)
    }

    // MARK: - Request Interception (no-op)

    func testInterceptRequestDoesNotModifyRequest() async throws {
        let url = URL(string: "https://api.gitbook.com/v1/user")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer test_token", forHTTPHeaderField: "Authorization")

        let originalHeaders = request.allHTTPHeaderFields

        try await interceptor.intercept(request: &request)

        // Verify request is not modified
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.allHTTPHeaderFields, originalHeaders)
    }

    // MARK: - Multiple 401 Responses

    func testMultiple401ResponsesPostMultipleNotifications() async throws {
        var notificationCount = 0

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
        }

        let url = URL(string: "https://api.gitbook.com/v1/user")!
        let request = URLRequest(url: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // Send multiple 401 responses
        for _ in 0..<3 {
            let _ = try await interceptor.intercept(
                response: response,
                data: data,
                request: request,
                retry: { fatalError("Retry should not be called") }
            )
        }

        // Give time for all notifications to be processed
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        XCTAssertEqual(notificationCount, 3, "Should receive 3 notifications for 3 401 responses")
    }

    // MARK: - Notification Name

    func testNotificationNameIsCorrect() {
        XCTAssertEqual(Notification.Name.sessionExpired.rawValue, "GitBeek.sessionExpired")
    }
}
