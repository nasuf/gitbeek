//
//  FavoritesView.swift
//  GitBeek
//
//  View for displaying favorite pages
//

import SwiftUI

/// View for displaying favorited/bookmarked pages
struct FavoritesView: View {
    // MARK: - Environment

    @Bindable var viewModel: SearchViewModel

    // MARK: - Body

    var body: some View {
        List {
            if viewModel.favoritePages.isEmpty {
                emptyStateSection
            } else {
                favoritesSection
            }
        }
        .navigationTitle("Favorites")
        .toolbar(.hidden, for: .tabBar)
        .refreshable {
            viewModel.loadFavoritePages()
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        Section {
            ContentUnavailableView(
                "No Favorites",
                systemImage: "star",
                description: Text("Bookmark pages for quick access")
            )
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        Section {
            ForEach(viewModel.favoritePages) { page in
                favoritePageRow(page)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let page = viewModel.favoritePages[index]
                    viewModel.recentPagesManager.removeFavorite(id: page.id, spaceId: page.spaceId)
                    viewModel.loadFavoritePages()
                }
            }
        } header: {
            Text("\(viewModel.favoritePages.count) favorite\(viewModel.favoritePages.count == 1 ? "" : "s")")
        }
    }

    // MARK: - Favorite Page Row

    private func favoritePageRow(_ page: FavoritePage) -> some View {
        NavigationLink(value: AppDestination.pageDetail(spaceId: page.spaceId, pageId: page.id)) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
                        .fill(AppColors.primaryFallback.opacity(0.1))
                        .frame(width: 44, height: 44)

                    if let emoji = page.emoji {
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
                    Text(verbatim: page.title.isEmpty ? "Untitled" : page.title)
                        .font(AppTypography.bodyMedium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if !page.path.isEmpty {
                        Text(verbatim: page.path)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(formatDate(page.addedAt))
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Star icon
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Added " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    FavoritesView(viewModel: DependencyContainer.shared.searchViewModel)
        .environment(DependencyContainer.shared.appRouter)
}
