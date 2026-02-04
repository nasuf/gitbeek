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
            .alert(
                "Sign Out",
                isPresented: $showLogoutConfirmation
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
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

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("fontScale") private var fontScale: FontScale = .default
    @AppStorage("codeTheme") private var codeTheme: CodeHighlightTheme = .xcode

    @State private var showReadingSettings = false

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.displayName, systemImage: theme.icon)
                            .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Reading") {
                Button {
                    showReadingSettings = true
                } label: {
                    HStack {
                        Text("Reading Settings")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(fontScale.displayName) · \(codeTheme.displayName)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
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
        .sheet(isPresented: $showReadingSettings) {
            ReadingSettingsSheet()
        }
    }
}

// MARK: - Cache Settings View

struct CacheSettingsView: View {
    @State private var stats: CacheManager.CacheStats?
    @State private var isLoading = true
    @State private var showClearAllConfirmation = false
    @State private var showClearImagesConfirmation = false
    @State private var showClearContentConfirmation = false
    @State private var showClearStaleConfirmation = false

    var body: some View {
        List {
            // Storage overview section
            storageOverviewSection

            // Detailed breakdown section
            if let stats = stats {
                detailedBreakdownSection(stats)
            }

            // Cache actions section
            cacheActionsSection
        }
        .navigationTitle("Storage & Cache")
        .task {
            await refreshStats()
        }
        .refreshable {
            await refreshStats()
        }
        // Clear All confirmation
        .alert("Clear All Cache", isPresented: $showClearAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                Task { @MainActor in
                    CacheManager.shared.clearAllCaches()
                    await refreshStats()
                }
            }
        } message: {
            Text("This will delete all cached data including images, pages, and offline content. You'll need to reload data when online.")
        }
        // Clear Images confirmation
        .alert("Clear Image Cache", isPresented: $showClearImagesConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Images", role: .destructive) {
                Task { @MainActor in
                    CacheManager.shared.clearImageCache()
                    await refreshStats()
                }
            }
        } message: {
            Text("This will delete all cached images. Images will be re-downloaded when needed.")
        }
        // Clear Content confirmation
        .alert("Clear Content Cache", isPresented: $showClearContentConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Content", role: .destructive) {
                Task { @MainActor in
                    CacheManager.shared.clearContentCache()
                    await refreshStats()
                }
            }
        } message: {
            Text("This will delete all cached organizations, spaces, and pages. Data will be refreshed from the server.")
        }
        // Clear Stale confirmation
        .alert("Clear Stale Data", isPresented: $showClearStaleConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Stale", role: .destructive) {
                Task { @MainActor in
                    CacheManager.shared.clearStaleCaches(maxAge: 86400)
                    await refreshStats()
                }
            }
        } message: {
            Text("This will delete cached data older than 24 hours while keeping recent items.")
        }
    }

    // MARK: - Storage Overview Section

    private var storageOverviewSection: some View {
        Section {
            HStack {
                // Storage icon with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "externaldrive.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Cache Size")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.secondary)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let stats = stats {
                        Text(CacheManager.formatBytes(stats.totalSize))
                            .font(AppTypography.titleLarge)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(AppTypography.titleLarge)
                    }
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.xs)
        } footer: {
            Text("Cache stores content for offline access and faster loading. Clearing cache will not affect your account or bookmarks.")
        }
    }

    // MARK: - Detailed Breakdown Section

    private func detailedBreakdownSection(_ stats: CacheManager.CacheStats) -> some View {
        Section("Storage Breakdown") {
            // Image cache (SDWebImage + our cache)
            CacheItemRow(
                icon: "photo.fill",
                iconColor: .orange,
                title: "Images",
                subtitle: "Downloaded images from pages",
                size: stats.totalImageCacheSize
            )

            // Content cache (SwiftData)
            CacheItemRow(
                icon: "doc.text.fill",
                iconColor: .blue,
                title: "Content",
                subtitle: "\(stats.organizationCount) orgs · \(stats.spaceCount) spaces · \(stats.pageCount) pages",
                size: stats.swiftDataSize
            )

            // Other files
            let otherSize = stats.fileCacheSize - stats.imageCacheSize
            if otherSize > 0 {
                CacheItemRow(
                    icon: "folder.fill",
                    iconColor: .gray,
                    title: "Other Files",
                    subtitle: "\(stats.fileCacheCount - stats.imageCacheCount) files",
                    size: otherSize
                )
            }
        }
    }

    // MARK: - Cache Actions Section

    private var cacheActionsSection: some View {
        Section("Manage Cache") {
            // Clear stale data (gentle option)
            Button {
                showClearStaleConfirmation = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Stale Data")
                        Text("Remove data older than 24 hours")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.orange)
                }
            }
            .tint(.primary)

            // Clear images only
            Button {
                showClearImagesConfirmation = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Image Cache")
                        Text("Free up space by removing cached images")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "photo.stack")
                        .foregroundStyle(.orange)
                }
            }
            .tint(.primary)

            // Clear content only
            Button {
                showClearContentConfirmation = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Content Cache")
                        Text("Remove cached organizations, spaces, and pages")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.blue)
                }
            }
            .tint(.primary)

            // Clear all (destructive)
            Button(role: .destructive) {
                showClearAllConfirmation = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear All Cache")
                        Text("Remove all cached data")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - Helpers

    @MainActor
    private func refreshStats() async {
        isLoading = true
        // Small delay to show loading state
        try? await Task.sleep(for: .milliseconds(300))
        stats = CacheManager.shared.getStats()
        isLoading = false
    }
}

// MARK: - Cache Item Row

private struct CacheItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let size: Int64

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyLarge)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CacheManager.formatBytes(size))
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
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
    func listMembers(organizationId: String) async throws -> [UserReference] { [] }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
