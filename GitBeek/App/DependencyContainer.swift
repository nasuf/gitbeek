//
//  DependencyContainer.swift
//  GitBeek
//
//  Dependency injection container
//

import Foundation

/// Container for app dependencies
@MainActor
final class DependencyContainer {
    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Services

    let apiService: GitBookAPIService
    let keychainManager: KeychainManager
    let swiftDataStore: SwiftDataStore
    let cacheManager: CacheManager

    // MARK: - Repositories

    let userRepository: UserRepository
    let organizationRepository: OrganizationRepository
    let authRepository: AuthRepository
    let spaceRepository: SpaceRepository
    let pageRepository: PageRepository
    let changeRequestRepository: ChangeRequestRepository

    // MARK: - ViewModels

    let authViewModel: AuthViewModel
    let profileViewModel: ProfileViewModel
    let appRouter: AppRouter
    let allChangeRequestsViewModel: AllChangeRequestsViewModel

    // MARK: - Initialization

    private init() {
        // Initialize services
        apiService = GitBookAPIService.shared
        keychainManager = KeychainManager.shared
        swiftDataStore = SwiftDataStore.shared
        cacheManager = CacheManager.shared

        // Initialize repositories
        let userRepo = UserRepositoryImpl(apiService: apiService, store: swiftDataStore)
        userRepository = userRepo

        organizationRepository = OrganizationRepositoryImpl(apiService: apiService, store: swiftDataStore)

        authRepository = AuthRepositoryImpl(
            apiService: apiService,
            keychainManager: keychainManager,
            userRepository: userRepo
        )

        spaceRepository = SpaceRepositoryImpl(apiService: apiService, store: swiftDataStore)

        pageRepository = PageRepositoryImpl(apiService: apiService, store: swiftDataStore)

        changeRequestRepository = ChangeRequestRepositoryImpl(apiService: apiService)

        // Initialize ViewModels
        authViewModel = AuthViewModel(authRepository: authRepository)

        profileViewModel = ProfileViewModel(
            userRepository: userRepository,
            organizationRepository: organizationRepository
        )

        allChangeRequestsViewModel = AllChangeRequestsViewModel(
            changeRequestRepository: changeRequestRepository,
            spaceRepository: spaceRepository,
            organizationRepository: organizationRepository
        )

        appRouter = AppRouter()
    }

    // MARK: - Factory Methods

    /// Create a fresh instance for testing
    static func createForTesting(
        apiService: GitBookAPIService? = nil,
        keychainManager: KeychainManager? = nil
    ) -> DependencyContainer {
        // For testing, return the shared instance (could be enhanced for proper DI)
        return shared
    }
}
