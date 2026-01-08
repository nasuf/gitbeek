//
//  MarkdownBlockView.swift
//  GitBeek
//
//  View for rendering individual markdown blocks
//

import SwiftUI

/// View for rendering a single markdown block
struct MarkdownBlockView: View {
    // MARK: - Properties

    let block: MarkdownBlock

    // MARK: - Body

    var body: some View {
        blockContent
    }

    // MARK: - Block Content

    @ViewBuilder
    private var blockContent: some View {
        switch block.content {
        case .heading(let level, let text):
            headingView(level: level, text: text)

        case .paragraph(let text):
            Text(text)
                .font(AppTypography.bodyMedium)
                .textSelection(.enabled)

        case .codeBlock(let language, let code):
            CodeBlockView(code: code, language: language)

        case .blockquote(let blocks):
            blockquoteView(blocks: blocks)

        case .unorderedList(let items):
            unorderedListView(items: items)

        case .orderedList(let items, let startIndex):
            orderedListView(items: items, startIndex: startIndex)

        case .image(let source, let alt):
            MarkdownImageView(source: source, altText: alt)

        case .thematicBreak:
            Divider()
                .padding(.vertical, AppSpacing.sm)

        case .table(let headers, let rows):
            MarkdownTableView(headers: headers, rows: rows)

        case .htmlBlock(let content):
            // Simple HTML display (could be enhanced with WKWebView)
            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

        case .hint(let type, let content):
            HintBlockView(type: type, content: content)

        case .tabs(let items):
            TabBlockView(tabs: items)

        case .expandable(let title, let content):
            ExpandableBlockView(title: title, content: content)
        }
    }

    // MARK: - Heading View

    private func headingView(level: Int, text: String) -> some View {
        Text(text)
            .font(headingFont(level: level))
            .fontWeight(.bold)
            .padding(.top, AppSpacing.sm)
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        case 5: return .headline
        default: return .subheadline
        }
    }

    // MARK: - Blockquote View

    private func blockquoteView(blocks: [MarkdownBlock]) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray3))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(blocks) { block in
                    MarkdownBlockView(block: block)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.leading, AppSpacing.sm)
    }

    // MARK: - Unordered List View

    private func unorderedListView(items: [ListItemBlock]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    // Bullet or checkbox
                    if let isChecked = item.isChecked {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .font(.system(size: 14))
                            .foregroundStyle(isChecked ? .green : .secondary)
                    } else {
                        Text("•")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        ForEach(item.content) { block in
                            MarkdownBlockView(block: block)
                        }
                    }
                }
            }
        }
        .padding(.leading, AppSpacing.sm)
    }

    // MARK: - Ordered List View

    private func orderedListView(items: [ListItemBlock], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    // Number
                    Text("\(startIndex + index).")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)

                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        ForEach(items[index].content) { block in
                            MarkdownBlockView(block: block)
                        }
                    }
                }
            }
        }
        .padding(.leading, AppSpacing.sm)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            MarkdownBlockView(block: .heading(level: 1, text: "Main Title"))
            MarkdownBlockView(block: .heading(level: 2, text: "Section Header"))

            MarkdownBlockView(block: .paragraph(text: AttributedString("This is a paragraph with some **bold** and *italic* text.")))

            MarkdownBlockView(block: .codeBlock(language: "swift", code: "let greeting = \"Hello\""))

            MarkdownBlockView(block: .unorderedList(items: [
                ListItemBlock(content: [.paragraph(text: AttributedString("First item"))], isChecked: nil),
                ListItemBlock(content: [.paragraph(text: AttributedString("Second item"))], isChecked: nil)
            ]))

            MarkdownBlockView(block: .orderedList(items: [
                ListItemBlock(content: [.paragraph(text: AttributedString("Step one"))], isChecked: nil),
                ListItemBlock(content: [.paragraph(text: AttributedString("Step two"))], isChecked: nil)
            ], startIndex: 1))

            MarkdownBlockView(block: .blockquote(blocks: [
                .paragraph(text: AttributedString("This is a quote."))
            ]))

            MarkdownBlockView(block: .thematicBreak())

            MarkdownBlockView(block: .hint(type: .info, content: [
                .paragraph(text: AttributedString("This is an info hint."))
            ]))
        }
        .padding()
    }
}
