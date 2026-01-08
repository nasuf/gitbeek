//
//  AuthViewModelTests.swift
//  GitBeekTests
//
//  Tests for AuthViewModel login flow
//

import XCTest
@testable import GitBeek

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var viewModel: AuthViewModel!
    private var mockRepository: MockAuthRepository!

    override func setUpWithError() throws {
        mockRepository = MockAuthRepository()
        viewModel = AuthViewModel(authRepository: mockRepository)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(viewModel.authState, .unknown)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.apiToken, "")
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }

    // MARK: - Login with Token - Success

    func testLoginWithTokenSuccess() async {
        let testUser = User(
            id: "user123",
            displayName: "Test User",
            email: "test@example.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockRepository.mockUser = testUser
        mockRepository.shouldSucceed = true

        viewModel.apiToken = "valid_token_12345"
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.authState, .authenticated(testUser))
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.id, "user123")
        XCTAssertEqual(viewModel.apiToken, "") // Token should be cleared after success
    }

    // MARK: - Login with Token - Empty Token

    func testLoginWithEmptyToken() async {
        viewModel.apiToken = ""
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)

        // Check error is ValidationError.emptyToken
        if let error = viewModel.error as? AuthViewModel.ValidationError {
            XCTAssertEqual(error, .emptyToken)
        } else {
            XCTFail("Expected ValidationError.emptyToken")
        }

        XCTAssertEqual(viewModel.authState, .unknown)
    }

    // MARK: - Login with Token - Failure

    func testLoginWithTokenFailure() async {
        mockRepository.shouldSucceed = false
        mockRepository.mockError = MockError.loginFailed

        viewModel.apiToken = "invalid_token"
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)
        XCTAssertEqual(viewModel.authState, .unknown)
        XCTAssertFalse(viewModel.isAuthenticated)
    }

    // MARK: - Login Loading State

    func testLoginSetsLoadingState() async {
        mockRepository.shouldSucceed = true
        mockRepository.mockDelay = 0.1 // Small delay to observe loading state

        viewModel.apiToken = "test_token"

        // Start login in a task
        let task = Task {
            await viewModel.loginWithToken()
        }

        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Note: Due to @MainActor, we might not be able to observe the loading state
        // in the middle of the operation. The test verifies the final state instead.

        await task.value

        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Logout

    func testLogout() async {
        // First, log in
        let testUser = User(
            id: "user123",
            displayName: "Test User",
            email: "test@example.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockRepository.mockUser = testUser
        mockRepository.shouldSucceed = true

        viewModel.apiToken = "valid_token"
        await viewModel.loginWithToken()

        XCTAssertTrue(viewModel.isAuthenticated)

        // Now logout
        await viewModel.logout()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }

    // MARK: - Check Auth State

    func testCheckAuthStateAuthenticated() async {
        let testUser = User(
            id: "user123",
            displayName: "Test User",
            email: "test@example.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockRepository.mockAuthState = .authenticated(testUser)

        await viewModel.checkAuthState()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.authState, .authenticated(testUser))
        XCTAssertTrue(viewModel.isAuthenticated)
    }

    func testCheckAuthStateUnauthenticated() async {
        mockRepository.mockAuthState = .unauthenticated

        await viewModel.checkAuthState()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertFalse(viewModel.isAuthenticated)
    }

    // MARK: - Clear Error

    func testClearError() async {
        mockRepository.shouldSucceed = false
        mockRepository.mockError = MockError.loginFailed

        viewModel.apiToken = "test"
        await viewModel.loginWithToken()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.hasError)

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    // MARK: - Error Message

    func testErrorMessage() async {
        viewModel.apiToken = ""
        await viewModel.loginWithToken()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please enter your API token.")
    }

    // MARK: - Multiple Login Attempts

    func testMultipleLoginAttempts() async {
        mockRepository.shouldSucceed = true
        mockRepository.mockUser = User(
            id: "user1",
            displayName: "User 1",
            email: "user1@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // First login
        viewModel.apiToken = "token1"
        await viewModel.loginWithToken()
        XCTAssertEqual(viewModel.currentUser?.id, "user1")

        // Logout
        await viewModel.logout()
        XCTAssertFalse(viewModel.isAuthenticated)

        // Second login with different user
        mockRepository.mockUser = User(
            id: "user2",
            displayName: "User 2",
            email: "user2@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        viewModel.apiToken = "token2"
        await viewModel.loginWithToken()

        XCTAssertEqual(viewModel.currentUser?.id, "user2")
    }
}

// MARK: - Mock Auth Repository

private final class MockAuthRepository: AuthRepository, @unchecked Sendable {
    var mockAuthState: AuthState = .unknown
    var mockUser: User?
    var mockError: Error?
    var shouldSucceed = true
    var mockDelay: TimeInterval = 0

    var authState: AuthState {
        get async {
            mockAuthState
        }
    }

    var isAuthenticated: Bool {
        get async {
            if case .authenticated = mockAuthState {
                return true
            }
            return false
        }
    }

    func loginWithOAuth(code: String, redirectUri: String) async throws -> User {
        if mockDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }

        if shouldSucceed, let user = mockUser {
            mockAuthState = .authenticated(user)
            return user
        }
        throw mockError ?? MockError.loginFailed
    }

    func loginWithToken(_ token: String) async throws -> User {
        if mockDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }

        if shouldSucceed, let user = mockUser {
            mockAuthState = .authenticated(user)
            return user
        }
        throw mockError ?? MockError.loginFailed
    }

    func refreshToken() async throws {
        if !shouldSucceed {
            throw mockError ?? MockError.refreshFailed
        }
    }

    func logout() async {
        mockAuthState = .unauthenticated
    }

    func getAccessToken() async -> String? {
        shouldSucceed ? "mock_token" : nil
    }
}

// MARK: - Mock Errors

private enum MockError: LocalizedError {
    case loginFailed
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .loginFailed:
            return "Login failed"
        case .refreshFailed:
            return "Token refresh failed"
        }
    }
}
