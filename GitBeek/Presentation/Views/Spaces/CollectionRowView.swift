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
    let allCollections: [Collection]
    let onToggle: () -> Void
    let onSpaceTap: (Space) -> Void
    let onDelete: (Space) -> Void
    let onMoveSpace: (Space, String?) -> Void
    let onRenameSpace: (Space, String) -> Void
    let onMoveCollection: (String, String?) -> Void   // (collectionId, targetParentId)
    let onRenameCollection: (String, String) -> Void  // (collectionId, newTitle)
    let onDeleteCollection: (String) -> Void           // (collectionId)
    var isExpandedCheck: ((String) -> Bool)?
    var onToggleById: ((String) -> Void)?

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var renameText = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            collectionHeader

            if isExpanded && collection.childCount > 0 {
                childrenList
            }
        }
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
        .alert("Rename Collection", isPresented: $showRenameAlert) {
            TextField("New name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onRenameCollection(collection.id, trimmed)
                }
            }
        } message: {
            Text("Enter a new name for this collection.")
        }
        .alert("Delete Collection", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDeleteCollection(collection.id)
            }
        } message: {
            Text("Are you sure you want to delete \"\(collection.collection.title)\"?\n\nAll spaces inside will also be deleted. Spaces can be restored from trash within 7 days, but the collection itself cannot be recovered.")
        }
    }

    // MARK: - Collection Header

    private var collectionHeader: some View {
        Button {
            HapticFeedback.light()
            onToggle()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isExpanded)

                collectionIcon

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
        .contextMenu {
            collectionContextMenu
        }
    }

    // MARK: - Collection Context Menu

    @ViewBuilder
    private var collectionContextMenu: some View {
        Menu {
            Button {
                onMoveCollection(collection.id, nil)
            } label: {
                Label("None (Top Level)", systemImage: "arrow.up.to.line")
            }

            Divider()

            ForEach(allCollections.filter { $0.id != collection.id && $0.id != collection.collection.parentId }) { col in
                Button {
                    onMoveCollection(collection.id, col.id)
                } label: {
                    Label(col.displayTitle, systemImage: "folder")
                }
            }
        } label: {
            Label("Move to...", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
        }

        Button {
            renameText = collection.collection.title
            showRenameAlert = true
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Menu {
            if let appURL = collection.collection.appURL {
                Button {
                    UIPasteboard.general.string = appURL.absoluteString
                } label: {
                    Label("Copy Link", systemImage: "link")
                }
            }

            Button {
                UIPasteboard.general.string = collection.id
            } label: {
                Label("Copy ID", systemImage: "number")
            }

            Button {
                UIPasteboard.general.string = collection.collection.title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc")
            }

            if let appURL = collection.collection.appURL {
                Button {
                    UIPasteboard.general.string = "[\(collection.collection.title)](\(appURL.absoluteString))"
                } label: {
                    Label("Copy Title as Link", systemImage: "link.badge.plus")
                }
            }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Collection Icon

    private var collectionIcon: some View {
        Group {
            if let emoji = collection.collection.emoji {
                Text(emoji)
                    .font(.title2)
            } else {
                Image(systemName: "folder.fill")
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
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.sm) {
                ForEach(collection.childCollections) { subCollection in
                    CollectionRowView(
                        collection: subCollection,
                        isExpanded: isExpandedCheck?(subCollection.id) ?? false,
                        allCollections: allCollections,
                        onToggle: { onToggleById?(subCollection.id) },
                        onSpaceTap: onSpaceTap,
                        onDelete: onDelete,
                        onMoveSpace: onMoveSpace,
                        onRenameSpace: onRenameSpace,
                        onMoveCollection: onMoveCollection,
                        onRenameCollection: onRenameCollection,
                        onDeleteCollection: onDeleteCollection,
                        isExpandedCheck: isExpandedCheck,
                        onToggleById: onToggleById
                    )
                }

                ForEach(collection.children) { space in
                    ChildSpaceRowView(
                        space: space,
                        collections: allCollections,
                        onTap: { onSpaceTap(space) },
                        onDelete: { onDelete(space) },
                        onMove: { parentId in onMoveSpace(space, parentId) },
                        onRename: { title in onRenameSpace(space, title) }
                    )
                }
            }
            .padding(AppSpacing.md)
            .padding(.leading, AppSpacing.lg)
        }
    }
}

/// Child space row inside a collection, with its own @State for alerts
private struct ChildSpaceRowView: View {
    let space: Space
    let collections: [Collection]
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (String?) -> Void
    let onRename: (String) -> Void

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var renameText = ""

    var body: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: AppSpacing.sm) {
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
            SpaceContextMenu(
                space: space,
                collections: collections,
                onMove: onMove,
                onRename: {
                    renameText = space.title
                    showRenameAlert = true
                },
                onDelete: { showDeleteAlert = true }
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
                    )
                ]
            ),
            isExpanded: true,
            allCollections: [],
            onToggle: {},
            onSpaceTap: { _ in },
            onDelete: { _ in },
            onMoveSpace: { _, _ in },
            onRenameSpace: { _, _ in },
            onMoveCollection: { _, _ in },
            onRenameCollection: { _, _ in },
            onDeleteCollection: { _ in }
        )
    }
    .padding()
}
