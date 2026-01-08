//
//  ProfileViewModel.swift
//  GitBeek
//
//  ViewModel for user profile and organization management
//

import Foundation

/// ViewModel for profile and organization management
@MainActor
@Observable
final class ProfileViewModel {
    // MARK: - Published State

    private(set) var user: User?
    private(set) var organizations: [Organization] = []
    private(set) var selectedOrganization: Organization?
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies

    private let userRepository: UserRepository
    private let organizationRepository: OrganizationRepository

    // MARK: - Initialization

    init(userRepository: UserRepository, organizationRepository: OrganizationRepository) {
        self.userRepository = userRepository
        self.organizationRepository = organizationRepository
    }

    // MARK: - Public Methods

    /// Load user profile
    func loadUser() async {
        isLoading = true
        error = nil

        // Try cached user first
        if let cachedUser = await userRepository.getCachedUser() {
            user = cachedUser
        }

        // Fetch fresh data
        do {
            user = try await userRepository.getCurrentUser()
        } catch {
            // Only set error if we don't have cached data
            if user == nil {
                self.error = error
            }
        }

        isLoading = false
    }

    /// Load organizations
    func loadOrganizations() async {
        isLoading = true
        error = nil

        // Try cached organizations first
        let cachedOrgs = await organizationRepository.getCachedOrganizations()
        if !cachedOrgs.isEmpty {
            organizations = cachedOrgs
            // Auto-select first if none selected
            if selectedOrganization == nil {
                selectedOrganization = cachedOrgs.first
            }
        }

        // Fetch fresh data
        do {
            organizations = try await organizationRepository.getOrganizations()
            // Auto-select first if none selected
            if selectedOrganization == nil {
                selectedOrganization = organizations.first
            }
        } catch {
            // Only set error if we don't have cached data
            if organizations.isEmpty {
                self.error = error
            }
        }

        isLoading = false
    }

    /// Load all profile data
    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadUser() }
            group.addTask { await self.loadOrganizations() }
        }
    }

    /// Select an organization
    func selectOrganization(_ organization: Organization) {
        selectedOrganization = organization
        // Persist selection
        UserDefaults.standard.set(organization.id, forKey: "selectedOrganizationId")
    }

    /// Restore selected organization from persistence
    func restoreSelectedOrganization() {
        guard let savedId = UserDefaults.standard.string(forKey: "selectedOrganizationId") else {
            return
        }

        if let org = organizations.first(where: { $0.id == savedId }) {
            selectedOrganization = org
        }
    }

    /// Clear error
    func clearError() {
        error = nil
    }

    /// Refresh all data
    func refresh() async {
        await loadAll()
    }
}

// MARK: - Convenience Properties

extension ProfileViewModel {
    var hasError: Bool {
        error != nil
    }

    var errorMessage: String? {
        error?.localizedDescription
    }

    var userInitials: String {
        user?.initials ?? "?"
    }

    var userName: String {
        user?.displayName ?? "Unknown"
    }

    var userEmail: String {
        user?.email ?? ""
    }

    var organizationCount: Int {
        organizations.count
    }
}
