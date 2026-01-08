//
//  PageTreeRow.swift
//  GitBeek
//
//  Row view for a page in the tree
//

import SwiftUI

/// Row view for a page in the hierarchical tree
struct PageTreeRow: View {
    // MARK: - Properties

    let page: Page
    let isExpanded: Bool
    let hasChildren: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Expand/collapse button (for groups)
            if hasChildren {
                expandButton
            } else {
                // Spacer for alignment
                Color.clear
                    .frame(width: 32, height: 32)
            }

            // Page content
            pageContent
        }
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
    }

    // MARK: - Expand Button

    private var expandButton: some View {
        Button {
            HapticFeedback.light()
            onToggle()
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isExpanded)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page Content

    private var pageContent: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Page icon
                pageIcon

                // Title
                Text(page.title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(page.isGroup ? .semibold : .regular)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Spacer()

                // Child count badge for groups
                if hasChildren {
                    Text("\(page.children.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }

                // Link indicator
                if page.isLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.trailing, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(scale: 0.98, duration: 0.1))
    }

    // MARK: - Page Icon

    private var pageIcon: some View {
        Group {
            if let emoji = page.emoji {
                Text(emoji)
                    .font(.body)
            } else {
                Image(systemName: page.type.icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
            }
        }
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Icon Color

    private var iconColor: Color {
        switch page.type {
        case .group:
            return AppColors.secondaryFallback
        case .link:
            return .blue
        case .document:
            return AppColors.primaryFallback
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.sm) {
        // Document page
        PageTreeRow(
            page: Page(
                id: "1",
                title: "Getting Started",
                emoji: "🚀",
                path: "getting-started",
                slug: nil,
                description: nil,
                type: .document,
                children: [],
                markdown: nil,
                createdAt: nil,
                updatedAt: nil,
                linkTarget: nil
            ),
            isExpanded: false,
            hasChildren: false,
            onTap: {},
            onToggle: {}
        )

        // Group page (collapsed)
        PageTreeRow(
            page: Page(
                id: "2",
                title: "API Reference",
                emoji: nil,
                path: "api",
                slug: nil,
                description: nil,
                type: .group,
                children: [
                    Page(id: "2-1", title: "Users", emoji: nil, path: "api/users", slug: nil, description: nil, type: .document, children: [], markdown: nil, createdAt: nil, updatedAt: nil, linkTarget: nil),
                    Page(id: "2-2", title: "Auth", emoji: nil, path: "api/auth", slug: nil, description: nil, type: .document, children: [], markdown: nil, createdAt: nil, updatedAt: nil, linkTarget: nil)
                ],
                markdown: nil,
                createdAt: nil,
                updatedAt: nil,
                linkTarget: nil
            ),
            isExpanded: false,
            hasChildren: true,
            onTap: {},
            onToggle: {}
        )

        // Group page (expanded)
        PageTreeRow(
            page: Page(
                id: "3",
                title: "Guides",
                emoji: "📖",
                path: "guides",
                slug: nil,
                description: nil,
                type: .group,
                children: [
                    Page(id: "3-1", title: "Quick Start", emoji: nil, path: "guides/quick", slug: nil, description: nil, type: .document, children: [], markdown: nil, createdAt: nil, updatedAt: nil, linkTarget: nil)
                ],
                markdown: nil,
                createdAt: nil,
                updatedAt: nil,
                linkTarget: nil
            ),
            isExpanded: true,
            hasChildren: true,
            onTap: {},
            onToggle: {}
        )

        // Link page
        PageTreeRow(
            page: Page(
                id: "4",
                title: "External Docs",
                emoji: nil,
                path: "external",
                slug: nil,
                description: nil,
                type: .link,
                children: [],
                markdown: nil,
                createdAt: nil,
                updatedAt: nil,
                linkTarget: Page.LinkTarget(kind: .url, url: "https://example.com", space: nil, page: nil)
            ),
            isExpanded: false,
            hasChildren: false,
            onTap: {},
            onToggle: {}
        )
    }
    .padding()
}
