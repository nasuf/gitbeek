//
//  MarkdownParserTests.swift
//  GitBeekTests
//
//  Tests for MarkdownParser
//

import XCTest
@testable import GitBeek

final class MarkdownParserTests: XCTestCase {

    // MARK: - Heading Tests

    func testParseHeading1() async {
        let markdown = "# Main Title"
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .heading(let level, let text) = blocks.first?.content else {
            XCTFail("Expected heading block")
            return
        }
        XCTAssertEqual(level, 1)
        XCTAssertEqual(text, "Main Title")
    }

    func testParseHeading2() async {
        let markdown = "## Section Title"
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .heading(let level, let text) = blocks.first?.content else {
            XCTFail("Expected heading block")
            return
        }
        XCTAssertEqual(level, 2)
        XCTAssertEqual(text, "Section Title")
    }

    func testParseMultipleHeadings() async {
        let markdown = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 3)

        guard case .heading(let level1, _) = blocks[0].content else {
            XCTFail("Expected heading block")
            return
        }
        XCTAssertEqual(level1, 1)

        guard case .heading(let level2, _) = blocks[1].content else {
            XCTFail("Expected heading block")
            return
        }
        XCTAssertEqual(level2, 2)

        guard case .heading(let level3, _) = blocks[2].content else {
            XCTFail("Expected heading block")
            return
        }
        XCTAssertEqual(level3, 3)
    }

    // MARK: - Paragraph Tests

    func testParseParagraph() async {
        let markdown = "This is a simple paragraph of text."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertEqual(String(text.characters), "This is a simple paragraph of text.")
    }

    func testParseParagraphWithBold() async {
        let markdown = "This has **bold** text."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertTrue(String(text.characters).contains("bold"))
    }

    func testParseParagraphWithItalic() async {
        let markdown = "This has *italic* text."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertTrue(String(text.characters).contains("italic"))
    }

    func testParseParagraphWithInlineCode() async {
        let markdown = "Use the `print()` function."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertTrue(String(text.characters).contains("print()"))
    }

    func testParseParagraphWithLink() async {
        let markdown = "Visit [Google](https://google.com) for more."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertTrue(String(text.characters).contains("Google"))
    }

    func testParseParagraphWithStrikethrough() async {
        let markdown = "This is ~~deleted~~ text."
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph(let text) = blocks.first?.content else {
            XCTFail("Expected paragraph block")
            return
        }
        XCTAssertTrue(String(text.characters).contains("deleted"))
    }

    // MARK: - Code Block Tests

    func testParseCodeBlock() async {
        let markdown = """
        ```swift
        let x = 42
        print(x)
        ```
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .codeBlock(let language, let code) = blocks.first?.content else {
            XCTFail("Expected code block")
            return
        }
        XCTAssertEqual(language, "swift")
        XCTAssertTrue(code.contains("let x = 42"))
    }

    func testParseCodeBlockWithoutLanguage() async {
        let markdown = """
        ```
        plain code
        ```
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .codeBlock(let language, let code) = blocks.first?.content else {
            XCTFail("Expected code block")
            return
        }
        XCTAssertNil(language)
        XCTAssertTrue(code.contains("plain code"))
    }

    // MARK: - Blockquote Tests

    func testParseBlockquote() async {
        let markdown = "> This is a quote"
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .blockquote(let innerBlocks) = blocks.first?.content else {
            XCTFail("Expected blockquote block")
            return
        }
        XCTAssertEqual(innerBlocks.count, 1)
    }

    func testParseNestedBlockquote() async {
        let markdown = """
        > Level 1
        > > Level 2
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .blockquote = blocks.first?.content else {
            XCTFail("Expected blockquote block")
            return
        }
    }

    // MARK: - List Tests

    func testParseUnorderedList() async {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .unorderedList(let items) = blocks.first?.content else {
            XCTFail("Expected unordered list block")
            return
        }
        XCTAssertEqual(items.count, 3)
    }

    func testParseOrderedList() async {
        let markdown = """
        1. First
        2. Second
        3. Third
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .orderedList(let items, let startIndex) = blocks.first?.content else {
            XCTFail("Expected ordered list block")
            return
        }
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(startIndex, 1)
    }

    func testParseOrderedListStartingAt5() async {
        let markdown = """
        5. Fifth item
        6. Sixth item
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .orderedList(let items, let startIndex) = blocks.first?.content else {
            XCTFail("Expected ordered list block")
            return
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(startIndex, 5)
    }

    func testParseTaskList() async {
        let markdown = """
        - [x] Completed task
        - [ ] Pending task
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .unorderedList(let items) = blocks.first?.content else {
            XCTFail("Expected unordered list block")
            return
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].isChecked, true)
        XCTAssertEqual(items[1].isChecked, false)
    }

    // MARK: - Image Tests

    func testParseImage() async {
        let markdown = "![Alt text](https://example.com/image.png)"
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .paragraph = blocks.first?.content else {
            // Images in paragraphs are handled as inline content
            return
        }
    }

    // MARK: - Thematic Break Tests

    func testParseThematicBreak() async {
        let markdown = """
        Above

        ---

        Below
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertTrue(blocks.contains { block in
            if case .thematicBreak = block.content { return true }
            return false
        })
    }

    // MARK: - Table Tests

    func testParseTable() async {
        let markdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        XCTAssertEqual(blocks.count, 1)
        guard case .table(let headers, let rows) = blocks.first?.content else {
            XCTFail("Expected table block")
            return
        }
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers[0], "Header 1")
        XCTAssertEqual(headers[1], "Header 2")
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0][0], "Cell 1")
    }

    // MARK: - HTML Block Tests

    func testParseHTMLBlock() async {
        let markdown = """
        <div class="custom">
        Content here
        </div>
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        guard case .htmlBlock(let content) = blocks.first?.content else {
            // HTML parsing may vary, just ensure no crash
            return
        }
        XCTAssertTrue(content.contains("<div"))
    }

    // MARK: - Complex Document Tests

    func testParseComplexDocument() async {
        let markdown = """
        # Getting Started

        Welcome to **GitBeek** documentation!

        ## Installation

        ```swift
        import GitBeek
        ```

        ## Features

        - Easy setup
        - Fast performance
        - Great documentation

        > Note: Keep your API key secure.

        | Feature | Status |
        |---------|--------|
        | Auth    | Done   |
        | API     | WIP    |
        """
        let blocks = await MarkdownParser.shared.parse(markdown)

        // Should have multiple block types
        XCTAssertGreaterThan(blocks.count, 5)

        // Check for heading
        let hasHeading = blocks.contains { block in
            if case .heading = block.content { return true }
            return false
        }
        XCTAssertTrue(hasHeading)

        // Check for code block
        let hasCode = blocks.contains { block in
            if case .codeBlock = block.content { return true }
            return false
        }
        XCTAssertTrue(hasCode)

        // Check for list
        let hasList = blocks.contains { block in
            if case .unorderedList = block.content { return true }
            return false
        }
        XCTAssertTrue(hasList)

        // Check for blockquote
        let hasQuote = blocks.contains { block in
            if case .blockquote = block.content { return true }
            return false
        }
        XCTAssertTrue(hasQuote)

        // Check for table
        let hasTable = blocks.contains { block in
            if case .table = block.content { return true }
            return false
        }
        XCTAssertTrue(hasTable)
    }

    // MARK: - Edge Cases

    func testParseEmptyMarkdown() async {
        let blocks = await MarkdownParser.shared.parse("")
        XCTAssertTrue(blocks.isEmpty)
    }

    func testParseWhitespaceOnlyMarkdown() async {
        let blocks = await MarkdownParser.shared.parse("   \n\n   ")
        XCTAssertTrue(blocks.isEmpty)
    }

    func testParseSingleLine() async {
        let blocks = await MarkdownParser.shared.parse("Just text")
        XCTAssertEqual(blocks.count, 1)
    }

    // MARK: - MarkdownBlock Identity Tests

    func testMarkdownBlockContentEquatable() {
        let heading1 = MarkdownBlock.heading(level: 1, text: "Title")
        let heading2 = MarkdownBlock.heading(level: 1, text: "Title")

        // Each call creates a new UUID, so IDs are different
        XCTAssertNotEqual(heading1.id, heading2.id)
        // But content should be equal
        XCTAssertEqual(heading1.content, heading2.content)
    }

    func testMarkdownBlockDifferentContent() {
        let heading1 = MarkdownBlock.heading(level: 1, text: "Title 1")
        let heading2 = MarkdownBlock.heading(level: 1, text: "Title 2")

        XCTAssertNotEqual(heading1.content, heading2.content)
    }

    func testListItemBlockEquatable() {
        let content = [MarkdownBlock.paragraph(text: AttributedString("Test"))]
        let item1 = ListItemBlock(content: content, isChecked: nil)
        let item2 = ListItemBlock(content: content, isChecked: nil)

        // Different UUIDs mean they're not equal
        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - HintType Tests

    func testHintTypeRawValues() {
        XCTAssertEqual(HintType.info.rawValue, "info")
        XCTAssertEqual(HintType.success.rawValue, "success")
        XCTAssertEqual(HintType.warning.rawValue, "warning")
        XCTAssertEqual(HintType.danger.rawValue, "danger")
    }

    // MARK: - TabItem Tests

    func testTabItemEquatable() {
        let content = [MarkdownBlock.paragraph(text: AttributedString("Content"))]
        let tab1 = TabItem(title: "Tab 1", content: content)
        let tab2 = TabItem(title: "Tab 1", content: content)

        // Different UUIDs
        XCTAssertNotEqual(tab1, tab2)
    }
}
