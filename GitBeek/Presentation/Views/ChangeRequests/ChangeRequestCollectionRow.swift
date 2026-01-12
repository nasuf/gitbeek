//
//  ChangeRequestCollectionRow.swift
//  GitBeek
//
//  Expandable collection row showing change requests from multiple spaces
//

import SwiftUI

/// Expandable row for collection with change requests from child spaces
struct ChangeRequestCollectionRow: View {
    // MARK: - Properties

    let collection: Collection
    let changeRequests: [(space: Space, changeRequest: ChangeRequest)]
    let isExpanded: Bool
    let displayMode: CollectionDisplayMode
    let onToggle: () -> Void
    let onToggleDisplayMode: () -> Void
    let onChangeRequestTap: (Space, ChangeRequest) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Collection header
            collectionHeader

            // Change requests (when expanded)
            if isExpanded && !changeRequests.isEmpty {
                changeRequestsList
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
                    Text(verbatim: collection.title)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("\(changeRequests.count) change request\(changeRequests.count == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Display mode toggle (shown when expanded)
                if isExpanded {
                    Button {
                        HapticFeedback.light()
                        onToggleDisplayMode()
                    } label: {
                        Image(systemName: displayMode == .groupedBySpaces ? "square.grid.2x2" : "list.bullet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Count badge
                if changeRequests.count > 0 {
                    Text("\(changeRequests.count)")
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
            if let emoji = collection.emoji {
                Text(verbatim: emoji)
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

    // MARK: - Change Requests List

    private var changeRequestsList: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
                .padding(.horizontal, AppSpacing.md)

            if displayMode == .groupedBySpaces {
                groupedBySpacesView
            } else {
                flatByTimeView
            }
        }
    }

    // MARK: - Grouped by Spaces View

    private var groupedBySpacesView: some View {
        VStack(spacing: AppSpacing.md) {
            // Group change requests by space
            ForEach(groupedBySpace, id: \.space.id) { group in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // Space header
                    HStack(spacing: AppSpacing.xs) {
                        if let emoji = group.space.emoji {
                            Text(verbatim: emoji)
                                .font(AppTypography.captionSmall)
                        }
                        Text(verbatim: group.space.title)
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                        Text("(\(group.changeRequests.count))")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.xs)

                    // Change requests for this space
                    ForEach(group.changeRequests, id: \.id) { cr in
                        changeRequestRow(space: group.space, changeRequest: cr)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .padding(.leading, AppSpacing.lg)
    }

    // MARK: - Flat by Time View

    private var flatByTimeView: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(sortedByTime, id: \.changeRequest.id) { (space, cr) in
                changeRequestRow(space: space, changeRequest: cr, showSpaceName: true)
            }
        }
        .padding(AppSpacing.md)
        .padding(.leading, AppSpacing.lg)
    }

    // MARK: - Computed Properties

    /// Group change requests by space
    private var groupedBySpace: [(space: Space, changeRequests: [ChangeRequest])] {
        var groups: [String: (space: Space, changeRequests: [ChangeRequest])] = [:]

        for (space, cr) in changeRequests {
            if var existing = groups[space.id] {
                existing.changeRequests.append(cr)
                groups[space.id] = existing
            } else {
                groups[space.id] = (space: space, changeRequests: [cr])
            }
        }

        return groups.values.sorted { $0.space.title < $1.space.title }
    }

    /// Sort change requests by time (newest first)
    private var sortedByTime: [(space: Space, changeRequest: ChangeRequest)] {
        changeRequests.sorted { lhs, rhs in
            guard let lhsDate = lhs.changeRequest.updatedAt,
                  let rhsDate = rhs.changeRequest.updatedAt else {
                return false
            }
            return lhsDate > rhsDate
        }
    }

    // MARK: - Change Request Row

    private func changeRequestRow(space: Space, changeRequest: ChangeRequest, showSpaceName: Bool = false) -> some View {
        Button {
            HapticFeedback.selection()
            onChangeRequestTap(space, changeRequest)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Status icon
                Image(systemName: changeRequest.status.icon)
                    .font(.title3)
                    .foregroundStyle(statusColor(changeRequest.status))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(statusColor(changeRequest.status).opacity(0.1))
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Space name (only show in flat mode)
                    if showSpaceName {
                        HStack(spacing: AppSpacing.xs) {
                            if let emoji = space.emoji {
                                Text(verbatim: emoji)
                                    .font(AppTypography.captionSmall)
                            }
                            Text(verbatim: space.title)
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Change request title or meta info as primary
                    if !changeRequest.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(verbatim: changeRequest.displayTitle)
                            .font(AppTypography.bodyMedium)
                            .lineLimit(1)
                    }

                    // Meta info (always shown, as primary if no title)
                    HStack(spacing: AppSpacing.xs) {
                        Text("#\(changeRequest.number)")
                            .font(changeRequest.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTypography.bodyMedium : AppTypography.captionSmall)
                            .fontWeight(changeRequest.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .medium : .regular)
                            .foregroundStyle(changeRequest.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .primary : .tertiary)

                        if let updatedAt = changeRequest.updatedAt {
                            Text("•")
                                .foregroundStyle(.tertiary)

                            Text(formatDate(updatedAt))
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Status badge
                Text(changeRequest.status.displayName)
                    .font(AppTypography.captionSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor(changeRequest.status))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        statusColor(changeRequest.status).opacity(0.15),
                        in: Capsule()
                    )

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(scale: 0.98, duration: 0.1))
    }

    // MARK: - Helpers

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
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
