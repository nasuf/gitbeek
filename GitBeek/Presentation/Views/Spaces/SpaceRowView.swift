//
//  SpaceRowView.swift
//  GitBeek
//
//  Row view for displaying a single space
//

import SwiftUI

/// Row view for a space item
struct SpaceRowView: View {
    // MARK: - Properties

    let space: Space
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Space icon/emoji
                spaceIcon

                // Title and metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(space.title)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.xs) {
                        visibilityBadge
                        if let type = space.type {
                            typeBadge(type)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
        .contextMenu {
            contextMenuItems
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Space Icon

    private var spaceIcon: some View {
        Group {
            if let emoji = space.emoji {
                Text(emoji)
                    .font(.title2)
            } else {
                Image(systemName: space.isCollection ? "folder.fill" : "doc.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primaryFallback)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Visibility Badge

    private var visibilityBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: space.visibility.icon)
            Text(space.visibility.displayName)
        }
        .font(AppTypography.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Type Badge

    private func typeBadge(_ type: Space.SpaceType) -> some View {
        Text(type.displayName)
            .font(AppTypography.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            onTap()
        } label: {
            Label("Open", systemImage: "arrow.right.circle")
        }

        Divider()

        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SpaceRowView(
            space: Space(
                id: "1",
                title: "API Documentation",
                emoji: "📚",
                visibility: .public,
                type: .document,
                appURL: nil,
                publishedURL: nil,
                parentId: nil,
                organizationId: nil,
                createdAt: nil,
                updatedAt: nil,
                deletedAt: nil
            ),
            onTap: {},
            onDelete: {}
        )

        SpaceRowView(
            space: Space(
                id: "2",
                title: "Internal Docs",
                emoji: nil,
                visibility: .private,
                type: .document,
                appURL: nil,
                publishedURL: nil,
                parentId: nil,
                organizationId: nil,
                createdAt: nil,
                updatedAt: nil,
                deletedAt: nil
            ),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
}
