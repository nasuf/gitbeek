//
//  ProfileViewModelTests.swift
//  GitBeekTests
//
//  Tests for ProfileViewModel
//

import XCTest
@testable import GitBeek

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private var viewModel: ProfileViewModel!
    private var mockUserRepository: MockUserRepository!
    private var mockOrganizationRepository: MockOrganizationRepository!

    override func setUpWithError() throws {
        mockUserRepository = MockUserRepository()
        mockOrganizationRepository = MockOrganizationRepository()
        viewModel = ProfileViewModel(
            userRepository: mockUserRepository,
            organizationRepository: mockOrganizationRepository
        )

        // Clear any persisted organization selection
        UserDefaults.standard.removeObject(forKey: "selectedOrganizationId")
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockUserRepository = nil
        mockOrganizationRepository = nil
        UserDefaults.standard.removeObject(forKey: "selectedOrganizationId")
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(viewModel.user)
        XCTAssertTrue(viewModel.organizations.isEmpty)
        XCTAssertNil(viewModel.selectedOrganization)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Load User

    func testLoadUserSuccess() async {
        let testUser = User(
            id: "user123",
            displayName: "Test User",
            email: "test@example.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockUserRepository.mockUser = testUser

        await viewModel.loadUser()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.user?.id, "user123")
        XCTAssertEqual(viewModel.user?.displayName, "Test User")
    }

    func testLoadUserFailure() async {
        mockUserRepository.shouldFail = true

        await viewModel.loadUser()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertNil(viewModel.user)
    }

    func testLoadUserUsesCachedDataOnFailure() async {
        let cachedUser = User(
            id: "cached",
            displayName: "Cached User",
            email: "cached@example.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockUserRepository.cachedUser = cachedUser
        mockUserRepository.shouldFail = true

        await viewModel.loadUser()

        XCTAssertFalse(viewModel.isLoading)
        // Error should not be set since we have cached data
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.user?.id, "cached")
    }

    // MARK: - Load Organizations

    func testLoadOrganizationsSuccess() async {
        let orgs = [
            Organization(id: "org1", title: "Org 1", spacesCount: 5),
            Organization(id: "org2", title: "Org 2", spacesCount: 3)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        await viewModel.loadOrganizations()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.organizations.count, 2)
        XCTAssertEqual(viewModel.organizations[0].title, "Org 1")
    }

    func testLoadOrganizationsAutoSelectsFirst() async {
        let orgs = [
            Organization(id: "org1", title: "First Org", spacesCount: 5)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        await viewModel.loadOrganizations()

        XCTAssertNotNil(viewModel.selectedOrganization)
        XCTAssertEqual(viewModel.selectedOrganization?.id, "org1")
    }

    func testLoadOrganizationsFailure() async {
        mockOrganizationRepository.shouldFail = true

        await viewModel.loadOrganizations()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.organizations.isEmpty)
    }

    func testLoadOrganizationsUsesCachedDataOnFailure() async {
        let cachedOrgs = [
            Organization(id: "cached1", title: "Cached Org", spacesCount: 1)
        ]
        mockOrganizationRepository.cachedOrganizations = cachedOrgs
        mockOrganizationRepository.shouldFail = true

        await viewModel.loadOrganizations()

        XCTAssertFalse(viewModel.isLoading)
        // Error should not be set since we have cached data
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.organizations.count, 1)
        XCTAssertEqual(viewModel.organizations[0].id, "cached1")
    }

    // MARK: - Load All

    func testLoadAllLoadsUserAndOrganizations() async {
        let testUser = User(
            id: "user1",
            displayName: "Test",
            email: "test@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let orgs = [
            Organization(id: "org1", title: "Org", spacesCount: 1)
        ]
        mockUserRepository.mockUser = testUser
        mockOrganizationRepository.mockOrganizations = orgs

        await viewModel.loadAll()

        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.organizations.isEmpty)
    }

    // MARK: - Organization Selection

    func testSelectOrganization() {
        let org = Organization(id: "org1", title: "Selected Org", spacesCount: 2)

        viewModel.selectOrganization(org)

        XCTAssertEqual(viewModel.selectedOrganization?.id, "org1")

        // Check persistence
        let savedId = UserDefaults.standard.string(forKey: "selectedOrganizationId")
        XCTAssertEqual(savedId, "org1")
    }

    func testRestoreSelectedOrganization() async {
        let orgs = [
            Organization(id: "org1", title: "Org 1", spacesCount: 1),
            Organization(id: "org2", title: "Org 2", spacesCount: 2)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        // Save org2 as selected
        UserDefaults.standard.set("org2", forKey: "selectedOrganizationId")

        await viewModel.loadOrganizations()
        viewModel.restoreSelectedOrganization()

        XCTAssertEqual(viewModel.selectedOrganization?.id, "org2")
    }

    func testRestoreSelectedOrganizationWithInvalidId() async {
        let orgs = [
            Organization(id: "org1", title: "Org 1", spacesCount: 1)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        // Save invalid org id
        UserDefaults.standard.set("nonexistent", forKey: "selectedOrganizationId")

        await viewModel.loadOrganizations()
        viewModel.restoreSelectedOrganization()

        // Should auto-select first since invalid id
        XCTAssertEqual(viewModel.selectedOrganization?.id, "org1")
    }

    // MARK: - Clear Error

    func testClearError() async {
        mockUserRepository.shouldFail = true
        await viewModel.loadUser()

        XCTAssertNotNil(viewModel.error)

        viewModel.clearError()

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasError)
    }

    // MARK: - Convenience Properties

    func testUserInitialsWithUser() async {
        let testUser = User(
            id: "user1",
            displayName: "John Doe",
            email: "john@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockUserRepository.mockUser = testUser

        await viewModel.loadUser()

        XCTAssertEqual(viewModel.userInitials, "JD")
    }

    func testUserInitialsWithoutUser() {
        XCTAssertEqual(viewModel.userInitials, "?")
    }

    func testUserNameWithUser() async {
        let testUser = User(
            id: "user1",
            displayName: "Jane Smith",
            email: "jane@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockUserRepository.mockUser = testUser

        await viewModel.loadUser()

        XCTAssertEqual(viewModel.userName, "Jane Smith")
    }

    func testUserNameWithoutUser() {
        XCTAssertEqual(viewModel.userName, "Unknown")
    }

    func testUserEmailWithUser() async {
        let testUser = User(
            id: "user1",
            displayName: "Test",
            email: "test@email.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        mockUserRepository.mockUser = testUser

        await viewModel.loadUser()

        XCTAssertEqual(viewModel.userEmail, "test@email.com")
    }

    func testUserEmailWithoutUser() {
        XCTAssertEqual(viewModel.userEmail, "")
    }

    func testOrganizationCount() async {
        let orgs = [
            Organization(id: "org1", title: "Org 1", spacesCount: 1),
            Organization(id: "org2", title: "Org 2", spacesCount: 2),
            Organization(id: "org3", title: "Org 3", spacesCount: 3)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        await viewModel.loadOrganizations()

        XCTAssertEqual(viewModel.organizationCount, 3)
    }

    // MARK: - Refresh

    func testRefresh() async {
        let testUser = User(
            id: "user1",
            displayName: "Test",
            email: "test@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let orgs = [
            Organization(id: "org1", title: "Org", spacesCount: 1)
        ]
        mockUserRepository.mockUser = testUser
        mockOrganizationRepository.mockOrganizations = orgs

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.organizations.isEmpty)
    }

    // MARK: - Loading State

    func testLoadingStateEndsAfterLoadUser() async {
        mockUserRepository.mockUser = User(
            id: "user1",
            displayName: "Test",
            email: "test@test.com",
            photoURL: nil,
            createdAt: nil,
            updatedAt: nil
        )

        XCTAssertFalse(viewModel.isLoading)

        await viewModel.loadUser()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadingStateEndsAfterLoadOrganizations() async {
        mockOrganizationRepository.mockOrganizations = [
            Organization(id: "org1", title: "Org", spacesCount: 1)
        ]

        XCTAssertFalse(viewModel.isLoading)

        await viewModel.loadOrganizations()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadingStateEndsOnError() async {
        mockUserRepository.shouldFail = true

        await viewModel.loadUser()

        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Organization Selection Persistence

    func testSelectionNotAffectedBySubsequentLoads() async {
        let orgs = [
            Organization(id: "org1", title: "Org 1", spacesCount: 1),
            Organization(id: "org2", title: "Org 2", spacesCount: 2)
        ]
        mockOrganizationRepository.mockOrganizations = orgs

        // Load and select org2
        await viewModel.loadOrganizations()
        viewModel.selectOrganization(orgs[1])

        XCTAssertEqual(viewModel.selectedOrganization?.id, "org2")

        // Load again - selection should remain
        await viewModel.loadOrganizations()

        // Selection should not change since we already have one selected
        XCTAssertEqual(viewModel.selectedOrganization?.id, "org2")
    }
}

// MARK: - Mock User Repository

private final class MockUserRepository: UserRepository, @unchecked Sendable {
    var mockUser: User?
    var cachedUser: User?
    var shouldFail = false

    func getCurrentUser() async throws -> User {
        if shouldFail {
            throw MockError.failed
        }
        guard let user = mockUser else {
            throw MockError.notFound
        }
        return user
    }

    func getCachedUser() async -> User? {
        cachedUser
    }

    func clearCache() async {}
}

// MARK: - Mock Organization Repository

private final class MockOrganizationRepository: OrganizationRepository, @unchecked Sendable {
    var mockOrganizations: [Organization] = []
    var cachedOrganizations: [Organization] = []
    var shouldFail = false

    func getOrganizations() async throws -> [Organization] {
        if shouldFail {
            throw MockError.failed
        }
        return mockOrganizations
    }

    func getOrganization(id: String) async throws -> Organization {
        if shouldFail {
            throw MockError.failed
        }
        guard let org = mockOrganizations.first(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        return org
    }

    func listMembers(organizationId: String) async throws -> [UserReference] { [] }

    func getCachedOrganizations() async -> [Organization] {
        cachedOrganizations
    }

    func clearCache() async {}
}

// MARK: - Mock Error

private enum MockError: Error {
    case failed
    case notFound
}
