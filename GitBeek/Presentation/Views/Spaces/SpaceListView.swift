//
//  SpaceListView.swift
//  GitBeek
//
//  Hierarchical list of spaces with collections
//

import SwiftUI

/// View displaying spaces organized by collections
struct SpaceListView: View {
    // MARK: - Environment

    @Environment(AppRouter.self) private var router

    // MARK: - Properties

    let organizationId: String
    @State private var viewModel: SpaceListViewModel
    @State private var showCreateSheet = false
    @State private var showTrash = false

    // MARK: - Initialization

    init(organizationId: String, spaceRepository: SpaceRepository) {
        self.organizationId = organizationId
        self._viewModel = State(initialValue: SpaceListViewModel(spaceRepository: spaceRepository))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                if viewModel.isLoading && viewModel.allSpaces.isEmpty {
                    loadingView
                } else if viewModel.allSpaces.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .padding()
        }
        .navigationTitle("Spaces")
        .toolbar {
            toolbarContent
        }
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $viewModel.searchQuery, prompt: "Search spaces")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadSpaces(organizationId: organizationId)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSpaceSheet(
                viewModel: viewModel,
                organizationId: organizationId
            )
        }
        .sheet(isPresented: $showTrash) {
            TrashView(viewModel: viewModel)
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
                showCreateSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showTrash = true
                } label: {
                    Label("Trash", systemImage: "trash")
                }

                Divider()

                Button {
                    viewModel.viewMode = .hierarchy
                } label: {
                    Label {
                        Text("Hierarchy")
                    } icon: {
                        if viewModel.viewMode == .hierarchy {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    viewModel.viewMode = .flat
                } label: {
                    Label {
                        Text("All Spaces")
                    } icon: {
                        if viewModel.viewMode == .flat {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.showHierarchy {
            hierarchyView
        } else {
            flatView
        }

        // Stats footer
        statsFooter
    }

    // MARK: - Hierarchy View

    @ViewBuilder
    private var hierarchyView: some View {
        // Collections section
        if !viewModel.filteredCollections.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                sectionHeader("Collections")

                ForEach(viewModel.filteredCollections) { collection in
                    CollectionRowView(
                        collection: collection,
                        isExpanded: viewModel.isExpanded(collection.id) || viewModel.isSearching,
                        allCollections: viewModel.allCollections,
                        onToggle: {
                            viewModel.toggleCollection(id: collection.id)
                        },
                        onSpaceTap: { space in
                            router.navigate(to: .spaceDetail(spaceId: space.id))
                        },
                        onDelete: { space in
                            Task {
                                await viewModel.deleteSpace(id: space.id)
                            }
                        },
                        onMoveSpace: { space, parentId in
                            Task {
                                await viewModel.moveSpace(id: space.id, toCollectionId: parentId)
                            }
                        },
                        onRenameSpace: { space, title in
                            Task {
                                await viewModel.renameSpace(id: space.id, title: title)
                            }
                        },
                        onMoveCollection: { collectionId, parentId in
                            Task {
                                await viewModel.moveCollection(id: collectionId, toCollectionId: parentId)
                            }
                        },
                        onRenameCollection: { collectionId, title in
                            Task {
                                await viewModel.renameCollection(id: collectionId, title: title)
                            }
                        },
                        onDeleteCollection: { collectionId in
                            Task {
                                await viewModel.deleteCollection(id: collectionId)
                            }
                        },
                        isExpandedCheck: { id in
                            viewModel.isExpanded(id) || viewModel.isSearching
                        },
                        onToggleById: { id in
                            viewModel.toggleCollection(id: id)
                        }
                    )
                }
            }
        }

        // Top-level spaces section
        if !viewModel.filteredTopLevelSpaces.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                sectionHeader("Spaces")

                ForEach(viewModel.filteredTopLevelSpaces) { space in
                    SpaceRowView(
                        space: space,
                        collections: viewModel.allCollections,
                        onTap: {
                            router.navigate(to: .spaceDetail(spaceId: space.id))
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteSpace(id: space.id)
                            }
                        },
                        onMove: { parentId in
                            Task {
                                await viewModel.moveSpace(id: space.id, toCollectionId: parentId)
                            }
                        },
                        onRename: { title in
                            Task {
                                await viewModel.renameSpace(id: space.id, title: title)
                            }
                        }
                    )
                }
            }
        }

        // No results message
        if viewModel.isSearching && viewModel.filteredCollections.isEmpty && viewModel.filteredTopLevelSpaces.isEmpty {
            noSearchResultsView
        }
    }

    // MARK: - No Search Results

    private var noSearchResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No results for \"\(viewModel.searchQuery)\"")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Flat View

    @ViewBuilder
    private var flatView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("All Spaces")

            ForEach(viewModel.flatSpaces) { space in
                SpaceRowView(
                    space: space,
                    collections: viewModel.allCollections,
                    onTap: {
                        router.navigate(to: .spaceDetail(spaceId: space.id))
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteSpace(id: space.id)
                        }
                    },
                    onMove: { parentId in
                        Task {
                            await viewModel.moveSpace(id: space.id, toCollectionId: parentId)
                        }
                    },
                    onRename: { title in
                        Task {
                            await viewModel.renameSpace(id: space.id, title: title)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.headlineSmall)
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.top, AppSpacing.md)
    }

    // MARK: - Stats Footer

    private var statsFooter: some View {
        HStack {
            Text("\(viewModel.activeSpacesCount) space\(viewModel.activeSpacesCount == 1 ? "" : "s")")
            if viewModel.trashedCount > 0 {
                Text("•")
                Text("\(viewModel.trashedCount) in trash")
            }
        }
        .font(AppTypography.caption)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.lg)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Loading spaces...")
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
                Text("No Spaces Yet")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)

                Text("Create your first space to get started")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            GlassButton("Create Space", systemImage: "plus.circle") {
                showCreateSheet = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.huge)
    }
}
