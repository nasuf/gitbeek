//
//  PageDetailView.swift
//  GitBeek
//
//  Page detail view with markdown content
//

import SwiftUI

/// View displaying page content with markdown rendering
struct PageDetailView: View {
    // MARK: - Environment

    @Environment(AppRouter.self) private var router

    // MARK: - Properties

    let spaceId: String
    let pageId: String
    @State private var viewModel: PageDetailViewModel
    @State private var isFavorite = false
    @State private var showReadingSettings = false

    private let recentPagesManager = RecentPagesManager.shared

    // MARK: - Initialization

    init(spaceId: String, pageId: String, pageRepository: PageRepository) {
        self.spaceId = spaceId
        self.pageId = pageId
        self._viewModel = State(initialValue: PageDetailViewModel(pageRepository: pageRepository))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                if viewModel.isLoading && viewModel.page == nil {
                    loadingView
                } else if let page = viewModel.page {
                    contentView(page)
                } else if viewModel.hasError {
                    errorView
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .toolbar(.hidden, for: .tabBar)
        .refreshable {
            await viewModel.refresh(spaceId: spaceId, pageId: pageId)
        }
        .task {
            await viewModel.loadPage(spaceId: spaceId, pageId: pageId)
            updateFavoriteState()
        }
        .onChange(of: viewModel.page) { _, _ in
            updateFavoriteState()
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        .sheet(isPresented: $showReadingSettings) {
            ReadingSettingsSheet()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Favorite button
        ToolbarItem(placement: .primaryAction) {
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .primary)
            }
        }

        // More menu
        ToolbarItem(placement: .primaryAction) {
            Menu {
                // Reading settings
                Button {
                    showReadingSettings = true
                } label: {
                    Label("Reading Settings", systemImage: "textformat.size")
                }

                Divider()

                // Share
                Button {
                    // TODO: Share page
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                // Open in browser
                Button {
                    // TODO: Open in browser
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Actions

    private func updateFavoriteState() {
        guard let page = viewModel.page else { return }
        isFavorite = recentPagesManager.isFavorite(id: page.id, spaceId: spaceId)
    }

    private func toggleFavorite() {
        guard let page = viewModel.page else { return }

        let favorite = FavoritePage(from: page, spaceId: spaceId)
        recentPagesManager.toggleFavorite(favorite)
        updateFavoriteState()

        HapticFeedback.selection()
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(_ page: Page) -> some View {
        // Breadcrumb navigation
        if !viewModel.breadcrumbs.isEmpty {
            BreadcrumbNavigationView(
                items: viewModel.breadcrumbs,
                onItemTap: { item in
                    router.navigate(to: .pageDetail(spaceId: spaceId, pageId: item.id))
                }
            )
        }

        // Markdown content
        if viewModel.hasMarkdown {
            markdownContent(viewModel.markdown, title: page.title)
        } else {
            emptyContentView
        }

        // Child pages section
        if viewModel.hasChildren {
            childPagesSection
        }
    }

    // MARK: - Page Header

    private func pageHeader(_ page: Page) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                // Page icon
                Group {
                    if let emoji = page.emoji {
                        Text(emoji)
                            .font(.system(size: 32))
                    } else {
                        Image(systemName: page.type.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(AppColors.primaryFallback)
                    }
                }
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title)
                        .font(AppTypography.titleLarge)
                        .fontWeight(.bold)

                    if let description = page.description, !description.isEmpty {
                        Text(description)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
    }

    // MARK: - Markdown Content

    private func markdownContent(_ markdown: String, title: String) -> some View {
        MarkdownContentView(markdown: markdown, titleToSkip: title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
    }

    // MARK: - Empty Content

    private var emptyContentView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No content yet")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Child Pages

    private var childPagesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Subpages")
                    .font(AppTypography.headlineSmall)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(viewModel.children.count)")
                    .font(AppTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, AppSpacing.sm)

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.children) { child in
                    childPageRow(child)
                }
            }
        }
        .padding(.top, AppSpacing.lg)
    }

    private func childPageRow(_ page: Page) -> some View {
        Button {
            HapticFeedback.selection()
            print("DEBUG: Navigating to subpage \(page.id) (\(page.title))")
            router.navigate(to: .pageDetail(spaceId: spaceId, pageId: page.id))
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Icon
                Group {
                    if let emoji = page.emoji {
                        Text(emoji)
                            .font(.title3)
                    } else {
                        Image(systemName: page.type.icon)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryFallback)
                    }
                }
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if let desc = page.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .contentShape(Rectangle())
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Loading page...")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.huge)
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red.opacity(0.8))

            VStack(spacing: AppSpacing.sm) {
                Text("Failed to Load Page")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)

                Text(viewModel.errorMessage ?? "An error occurred")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            GlassButton("Retry", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.refresh(spaceId: spaceId, pageId: pageId)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.huge)
    }
}
