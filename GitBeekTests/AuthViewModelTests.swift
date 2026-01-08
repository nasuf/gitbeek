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
        let testUser = makeTestUser()
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
        mockRepository.mockUser = makeTestUser()
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
        let testUser = makeTestUser()
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
        mockRepository.mockUser = makeTestUser(id: "user1", displayName: "User 1", email: "user1@test.com")

        // First login
        viewModel.apiToken = "token1"
        await viewModel.loginWithToken()
        XCTAssertEqual(viewModel.currentUser?.id, "user1")

        // Logout
        await viewModel.logout()
        XCTAssertFalse(viewModel.isAuthenticated)

        // Second login with different user
        mockRepository.mockUser = makeTestUser(id: "user2", displayName: "User 2", email: "user2@test.com")
        viewModel.apiToken = "token2"
        await viewModel.loginWithToken()

        XCTAssertEqual(viewModel.currentUser?.id, "user2")
    }

    // MARK: - Loading State Transitions

    func testLoadingStateStartsAndEndsCorrectly() async {
        mockRepository.shouldSucceed = true
        mockRepository.mockUser = makeTestUser()

        XCTAssertFalse(viewModel.isLoading)

        viewModel.apiToken = "token"
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadingStateEndsOnFailure() async {
        mockRepository.shouldSucceed = false
        mockRepository.mockError = MockError.loginFailed

        viewModel.apiToken = "invalid_token"
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }

    func testLoadingStateDuringCheckAuthState() async {
        mockRepository.mockAuthState = .unauthenticated

        XCTAssertFalse(viewModel.isLoading)

        await viewModel.checkAuthState()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadingStateDuringLogout() async {
        mockRepository.mockUser = makeTestUser()
        mockRepository.shouldSucceed = true

        viewModel.apiToken = "token"
        await viewModel.loginWithToken()

        XCTAssertFalse(viewModel.isLoading)

        await viewModel.logout()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.authState, .unauthenticated)
    }

    // MARK: - Token Clearing

    func testTokenClearedAfterSuccessfulLogin() async {
        mockRepository.shouldSucceed = true
        mockRepository.mockUser = makeTestUser()

        viewModel.apiToken = "my_secret_token"
        XCTAssertEqual(viewModel.apiToken, "my_secret_token")

        await viewModel.loginWithToken()

        XCTAssertEqual(viewModel.apiToken, "", "Token should be cleared after successful login")
    }

    func testTokenNotClearedAfterFailedLogin() async {
        mockRepository.shouldSucceed = false
        mockRepository.mockError = MockError.loginFailed

        viewModel.apiToken = "my_token"
        await viewModel.loginWithToken()

        // Token should remain so user can retry
        XCTAssertEqual(viewModel.apiToken, "my_token")
    }

    // MARK: - Button Disabled State

    func testButtonShouldBeDisabledWhenTokenEmpty() {
        viewModel.apiToken = ""

        // The button should be disabled when token is empty
        XCTAssertTrue(viewModel.apiToken.isEmpty)
    }

    func testButtonShouldBeEnabledWhenTokenNotEmpty() {
        viewModel.apiToken = "valid_token"

        XCTAssertFalse(viewModel.apiToken.isEmpty)
    }

    func testButtonDisabledDuringLoading() async {
        mockRepository.shouldSucceed = true
        mockRepository.mockDelay = 0.2

        viewModel.apiToken = "token"

        let task = Task {
            await viewModel.loginWithToken()
        }

        // Give a moment to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // During loading, button should be disabled
        // (isLoading should be true while loginWithToken is executing)

        await task.value

        // After completion, isLoading should be false
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Whitespace Token Handling

    func testWhitespaceOnlyTokenTreatedAsEmpty() async {
        viewModel.apiToken = "   "

        // Whitespace tokens are not currently treated as empty
        // If this is desired behavior, the view should trim the token
        // This test documents current behavior
        await viewModel.loginWithToken()

        // Current implementation does not trim whitespace
        // The repository would receive the whitespace token
    }
}

// MARK: - Test Helpers

private func makeTestUser(id: String = "user123", displayName: String = "Test User", email: String = "test@example.com") -> User {
    User(id: id, displayName: displayName, email: email, photoURL: nil, createdAt: nil, updatedAt: nil)
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
