//
//  AllChangeRequestsView.swift
//  GitBeek
//
//  View for displaying all change requests across all spaces
//

import SwiftUI

/// View for displaying all change requests across all spaces
struct AllChangeRequestsView: View {
    // MARK: - Properties

    @Environment(AppRouter.self) private var router
    @Bindable var viewModel: AllChangeRequestsViewModel

    // MARK: - Initialization

    init(viewModel: AllChangeRequestsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Content
            if viewModel.changeRequests.isEmpty && !viewModel.isLoading {
                ContentUnavailableView {
                    Label("No Change Requests", systemImage: "doc.text")
                } description: {
                    Text("There are no change requests across your spaces.")
                }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        // Liquid Glass Filter Bar
                        LiquidGlassFilterBar(
                            options: [
                                FilterOption(title: "All", count: viewModel.changeRequests.count, value: nil as ChangeRequestStatus?, isLoading: viewModel.isLoading && !viewModel.hasLoadedData),
                                FilterOption(title: "Open", count: viewModel.openCount, value: ChangeRequestStatus.open, isLoading: viewModel.isLoading && !viewModel.hasLoadedData),
                                FilterOption(title: "Draft", count: viewModel.draftCount, value: ChangeRequestStatus.draft, isLoading: viewModel.isLoading && !viewModel.hasLoadedData),
                                FilterOption(title: "Merged", count: viewModel.mergedCount, value: ChangeRequestStatus.merged, isLoading: viewModel.isLoading && !viewModel.hasLoadedData),
                                FilterOption(title: "Archived", count: viewModel.archivedCount, value: ChangeRequestStatus.archived, isLoading: viewModel.isLoading && !viewModel.hasLoadedData)
                            ],
                            selectedValue: $viewModel.selectedStatus,
                            onFilterTap: nil  // No action needed - just switch filter
                        )
                        .padding(.top, AppSpacing.sm)

                        // Hierarchical change request list
                        hierarchicalContent
                            .padding(.horizontal)
                    }
                    .padding(.bottom, AppSpacing.lg)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("All Change Requests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeRequestStatusDidChange)) { notification in
            if let change = notification.object as? ChangeRequestStatusChange {
                viewModel.updateLocalStatus(changeRequestId: change.changeRequestId, newStatus: change.newStatus)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Hierarchical Content

    @ViewBuilder
    private var hierarchicalContent: some View {
        LazyVStack(spacing: AppSpacing.md) {
            // Skeleton loading when current filter has no data yet
            if viewModel.isLoading && viewModel.collectionGroups.isEmpty && viewModel.topLevelSpaceGroups.isEmpty {
                skeletonLoadingView
            } else {
                // Collections with change requests
                if !viewModel.collectionGroups.isEmpty {
                    ForEach(viewModel.collectionGroups) { group in
                        ChangeRequestCollectionRow(
                            collection: group.collection,
                            changeRequests: group.changeRequests,
                            isExpanded: viewModel.isExpanded(group.collection.id),
                            displayMode: viewModel.getDisplayMode(for: group.collection.id),
                            onToggle: {
                                viewModel.toggleCollection(group.collection.id)
                            },
                            onToggleDisplayMode: {
                                viewModel.toggleDisplayMode(for: group.collection.id)
                            },
                            onChangeRequestTap: { space, cr in
                                router.navigate(to: .changeRequestDetail(
                                    spaceId: space.id,
                                    changeRequestId: cr.id
                                ))
                            }
                        )
                    }
                }

                // Top-level spaces with change requests
                if !viewModel.topLevelSpaceGroups.isEmpty {
                    ForEach(viewModel.topLevelSpaceGroups) { group in
                        ChangeRequestSpaceGroupRow(
                            space: group.space,
                            changeRequests: group.changeRequests,
                            onChangeRequestTap: { cr in
                                router.navigate(to: .changeRequestDetail(
                                    spaceId: group.space.id,
                                    changeRequestId: cr.id
                                ))
                            }
                        )
                    }
                }

                // No results message (only when not loading)
                if !viewModel.isLoading && viewModel.collectionGroups.isEmpty && viewModel.topLevelSpaceGroups.isEmpty {
                    noResultsView
                }
            }
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No change requests match the current filter")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Skeleton Loading View

    private var skeletonLoadingView: some View {
        VStack(spacing: AppSpacing.md) {
            // Multiple skeleton groups to fill the screen
            ForEach(0..<3, id: \.self) { _ in
                spaceGroupSkeletonView
            }
        }
    }

    private var spaceGroupSkeletonView: some View {
        VStack(spacing: AppSpacing.sm) {
            // Space header skeleton
            HStack(spacing: AppSpacing.md) {
                // Icon placeholder
                SkeletonView()
                    .frame(width: 44, height: 44)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView()
                        .frame(width: 140, height: 18)
                    SkeletonView()
                        .frame(width: 100, height: 14)
                }

                Spacer()

                // Count badge
                SkeletonView()
                    .frame(width: 30, height: 24)
            }

            // CR rows skeleton
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: AppSpacing.sm) {
                    SkeletonView()
                        .frame(width: 50, height: 22)
                    SkeletonView()
                        .frame(width: 60, height: 22)
                    Spacer()
                    SkeletonView()
                        .frame(width: 80, height: 16)
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

}

// MARK: - Preview

#Preview("All Change Requests") {
    NavigationStack {
        AllChangeRequestsView(
            viewModel: DependencyContainer.shared.allChangeRequestsViewModel
        )
    }
}
