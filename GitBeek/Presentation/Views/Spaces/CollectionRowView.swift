//
//  CollectionRowView.swift
//  GitBeek
//
//  Expandable collection row with child spaces
//

import SwiftUI

/// Expandable row view for a collection with its child spaces
struct CollectionRowView: View {
    // MARK: - Properties

    let collection: SpaceListViewModel.CollectionWithSpaces
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSpaceTap: (Space) -> Void
    let onDelete: (Space) -> Void
    var isExpandedCheck: ((String) -> Bool)?
    var onToggleById: ((String) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Collection header
            collectionHeader

            // Children (when expanded)
            if isExpanded && collection.childCount > 0 {
                childrenList
            }
        }
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
    }

    // MARK: - Collection Header

    private var collectionHeader: some View {
        Button {
            HapticFeedback.light()
            onToggle()
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Expand/collapse chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isExpanded)

                // Collection icon/emoji
                collectionIcon

                // Title and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.collection.title)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("\(collection.childCount) space\(collection.childCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Child count badge with glass effect
                if collection.childCount > 0 {
                    Text("\(collection.childCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress)
    }

    // MARK: - Collection Icon

    private var collectionIcon: some View {
        Group {
            if let emoji = collection.collection.emoji {
                Text(emoji)
                    .font(.title2)
            } else {
                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .font(.title3)
                    .foregroundStyle(AppColors.secondaryFallback)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Children List

    private var childrenList: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.sm) {
                // Sub-collections
                ForEach(collection.childCollections) { subCollection in
                    CollectionRowView(
                        collection: subCollection,
                        isExpanded: isExpandedCheck?(subCollection.id) ?? false,
                        onToggle: { onToggleById?(subCollection.id) },
                        onSpaceTap: onSpaceTap,
                        onDelete: onDelete,
                        isExpandedCheck: isExpandedCheck,
                        onToggleById: onToggleById
                    )
                }

                // Child spaces
                ForEach(collection.children) { space in
                    childSpaceRow(space)
                }
            }
            .padding(AppSpacing.md)
            .padding(.leading, AppSpacing.lg)
        }
    }

    // MARK: - Child Space Row

    private func childSpaceRow(_ space: Space) -> some View {
        Button {
            HapticFeedback.selection()
            onSpaceTap(space)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Space icon
                Group {
                    if let emoji = space.emoji {
                        Text(emoji)
                            .font(.body)
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.callout)
                            .foregroundStyle(AppColors.primaryFallback)
                    }
                }
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                Text(space.title)
                    .font(AppTypography.bodyMedium)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(scale: 0.98, duration: 0.1))
        .contextMenu {
            Button {
                onSpaceTap(space)
            } label: {
                Label("Open", systemImage: "arrow.right.circle")
            }

            Divider()

            Button(role: .destructive) {
                onDelete(space)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete(space)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.md) {
        CollectionRowView(
            collection: SpaceListViewModel.CollectionWithSpaces(
                collection: Collection(
                    id: "col1",
                    title: "Tech Documentation",
                    emoji: "💻",
                    description: nil,
                    appURL: nil,
                    parentId: nil,
                    organizationId: nil,
                    createdAt: nil,
                    updatedAt: nil
                ),
                children: [
                    Space(
                        id: "1",
                        title: "API Reference",
                        emoji: "📚",
                        visibility: .public,
                        type: .document,
                        appURL: nil,
                        publishedURL: nil,
                        parentId: "col1",
                        organizationId: nil,
                        createdAt: nil,
                        updatedAt: nil,
                        deletedAt: nil
                    ),
                    Space(
                        id: "2",
                        title: "SDK Guide",
                        emoji: nil,
                        visibility: .public,
                        type: .document,
                        appURL: nil,
                        publishedURL: nil,
                        parentId: "col1",
                        organizationId: nil,
                        createdAt: nil,
                        updatedAt: nil,
                        deletedAt: nil
                    )
                ]
            ),
            isExpanded: true,
            onToggle: {},
            onSpaceTap: { _ in },
            onDelete: { _ in }
        )
    }
    .padding()
}
