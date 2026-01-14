//
//  RecentPagesView.swift
//  GitBeek
//
//  View for displaying recent pages
//

import SwiftUI

/// View for displaying recently viewed pages
struct RecentPagesView: View {
    // MARK: - Environment

    @Bindable var viewModel: SearchViewModel
    @Environment(AppRouter.self) private var router

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if viewModel.recentPages.isEmpty {
                    emptyStateSection
                } else {
                    recentPagesSection
                }
            }
            .navigationTitle("Recent Pages")
            .toolbar {
                if !viewModel.recentPages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            viewModel.clearRecentPages()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .refreshable {
                viewModel.loadRecentPages()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        Section {
            ContentUnavailableView(
                "No Recent Pages",
                systemImage: "clock",
                description: Text("Pages you visit will appear here")
            )
        }
    }

    // MARK: - Recent Pages Section

    private var recentPagesSection: some View {
        Section {
            ForEach(viewModel.recentPages) { page in
                recentPageRow(page)
            }
        } header: {
            Text("\(viewModel.recentPages.count) recent page\(viewModel.recentPages.count == 1 ? "" : "s")")
        }
    }

    // MARK: - Recent Page Row

    private func recentPageRow(_ page: RecentPage) -> some View {
        Button {
            router.navigate(to: .pageDetail(spaceId: page.spaceId, pageId: page.id))
        } label: {
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

                    Text(formatDate(page.lastVisited))
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.tertiary)
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
        .contextMenu {
            Button(role: .destructive) {
                viewModel.recentPagesManager.removeRecentPage(id: page.id, spaceId: page.spaceId)
                viewModel.loadRecentPages()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    RecentPagesView(viewModel: DependencyContainer.shared.searchViewModel)
        .environment(DependencyContainer.shared.appRouter)
}
