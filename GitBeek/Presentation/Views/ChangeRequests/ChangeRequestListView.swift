//
//  ChangeRequestListView.swift
//  GitBeek
//
//  View for displaying list of change requests
//

import SwiftUI

/// View for displaying list of change requests
struct ChangeRequestListView: View {
    // MARK: - Properties

    @Environment(AppRouter.self) private var router
    @State private var viewModel: ChangeRequestListViewModel

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestRepository: ChangeRequestRepository
    ) {
        let vm = ChangeRequestListViewModel(
            spaceId: spaceId,
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
            if viewModel.isLoading && viewModel.changeRequests.isEmpty {
                ProgressView("Loading change requests...")
            } else if viewModel.changeRequests.isEmpty {
                ContentUnavailableView {
                    Label("No Change Requests", systemImage: "doc.text")
                } description: {
                    Text("There are no change requests for this space yet.")
                }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        // Filter segmented control
                        filterSegmentedControl
                            .padding(.horizontal)
                            .padding(.top, AppSpacing.sm)

                        // Stats card
                        statsCard
                            .padding(.horizontal)

                        // Change request list
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(viewModel.filteredChangeRequests) { changeRequest in
                                ChangeRequestRow(changeRequest: changeRequest)
                                    .onTapGesture {
                                        router.navigate(to: .changeRequestDetail(
                                            spaceId: viewModel.spaceId,
                                            changeRequestId: changeRequest.id
                                        ))
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, AppSpacing.lg)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Change Requests")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeRequestStatusDidChange)) { notification in
            if let change = notification.object as? ChangeRequestStatusChange {
                viewModel.updateLocalStatus(changeRequestId: change.changeRequestId, newStatus: change.newStatus)
            }
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

    // MARK: - Filter Segmented Control

    @ViewBuilder
    private var filterSegmentedControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                FilterChip(
                    title: "All",
                    count: viewModel.changeRequests.count,
                    isSelected: viewModel.selectedStatus == nil
                ) {
                    viewModel.setFilter(nil)
                }

                FilterChip(
                    title: "Open",
                    count: viewModel.openCount,
                    isSelected: viewModel.selectedStatus == .open
                ) {
                    viewModel.setFilter(.open)
                }

                FilterChip(
                    title: "Draft",
                    count: viewModel.draftCount,
                    isSelected: viewModel.selectedStatus == .draft
                ) {
                    viewModel.setFilter(.draft)
                }

                FilterChip(
                    title: "Merged",
                    count: viewModel.mergedCount,
                    isSelected: viewModel.selectedStatus == .merged
                ) {
                    viewModel.setFilter(.merged)
                }

                FilterChip(
                    title: "Archived",
                    count: viewModel.archivedCount,
                    isSelected: viewModel.selectedStatus == .archived
                ) {
                    viewModel.setFilter(.archived)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Stats Card

    @ViewBuilder
    private var statsCard: some View {
        HStack(spacing: AppSpacing.lg) {
            StatItem(
                title: "Open",
                value: viewModel.openCount,
                color: .blue
            )

            Divider()
                .frame(height: 40)

            StatItem(
                title: "Merged",
                value: viewModel.mergedCount,
                color: .green
            )
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLarge)
        )
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.labelMedium)

                Text("\(count)")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.clear,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("\(value)")
                .font(AppTypography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(AppTypography.captionSmall)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Change Request Row

private struct ChangeRequestRow: View {
    let changeRequest: ChangeRequest

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Status icon
            Image(systemName: changeRequest.status.icon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Title
                Text(changeRequest.displayTitle)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .lineLimit(2)

                // Meta info
                HStack(spacing: AppSpacing.sm) {
                    Label("#\(changeRequest.number)", systemImage: "number")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.secondary)

                    if let createdAt = changeRequest.createdAt {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(formatDate(createdAt))
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status badge
                    Text(changeRequest.status.displayName)
                        .font(AppTypography.captionSmall)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            statusColor.opacity(0.15),
                            in: Capsule()
                        )
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(AppTypography.captionSmall)
                .foregroundStyle(.tertiary)
        }
        .padding(AppSpacing.md)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
        )
    }

    private var statusColor: Color {
        switch changeRequest.status {
        case .draft: return .gray
        case .open: return .blue
        case .merged: return .green
        case .archived: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Change Request List") {
    NavigationStack {
        ChangeRequestListView(
            spaceId: "preview-space",
            changeRequestRepository: DependencyContainer.shared.changeRequestRepository
        )
    }
}
