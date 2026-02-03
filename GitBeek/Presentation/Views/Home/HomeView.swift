//
//  HomeView.swift
//  GitBeek
//
//  Main home view with organizations and recent spaces
//

import SwiftUI

/// Home view showing organizations and recent activity
struct HomeView: View {
    // MARK: - Environment

    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(AppRouter.self) private var router

    // MARK: - State

    @State private var showOrganizationPicker = false
    @State private var showCreateSpace = false
    @State private var spaceListViewModel: SpaceListViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Binding(
            get: { router.path },
            set: { router.path = $0 }
        )) {
            Group {
                if recentSpaces.isEmpty {
                    // Fixed layout when no recent spaces - no scroll
                    emptyStateLayout
                } else {
                    // Scrollable layout when there are recent spaces
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            organizationHeader
                            quickActionsSection
                            recentSpacesSection
                            allSpacesButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Home")
            .refreshable {
                await profileViewModel.refresh()
            }
            .task {
                await profileViewModel.loadAll()
            }
            .navigationDestinations()
            .sheet(isPresented: $showOrganizationPicker) {
                OrganizationPickerView()
            }
            .sheet(isPresented: $showCreateSpace) {
                if let orgId = profileViewModel.selectedOrganization?.id {
                    CreateSpaceSheet(
                        viewModel: spaceListViewModel ?? SpaceListViewModel(spaceRepository: DependencyContainer.shared.spaceRepository),
                        organizationId: orgId
                    )
                }
            }
        }
    }

    // MARK: - Organization Header

    private var organizationHeader: some View {
        VStack(spacing: AppSpacing.md) {
            if let org = profileViewModel.selectedOrganization {
                HStack {
                    // Organization avatar
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
                            Text(org.initials)
                                .font(AppTypography.headlineLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(org.title)
                            .font(AppTypography.titleMedium)
                            .fontWeight(.semibold)

                        if let spacesCount = org.spacesCount {
                            Text("\(spacesCount) space\(spacesCount == 1 ? "" : "s")")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Switch organization button
                    Button {
                        showOrganizationPicker = true
                    } label: {
                        Image(systemName: "chevron.down.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
            } else {
                // Loading state
                HStack {
                    ProgressView()
                    Text("Loading organization...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(AppTypography.headlineLarge)
                .padding(.horizontal, AppSpacing.sm)

            HStack(spacing: AppSpacing.md) {
                QuickActionButton(
                    title: "Search",
                    icon: "magnifyingglass",
                    color: AppColors.primaryFallback
                ) {
                    router.switchTab(to: .search)
                }

                QuickActionButton(
                    title: "New Space",
                    icon: "plus.circle",
                    color: AppColors.success
                ) {
                    guard profileViewModel.selectedOrganization?.id != nil else {
                        #if DEBUG
                        print("[HomeView] Cannot create space: No organization selected")
                        #endif
                        return
                    }
                    if spaceListViewModel == nil {
                        spaceListViewModel = SpaceListViewModel(
                            spaceRepository: DependencyContainer.shared.spaceRepository
                        )
                    }
                    showCreateSpace = true
                }

                QuickActionButton(
                    title: "Change Requests",
                    icon: "arrow.triangle.branch",
                    color: .purple
                ) {
                    print("🟡 点击了 Change Requests 按钮")
                    router.navigate(to: .allChangeRequests)
                    print("🟡 已调用 router.navigate(to: .allChangeRequests)")
                }
            }
        }
    }

    // MARK: - Recent Spaces

    private var recentSpaces: [RecentSpace] {
        RecentSpacesManager.shared.getRecentSpaces(organizationId: profileViewModel.selectedOrganization?.id)
    }

    // MARK: - Empty State Layout

    private var emptyStateLayout: some View {
        VStack(spacing: 0) {
            // Top section: org header + quick actions
            VStack(spacing: AppSpacing.xl) {
                organizationHeader
                quickActionsSection

                // Recent Spaces header
                HStack {
                    Text("Recent Spaces")
                        .font(AppTypography.headlineLarge)

                    Spacer()

                    Button("See All") {
                        guard let orgId = profileViewModel.selectedOrganization?.id else { return }
                        router.navigate(to: .spaceList(organizationId: orgId))
                    }
                    .font(AppTypography.bodyMedium)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, AppSpacing.sm)
            }
            .padding([.horizontal, .top])

            // Middle section: empty state (expands to fill)
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)

                Text("No recent spaces")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)

                Text("Spaces will appear here once you start browsing")
                    .font(AppTypography.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            // Bottom section: View All Spaces button
            allSpacesButton
                .padding()
        }
    }

    private var recentSpacesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Spaces")
                    .font(AppTypography.headlineLarge)

                Spacer()

                Button("See All") {
                    guard let orgId = profileViewModel.selectedOrganization?.id else {
                        #if DEBUG
                        print("[HomeView] Cannot navigate to space list: No organization selected")
                        #endif
                        return
                    }
                    router.navigate(to: .spaceList(organizationId: orgId))
                }
                .font(AppTypography.bodyMedium)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, AppSpacing.sm)

            if recentSpaces.isEmpty {
                // Empty state
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)

                    Text("No recent spaces")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.secondary)

                    Text("Spaces will appear here once you start browsing")
                        .font(AppTypography.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                // Recent spaces list
                VStack(spacing: AppSpacing.sm) {
                    ForEach(recentSpaces.prefix(5)) { space in
                        Button {
                            router.navigate(to: .spaceDetail(spaceId: space.id))
                        } label: {
                            RecentSpaceRow(space: space)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - All Spaces Button

    private var allSpacesButton: some View {
        GlassButton("View All Spaces", systemImage: "square.grid.2x2") {
            guard let orgId = profileViewModel.selectedOrganization?.id else {
                #if DEBUG
                print("[HomeView] Cannot view all spaces: No organization selected")
                #endif
                return
            }
            router.navigate(to: .spaceList(organizationId: orgId))
        }
    }

    // MARK: - Destination View

}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(ProfileViewModel(
            userRepository: PreviewMockUserRepository(),
            organizationRepository: PreviewMockOrganizationRepository()
        ))
        .environment(AppRouter())
}

private actor PreviewMockUserRepository: UserRepository {
    func getCurrentUser() async throws -> User { fatalError() }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewMockOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] { [] }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func listMembers(organizationId: String) async throws -> [UserReference] { [] }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}

// MARK: - Recent Space Row

private struct RecentSpaceRow: View {
    let space: RecentSpace

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Space icon
            Group {
                if let emoji = space.emoji {
                    Text(emoji)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.primaryFallback)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(space.title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: space.visibilityIcon)
                        .font(.caption2)
                    Text(relativeTime(from: space.lastVisited))
                        .font(AppTypography.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
