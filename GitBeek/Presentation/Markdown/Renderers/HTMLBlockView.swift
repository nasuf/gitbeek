//
//  HTMLBlockView.swift
//  GitBeek
//
//  HTML block renderer with <pre><code> support
//

import SwiftUI

/// View for rendering HTML blocks with special handling for code blocks
struct HTMLBlockView: View {
    let htmlContent: String

    // MARK: - Constants

    private static let preCodePattern = #"<pre[^>]*>\s*<code[^>]*>(.*?)</code>\s*</pre>"#
    private static let strongPattern = #"<strong>(.*?)</strong>"#
    private static let emPattern = #"<em>(.*?)</em>"#

    // MARK: - Body

    var body: some View {
        if let code = extractCodeFromPreTag() {
            // Reuse CodeBlockView for consistent styling
            CodeBlockView(code: code, language: nil)
        } else {
            formattedTextView
        }
    }

    // MARK: - Code Extraction

    /// Extracts code content from <pre><code> tags
    /// - Returns: Extracted and cleaned code string, or nil if not a code block
    private func extractCodeFromPreTag() -> String? {
        // Must use NSRegularExpression with dotMatchesLineSeparators for multi-line content
        guard let regex = try? NSRegularExpression(
            pattern: Self.preCodePattern,
            options: [.dotMatchesLineSeparators]
        ),
              let match = regex.firstMatch(
                in: htmlContent,
                range: NSRange(htmlContent.startIndex..., in: htmlContent)
              ),
              match.numberOfRanges > 1,
              let codeRange = Range(match.range(at: 1), in: htmlContent) else {
            return nil
        }

        var code = String(htmlContent[codeRange])

        // Convert <br> tags to newlines
        code = code.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)

        // Clean HTML tags
        code = cleanHTMLTags(from: code)

        // Trim whitespace
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Views

    private var formattedTextView: some View {
        Text(parseHTMLToAttributedString(htmlContent))
            .font(AppTypography.bodyMedium)
            .textSelection(.enabled)
    }

    // MARK: - HTML Processing

    private func cleanHTMLTags(from text: String) -> String {
        var result = text

        // Remove <strong> tags but keep content
        result = result.replacingOccurrences(
            of: Self.strongPattern,
            with: "$1",
            options: .regularExpression
        )

        // Remove <em> tags but keep content
        result = result.replacingOccurrences(
            of: Self.emPattern,
            with: "$1",
            options: .regularExpression
        )

        // Decode HTML entities
        result = decodeHTMLEntities(result)

        return result
    }

    private func parseHTMLToAttributedString(_ html: String) -> AttributedString {
        // Strip HTML tags and decode entities
        // TODO: Properly parse and apply formatting for <strong>, <em>, etc.
        var text = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = decodeHTMLEntities(text)
        return AttributedString(text)
    }

    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text

        // Common HTML entities
        let entities: [String: String] = [
            "&lt;": "<",
            "&gt;": ">",
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&#x27;": "'"
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        return result
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            // Code block example
            HTMLBlockView(htmlContent: """
                <pre><code>输入：nums = [2,1,6,4]
                输出：1
                <strong>解释：
                </strong>删除下标 0 ：[1,6,4] -> 偶数元素下标为：1 + 4 = 5
                </code></pre>
                """)

            // Plain HTML example
            HTMLBlockView(htmlContent: """
                <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
                """)
        }
        .padding()
    }
}
