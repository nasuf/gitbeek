//
//  MarkdownContentView.swift
//  GitBeek
//
//  Main container for rendering markdown content
//

import SwiftUI

/// View for rendering markdown content
struct MarkdownContentView: View {
    // MARK: - Properties

    let markdown: String
    let titleToSkip: String?

    @State private var blocks: [MarkdownBlock] = []
    @State private var isLoading = true
    @State private var parseError: Error?

    init(markdown: String, titleToSkip: String? = nil) {
        self.markdown = markdown
        self.titleToSkip = titleToSkip
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = parseError {
                errorView(error)
            } else if blocks.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .task {
            await parseMarkdown()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(blocks) { block in
                MarkdownBlockView(block: block)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text("Parsing content...")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.orange)

            Text("Failed to parse content")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)

            Text(error.localizedDescription)
                .font(AppTypography.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "doc.text")
                .font(.title)
                .foregroundStyle(.tertiary)

            Text("No content")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Parsing

    private func parseMarkdown() async {
        isLoading = true
        parseError = nil

        var parsed = await MarkdownParser.shared.parse(markdown)

        // Skip first heading if it matches titleToSkip
        if let titleToSkip = titleToSkip, !parsed.isEmpty {
            if case .heading(_, let text) = parsed[0].content,
               text.lowercased() == titleToSkip.lowercased() {
                parsed.removeFirst()
            }
        }

        await MainActor.run {
            blocks = parsed
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MarkdownContentView(markdown: """
        # Getting Started

        Welcome to the **GitBeek** documentation!

        ## Installation

        First, install the package:

        ```swift
        let package = Package(
            name: "MyApp",
            dependencies: [
                .package(url: "https://github.com/example/gitbeek", from: "1.0.0")
            ]
        )
        ```

        ## Features

        Here are the main features:

        - Easy to use API
        - Fast and reliable
        - Cross-platform support

        ### Steps to get started

        1. Create an account
        2. Generate an API key
        3. Make your first request

        > Note: Keep your API key secure!

        ## API Reference

        | Method | Endpoint | Description |
        |--------|----------|-------------|
        | GET | /users | List users |
        | POST | /users | Create user |

        ---

        That's it! You're ready to start building.
        """)
        .padding()
    }
}
