//
//  ExpandableBlockView.swift
//  GitBeek
//
//  GitBook expandable/collapsible block
//

import SwiftUI

/// View for rendering GitBook expandable blocks
struct ExpandableBlockView: View {
    // MARK: - Properties

    let title: String
    let content: [MarkdownBlock]

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticFeedback.light()
            } label: {
                HStack {
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    // Title
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content (when expanded)
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(content) { block in
                        MarkdownBlockView(block: block)
                    }
                }
                .padding()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            ExpandableBlockView(
                title: "Click to expand",
                content: [
                    .paragraph(text: AttributedString("This is the hidden content that appears when you expand the block."))
                ]
            )

            ExpandableBlockView(
                title: "Advanced Configuration",
                content: [
                    .paragraph(text: AttributedString("Here are some advanced configuration options:")),
                    .codeBlock(language: "json", code: """
                    {
                      "debug": true,
                      "verbose": false
                    }
                    """)
                ]
            )

            ExpandableBlockView(
                title: "Troubleshooting",
                content: [
                    .paragraph(text: AttributedString("If you encounter issues, try these steps:")),
                    .unorderedList(items: [
                        ListItemBlock(content: [.paragraph(text: AttributedString("Check your configuration"))], isChecked: nil),
                        ListItemBlock(content: [.paragraph(text: AttributedString("Restart the application"))], isChecked: nil),
                        ListItemBlock(content: [.paragraph(text: AttributedString("Contact support"))], isChecked: nil)
                    ])
                ]
            )
        }
        .padding()
    }
}
