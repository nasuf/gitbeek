//
//  ChangeRequestDetailView.swift
//  GitBeek
//
//  View for displaying change request details
//

import SwiftUI

/// View for displaying change request details
struct ChangeRequestDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChangeRequestDetailViewModel

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestId: String,
        changeRequestRepository: ChangeRequestRepository
    ) {
        let vm = ChangeRequestDetailViewModel(
            spaceId: spaceId,
            changeRequestId: changeRequestId,
            changeRequestRepository: changeRequestRepository
        )
        self._viewModel = State(initialValue: vm)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Content
            if viewModel.isLoading && viewModel.changeRequest == nil {
                ProgressView("Loading...")
            } else if let changeRequest = viewModel.changeRequest {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header card
                        headerCard(changeRequest: changeRequest)
                            .padding(.horizontal)
                            .padding(.top, AppSpacing.sm)

                        // Actions
                        if changeRequest.isActive {
                            actionsSection(changeRequest: changeRequest)
                                .padding(.horizontal)
                        }

                        // Diff section
                        diffSection
                            .padding(.horizontal)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.bottom, AppSpacing.lg)
                }
            }
        }
        .navigationTitle("Change Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
            await viewModel.loadDiff()
        }
        .onChange(of: viewModel.didMerge) { _, didMerge in
            if didMerge {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .alert("Merge Change Request?", isPresented: $viewModel.showMergeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Merge", role: .destructive) {
                Task {
                    await viewModel.merge()
                }
            }
        } message: {
            Text("This will merge all changes into the main content. This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Header Card

    @ViewBuilder
    private func headerCard(changeRequest: ChangeRequest) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Title and number
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("#\(changeRequest.number)")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.secondary)

                        statusBadge(status: changeRequest.status)
                    }

                    Text(changeRequest.displayTitle)
                        .font(AppTypography.titleMedium)
                        .fontWeight(.semibold)
                }

                Spacer()

                Image(systemName: changeRequest.status.icon)
                    .font(.title)
                    .foregroundStyle(statusColor(changeRequest.status))
            }

            Divider()

            // Metadata
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let createdBy = changeRequest.createdBy {
                    MetadataRow(
                        icon: "person.circle",
                        label: "Created by",
                        value: createdBy.displayName
                    )
                }

                if let createdAt = changeRequest.createdAt {
                    MetadataRow(
                        icon: "calendar",
                        label: "Created",
                        value: formatDate(createdAt)
                    )
                }

                if let updatedAt = changeRequest.updatedAt {
                    MetadataRow(
                        icon: "clock",
                        label: "Updated",
                        value: formatDate(updatedAt)
                    )
                }

                if changeRequest.status == .merged, let mergedAt = changeRequest.mergedAt {
                    MetadataRow(
                        icon: "checkmark.circle",
                        label: "Merged",
                        value: formatDate(mergedAt)
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLarge)
        )
    }

    // MARK: - Actions Section

    @ViewBuilder
    private func actionsSection(changeRequest: ChangeRequest) -> some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.canMerge {
                Button {
                    viewModel.showMergeConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isMerging {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.merge")
                        }

                        Text("Merge Changes")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
                .disabled(viewModel.isMerging)
            }
        }
    }

    // MARK: - Diff Section

    @ViewBuilder
    private var diffSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("Changes", systemImage: "doc.text.magnifyingglass")
                    .font(AppTypography.headlineMedium)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoadingDiff {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let diff = viewModel.diff {
                if diff.hasChanges {
                    // Summary
                    HStack(spacing: AppSpacing.md) {
                        if diff.addedCount > 0 {
                            ChangeCountBadge(
                                count: diff.addedCount,
                                type: .added
                            )
                        }

                        if diff.modifiedCount > 0 {
                            ChangeCountBadge(
                                count: diff.modifiedCount,
                                type: .modified
                            )
                        }

                        if diff.removedCount > 0 {
                            ChangeCountBadge(
                                count: diff.removedCount,
                                type: .removed
                            )
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    )

                    // Changes list
                    ForEach(diff.changes) { change in
                        ChangeRow(change: change)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Changes", systemImage: "doc.text")
                    } description: {
                        Text("This change request has no changes.")
                    }
                }
            } else if !viewModel.isLoadingDiff {
                Text("Unable to load changes")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Functions

    private func statusBadge(status: ChangeRequestStatus) -> some View {
        Text(status.displayName)
            .font(AppTypography.captionSmall)
            .fontWeight(.medium)
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(
                statusColor(status).opacity(0.15),
                in: Capsule()
            )
    }

    private func statusColor(_ status: ChangeRequestStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .open: return .blue
        case .merged: return .green
        case .archived: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppTypography.bodySmall)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Change Count Badge

private struct ChangeCountBadge: View {
    let count: Int
    let type: ChangeType

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: type.icon)
                .font(AppTypography.captionSmall)

            Text("\(count) \(type.displayName.lowercased())")
                .font(AppTypography.captionSmall)
                .fontWeight(.medium)
        }
        .foregroundStyle(typeColor)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(
            typeColor.opacity(0.15),
            in: Capsule()
        )
    }

    private var typeColor: Color {
        switch type {
        case .added: return .green
        case .modified: return .orange
        case .removed: return .red
        }
    }
}

// MARK: - Change Row

private struct ChangeRow: View {
    let change: Change

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: change.type.icon)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(typeColor)

                Text(change.displayPath)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)

                Spacer()

                Text(change.type.displayName)
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(
                        typeColor.opacity(0.15),
                        in: Capsule()
                    )
            }

            if let document = change.document, document.hasChanges {
                Divider()

                // Diff content (simplified)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if let before = document.before, change.type != .added {
                        Text("Before:")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)

                        Text(before)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppSpacing.cornerRadiusSmall)
                            .lineLimit(5)
                    }

                    if let after = document.after, change.type != .removed {
                        Text("After:")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)

                        Text(after)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.8))
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(AppSpacing.cornerRadiusSmall)
                            .lineLimit(5)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
        )
    }

    private var typeColor: Color {
        switch change.type {
        case .added: return .green
        case .modified: return .orange
        case .removed: return .red
        }
    }
}

// MARK: - Preview

#Preview("Change Request Detail") {
    NavigationStack {
        ChangeRequestDetailView(
            spaceId: "preview-space",
            changeRequestId: "preview-cr",
            changeRequestRepository: DependencyContainer.shared.changeRequestRepository
        )
    }
}
