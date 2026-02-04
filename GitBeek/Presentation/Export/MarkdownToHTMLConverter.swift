//
//  MarkdownToHTMLConverter.swift
//  GitBeek
//
//  Convert MarkdownBlock array to HTML for PDF export
//

import Foundation

/// Converts MarkdownBlock array to HTML string
struct MarkdownToHTMLConverter {
    // MARK: - Properties

    /// Map of original image URLs to Base64 Data URIs
    private let imageMap: [String: String]

    /// Whether to use dark theme for code blocks
    private let isDarkCodeTheme: Bool

    // MARK: - Initialization

    init(imageMap: [String: String] = [:], isDarkCodeTheme: Bool = false) {
        self.imageMap = imageMap
        self.isDarkCodeTheme = isDarkCodeTheme
    }

    // MARK: - Public Methods

    /// Convert blocks to HTML body content
    func convert(blocks: [MarkdownBlock]) -> String {
        blocks.map { convertBlock($0) }.joined(separator: "\n")
    }

    // MARK: - Block Conversion

    private func convertBlock(_ block: MarkdownBlock) -> String {
        switch block.content {
        case let .heading(level, text):
            return convertHeading(level: level, text: text)

        case let .paragraph(text):
            return convertParagraph(text: text)

        case let .codeBlock(language, code):
            return convertCodeBlock(language: language, code: code)

        case let .blockquote(blocks):
            return convertBlockquote(blocks: blocks)

        case let .unorderedList(items):
            return convertUnorderedList(items: items)

        case let .orderedList(items, startIndex):
            return convertOrderedList(items: items, startIndex: startIndex)

        case let .image(source, alt):
            return convertImage(source: source, alt: alt)

        case .thematicBreak:
            return "<hr>"

        case let .table(headers, rows):
            return convertTable(headers: headers, rows: rows)

        case let .htmlBlock(content):
            return content

        case let .hint(type, content):
            return convertHint(type: type, content: content)

        case let .tabs(items):
            return convertTabs(items: items)

        case let .expandable(title, content):
            return convertExpandable(title: title, content: content)

        case let .embed(type, url, title):
            return convertEmbed(type: type, url: url, title: title)
        }
    }

    // MARK: - Standard Blocks

    private func convertHeading(level: Int, text: String) -> String {
        let tag = "h\(min(max(level, 1), 6))"
        return "<\(tag)>\(escape(text))</\(tag)>"
    }

    private func convertParagraph(text: AttributedString) -> String {
        "<p>\(convertAttributedString(text))</p>"
    }

    private func convertCodeBlock(language: String?, code: String) -> String {
        let langClass = language.map { "language-\($0)" } ?? ""

        // Apply inline styles to ensure theme is respected in PDF print context
        // -webkit-print-color-adjust: exact forces WebKit to print background colors
        let preStyle: String
        let codeStyle: String

        if isDarkCodeTheme {
            preStyle = "background-color: #1e1e1e; border: 1px solid #444; color: #f8f8f2; -webkit-print-color-adjust: exact; print-color-adjust: exact;"
            codeStyle = "background-color: transparent; color: #f8f8f2;"
        } else {
            preStyle = "background-color: #f6f8fa; border: 1px solid #e1e4e8; color: #24292e; -webkit-print-color-adjust: exact; print-color-adjust: exact;"
            codeStyle = "background-color: transparent; color: #24292e;"
        }

        return """
        <pre style="\(preStyle)"><code class="\(langClass)" style="\(codeStyle)">\(escape(code))</code></pre>
        """
    }

    private func convertBlockquote(blocks: [MarkdownBlock]) -> String {
        let content = blocks.map { convertBlock($0) }.joined(separator: "\n")
        return "<blockquote>\(content)</blockquote>"
    }

    private func convertUnorderedList(items: [ListItemBlock]) -> String {
        let hasCheckboxes = items.contains { $0.isChecked != nil }
        let listClass = hasCheckboxes ? " class=\"task-list\"" : ""

        var html = "<ul\(listClass)>"
        for item in items {
            html += convertListItem(item)
        }
        html += "</ul>"
        return html
    }

    private func convertOrderedList(items: [ListItemBlock], startIndex: Int) -> String {
        let startAttr = startIndex != 1 ? " start=\"\(startIndex)\"" : ""

        var html = "<ol\(startAttr)>"
        for item in items {
            html += convertListItem(item)
        }
        html += "</ol>"
        return html
    }

    private func convertListItem(_ item: ListItemBlock) -> String {
        let content = item.content.map { convertBlock($0) }.joined()

        if let isChecked = item.isChecked {
            let checkbox = isChecked ? "☑" : "☐"
            return "<li><span class=\"task-checkbox\">\(checkbox)</span>\(content)</li>"
        }

        return "<li>\(content)</li>"
    }

    private func convertImage(source: String, alt: String?) -> String {
        // Use Data URI if available, otherwise use original URL
        let src = imageMap[source] ?? source
        let altText = alt ?? ""

        var html = "<figure>"
        html += "<img src=\"\(src)\" alt=\"\(escape(altText))\">"
        if let alt = alt, !alt.isEmpty {
            html += "<figcaption>\(escape(alt))</figcaption>"
        }
        html += "</figure>"
        return html
    }

    private func convertTable(headers: [String], rows: [[String]]) -> String {
        var html = "<table>"

        // Header
        html += "<thead><tr>"
        for header in headers {
            html += "<th>\(escape(header))</th>"
        }
        html += "</tr></thead>"

        // Body
        html += "<tbody>"
        for row in rows {
            html += "<tr>"
            for cell in row {
                html += "<td>\(escape(cell))</td>"
            }
            html += "</tr>"
        }
        html += "</tbody>"

        html += "</table>"
        return html
    }

    // MARK: - GitBook Custom Blocks

    private func convertHint(type: HintType, content: [MarkdownBlock]) -> String {
        let icon: String
        let title: String

        switch type {
        case .info:
            icon = "ℹ️"
            title = "Info"
        case .success:
            icon = "✅"
            title = "Success"
        case .warning:
            icon = "⚠️"
            title = "Warning"
        case .danger:
            icon = "🚨"
            title = "Danger"
        }

        let innerContent = content.map { convertBlock($0) }.joined(separator: "\n")

        return """
        <div class="hint hint-\(type.rawValue)">
            <div class="hint-title"><span class="hint-icon">\(icon)</span>\(title)</div>
            \(innerContent)
        </div>
        """
    }

    private func convertTabs(items: [TabItem]) -> String {
        var html = "<div class=\"tabs-container\">"

        for item in items {
            let content = item.content.map { convertBlock($0) }.joined(separator: "\n")
            html += """
            <div class="tab-section">
                <div class="tab-title">\(escape(item.title))</div>
                \(content)
            </div>
            """
        }

        html += "</div>"
        return html
    }

    private func convertExpandable(title: String, content: [MarkdownBlock]) -> String {
        let innerContent = content.map { convertBlock($0) }.joined(separator: "\n")

        return """
        <div class="expandable">
            <div class="expandable-title">\(escape(title))</div>
            <div class="expandable-content">\(innerContent)</div>
        </div>
        """
    }

    private func convertEmbed(type: EmbedType, url: String, title: String?) -> String {
        let icon: String
        let platformName: String

        switch type {
        case .youtube:
            icon = "🎬"
            platformName = "YouTube Video"
        case .vimeo:
            icon = "🎬"
            platformName = "Vimeo Video"
        case .twitter:
            icon = "🐦"
            platformName = "Twitter/X Post"
        case .github:
            icon = "🐙"
            platformName = "GitHub"
        case .codepen:
            icon = "💻"
            platformName = "CodePen"
        case .figma:
            icon = "🎨"
            platformName = "Figma Design"
        case .loom:
            icon = "📹"
            platformName = "Loom Video"
        case .generic:
            icon = "🔗"
            platformName = "Embedded Content"
        }

        let displayTitle = title ?? platformName

        return """
        <div class="embed">
            <div class="embed-icon">\(icon)</div>
            <div class="embed-title">\(escape(displayTitle))</div>
            <a class="embed-url" href="\(escape(url))">\(escape(url))</a>
        </div>
        """
    }

    // MARK: - Attributed String Conversion

    private func convertAttributedString(_ attributedString: AttributedString) -> String {
        var result = ""

        for run in attributedString.runs {
            var text = String(attributedString[run.range].characters)

            // Check for link
            if let link = run.link {
                text = "<a href=\"\(escape(link.absoluteString))\">\(escape(text))</a>"
            } else {
                text = escape(text)
            }

            // Check for inline code (monospace font)
            if let font = run.font, font == .system(.body, design: .monospaced) {
                text = "<code>\(text)</code>"
            }

            // Check for bold
            if let font = run.font, font == .body.bold() {
                text = "<strong>\(text)</strong>"
            }

            // Check for italic
            if let font = run.font, font == .body.italic() {
                text = "<em>\(text)</em>"
            }

            // Check for strikethrough
            if run.strikethroughStyle != nil {
                text = "<del>\(text)</del>"
            }

            result += text
        }

        return result
    }

    // MARK: - Helpers

    private func escape(_ text: String) -> String {
        PDFStyleSheet.escapeHTML(text)
    }
}
