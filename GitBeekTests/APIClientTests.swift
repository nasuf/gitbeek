//
//  APIClientTests.swift
//  GitBeekTests
//
//  Tests for APIClient request execution
//

import XCTest
@testable import GitBeek

final class APIClientTests: XCTestCase {

    private var apiClient: APIClient!
    private let baseURL = URL(string: "https://api.test.com/v1")!

    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        apiClient = APIClient(baseURL: baseURL, session: mockSession)
    }

    override func tearDownWithError() throws {
        apiClient = nil
        MockURLProtocol.reset()
    }

    // MARK: - Auth Token Management

    func testSetAndGetAuthToken() async {
        await apiClient.setAuthToken("test_token_123")
        let token = await apiClient.getAuthToken()
        XCTAssertEqual(token, "test_token_123")
    }

    func testSetNilAuthToken() async {
        await apiClient.setAuthToken("test_token")
        await apiClient.setAuthToken(nil)
        let token = await apiClient.getAuthToken()
        XCTAssertNil(token)
    }

    func testMultipleTokenChanges() async {
        await apiClient.setAuthToken("token1")
        var token = await apiClient.getAuthToken()
        XCTAssertEqual(token, "token1")

        await apiClient.setAuthToken("token2")
        token = await apiClient.getAuthToken()
        XCTAssertEqual(token, "token2")

        await apiClient.setAuthToken(nil)
        token = await apiClient.getAuthToken()
        XCTAssertNil(token)

        await apiClient.setAuthToken("token3")
        token = await apiClient.getAuthToken()
        XCTAssertEqual(token, "token3")
    }

    // MARK: - Request Success

    func testRequestDecodesJSON() async throws {
        let testResponse = TestResponse(id: "123", name: "Test")
        let responseData = try JSONEncoder().encode(testResponse)

        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: responseData
        )

        let result: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "123"))

        XCTAssertEqual(result.id, "123")
        XCTAssertEqual(result.name, "Test")
    }

    func testRequestDataReturnsRawData() async throws {
        let testData = "Raw test data".data(using: .utf8)!

        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: testData
        )

        let result = try await apiClient.requestData(TestEndpoint.getItem(id: "1"))

        XCTAssertEqual(result, testData)
    }

    func testRequestVoidSucceeds() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 204,
            data: Data()
        )

        // Should not throw
        try await apiClient.requestVoid(TestEndpoint.deleteItem(id: "1"))
    }

    // MARK: - HTTP Errors

    func testUnauthorizedError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 401,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .unauthorized = error {
                // Expected
            } else {
                XCTFail("Expected unauthorized error, got \(error)")
            }
        }
    }

    func testNotFoundError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 404,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "nonexistent"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .notFound = error {
                // Expected
            } else {
                XCTFail("Expected notFound error, got \(error)")
            }
        }
    }

    func testServerError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 500,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .serverError = error {
                // Expected
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testForbiddenError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 403,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .forbidden = error {
                // Expected
            } else {
                XCTFail("Expected forbidden error, got \(error)")
            }
        }
    }

    func testBadRequestError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 400,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .badRequest = error {
                // Expected
            } else {
                XCTFail("Expected badRequest error, got \(error)")
            }
        }
    }

    func testRateLimitedError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 429,
            data: Data()
        )

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .rateLimited = error {
                // Expected
            } else {
                XCTFail("Expected rateLimited error, got \(error)")
            }
        }
    }

    // MARK: - Decoding Error

    func testDecodingError() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: "invalid json".data(using: .utf8)!
        )

        do {
            let _: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        }
    }

    // MARK: - Network Error

    func testNetworkError() async throws {
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected network error")
        } catch let error as APIError {
            if case .noConnection = error {
                // Expected
            } else {
                XCTFail("Expected noConnection error, got \(error)")
            }
        }
    }

    func testTimeoutError() async throws {
        MockURLProtocol.mockError = URLError(.timedOut)

        do {
            let _: EmptyResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
            XCTFail("Expected timeout error")
        } catch let error as APIError {
            if case .timeout = error {
                // Expected
            } else {
                XCTFail("Expected timeout error, got \(error)")
            }
        }
    }

    // MARK: - Multiple Sequential Requests

    func testMultipleSequentialRequests() async throws {
        // Test that we can make multiple requests in sequence

        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: "{\"id\":\"1\",\"name\":\"Item1\"}".data(using: .utf8)!
        )
        let result1: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
        XCTAssertEqual(result1.id, "1")

        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: "{\"id\":\"2\",\"name\":\"Item2\"}".data(using: .utf8)!
        )
        let result2: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "2"))
        XCTAssertEqual(result2.id, "2")

        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: "{\"id\":\"3\",\"name\":\"Item3\"}".data(using: .utf8)!
        )
        let result3: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "3"))
        XCTAssertEqual(result3.id, "3")
    }

    // MARK: - Different HTTP Methods

    func testGetRequest() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 200,
            data: "{\"id\":\"1\",\"name\":\"Test\"}".data(using: .utf8)!
        )

        let _: TestResponse = try await apiClient.request(TestEndpoint.getItem(id: "1"))
        XCTAssertEqual(MockURLProtocol.lastRequest?.httpMethod, "GET")
    }

    func testPostRequest() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 201,
            data: "{\"id\":\"new\",\"name\":\"Created\"}".data(using: .utf8)!
        )

        let body = TestRequestBody(title: "Test", value: 42)
        let _: TestResponse = try await apiClient.request(TestEndpoint.createItem(body: body))
        XCTAssertEqual(MockURLProtocol.lastRequest?.httpMethod, "POST")
    }

    func testDeleteRequest() async throws {
        MockURLProtocol.mockResponse = MockResponse(
            statusCode: 204,
            data: Data()
        )

        try await apiClient.requestVoid(TestEndpoint.deleteItem(id: "1"))
        XCTAssertEqual(MockURLProtocol.lastRequest?.httpMethod, "DELETE")
    }
}

// MARK: - Test Helpers

private struct TestResponse: Codable, Equatable {
    let id: String
    let name: String
}

private struct EmptyResponse: Codable {}

private struct TestRequestBody: Codable, Equatable {
    let title: String
    let value: Int
}

private enum TestEndpoint: APIEndpoint {
    case getItem(id: String)
    case createItem(body: TestRequestBody)
    case deleteItem(id: String)
    case listItems(page: String, limit: String)
    case publicEndpoint

    var path: String {
        switch self {
        case .getItem(let id):
            return "/items/\(id)"
        case .createItem:
            return "/items"
        case .deleteItem(let id):
            return "/items/\(id)"
        case .listItems:
            return "/items"
        case .publicEndpoint:
            return "/public"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getItem, .listItems, .publicEndpoint:
            return .get
        case .createItem:
            return .post
        case .deleteItem:
            return .delete
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .listItems(let page, let limit):
            return ["page": page, "limit": limit]
        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .createItem(let body):
            return body
        default:
            return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .publicEndpoint:
            return false
        default:
            return true
        }
    }
}

// MARK: - Mock Response

private struct MockResponse {
    let statusCode: Int
    let data: Data
}

// MARK: - Mock URL Protocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    // Thread-safe static storage
    private static let lock = NSLock()

    nonisolated(unsafe) private static var _mockResponse: MockResponse?
    nonisolated(unsafe) private static var _mockError: Error?
    nonisolated(unsafe) private static var _lastRequest: URLRequest?

    static var mockResponse: MockResponse? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockResponse
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockResponse = newValue
            _mockError = nil
        }
    }

    static var mockError: Error? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockError
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockError = newValue
            _mockResponse = nil
        }
    }

    static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return _lastRequest
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        _mockResponse = nil
        _mockError = nil
        _lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Capture the request
        MockURLProtocol.lock.lock()
        MockURLProtocol._lastRequest = request
        let mockError = MockURLProtocol._mockError
        let mockResponse = MockURLProtocol._mockResponse
        MockURLProtocol.lock.unlock()

        if let error = mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let mock = mockResponse else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mock.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mock.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
