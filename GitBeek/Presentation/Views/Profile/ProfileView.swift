//
//  ProfileView.swift
//  GitBeek
//
//  User profile view with organization switcher
//

import SwiftUI
import SDWebImageSwiftUI

/// User profile view
struct ProfileView: View {
    // MARK: - Environment

    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel

    // MARK: - State

    @State private var showOrganizationPicker = false
    @State private var showLogoutConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // User section
                userSection

                // Organization section
                organizationSection

                // Settings section
                settingsSection

                // Account section
                accountSection
            }
            .navigationTitle("Profile")
            .refreshable {
                await profileViewModel.refresh()
            }
            .task {
                await profileViewModel.loadAll()
            }
            .sheet(isPresented: $showOrganizationPicker) {
                OrganizationPickerView()
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - User Section

    private var userSection: some View {
        Section {
            HStack(spacing: AppSpacing.md) {
                // Avatar
                userAvatar

                // User info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(profileViewModel.userName)
                        .font(AppTypography.headlineLarge)

                    if !profileViewModel.userEmail.isEmpty {
                        Text(profileViewModel.userEmail)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    @ViewBuilder
    private var userAvatar: some View {
        if let photoURL = profileViewModel.user?.photoURL {
            WebImage(url: photoURL) { image in
                image.resizable()
            } placeholder: {
                avatarPlaceholder
            }
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay {
                Text(profileViewModel.userInitials)
                    .font(AppTypography.titleLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Organization Section

    private var organizationSection: some View {
        Section("Organization") {
            Button {
                showOrganizationPicker = true
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profileViewModel.selectedOrganization?.title ?? "Select Organization")
                                .foregroundStyle(.primary)

                            Text("\(profileViewModel.organizationCount) organization\(profileViewModel.organizationCount == 1 ? "" : "s")")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "building.2")
                            .foregroundStyle(AppColors.primaryFallback)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section("Settings") {
            NavigationLink {
                SettingsView()
            } label: {
                Label("App Settings", systemImage: "gear")
            }

            NavigationLink {
                CacheSettingsView()
            } label: {
                Label("Storage & Cache", systemImage: "internaldrive")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            Link(destination: URL(string: "https://app.gitbook.com/account")!) {
                Label("Manage Account", systemImage: "person.crop.circle")
            }

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

// MARK: - Organization Picker View

struct OrganizationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProfileViewModel.self) private var profileViewModel

    var body: some View {
        NavigationStack {
            List(profileViewModel.organizations) { org in
                Button {
                    profileViewModel.selectOrganization(org)
                    dismiss()
                } label: {
                    HStack {
                        // Organization icon
                        Circle()
                            .fill(AppColors.primaryFallback.gradient)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(org.initials)
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(org.title)
                                .font(AppTypography.bodyLarge)
                                .foregroundStyle(.primary)

                            if let spacesCount = org.spacesCount {
                                Text("\(spacesCount) space\(spacesCount == 1 ? "" : "s")")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if org.id == profileViewModel.selectedOrganization?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.primaryFallback)
                        }
                    }
                }
            }
            .navigationTitle("Organizations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    var body: some View {
        List {
            Section("Appearance") {
                // Theme is automatic in iOS 26
                Label("Theme follows system", systemImage: "circle.lefthalf.filled")
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }

            Section {
                Link(destination: URL(string: "https://gitbook.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://gitbook.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Cache Settings View

struct CacheSettingsView: View {
    @State private var cacheSize: String = "Calculating..."

    var body: some View {
        List {
            Section {
                LabeledContent("Cache Size", value: cacheSize)
            } footer: {
                Text("Cache stores content for offline access and faster loading.")
            }

            Section {
                Button("Clear Cache", role: .destructive) {
                    Task { @MainActor in
                        CacheManager.shared.clearAllCaches()
                        await updateCacheSize()
                    }
                }
            }
        }
        .navigationTitle("Storage & Cache")
        .task {
            await updateCacheSize()
        }
    }

    @MainActor
    private func updateCacheSize() async {
        let stats = CacheManager.shared.getStats()
        cacheSize = CacheManager.formatBytes(stats.fileCacheSize)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AuthViewModel(authRepository: PreviewMockAuthRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewMockUserRepository(),
            organizationRepository: PreviewMockOrganizationRepository()
        ))
}

// Preview mocks
private actor PreviewMockAuthRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}

private actor PreviewMockUserRepository: UserRepository {
    func getCurrentUser() async throws -> User {
        User(from: CurrentUserDTO(object: "user", id: "1", displayName: "John Doe", email: "john@example.com", photoURL: nil, urls: nil))
    }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewMockOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] {
        [
            Organization(from: OrganizationDTO(object: "organization", id: "1", title: "Acme Inc", createdAt: nil, updatedAt: nil, urls: nil)),
            Organization(from: OrganizationDTO(object: "organization", id: "2", title: "GitBook", createdAt: nil, updatedAt: nil, urls: nil))
        ]
    }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
