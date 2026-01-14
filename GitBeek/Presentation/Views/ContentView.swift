//
//  ContentView.swift
//  GitBeek
//
//  Main content view with tab navigation
//

import SwiftUI

/// Main content view with tab bar navigation
struct ContentView: View {
    // MARK: - Environment

    @Environment(AppRouter.self) private var router
    @Environment(SearchViewModel.self) private var searchViewModel

    // MARK: - Body

    var body: some View {
        @Bindable var routerBinding = router

        TabView(selection: $routerBinding.selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label(
                        AppRouter.Tab.home.title,
                        systemImage: router.selectedTab == .home
                            ? AppRouter.Tab.home.selectedIcon
                            : AppRouter.Tab.home.icon
                    )
                }
                .tag(AppRouter.Tab.home)

            // Search Tab
            SearchView(viewModel: searchViewModel)
                .tabItem {
                    Label(
                        AppRouter.Tab.search.title,
                        systemImage: router.selectedTab == .search
                            ? AppRouter.Tab.search.selectedIcon
                            : AppRouter.Tab.search.icon
                    )
                }
                .tag(AppRouter.Tab.search)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label(
                        AppRouter.Tab.profile.title,
                        systemImage: router.selectedTab == .profile
                            ? AppRouter.Tab.profile.selectedIcon
                            : AppRouter.Tab.profile.icon
                    )
                }
                .tag(AppRouter.Tab.profile)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppRouter())
        .environment(AuthViewModel(authRepository: PreviewContentMockAuthRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewContentMockUserRepository(),
            organizationRepository: PreviewContentMockOrganizationRepository()
        ))
}

private actor PreviewContentMockAuthRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}

private actor PreviewContentMockUserRepository: UserRepository {
    func getCurrentUser() async throws -> User { fatalError() }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewContentMockOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] { [] }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
