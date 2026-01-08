//
//  MarkdownTableView.swift
//  GitBeek
//
//  Table renderer for markdown tables
//

import SwiftUI

/// View for rendering markdown tables
struct MarkdownTableView: View {
    // MARK: - Properties

    let headers: [String]
    let rows: [[String]]

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                headerRow

                Divider()

                // Data rows
                ForEach(rows.indices, id: \.self) { index in
                    dataRow(rows[index], isAlternate: index % 2 == 1)

                    if index < rows.count - 1 {
                        Divider()
                            .opacity(0.5)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(headers.indices, id: \.self) { index in
                Text(headers[index])
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(minWidth: cellWidth, alignment: .leading)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.sm)

                if index < headers.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color(.systemGray5))
    }

    // MARK: - Data Row

    private func dataRow(_ cells: [String], isAlternate: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(cells.indices, id: \.self) { index in
                Text(cells[safe: index] ?? "")
                    .font(AppTypography.bodyMedium)
                    .lineLimit(nil)
                    .frame(minWidth: cellWidth, alignment: .leading)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.sm)

                if index < cells.count - 1 {
                    Divider()
                }
            }
        }
        .background(isAlternate ? Color(.systemGray6).opacity(0.5) : Color.clear)
    }

    // MARK: - Cell Width

    private var cellWidth: CGFloat {
        // Calculate minimum cell width based on content
        max(100, UIScreen.main.bounds.width / CGFloat(max(headers.count, 1)) - 40)
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            MarkdownTableView(
                headers: ["Method", "Endpoint", "Description"],
                rows: [
                    ["GET", "/users", "List all users"],
                    ["GET", "/users/:id", "Get user by ID"],
                    ["POST", "/users", "Create a new user"],
                    ["PUT", "/users/:id", "Update user"],
                    ["DELETE", "/users/:id", "Delete user"]
                ]
            )

            MarkdownTableView(
                headers: ["Status", "Meaning"],
                rows: [
                    ["200", "OK - Request succeeded"],
                    ["400", "Bad Request - Invalid input"],
                    ["401", "Unauthorized - Auth required"],
                    ["404", "Not Found - Resource doesn't exist"],
                    ["500", "Server Error - Something went wrong"]
                ]
            )
        }
        .padding()
    }
}
