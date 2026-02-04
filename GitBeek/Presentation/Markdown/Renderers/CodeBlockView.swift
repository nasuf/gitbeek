//
//  CodeBlockView.swift
//  GitBeek
//
//  Code block with Highlightr multi-language syntax highlighting
//

import SwiftUI
import Highlightr

/// View for rendering code blocks with syntax highlighting
struct CodeBlockView: View {
    // MARK: - Properties

    let code: String
    let language: String?

    // MARK: - Environment

    @Environment(\.codeTheme) private var codeTheme
    @Environment(\.fontScale) private var fontScale

    // MARK: - State

    @State private var highlightedCode: AttributedString?
    @State private var isCopied = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            header

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                codeContent
                    .padding()
            }
        }
        .background(codeTheme.isDark ? Color.black.opacity(0.85) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
        .task {
            await highlightCode()
        }
        .onChange(of: codeTheme) { _, _ in
            Task { await highlightCode() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Language label
            if let language = language, !language.isEmpty {
                Text(language.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(codeTheme.isDark ? .white.opacity(0.6) : .secondary)
            }

            Spacer()

            // Copy button
            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .frame(width: 12, height: 12)

                    Text(isCopied ? "Copied" : "Copy")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 42, alignment: .leading)
                }
                .foregroundStyle(isCopied ? (codeTheme.isDark ? Color(red: 0.4, green: 1.0, blue: 0.4) : .green) : (codeTheme.isDark ? .white.opacity(0.7) : .secondary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(codeTheme.isDark ? Color.black.opacity(0.7) : Color(.systemGray5))
    }

    // MARK: - Code Content

    @ViewBuilder
    private var codeContent: some View {
        if let highlighted = highlightedCode {
            Text(highlighted)
                .font(.system(size: 13 * fontScale, weight: .regular, design: .monospaced))
                .textSelection(.enabled)
        } else {
            Text(code)
                .font(.system(size: 13 * fontScale, weight: .regular, design: .monospaced))
                .foregroundStyle(codeTheme.isDark ? .white : .primary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Syntax Highlighting

    private func highlightCode() async {
        // Use Highlightr for syntax highlighting (supports 185+ languages)
        guard let lang = language, !lang.isEmpty else {
            return
        }

        // Create highlighter instance with current theme
        let highlightr = Highlightr()
        highlightr?.setTheme(to: codeTheme.highlightrThemeName)

        // Highlight code on background thread
        guard let highlighted = highlightr?.highlight(code, as: lang) else {
            return
        }

        // Convert NSAttributedString to AttributedString
        await MainActor.run {
            highlightedCode = AttributedString(highlighted)
        }
    }

    // MARK: - Copy

    private func copyToClipboard() {
        UIPasteboard.general.string = code
        HapticFeedback.success()

        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }

        // Reset after delay
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCopied = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            CodeBlockView(
                code: """
                func greet(name: String) -> String {
                    return "Hello, \\(name)!"
                }

                let message = greet(name: "World")
                print(message)
                """,
                language: "swift"
            )

            CodeBlockView(
                code: """
                function greet(name) {
                    return `Hello, ${name}!`;
                }

                const message = greet('World');
                console.log(message);
                """,
                language: "javascript"
            )

            CodeBlockView(
                code: "pip install gitbook",
                language: nil
            )
        }
        .padding()
    }
}
