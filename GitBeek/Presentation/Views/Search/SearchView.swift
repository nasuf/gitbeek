//
//  SearchView.swift
//  GitBeek
//
//  Search view for finding content
//

import SwiftUI

/// Search view for finding spaces and content
struct SearchView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SearchViewModel
    @Environment(AppRouter.self) private var router

    // MARK: - State

    @State private var showScopeSheet = false

    // MARK: - Body

    var body: some View {
        @Bindable var routerBinding = router

        NavigationStack(path: Binding(
            get: { router.path },
            set: { router.path = $0 }
        )) {
            ZStack {
                List {
                    if viewModel.isSearching {
                        // Search suggestions while typing
                        if !viewModel.searchSuggestions.isEmpty {
                            searchSuggestionsSection
                        }

                        // Search results
                        searchResultsSection
                    } else {
                        // Search history and quick access
                        searchHistorySection
                        quickAccessSection
                        recentPagesPreviewSection
                        favoritesPreviewSection
                    }
                }
                .listStyle(.insetGrouped)

                // Loading overlay
                if viewModel.isLoading {
                    loadingView
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchQuery,
                prompt: searchPrompt
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    scopeButton
                }
            }
            .sheet(isPresented: $showScopeSheet) {
                scopeSheet
            }
            .navigationDestinations()
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Search Results Section

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.hasResults {
            Section {
                ForEach(viewModel.searchResults) { result in
                    searchResultRow(result)
                }
            } header: {
                Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
            }
        } else if viewModel.showEmptyState {
            Section {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your search or change the scope")
                )
            }
        } else if viewModel.hasError {
            Section {
                ContentUnavailableView(
                    "Search Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "An error occurred")
                )
            }
        }
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ result: SearchResult) -> some View {
        Button {
            handleResultTap(result)
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
                        .fill(AppColors.primaryFallback.opacity(0.1))
                        .frame(width: 44, height: 44)

                    if let emoji = result.emoji {
                        Text(verbatim: emoji)
                            .font(.title3)
                    } else {
                        Image(systemName: "doc.text")
                            .font(.title3)
                            .foregroundStyle(AppColors.primaryFallback)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(verbatim: result.title.isEmpty ? "Untitled" : result.title)
                        .font(AppTypography.bodyMedium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    // Path info
                    if !result.path.isEmpty {
                        Text(verbatim: result.path)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Excerpt/snippet
                    if let snippet = result.snippet {
                        Text(verbatim: snippet)
                            .font(AppTypography.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Suggestions Section

    @ViewBuilder
    private var searchSuggestionsSection: some View {
        Section("Suggestions") {
            ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                Button {
                    viewModel.searchQuery = suggestion
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        Text(verbatim: suggestion)
                            .font(AppTypography.bodyMedium)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Search History Section

    @ViewBuilder
    private var searchHistorySection: some View {
        if !viewModel.searchHistory.isEmpty {
            Section {
                ForEach(viewModel.searchHistory) { item in
                    searchHistoryRow(item)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = viewModel.searchHistory[index]
                        Task {
                            await viewModel.removeHistoryItem(item)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recent Searches")
                    Spacer()
                    Button("Clear") {
                        Task {
                            await viewModel.clearSearchHistory()
                        }
                    }
                    .font(AppTypography.captionSmall)
                }
            }
        }
    }

    private func searchHistoryRow(_ item: SearchHistoryItem) -> some View {
        Button {
            viewModel.selectHistoryItem(item)
        } label: {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)

                Text(verbatim: item.query)
                    .font(AppTypography.bodyMedium)

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        Section("Quick Access") {
            NavigationLink {
                RecentPagesView(viewModel: viewModel)
            } label: {
                HStack {
                    Label("Recent Pages", systemImage: "clock")
                    Spacer()
                    if !viewModel.recentPages.isEmpty {
                        Text("\(viewModel.recentPages.count)")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                FavoritesView(viewModel: viewModel)
            } label: {
                HStack {
                    Label("Favorites", systemImage: "star")
                    Spacer()
                    if !viewModel.favoritePages.isEmpty {
                        Text("\(viewModel.favoritePages.count)")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Recent Pages Preview Section

    @ViewBuilder
    private var recentPagesPreviewSection: some View {
        if !viewModel.recentPages.isEmpty {
            Section {
                ForEach(viewModel.recentPages.prefix(3)) { page in
                    recentPagePreviewRow(page)
                }

                if viewModel.recentPages.count > 3 {
                    NavigationLink {
                        RecentPagesView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("See All Recent Pages")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.primaryFallback)
                            Spacer()
                            Text("\(viewModel.recentPages.count)")
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Recently Viewed")
            }
        }
    }

    private func recentPagePreviewRow(_ page: RecentPage) -> some View {
        Button {
            router.navigate(to: .pageDetail(spaceId: page.spaceId, pageId: page.id))
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let emoji = page.emoji {
                    Text(verbatim: emoji)
                        .font(.title3)
                } else {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: page.title.isEmpty ? "Untitled" : page.title)
                        .font(AppTypography.bodyMedium)
                        .lineLimit(1)

                    Text(formatRelativeDate(page.lastVisited))
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Favorites Preview Section

    @ViewBuilder
    private var favoritesPreviewSection: some View {
        if !viewModel.favoritePages.isEmpty {
            Section {
                ForEach(viewModel.favoritePages.prefix(3)) { page in
                    favoritePagePreviewRow(page)
                }

                if viewModel.favoritePages.count > 3 {
                    NavigationLink {
                        FavoritesView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("See All Favorites")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.primaryFallback)
                            Spacer()
                            Text("\(viewModel.favoritePages.count)")
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Favorites")
            }
        }
    }

    private func favoritePagePreviewRow(_ page: FavoritePage) -> some View {
        Button {
            router.navigate(to: .pageDetail(spaceId: page.spaceId, pageId: page.id))
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let emoji = page.emoji {
                    Text(verbatim: emoji)
                        .font(.title3)
                } else {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                }

                Text(verbatim: page.title.isEmpty ? "Untitled" : page.title)
                    .font(AppTypography.bodyMedium)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Scope Button

    private var scopeButton: some View {
        Button {
            showScopeSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.searchScope.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(scopeButtonTitle)
                    .font(AppTypography.captionSmall)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var scopeButtonTitle: String {
        switch viewModel.searchScope {
        case .organization:
            return "All"
        case .currentSpace:
            return viewModel.selectedSpaceName
        }
    }

    // MARK: - Space Row

    private func spaceRow(_ space: Space) -> some View {
        Button {
            viewModel.selectSpace(space)
            showScopeSheet = false
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Space icon/emoji
                if let emoji = space.emoji {
                    Text(verbatim: emoji)
                        .font(.title3)
                } else {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(.secondary)
                }

                Text(verbatim: space.title)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.searchScope == .currentSpace && viewModel.spaceId == space.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.primaryFallback)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scope Sheet

    private var scopeSheet: some View {
        NavigationStack {
            List {
                // All Organizations option
                Section {
                    Button {
                        viewModel.searchScope = .organization
                        showScopeSheet = false
                        Task {
                            await viewModel.performSearch()
                        }
                    } label: {
                        HStack {
                            Label("All", systemImage: "globe")
                            Spacer()
                            if viewModel.searchScope == .organization {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.primaryFallback)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Search Scope")
                } footer: {
                    Text("Search across all spaces in your organization")
                }

                // Individual spaces
                if !viewModel.availableSpaces.isEmpty {
                    Section {
                        ForEach(viewModel.availableSpaces) { space in
                            spaceRow(space)
                        }
                    } header: {
                        Text("Spaces")
                    } footer: {
                        Text("Search within a specific space")
                    }
                }
            }
            .navigationTitle("Search Scope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showScopeSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Searching...")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Computed Properties

    private var searchPrompt: String {
        switch viewModel.searchScope {
        case .organization:
            return "Search across all spaces"
        case .currentSpace:
            return "Search in current space"
        }
    }

    // MARK: - Actions

    private func handleResultTap(_ result: SearchResult) {
        // Navigate to the result
        if !result.spaceId.isEmpty {
            router.navigate(to: .pageDetail(spaceId: result.spaceId, pageId: result.pageId))
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView(viewModel: DependencyContainer.shared.searchViewModel)
        .environment(DependencyContainer.shared.appRouter)
}
