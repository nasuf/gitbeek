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
    let collections: [Collection]
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (String?) -> Void
    let onRename: (String) -> Void
    let onUpdateSpace: (String?, String?, Space.Visibility?) async throws -> Void

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var renameText = ""

    // MARK: - Body

    var body: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: AppSpacing.md) {
                spaceIcon

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
            SpaceContextMenu(
                space: space,
                collections: collections,
                onMove: onMove,
                onRename: {
                    renameText = space.title
                    showRenameAlert = true
                },
                onDelete: { showDeleteAlert = true },
                onMoreOptions: { showEditSheet = true }
            )
        }
        .sheet(isPresented: $showEditSheet) {
            SpaceSettingsView(
                space: space,
                collections: collections,
                onSave: onUpdateSpace,
                onMove: onMove,
                onDelete: onDelete
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Rename Space", isPresented: $showRenameAlert) {
            TextField("New name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onRename(trimmed)
                }
            }
        } message: {
            Text("Enter a new name for this space.")
        }
        .alert("Delete Space", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(space.title)\"? It will be moved to trash and can be restored within 7 days.")
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
}

// MARK: - Shared Space Context Menu

/// Reusable context menu for space items with nested Move/Copy submenus
struct SpaceContextMenu: View {
    let space: Space
    let collections: [Collection]
    let onMove: (String?) -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    var onMoreOptions: (() -> Void)? = nil

    var body: some View {
        Menu {
            Button {
                onMove(nil)
            } label: {
                Label("None (Top Level)", systemImage: "arrow.up.to.line")
            }

            Divider()

            ForEach(collections.filter { $0.id != space.parentId }) { collection in
                Button {
                    onMove(collection.id)
                } label: {
                    Label(collection.displayTitle, systemImage: "folder")
                }
            }
        } label: {
            Label("Move to...", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
        }

        Button {
            onRename()
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Menu {
            if let appURL = space.appURL {
                Button {
                    UIPasteboard.general.string = appURL.absoluteString
                } label: {
                    Label("Copy Link", systemImage: "link")
                }
            }

            Button {
                UIPasteboard.general.string = space.id
            } label: {
                Label("Copy ID", systemImage: "number")
            }

            Button {
                UIPasteboard.general.string = space.title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc")
            }

            if let appURL = space.appURL {
                Button {
                    UIPasteboard.general.string = "[\(space.title)](\(appURL.absoluteString))"
                } label: {
                    Label("Copy Title as Link", systemImage: "link.badge.plus")
                }
            }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        if let onMoreOptions {
            Divider()

            Button {
                onMoreOptions()
            } label: {
                Label("More Options...", systemImage: "ellipsis.circle")
            }
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
            collections: [],
            onTap: {},
            onDelete: {},
            onMove: { _ in },
            onRename: { _ in },
            onUpdateSpace: { _, _, _ in }
        )
    }
    .padding()
}
