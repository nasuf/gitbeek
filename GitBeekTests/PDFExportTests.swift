//
//  PDFExportTests.swift
//  GitBeekTests
//
//  Tests for PDF export functionality
//

import XCTest
@testable import GitBeek

final class PDFExportTests: XCTestCase {

    // MARK: - MarkdownToHTMLConverter Tests

    // MARK: Code Block Theme Tests

    func testCodeBlockLightTheme() {
        let converter = MarkdownToHTMLConverter(isDarkCodeTheme: false)
        let block = MarkdownBlock.codeBlock(language: "swift", code: "let x = 42")
        let html = converter.convert(blocks: [block])

        // Light theme should have light background
        XCTAssertTrue(html.contains("background-color: #f6f8fa"))
        XCTAssertTrue(html.contains("color: #24292e"))
        XCTAssertTrue(html.contains("-webkit-print-color-adjust: exact"))
    }

    func testCodeBlockDarkTheme() {
        let converter = MarkdownToHTMLConverter(isDarkCodeTheme: true)
        let block = MarkdownBlock.codeBlock(language: "swift", code: "let x = 42")
        let html = converter.convert(blocks: [block])

        // Dark theme should have dark background
        XCTAssertTrue(html.contains("background-color: #1e1e1e"))
        XCTAssertTrue(html.contains("color: #f8f8f2"))
        XCTAssertTrue(html.contains("-webkit-print-color-adjust: exact"))
    }

    func testCodeBlockWithLanguageClass() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.codeBlock(language: "python", code: "print('hello')")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("class=\"language-python\""))
    }

    func testCodeBlockWithoutLanguage() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.codeBlock(language: nil, code: "plain code")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<code class=\"\""))
    }

    func testCodeBlockEscapesHTML() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.codeBlock(language: "html", code: "<div>test</div>")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("&lt;div&gt;"))
        XCTAssertFalse(html.contains("<div>test</div>"))
    }

    // MARK: Heading Tests

    func testHeadingConversion() {
        let converter = MarkdownToHTMLConverter()

        for level in 1...6 {
            let block = MarkdownBlock.heading(level: level, text: "Heading \(level)")
            let html = converter.convert(blocks: [block])
            XCTAssertTrue(html.contains("<h\(level)>"))
            XCTAssertTrue(html.contains("</h\(level)>"))
        }
    }

    func testHeadingLevelClamping() {
        let converter = MarkdownToHTMLConverter()

        // Level 0 should become h1
        let block0 = MarkdownBlock.heading(level: 0, text: "Test")
        let html0 = converter.convert(blocks: [block0])
        XCTAssertTrue(html0.contains("<h1>"))

        // Level 7 should become h6
        let block7 = MarkdownBlock.heading(level: 7, text: "Test")
        let html7 = converter.convert(blocks: [block7])
        XCTAssertTrue(html7.contains("<h6>"))
    }

    func testHeadingEscapesHTML() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.heading(level: 1, text: "<script>alert('xss')</script>")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("<script>"))
    }

    // MARK: Paragraph Tests

    func testParagraphConversion() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.paragraph(text: AttributedString("Hello world"))
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<p>"))
        XCTAssertTrue(html.contains("Hello world"))
        XCTAssertTrue(html.contains("</p>"))
    }

    // MARK: List Tests

    func testUnorderedListConversion() {
        let converter = MarkdownToHTMLConverter()
        let items = [
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Item 1"))], isChecked: nil),
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Item 2"))], isChecked: nil)
        ]
        let block = MarkdownBlock.unorderedList(items: items)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>"))
        XCTAssertTrue(html.contains("</ul>"))
    }

    func testOrderedListConversion() {
        let converter = MarkdownToHTMLConverter()
        let items = [
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("First"))], isChecked: nil),
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Second"))], isChecked: nil)
        ]
        let block = MarkdownBlock.orderedList(items: items, startIndex: 1)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>"))
        XCTAssertTrue(html.contains("</ol>"))
    }

    func testOrderedListWithCustomStart() {
        let converter = MarkdownToHTMLConverter()
        let items = [
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Fifth"))], isChecked: nil)
        ]
        let block = MarkdownBlock.orderedList(items: items, startIndex: 5)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("start=\"5\""))
    }

    func testTaskListConversion() {
        let converter = MarkdownToHTMLConverter()
        let items = [
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Done"))], isChecked: true),
            ListItemBlock(content: [MarkdownBlock.paragraph(text: AttributedString("Todo"))], isChecked: false)
        ]
        let block = MarkdownBlock.unorderedList(items: items)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("class=\"task-list\""))
        XCTAssertTrue(html.contains("class=\"task-checkbox\""))
        XCTAssertTrue(html.contains("☑"))
        XCTAssertTrue(html.contains("☐"))
    }

    // MARK: Table Tests

    func testTableConversion() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.table(
            headers: ["Name", "Value"],
            rows: [["Item 1", "100"], ["Item 2", "200"]]
        )
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<th>Name</th>"))
        XCTAssertTrue(html.contains("<td>100</td>"))
    }

    func testTableEscapesHTML() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.table(
            headers: ["<Header>"],
            rows: [["<Cell>"]]
        )
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("&lt;Header&gt;"))
        XCTAssertTrue(html.contains("&lt;Cell&gt;"))
    }

    // MARK: Blockquote Tests

    func testBlockquoteConversion() {
        let converter = MarkdownToHTMLConverter()
        let innerBlock = MarkdownBlock.paragraph(text: AttributedString("Quote text"))
        let block = MarkdownBlock.blockquote(blocks: [innerBlock])
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("Quote text"))
        XCTAssertTrue(html.contains("</blockquote>"))
    }

    // MARK: Image Tests

    func testImageConversion() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.image(source: "https://example.com/img.png", alt: "Alt text")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("<figure>"))
        XCTAssertTrue(html.contains("<img src=\"https://example.com/img.png\""))
        XCTAssertTrue(html.contains("alt=\"Alt text\""))
        XCTAssertTrue(html.contains("<figcaption>Alt text</figcaption>"))
    }

    func testImageWithoutAlt() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.image(source: "https://example.com/img.png", alt: nil)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("alt=\"\""))
        XCTAssertFalse(html.contains("<figcaption>"))
    }

    func testImageWithImageMap() {
        let imageMap = ["https://example.com/img.png": "data:image/png;base64,ABC123"]
        let converter = MarkdownToHTMLConverter(imageMap: imageMap)
        let block = MarkdownBlock.image(source: "https://example.com/img.png", alt: nil)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("data:image/png;base64,ABC123"))
        XCTAssertFalse(html.contains("https://example.com/img.png"))
    }

    // MARK: Thematic Break Tests

    func testThematicBreakConversion() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.thematicBreak()
        let html = converter.convert(blocks: [block])

        XCTAssertEqual(html, "<hr>")
    }

    // MARK: HTML Block Tests

    func testHTMLBlockPassthrough() {
        let converter = MarkdownToHTMLConverter()
        let htmlContent = "<div class=\"custom\">Content</div>"
        let block = MarkdownBlock.htmlBlock(content: htmlContent)
        let html = converter.convert(blocks: [block])

        XCTAssertEqual(html, htmlContent)
    }

    // MARK: Hint Tests

    func testHintConversionAllTypes() {
        let converter = MarkdownToHTMLConverter()
        let innerBlock = MarkdownBlock.paragraph(text: AttributedString("Hint content"))

        let types: [HintType] = [.info, .success, .warning, .danger]
        let expectedIcons = ["ℹ️", "✅", "⚠️", "🚨"]
        let expectedTitles = ["Info", "Success", "Warning", "Danger"]

        for (index, type) in types.enumerated() {
            let block = MarkdownBlock.hint(type: type, content: [innerBlock])
            let html = converter.convert(blocks: [block])

            XCTAssertTrue(html.contains("class=\"hint hint-\(type.rawValue)\""))
            XCTAssertTrue(html.contains(expectedIcons[index]))
            XCTAssertTrue(html.contains(expectedTitles[index]))
        }
    }

    // MARK: Tabs Tests

    func testTabsConversion() {
        let converter = MarkdownToHTMLConverter()
        let tabContent = MarkdownBlock.paragraph(text: AttributedString("Tab content"))
        let tabs = [
            TabItem(title: "Tab 1", content: [tabContent]),
            TabItem(title: "Tab 2", content: [tabContent])
        ]
        let block = MarkdownBlock.tabs(items: tabs)
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("class=\"tabs-container\""))
        XCTAssertTrue(html.contains("class=\"tab-section\""))
        XCTAssertTrue(html.contains("class=\"tab-title\""))
        XCTAssertTrue(html.contains("Tab 1"))
        XCTAssertTrue(html.contains("Tab 2"))
    }

    // MARK: Expandable Tests

    func testExpandableConversion() {
        let converter = MarkdownToHTMLConverter()
        let content = MarkdownBlock.paragraph(text: AttributedString("Expandable content"))
        let block = MarkdownBlock.expandable(title: "Click to expand", content: [content])
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("class=\"expandable\""))
        XCTAssertTrue(html.contains("class=\"expandable-title\""))
        XCTAssertTrue(html.contains("Click to expand"))
        XCTAssertTrue(html.contains("Expandable content"))
    }

    // MARK: Embed Tests

    func testEmbedConversionAllTypes() {
        let converter = MarkdownToHTMLConverter()

        let testCases: [(EmbedType, String, String)] = [
            (.youtube, "🎬", "YouTube Video"),
            (.vimeo, "🎬", "Vimeo Video"),
            (.twitter, "🐦", "Twitter/X Post"),
            (.github, "🐙", "GitHub"),
            (.codepen, "💻", "CodePen"),
            (.figma, "🎨", "Figma Design"),
            (.loom, "📹", "Loom Video"),
            (.generic, "🔗", "Embedded Content")
        ]

        for (type, expectedIcon, expectedName) in testCases {
            let block = MarkdownBlock.embed(type: type, url: "https://example.com", title: nil)
            let html = converter.convert(blocks: [block])

            XCTAssertTrue(html.contains("class=\"embed\""))
            XCTAssertTrue(html.contains(expectedIcon), "Expected icon \(expectedIcon) for type \(type)")
            XCTAssertTrue(html.contains(expectedName), "Expected name \(expectedName) for type \(type)")
        }
    }

    func testEmbedWithCustomTitle() {
        let converter = MarkdownToHTMLConverter()
        let block = MarkdownBlock.embed(type: .youtube, url: "https://youtube.com/watch?v=123", title: "My Video")
        let html = converter.convert(blocks: [block])

        XCTAssertTrue(html.contains("My Video"))
        XCTAssertFalse(html.contains("YouTube Video"))
    }

    // MARK: Multiple Blocks Tests

    func testMultipleBlocksConversion() {
        let converter = MarkdownToHTMLConverter()
        let blocks = [
            MarkdownBlock.heading(level: 1, text: "Title"),
            MarkdownBlock.paragraph(text: AttributedString("Content")),
            MarkdownBlock.codeBlock(language: "swift", code: "let x = 1")
        ]
        let html = converter.convert(blocks: blocks)

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<p>Content</p>"))
        XCTAssertTrue(html.contains("<pre"))
    }

    func testEmptyBlocksConversion() {
        let converter = MarkdownToHTMLConverter()
        let html = converter.convert(blocks: [])

        XCTAssertEqual(html, "")
    }

    // MARK: - PDFStyleSheet Tests

    func testGenerateCSSLightTheme() {
        let css = PDFStyleSheet.generateCSS(isDarkCodeTheme: false)

        // Should contain base CSS
        XCTAssertTrue(css.contains("box-sizing: border-box"))
        XCTAssertTrue(css.contains("font-family:"))

        // Should contain light theme
        XCTAssertTrue(css.contains("background: #f6f8fa"))
        XCTAssertFalse(css.contains("background: #1e1e1e"))
    }

    func testGenerateCSSDarkTheme() {
        let css = PDFStyleSheet.generateCSS(isDarkCodeTheme: true)

        // Should contain base CSS
        XCTAssertTrue(css.contains("box-sizing: border-box"))

        // Should contain dark theme
        XCTAssertTrue(css.contains("background: #1e1e1e"))
    }

    func testInlineCodeAlwaysLightBackground() {
        let css = PDFStyleSheet.baseCSS

        // Inline code should always have light gray background
        XCTAssertTrue(css.contains(":not(pre) > code"))
        XCTAssertTrue(css.contains("background-color: #f0f0f0"))
    }

    func testWrapInHTMLLightTheme() {
        let html = PDFStyleSheet.wrapInHTML(body: "<p>Test</p>", title: "Test Title", isDarkCodeTheme: false)

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<title>Test Title</title>"))
        XCTAssertTrue(html.contains("<p>Test</p>"))
        XCTAssertTrue(html.contains("highlight.js"))

        // Light theme CSS
        XCTAssertTrue(html.contains("background: #f6f8fa"))
    }

    func testWrapInHTMLDarkTheme() {
        let html = PDFStyleSheet.wrapInHTML(body: "<p>Test</p>", title: "Test Title", isDarkCodeTheme: true)

        // Dark theme CSS
        XCTAssertTrue(html.contains("background: #1e1e1e"))
    }

    func testWrapInHTMLEscapesTitle() {
        let html = PDFStyleSheet.wrapInHTML(body: "", title: "<script>alert('xss')</script>", isDarkCodeTheme: false)

        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("<script>alert"))
    }

    func testEscapeHTML() {
        let escaped = PDFStyleSheet.escapeHTML("<div class=\"test\">'Hello' & World</div>")

        XCTAssertEqual(escaped, "&lt;div class=&quot;test&quot;&gt;&#39;Hello&#39; &amp; World&lt;/div&gt;")
    }

    func testEscapeHTMLAllCharacters() {
        // Test each special character individually
        XCTAssertEqual(PDFStyleSheet.escapeHTML("&"), "&amp;")
        XCTAssertEqual(PDFStyleSheet.escapeHTML("<"), "&lt;")
        XCTAssertEqual(PDFStyleSheet.escapeHTML(">"), "&gt;")
        XCTAssertEqual(PDFStyleSheet.escapeHTML("\""), "&quot;")
        XCTAssertEqual(PDFStyleSheet.escapeHTML("'"), "&#39;")
    }

    func testEscapeHTMLPreservesNormalText() {
        let text = "Hello World 123"
        XCTAssertEqual(PDFStyleSheet.escapeHTML(text), text)
    }

    // MARK: - Print Color Adjust Tests

    func testPrintColorAdjustInCSS() {
        let lightCSS = PDFStyleSheet.lightCodeThemeCSS
        let darkCSS = PDFStyleSheet.darkCodeThemeCSS

        // Both themes should have print color adjust for proper PDF rendering
        XCTAssertTrue(lightCSS.contains("-webkit-print-color-adjust: exact"))
        XCTAssertTrue(darkCSS.contains("-webkit-print-color-adjust: exact"))
    }

    func testPrintColorAdjustInInlineStyles() {
        let lightConverter = MarkdownToHTMLConverter(isDarkCodeTheme: false)
        let darkConverter = MarkdownToHTMLConverter(isDarkCodeTheme: true)

        let block = MarkdownBlock.codeBlock(language: "swift", code: "test")

        let lightHTML = lightConverter.convert(blocks: [block])
        let darkHTML = darkConverter.convert(blocks: [block])

        // Both should have print color adjust in inline styles
        XCTAssertTrue(lightHTML.contains("-webkit-print-color-adjust: exact"))
        XCTAssertTrue(darkHTML.contains("-webkit-print-color-adjust: exact"))
    }

    // MARK: - Integration Tests

    func testCompleteHTMLGenerationLightTheme() {
        let converter = MarkdownToHTMLConverter(isDarkCodeTheme: false)
        let blocks = [
            MarkdownBlock.heading(level: 1, text: "API Documentation"),
            MarkdownBlock.paragraph(text: AttributedString("This is a test.")),
            MarkdownBlock.codeBlock(language: "swift", code: "let api = API()")
        ]

        let body = converter.convert(blocks: blocks)
        let html = PDFStyleSheet.wrapInHTML(body: body, title: "API Documentation", isDarkCodeTheme: false)

        // Verify complete HTML structure
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<html"))
        XCTAssertTrue(html.contains("</html>"))

        // Verify content
        XCTAssertTrue(html.contains("<h1>API Documentation</h1>"))
        XCTAssertTrue(html.contains("<p>This is a test.</p>"))
        XCTAssertTrue(html.contains("let api = API()"))

        // Verify light theme applied
        XCTAssertTrue(html.contains("background-color: #f6f8fa"))
    }

    func testCompleteHTMLGenerationDarkTheme() {
        let converter = MarkdownToHTMLConverter(isDarkCodeTheme: true)
        let blocks = [
            MarkdownBlock.codeBlock(language: "python", code: "print('hello')")
        ]

        let body = converter.convert(blocks: blocks)
        let html = PDFStyleSheet.wrapInHTML(body: body, title: "Test", isDarkCodeTheme: true)

        // Verify dark theme in both inline styles and CSS
        XCTAssertTrue(html.contains("background-color: #1e1e1e"))  // inline style
        XCTAssertTrue(html.contains("background: #1e1e1e"))        // CSS
    }
}
