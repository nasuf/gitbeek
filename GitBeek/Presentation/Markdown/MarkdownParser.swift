//
//  MarkdownParser.swift
//  GitBeek
//
//  Markdown parsing with swift-markdown
//

import Foundation
import Markdown

/// Parsed markdown block types with unique IDs
struct MarkdownBlock: Identifiable, Equatable, Sendable {
    let id: String
    let content: MarkdownBlockContent

    init(id: String, content: MarkdownBlockContent) {
        self.id = id
        self.content = content
    }

    init(_ content: MarkdownBlockContent) {
        self.id = UUID().uuidString
        self.content = content
    }

    // Convenience initializers
    static func heading(level: Int, text: String) -> MarkdownBlock {
        MarkdownBlock(.heading(level: level, text: text))
    }

    static func paragraph(text: AttributedString) -> MarkdownBlock {
        MarkdownBlock(.paragraph(text: text))
    }

    static func codeBlock(language: String?, code: String) -> MarkdownBlock {
        MarkdownBlock(.codeBlock(language: language, code: code))
    }

    static func blockquote(blocks: [MarkdownBlock]) -> MarkdownBlock {
        MarkdownBlock(.blockquote(blocks: blocks))
    }

    static func unorderedList(items: [ListItemBlock]) -> MarkdownBlock {
        MarkdownBlock(.unorderedList(items: items))
    }

    static func orderedList(items: [ListItemBlock], startIndex: Int) -> MarkdownBlock {
        MarkdownBlock(.orderedList(items: items, startIndex: startIndex))
    }

    static func image(source: String, alt: String?) -> MarkdownBlock {
        MarkdownBlock(.image(source: source, alt: alt))
    }

    static func thematicBreak() -> MarkdownBlock {
        MarkdownBlock(.thematicBreak)
    }

    static func table(headers: [String], rows: [[String]]) -> MarkdownBlock {
        MarkdownBlock(.table(headers: headers, rows: rows))
    }

    static func htmlBlock(content: String) -> MarkdownBlock {
        MarkdownBlock(.htmlBlock(content: content))
    }

    static func hint(type: HintType, content: [MarkdownBlock]) -> MarkdownBlock {
        MarkdownBlock(.hint(type: type, content: content))
    }

    static func tabs(items: [TabItem]) -> MarkdownBlock {
        MarkdownBlock(.tabs(items: items))
    }

    static func expandable(title: String, content: [MarkdownBlock]) -> MarkdownBlock {
        MarkdownBlock(.expandable(title: title, content: content))
    }

    static func embed(type: EmbedType, url: String, title: String?) -> MarkdownBlock {
        MarkdownBlock(.embed(type: type, url: url, title: title))
    }
}

/// The actual content of a markdown block
enum MarkdownBlockContent: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(text: AttributedString)
    case codeBlock(language: String?, code: String)
    case blockquote(blocks: [MarkdownBlock])
    case unorderedList(items: [ListItemBlock])
    case orderedList(items: [ListItemBlock], startIndex: Int)
    case image(source: String, alt: String?)
    case thematicBreak
    case table(headers: [String], rows: [[String]])
    case htmlBlock(content: String)

    // GitBook custom blocks
    case hint(type: HintType, content: [MarkdownBlock])
    case tabs(items: [TabItem])
    case expandable(title: String, content: [MarkdownBlock])
    case embed(type: EmbedType, url: String, title: String?)
}

/// List item
struct ListItemBlock: Identifiable, Equatable, Sendable {
    let id: String
    let content: [MarkdownBlock]
    let isChecked: Bool?

    init(id: String = UUID().uuidString, content: [MarkdownBlock], isChecked: Bool?) {
        self.id = id
        self.content = content
        self.isChecked = isChecked
    }

    static func == (lhs: ListItemBlock, rhs: ListItemBlock) -> Bool {
        lhs.id == rhs.id
    }
}

/// Hint block type
enum HintType: String, Sendable {
    case info
    case success
    case warning
    case danger
}

/// Embed type for different platforms
enum EmbedType: String, Codable, Sendable {
    case youtube
    case vimeo
    case twitter
    case github
    case codepen
    case figma
    case loom
    case generic
}

/// Tab item for tabbed content
struct TabItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let content: [MarkdownBlock]

    init(id: String = UUID().uuidString, title: String, content: [MarkdownBlock]) {
        self.id = id
        self.title = title
        self.content = content
    }

    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Markdown parser using swift-markdown
actor MarkdownParser {
    // MARK: - Singleton

    static let shared = MarkdownParser()

    private init() {}

    // MARK: - Context

    /// Parsing context to track state across recursive calls
    private struct ParsingContext {
        var counters: [String: Int] = [:]
        let prefix: String

        mutating func nextId(for markup: any Markup) -> String {
            let typeName = String(describing: type(of: markup)).lowercased()
            let count = counters[typeName, default: 0]
            counters[typeName] = count + 1
            let id = prefix.isEmpty ? "\(typeName)--\(count)" : "\(prefix)-\(typeName)--\(count)"
            return id
        }

        func childContext(for id: String) -> ParsingContext {
            ParsingContext(prefix: id)
        }
    }

    // MARK: - Parsing

    /// Parse markdown string into blocks
    func parse(_ markdown: String) async -> [MarkdownBlock] {
        let document = Document(parsing: markdown)
        var blocks: [MarkdownBlock] = []
        var context = ParsingContext(prefix: "")

        for child in document.children {
            if let block = parseBlock(child, context: &context) {
                blocks.append(block)
            }
        }

        return blocks
    }

    // MARK: - Block Parsing

    private func parseBlock(_ markup: any Markup, context: inout ParsingContext) -> MarkdownBlock? {
        let id = context.nextId(for: markup)

        switch markup {
        case let heading as Heading:
            return MarkdownBlock(id: id, content: .heading(level: heading.level, text: extractPlainText(from: heading)))

        case let paragraph as Paragraph:
            return MarkdownBlock(id: id, content: .paragraph(text: parseInlineContent(paragraph.inlineChildren)))

        case let codeBlock as CodeBlock:
            return MarkdownBlock(id: id, content: .codeBlock(language: codeBlock.language, code: codeBlock.code))

        case let blockquote as BlockQuote:
            var childContext = context.childContext(for: id)
            var blocks: [MarkdownBlock] = []
            for child in blockquote.blockChildren {
                if let parsed = self.parseBlock(child, context: &childContext) {
                    blocks.append(parsed)
                }
            }
            return MarkdownBlock(id: id, content: .blockquote(blocks: blocks))

        case let unorderedList as UnorderedList:
            var items: [ListItemBlock] = []
            for (index, listItem) in unorderedList.listItems.enumerated() {
                let itemId = "\(id)-item--\(index)"
                var itemContext = context.childContext(for: itemId)
                var listBlocks: [MarkdownBlock] = []
                for child in listItem.blockChildren {
                    if let parsed = self.parseBlock(child, context: &itemContext) {
                        listBlocks.append(parsed)
                    }
                }
                // Only set isChecked if checkbox exists (task list)
                let isChecked: Bool? = listItem.checkbox.map { $0 == .checked }
                items.append(ListItemBlock(id: itemId, content: listBlocks, isChecked: isChecked))
            }
            return MarkdownBlock(id: id, content: .unorderedList(items: items))

        case let orderedList as OrderedList:
            var items: [ListItemBlock] = []
            for (index, listItem) in orderedList.listItems.enumerated() {
                let itemId = "\(id)-item--\(index)"
                var itemContext = context.childContext(for: itemId)
                var listBlocks: [MarkdownBlock] = []
                for child in listItem.blockChildren {
                    if let parsed = self.parseBlock(child, context: &itemContext) {
                        listBlocks.append(parsed)
                    }
                }
                items.append(ListItemBlock(id: itemId, content: listBlocks, isChecked: nil))
            }
            return MarkdownBlock(id: id, content: .orderedList(items: items, startIndex: Int(orderedList.startIndex)))

        case let image as Markdown.Image:
            return MarkdownBlock(id: id, content: .image(source: image.source ?? "", alt: image.plainText))

        case _ as ThematicBreak:
            return MarkdownBlock(id: id, content: .thematicBreak)

        case let table as Markdown.Table:
            var headers: [String] = []
            for cell in table.head.cells {
                headers.append(self.extractPlainText(from: cell))
            }
            
            var rows: [[String]] = []
            for row in table.body.rows {
                var rowCells: [String] = []
                for cell in row.cells {
                    rowCells.append(self.extractPlainText(from: cell))
                }
                rows.append(rowCells)
            }
            return MarkdownBlock(id: id, content: .table(headers: headers, rows: rows))

        case let htmlBlock as HTMLBlock:
            return MarkdownBlock(id: id, content: .htmlBlock(content: htmlBlock.rawHTML))

        default:
            return nil
        }
    }

    // MARK: - Inline Content Parsing

    private func parseInlineContent(_ children: some Sequence<InlineMarkup>) -> AttributedString {
        var result = AttributedString()

        for child in children {
            result.append(self.parseInlineMarkup(child))
        }

        return result
    }

    private func parseInlineMarkup(_ markup: any InlineMarkup) -> AttributedString {
        switch markup {
        case let text as Text:
            return AttributedString(text.string)

        case let strong as Strong:
            var result = self.parseInlineContent(strong.inlineChildren)
            result.font = .body.bold()
            return result

        case let emphasis as Emphasis:
            var result = self.parseInlineContent(emphasis.inlineChildren)
            result.font = .body.italic()
            return result

        case let code as InlineCode:
            var result = AttributedString(code.code)
            result.font = .system(.body, design: .monospaced)
            result.backgroundColor = .gray.opacity(0.2)
            return result

        case let link as Markdown.Link:
            var result = self.parseInlineContent(link.inlineChildren)
            if let urlString = link.destination, let url = URL(string: urlString) {
                result.link = url
            }
            result.foregroundColor = .blue
            return result

        case let strikethrough as Strikethrough:
            var result = self.parseInlineContent(strikethrough.inlineChildren)
            result.strikethroughStyle = .single
            return result

        case let image as Markdown.Image:
            var result = AttributedString("[Image: \(image.title ?? "")]")
            result.font = .caption
            return result

        case _ as SoftBreak:
            return AttributedString(" ")

        case _ as LineBreak:
            return AttributedString("\n")

        default:
            return AttributedString()
        }
    }

    // MARK: - Text Extraction

    private func extractPlainText(from markup: any Markup) -> String {
        if let text = markup as? Text {
            return text.string
        }

        var result = ""
        for child in markup.children {
            result += self.extractPlainText(from: child)
        }
        return result
    }
}
