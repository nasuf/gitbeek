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
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Organization header
                    organizationHeader

                    // Quick actions
                    quickActionsSection

                    // Recent spaces (placeholder)
                    recentSpacesSection

                    // All spaces button
                    allSpacesButton
                }
                .padding()
            }
            .navigationTitle("Home")
            .refreshable {
                await profileViewModel.refresh()
            }
            .task {
                await profileViewModel.loadAll()
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showOrganizationPicker) {
                OrganizationPickerView()
            }
            .sheet(isPresented: $showCreateSpace) {
                if let viewModel = spaceListViewModel,
                   let orgId = profileViewModel.selectedOrganization?.id {
                    CreateSpaceSheet(
                        viewModel: viewModel,
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
                    if let orgId = profileViewModel.selectedOrganization?.id {
                        spaceListViewModel = SpaceListViewModel(
                            spaceRepository: DependencyContainer.shared.spaceRepository
                        )
                        Task {
                            await spaceListViewModel?.loadSpaces(organizationId: orgId)
                        }
                        showCreateSpace = true
                    }
                }

                QuickActionButton(
                    title: "Recent",
                    icon: "clock",
                    color: AppColors.secondaryFallback
                ) {
                    // TODO: Show recent items
                }
            }
        }
    }

    // MARK: - Recent Spaces

    private var recentSpacesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Spaces")
                    .font(AppTypography.headlineLarge)

                Spacer()

                Button("See All") {
                    if let orgId = profileViewModel.selectedOrganization?.id {
                        router.navigate(to: .spaceList(organizationId: orgId))
                    }
                }
                .font(AppTypography.bodyMedium)
            }
            .padding(.horizontal, AppSpacing.sm)

            // Placeholder for recent spaces
            VStack(spacing: AppSpacing.sm) {
                ForEach(0..<3) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                                .frame(width: 150, height: 16)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                                .frame(width: 100, height: 12)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.sm))
                }
            }

            Text("Spaces will appear here once you start browsing")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: - All Spaces Button

    private var allSpacesButton: some View {
        GlassButton("View All Spaces", systemImage: "square.grid.2x2") {
            if let orgId = profileViewModel.selectedOrganization?.id {
                router.navigate(to: .spaceList(organizationId: orgId))
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .spaceList(let organizationId):
            SpaceListView(
                organizationId: organizationId,
                spaceRepository: DependencyContainer.shared.spaceRepository
            )

        case .spaceDetail(let spaceId):
            Text("Space: \(spaceId)")
                .navigationTitle("Space")

        case .trash(let organizationId):
            // Trash is handled as a sheet in SpaceListView
            Text("Trash for \(organizationId)")

        default:
            EmptyView()
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

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
        }
        .buttonStyle(.plain)
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
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
