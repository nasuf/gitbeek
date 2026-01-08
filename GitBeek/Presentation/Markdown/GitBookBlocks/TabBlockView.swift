//
//  TabBlockView.swift
//  GitBeek
//
//  GitBook tabbed content block
//

import SwiftUI

/// View for rendering GitBook tabbed content blocks
struct TabBlockView: View {
    // MARK: - Properties

    let tabs: [TabItem]
    @State private var selectedIndex = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab bar
            tabBar

            // Content
            tabContent
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    tabButton(for: index)
                }
            }
        }
        .background(Color(.systemGray5))
    }

    private func tabButton(for index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
            }
        } label: {
            Text(tabs[index].title)
                .font(AppTypography.bodyMedium)
                .fontWeight(selectedIndex == index ? .semibold : .regular)
                .foregroundStyle(selectedIndex == index ? .primary : .secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(selectedIndex == index ? Color(.systemBackground) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        if tabs.indices.contains(selectedIndex) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(tabs[selectedIndex].content) { block in
                    MarkdownBlockView(block: block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            TabBlockView(
                tabs: [
                    TabItem(
                        title: "Swift",
                        content: [
                            .codeBlock(language: "swift", code: "let message = \"Hello, World!\"")
                        ]
                    ),
                    TabItem(
                        title: "JavaScript",
                        content: [
                            .codeBlock(language: "javascript", code: "const message = 'Hello, World!';")
                        ]
                    ),
                    TabItem(
                        title: "Python",
                        content: [
                            .codeBlock(language: "python", code: "message = \"Hello, World!\"")
                        ]
                    )
                ]
            )

            TabBlockView(
                tabs: [
                    TabItem(
                        title: "Installation",
                        content: [.paragraph(text: AttributedString("Run npm install to get started."))]
                    ),
                    TabItem(
                        title: "Usage",
                        content: [.paragraph(text: AttributedString("Import the module and call the function."))]
                    )
                ]
            )
        }
        .padding()
    }
}
