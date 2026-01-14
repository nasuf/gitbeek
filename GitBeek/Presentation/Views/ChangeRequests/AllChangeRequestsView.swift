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
            // Loading state for current filter
            if viewModel.isLoading && viewModel.collectionGroups.isEmpty && viewModel.topLevelSpaceGroups.isEmpty {
                loadingView
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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading change requests...")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
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
