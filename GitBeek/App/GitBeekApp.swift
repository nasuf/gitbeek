//
//  GitBeekApp.swift
//  GitBeek
//
//  Created for GitBook iOS App
//

import SwiftUI

@main
struct GitBeekApp: App {
    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container.authViewModel)
                .environment(container.profileViewModel)
                .environment(container.appRouter)
        }
    }
}

/// Root view that handles authentication state
struct RootView: View {
    // MARK: - Environment

    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - Body

    var body: some View {
        GlassEffectContainer {
            Group {
                switch authViewModel.authState {
                case .unknown:
                    // Loading state - checking auth
                    loadingView

                case .authenticated:
                    // Main content
                    ContentView()

                case .unauthenticated:
                    // Login screen
                    LoginView()
                }
            }
        }
        .task {
            await authViewModel.checkAuthState()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading...")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    RootView()
        .environment(AuthViewModel(authRepository: PreviewAuthenticatedRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewUserRepository(),
            organizationRepository: PreviewOrganizationRepository()
        ))
        .environment(AppRouter())
}

#Preview("Unauthenticated") {
    RootView()
        .environment(AuthViewModel(authRepository: PreviewUnauthenticatedRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewUserRepository(),
            organizationRepository: PreviewOrganizationRepository()
        ))
        .environment(AppRouter())
}

// Preview mocks
private actor PreviewAuthenticatedRepository: AuthRepository {
    var authState: AuthState {
        .authenticated(User(from: CurrentUserDTO(
            object: "user",
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            photoURL: nil,
            urls: nil
        )))
    }
    var isAuthenticated: Bool { true }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { "token" }
}

private actor PreviewUnauthenticatedRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}

private actor PreviewUserRepository: UserRepository {
    func getCurrentUser() async throws -> User {
        User(from: CurrentUserDTO(
            object: "user",
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            photoURL: nil,
            urls: nil
        ))
    }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] {
        [
            Organization(from: OrganizationDTO(
                object: "organization",
                id: "1",
                title: "Acme Inc",
                createdAt: nil,
                updatedAt: nil,
                urls: nil
            ))
        ]
    }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
