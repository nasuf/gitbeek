//
//  PDFStyleSheet.swift
//  GitBeek
//
//  CSS styles for PDF export
//

import Foundation

/// CSS stylesheet for PDF export
enum PDFStyleSheet {
    /// Base CSS (without code theme)
    static let baseCSS: String = """
    /* Base styles */
    * {
        box-sizing: border-box;
    }

    html {
        font-size: 14px;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
        line-height: 1.6;
        color: #1a1a1a;
        margin: 0;
        padding: 40px;
        background: white;
    }

    /* Typography */
    h1, h2, h3, h4, h5, h6 {
        margin-top: 1.5em;
        margin-bottom: 0.5em;
        font-weight: 600;
        line-height: 1.3;
        page-break-after: avoid;
    }

    h1 { font-size: 2rem; margin-top: 0; }
    h2 { font-size: 1.6rem; }
    h3 { font-size: 1.35rem; }
    h4 { font-size: 1.15rem; }
    h5 { font-size: 1rem; }
    h6 { font-size: 0.9rem; }

    p {
        margin: 0 0 1em 0;
        orphans: 3;
        widows: 3;
    }

    /* Links */
    a {
        color: #0066cc;
        text-decoration: none;
    }

    @media print {
        a[href]:after {
            content: " (" attr(href) ")";
            font-size: 0.8em;
            color: #666;
        }
        a[href^="#"]:after,
        a[href^="javascript"]:after {
            content: "";
        }
    }

    /* Code blocks - with word wrap for PDF */
    pre {
        border-radius: 8px;
        padding: 16px;
        font-size: 0.85rem;
        line-height: 1.5;
        margin: 1em 0;
        page-break-inside: avoid;
        /* Enable word wrap for PDF */
        white-space: pre-wrap;
        word-wrap: break-word;
        word-break: break-word;
        overflow-wrap: break-word;
    }

    pre code {
        background: none;
        padding: 0;
        border-radius: 0;
        font-size: inherit;
        white-space: pre-wrap;
        word-wrap: break-word;
        word-break: break-word;
    }

    code {
        font-family: 'SF Mono', SFMono-Regular, Menlo, Monaco, Consolas, monospace;
        padding: 0.2em 0.4em;
        border-radius: 4px;
        font-size: 0.9em;
    }

    /* Inline code (not in pre blocks) - always use light gray background */
    :not(pre) > code {
        background-color: #f0f0f0 !important;
        color: #24292e !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
    }

    /* Images */
    figure {
        margin: 1.5em 0;
        page-break-inside: avoid;
    }

    img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 0 auto;
        border-radius: 8px;
    }

    figcaption {
        text-align: center;
        color: #666;
        font-size: 0.85rem;
        margin-top: 0.5em;
    }

    /* Tables */
    table {
        width: 100%;
        border-collapse: collapse;
        margin: 1em 0;
        page-break-inside: avoid;
        font-size: 0.9rem;
    }

    th, td {
        border: 1px solid #ddd;
        padding: 10px 12px;
        text-align: left;
    }

    th {
        background: #f6f8fa;
        font-weight: 600;
    }

    tr:nth-child(even) {
        background: #fafbfc;
    }

    /* Lists */
    ul, ol {
        margin: 1em 0;
        padding-left: 2em;
    }

    li {
        margin: 0.3em 0;
    }

    li > ul, li > ol {
        margin: 0.3em 0;
    }

    /* Task lists */
    .task-list {
        list-style: none;
        padding-left: 0;
    }

    .task-list li {
        position: relative;
        padding-left: 1.8em;
    }

    .task-checkbox {
        position: absolute;
        left: 0;
        top: 0.15em;
    }

    /* Blockquotes */
    blockquote {
        margin: 1em 0;
        padding: 0.5em 1em;
        border-left: 4px solid #ddd;
        background: #f9f9f9;
        color: #555;
        page-break-inside: avoid;
    }

    blockquote p {
        margin: 0.5em 0;
    }

    /* Horizontal rule */
    hr {
        border: none;
        border-top: 1px solid #ddd;
        margin: 2em 0;
    }

    /* GitBook Hints */
    .hint {
        margin: 1em 0;
        padding: 16px;
        border-radius: 8px;
        border-left: 4px solid;
        page-break-inside: avoid;
    }

    .hint-icon {
        font-size: 1.1em;
        margin-right: 8px;
    }

    .hint-title {
        font-weight: 600;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
    }

    .hint-info {
        background: #e7f3ff;
        border-color: #0066cc;
    }
    .hint-info .hint-title { color: #0066cc; }

    .hint-success {
        background: #e6f7e6;
        border-color: #28a745;
    }
    .hint-success .hint-title { color: #28a745; }

    .hint-warning {
        background: #fff8e6;
        border-color: #f59e0b;
    }
    .hint-warning .hint-title { color: #b45309; }

    .hint-danger {
        background: #fee;
        border-color: #dc3545;
    }
    .hint-danger .hint-title { color: #dc3545; }

    .hint p:last-child {
        margin-bottom: 0;
    }

    /* Tabs (expanded for PDF) */
    .tabs-container {
        margin: 1em 0;
        page-break-inside: avoid;
    }

    .tab-section {
        margin-bottom: 1.5em;
        padding: 16px;
        background: #f9f9f9;
        border-radius: 8px;
        border: 1px solid #e1e4e8;
    }

    .tab-title {
        font-weight: 600;
        font-size: 1rem;
        margin-bottom: 12px;
        padding-bottom: 8px;
        border-bottom: 2px solid #0066cc;
        color: #0066cc;
    }

    /* Expandable (always expanded for PDF) */
    .expandable {
        margin: 1em 0;
        border: 1px solid #e1e4e8;
        border-radius: 8px;
        page-break-inside: avoid;
    }

    .expandable-title {
        font-weight: 600;
        padding: 12px 16px;
        background: #f6f8fa;
        border-radius: 8px 8px 0 0;
        border-bottom: 1px solid #e1e4e8;
    }

    .expandable-content {
        padding: 16px;
    }

    /* Embed placeholder */
    .embed {
        margin: 1em 0;
        padding: 20px;
        background: #f6f8fa;
        border: 1px dashed #ccc;
        border-radius: 8px;
        text-align: center;
        page-break-inside: avoid;
    }

    .embed-icon {
        font-size: 2em;
        margin-bottom: 8px;
    }

    .embed-title {
        font-weight: 600;
        margin-bottom: 4px;
    }

    .embed-url {
        font-size: 0.85rem;
        color: #0066cc;
        word-break: break-all;
    }

    /* Print-specific styles */
    @media print {
        body {
            padding: 20px;
        }

        pre, blockquote, table, .hint, .expandable, figure {
            page-break-inside: avoid;
        }

        h1, h2, h3, h4, h5, h6 {
            page-break-after: avoid;
        }

        img {
            max-height: 400px;
            object-fit: contain;
        }
    }
    """

    /// Light code theme CSS (GitHub Light style)
    static let lightCodeThemeCSS: String = """
    /* Light theme code block - apply only to pre blocks, not inline code */
    pre {
        background: #f6f8fa !important;
        background-color: #f6f8fa !important;
        border: 1px solid #e1e4e8 !important;
        color: #24292e !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
    }

    pre code {
        background: transparent !important;
        background-color: transparent !important;
        color: #24292e !important;
    }

    /* Highlight.js - GitHub Light */
    .hljs {
        color: #24292e !important;
        background: #f6f8fa !important;
        background-color: #f6f8fa !important;
    }

    pre .hljs {
        background: transparent !important;
        background-color: transparent !important;
    }

    /* Force print to respect background colors for code blocks */
    @media print {
        pre {
            background: #f6f8fa !important;
            background-color: #f6f8fa !important;
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }
        pre code {
            background: transparent !important;
            background-color: transparent !important;
            color: #24292e !important;
        }
    }

    .hljs-doctag,
    .hljs-keyword,
    .hljs-meta .hljs-keyword,
    .hljs-template-tag,
    .hljs-template-variable,
    .hljs-type,
    .hljs-variable.language_ {
        color: #d73a49;
    }

    .hljs-title,
    .hljs-title.class_,
    .hljs-title.class_.inherited__,
    .hljs-title.function_ {
        color: #6f42c1;
    }

    .hljs-attr,
    .hljs-attribute,
    .hljs-literal,
    .hljs-meta,
    .hljs-number,
    .hljs-operator,
    .hljs-variable,
    .hljs-selector-attr,
    .hljs-selector-class,
    .hljs-selector-id {
        color: #005cc5;
    }

    .hljs-regexp,
    .hljs-string,
    .hljs-meta .hljs-string {
        color: #032f62;
    }

    .hljs-built_in,
    .hljs-symbol {
        color: #e36209;
    }

    .hljs-comment,
    .hljs-code,
    .hljs-formula {
        color: #6a737d;
    }

    .hljs-name,
    .hljs-quote,
    .hljs-selector-tag,
    .hljs-selector-pseudo {
        color: #22863a;
    }

    .hljs-subst {
        color: #24292e;
    }

    .hljs-section {
        color: #005cc5;
        font-weight: bold;
    }

    .hljs-bullet {
        color: #735c0f;
    }

    .hljs-emphasis {
        color: #24292e;
        font-style: italic;
    }

    .hljs-strong {
        color: #24292e;
        font-weight: bold;
    }

    .hljs-addition {
        color: #22863a;
        background-color: #f0fff4;
    }

    .hljs-deletion {
        color: #b31d28;
        background-color: #ffeef0;
    }
    """

    /// Dark code theme CSS (GitHub Dark / Monokai style)
    static let darkCodeThemeCSS: String = """
    /* Dark theme code block - apply only to pre blocks, not inline code */
    pre {
        background: #1e1e1e !important;
        background-color: #1e1e1e !important;
        border: 1px solid #444 !important;
        color: #f8f8f2 !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        color-adjust: exact !important;
    }

    pre code {
        background: transparent !important;
        background-color: transparent !important;
        color: #f8f8f2 !important;
    }

    /* Highlight.js - Dark theme (Monokai-inspired) - if highlight.js loads */
    .hljs {
        color: #f8f8f2 !important;
        background: #1e1e1e !important;
        background-color: #1e1e1e !important;
    }

    pre .hljs {
        background: transparent !important;
        background-color: transparent !important;
    }

    /* Force print to respect background colors for code blocks only */
    @media print {
        pre {
            background: #1e1e1e !important;
            background-color: #1e1e1e !important;
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
            color-adjust: exact !important;
        }
        pre code {
            background: transparent !important;
            background-color: transparent !important;
            color: #f8f8f2 !important;
        }
    }

    .hljs-doctag,
    .hljs-keyword,
    .hljs-meta .hljs-keyword,
    .hljs-template-tag,
    .hljs-template-variable,
    .hljs-type,
    .hljs-variable.language_ {
        color: #ff79c6;
    }

    .hljs-title,
    .hljs-title.class_,
    .hljs-title.class_.inherited__,
    .hljs-title.function_ {
        color: #a6e22e;
    }

    .hljs-attr,
    .hljs-attribute,
    .hljs-literal,
    .hljs-meta,
    .hljs-number,
    .hljs-operator,
    .hljs-variable,
    .hljs-selector-attr,
    .hljs-selector-class,
    .hljs-selector-id {
        color: #ae81ff;
    }

    .hljs-regexp,
    .hljs-string,
    .hljs-meta .hljs-string {
        color: #e6db74;
    }

    .hljs-built_in,
    .hljs-symbol {
        color: #66d9ef;
    }

    .hljs-comment,
    .hljs-code,
    .hljs-formula {
        color: #75715e;
    }

    .hljs-name,
    .hljs-quote,
    .hljs-selector-tag,
    .hljs-selector-pseudo {
        color: #f92672;
    }

    .hljs-subst {
        color: #f8f8f2;
    }

    .hljs-section {
        color: #a6e22e;
        font-weight: bold;
    }

    .hljs-bullet {
        color: #ae81ff;
    }

    .hljs-emphasis {
        color: #f8f8f2;
        font-style: italic;
    }

    .hljs-strong {
        color: #f8f8f2;
        font-weight: bold;
    }

    .hljs-addition {
        color: #a6e22e;
        background-color: #2a3d2a;
    }

    .hljs-deletion {
        color: #f92672;
        background-color: #3d2a2a;
    }
    """

    /// Highlight.js CDN URL (minified)
    static let highlightJSURL = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"

    /// Generate complete CSS with specified code theme
    static func generateCSS(isDarkCodeTheme: Bool) -> String {
        let codeThemeCSS = isDarkCodeTheme ? darkCodeThemeCSS : lightCodeThemeCSS
        return baseCSS + "\n" + codeThemeCSS
    }

    /// Generate complete HTML document
    static func wrapInHTML(body: String, title: String, isDarkCodeTheme: Bool = false) -> String {
        let css = generateCSS(isDarkCodeTheme: isDarkCodeTheme)
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(title))</title>
            <style>
            \(css)
            </style>
        </head>
        <body>
            \(body)
            <script src="\(highlightJSURL)"></script>
            <script>hljs.highlightAll();</script>
        </body>
        </html>
        """
    }

    /// Escape HTML special characters
    static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
