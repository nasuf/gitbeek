//
//  String+Emoji.swift
//  GitBeek
//
//  String extension for emoji conversion
//

import Foundation

extension String {
    /// Converts a Unicode hex code string (e.g., "1f4d9") to an emoji character (e.g., "📙")
    /// Supports single code points and compound emojis with multiple code points separated by hyphens
    func hexToEmoji() -> String? {
        // Handle compound emojis (e.g., "1f1fa-1f1f8" for 🇺🇸)
        let components = self.split(separator: "-")

        var result = ""
        for component in components {
            guard let scalar = UInt32(component, radix: 16),
                  let unicodeScalar = Unicode.Scalar(scalar) else {
                return nil
            }
            result.append(Character(unicodeScalar))
        }

        return result.isEmpty ? nil : result
    }

    /// Returns true if this string looks like a Unicode hex code (e.g., "1f4d9")
    var isHexEmojiCode: Bool {
        let pattern = "^[0-9a-fA-F]+(-[0-9a-fA-F]+)*$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Converts hex code to emoji if it looks like a hex code, otherwise returns self
    var asEmoji: String {
        if isHexEmojiCode, let emoji = hexToEmoji() {
            return emoji
        }
        return self
    }
}
