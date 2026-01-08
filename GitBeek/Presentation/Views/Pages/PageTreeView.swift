//
//  PageTreeView.swift
//  GitBeek
//
//  Hierarchical page tree view with OutlineGroup
//

import SwiftUI

/// Hierarchical view of pages using OutlineGroup
struct PageTreeView: View {
    // MARK: - Properties

    let pages: [Page]
    @Binding var expandedIds: Set<String>
    let onPageTap: (Page) -> Void

    // MARK: - Body

    var body: some View {
        if pages.isEmpty {
            emptyView
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(pages) { page in
                    PageTreeNode(
                        page: page,
                        level: 0,
                        expandedIds: $expandedIds,
                        onPageTap: onPageTap
                    )
                }
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        Text("No pages found")
            .font(AppTypography.bodyMedium)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
    }
}

// MARK: - Page Tree Node

/// Recursive node in the page tree
struct PageTreeNode: View {
    // MARK: - Properties

    let page: Page
    let level: Int
    @Binding var expandedIds: Set<String>
    let onPageTap: (Page) -> Void

    // MARK: - Computed

    private var isExpanded: Bool {
        expandedIds.contains(page.id)
    }

    private var indentWidth: CGFloat {
        CGFloat(level) * 20
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Page row
            PageTreeRow(
                page: page,
                isExpanded: isExpanded,
                hasChildren: page.hasChildren,
                onTap: {
                    onPageTap(page)
                },
                onToggle: {
                    toggleExpansion()
                }
            )
            .padding(.leading, indentWidth)

            // Children (when expanded)
            if isExpanded && page.hasChildren {
                VStack(spacing: 0) {
                    ForEach(page.children) { child in
                        PageTreeNode(
                            page: child,
                            level: level + 1,
                            expandedIds: $expandedIds,
                            onPageTap: onPageTap
                        )
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleExpansion() {
        if expandedIds.contains(page.id) {
            expandedIds.remove(page.id)
        } else {
            expandedIds.insert(page.id)
        }
    }
}

// MARK: - Preview

#Preview {
    let samplePages = [
        Page(
            id: "1",
            title: "Getting Started",
            emoji: "🚀",
            path: "getting-started",
            slug: "getting-started",
            description: nil,
            type: .group,
            children: [
                Page(
                    id: "1-1",
                    title: "Installation",
                    emoji: "📦",
                    path: "getting-started/installation",
                    slug: "installation",
                    description: nil,
                    type: .document,
                    children: [],
                    markdown: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    linkTarget: nil
                ),
                Page(
                    id: "1-2",
                    title: "Configuration",
                    emoji: nil,
                    path: "getting-started/configuration",
                    slug: "configuration",
                    description: nil,
                    type: .document,
                    children: [],
                    markdown: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    linkTarget: nil
                )
            ],
            markdown: nil,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        ),
        Page(
            id: "2",
            title: "API Reference",
            emoji: "📚",
            path: "api-reference",
            slug: "api-reference",
            description: nil,
            type: .document,
            children: [],
            markdown: nil,
            createdAt: nil,
            updatedAt: nil,
            linkTarget: nil
        )
    ]

    return NavigationStack {
        ScrollView {
            PageTreeView(
                pages: samplePages,
                expandedIds: .constant(Set(["1"])),
                onPageTap: { _ in }
            )
            .padding()
        }
        .navigationTitle("Pages")
    }
}
