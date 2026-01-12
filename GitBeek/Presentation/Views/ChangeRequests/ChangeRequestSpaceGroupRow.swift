//
//  ChangeRequestSpaceGroupRow.swift
//  GitBeek
//
//  Row showing change requests from a single space
//

import SwiftUI

/// Row for displaying change requests from a top-level space (not in collection)
struct ChangeRequestSpaceGroupRow: View {
    // MARK: - Properties

    let space: Space
    let changeRequests: [ChangeRequest]
    let onChangeRequestTap: (ChangeRequest) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Space header
            spaceHeader

            // Change requests list
            VStack(spacing: AppSpacing.xs) {
                ForEach(changeRequests) { cr in
                    changeRequestRow(changeRequest: cr)
                }
            }
        }
        .padding(AppSpacing.md)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusLarge)
    }

    // MARK: - Space Header

    private var spaceHeader: some View {
        HStack(spacing: AppSpacing.md) {
            // Space icon/emoji
            Group {
                if let emoji = space.emoji {
                    Text(verbatim: emoji)
                        .font(.title2)
                } else {
                    Image(systemName: "doc.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primaryFallback)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
                    .fill(.ultraThinMaterial)
            )

            // Title and count
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: space.title)
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("\(changeRequests.count) change request\(changeRequests.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Count badge
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

    // MARK: - Change Request Row

    private func changeRequestRow(changeRequest: ChangeRequest) -> some View {
        Button {
            HapticFeedback.selection()
            onChangeRequestTap(changeRequest)
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
