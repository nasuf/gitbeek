//
//  SpaceDetailView.swift
//  GitBeek
//
//  Space detail view with content tree navigation
//

import SwiftUI

/// View displaying space details and content tree
struct SpaceDetailView: View {
    // MARK: - Environment

    @Environment(AppRouter.self) private var router

    // MARK: - Properties

    let spaceId: String
    @State private var viewModel: SpaceDetailViewModel
    @State private var showSettings = false

    // MARK: - Initialization

    init(spaceId: String, spaceRepository: SpaceRepository, pageRepository: PageRepository) {
        self.spaceId = spaceId
        self._viewModel = State(initialValue: SpaceDetailViewModel(
            spaceRepository: spaceRepository,
            pageRepository: pageRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                if viewModel.isLoading && viewModel.contentTree.isEmpty {
                    loadingView
                } else if viewModel.contentTree.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.displayTitle)
        .searchable(text: $viewModel.searchQuery, prompt: "Search pages")
        .toolbar {
            toolbarContent
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadAll(spaceId: spaceId)
        }
        .sheet(isPresented: $showSettings) {
            if let space = viewModel.space {
                SpaceSettingsView(
                    space: space,
                    onSave: { title, emoji, visibility in
                        Task {
                            try await viewModel.updateSpace(
                                title: title,
                                emoji: emoji,
                                visibility: visibility
                            )
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    router.navigate(to: .changeRequestList(spaceId: spaceId))
                } label: {
                    Label("Change Requests", systemImage: "arrow.triangle.branch")
                }

                Divider()

                Button {
                    viewModel.expandAll()
                } label: {
                    Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                }

                Button {
                    viewModel.collapseAll()
                } label: {
                    Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        // Content tree
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Pages", count: viewModel.totalPageCount)

            PageTreeView(
                pages: viewModel.filteredPages,
                expandedIds: $viewModel.expandedPageIds,
                onPageTap: { page in
                    router.navigate(to: .pageDetail(spaceId: spaceId, pageId: page.id))
                }
            )
        }
    }

    // MARK: - Space Header

    private func spaceHeader(_ space: Space) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                // Space icon
                Group {
                    if let emoji = space.emoji {
                        Text(emoji)
                            .font(.system(size: 40))
                    } else {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppColors.primaryFallback)
                    }
                }
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(space.title)
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)

                    HStack(spacing: AppSpacing.sm) {
                        // Visibility badge
                        HStack(spacing: 4) {
                            Image(systemName: space.visibility.icon)
                            Text(space.visibility.displayName)
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                        // Page count
                        Text("•")
                            .foregroundStyle(.tertiary)

                        Text("\(viewModel.totalPageCount) pages")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.headlineSmall)
                .foregroundStyle(.secondary)

            if let count = count {
                Text("(\(count))")
                    .font(AppTypography.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Loading content...")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.huge)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: AppSpacing.sm) {
                Text("No Pages Yet")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)

                Text("This space doesn't have any content yet")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.huge)
    }
}
