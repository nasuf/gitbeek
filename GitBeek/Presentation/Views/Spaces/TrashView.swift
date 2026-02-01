//
//  TrashView.swift
//  GitBeek
//
//  View for displaying and managing trashed spaces
//

import SwiftUI

/// View for managing deleted spaces in trash
struct TrashView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var viewModel: SpaceListViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.trashedSpaces.isEmpty {
                    emptyStateView
                } else {
                    trashedSpacesList
                }
            }
            .navigationTitle("Trash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Trashed Spaces List

    private var trashedSpacesList: some View {
        List {
            Section {
                ForEach(viewModel.trashedSpaces) { space in
                    trashedSpaceRow(space)
                }
            } header: {
                Text("Deleted spaces are permanently removed after 7 days")
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Trashed Space Row

    private func trashedSpaceRow(_ space: Space) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Space icon
            Group {
                if let emoji = space.emoji {
                    Text(emoji)
                        .font(.title3)
                } else {
                    Image(systemName: space.isCollection ? "folder.fill" : "doc.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(space.title)
                    .font(AppTypography.bodyMedium)
                    .lineLimit(1)

                if let daysRemaining = space.daysUntilPermanentDeletion {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(daysRemainingText(daysRemaining))
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(daysRemaining <= 1 ? .red : .secondary)
                }
            }

            Spacer()
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    await viewModel.restoreSpace(id: space.id)
                }
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(AppColors.success)
        }
        .contextMenu {
            Button {
                Task {
                    await viewModel.restoreSpace(id: space.id)
                }
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
        }
    }

    // MARK: - Days Remaining Text

    private func daysRemainingText(_ days: Int) -> String {
        switch days {
        case 0:
            return "Deleting today"
        case 1:
            return "1 day remaining"
        default:
            return "\(days) days remaining"
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "trash")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: AppSpacing.sm) {
                Text("Trash is Empty")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.semibold)

                Text("Deleted spaces will appear here for 7 days before being permanently removed")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    TrashView(
        viewModel: {
            let vm = SpaceListViewModel(spaceRepository: PreviewSpaceRepository())
            return vm
        }()
    )
}

private actor PreviewSpaceRepository: SpaceRepository {
    func getCollections(organizationId: String) async throws -> [Collection] { [] }
    func getSpaces(organizationId: String) async throws -> [Space] { [] }
    func getSpace(id: String) async throws -> Space { fatalError() }
    func createSpace(organizationId: String, title: String, emoji: String?, visibility: Space.Visibility, parentId: String?) async throws -> Space { fatalError() }
    func createCollection(organizationId: String, title: String, parentId: String?) async throws -> Collection { fatalError() }
    func updateSpace(id: String, title: String?, emoji: String?, visibility: Space.Visibility?, parentId: String?) async throws -> Space { fatalError() }
    func deleteSpace(id: String) async throws {}
    func restoreSpace(id: String) async throws -> Space { fatalError() }
    func getCachedSpaces(organizationId: String) async -> [Space] { [] }
    func clearCache() async {}
}
