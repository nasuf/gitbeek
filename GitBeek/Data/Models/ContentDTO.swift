//
//  ContentDTO.swift
//  GitBeek
//
//  Data transfer objects for Content/Page API responses
//

import Foundation

/// Content node type
enum ContentNodeType: String, Codable, Sendable {
    case document
    case group
    case link
}

/// Content node (page or group)
struct ContentNodeDTO: Codable, Equatable, Sendable, Identifiable {
    let object: String  // "document", "group", or "link"
    let id: String
    let title: String
    let emoji: String?
    let path: String
    let slug: String?
    let description: String?
    let type: ContentNodeType?
    let pages: [ContentNodeDTO]?  // Child pages for groups
    let createdAt: Date?
    let updatedAt: Date?

    // For link type
    let target: LinkTargetDTO?

    struct LinkTargetDTO: Codable, Equatable, Sendable {
        let kind: String  // "url", "space", "page"
        let url: String?
        let space: String?
        let page: String?
    }
}

/// Content tree structure
struct ContentTreeDTO: Codable, Equatable, Sendable {
    let object: String  // "content"
    let pages: [ContentNodeDTO]
}

/// Page content (markdown/document)
struct PageContentDTO: Codable, Equatable, Sendable {
    let object: String  // "document"
    let id: String
    let title: String
    let emoji: String?
    let path: String
    let slug: String?
    let description: String?
    let createdAt: Date?
    let updatedAt: Date?

    // Content in various formats
    let markdown: String?
    let document: DocumentBlockDTO?
}

/// GitBook document block structure
struct DocumentBlockDTO: Codable, Equatable, Sendable {
    let object: String  // "document"
    let data: [String: AnyCodable]?
    let nodes: [DocumentNodeDTO]?
}

/// Document node in GitBook format
struct DocumentNodeDTO: Codable, Equatable, Sendable {
    let object: String  // "block" or "text"
    let type: String?
    let data: [String: AnyCodable]?
    let nodes: [DocumentNodeDTO]?
    let leaves: [DocumentLeafDTO]?
    let isVoid: Bool?
}

/// Text leaf in document
struct DocumentLeafDTO: Codable, Equatable, Sendable {
    let object: String  // "leaf"
    let text: String
    let marks: [DocumentMarkDTO]?
}

/// Text mark (bold, italic, etc.)
struct DocumentMarkDTO: Codable, Equatable, Sendable {
    let object: String  // "mark"
    let type: String
    let data: [String: AnyCodable]?
}

/// Type-erased Codable for dynamic JSON
/// @unchecked Sendable because value contains only JSON-compatible types (primitives, arrays, dictionaries)
struct AnyCodable: Codable, Equatable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value"))
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check for common types
        switch (lhs.value, rhs.value) {
        case (let l as Bool, let r as Bool): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
}

/// Create/update page request
struct PageRequestDTO: Codable, Sendable {
    let title: String?
    let emoji: String?
    let description: String?
    let markdown: String?
    let parent: String?  // Parent page ID

    init(title: String? = nil, emoji: String? = nil, description: String? = nil, markdown: String? = nil, parent: String? = nil) {
        self.title = title
        self.emoji = emoji
        self.description = description
        self.markdown = markdown
        self.parent = parent
    }
}
