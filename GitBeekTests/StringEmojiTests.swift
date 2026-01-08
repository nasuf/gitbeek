//
//  StringEmojiTests.swift
//  GitBeekTests
//
//  Tests for String emoji conversion extension
//

import XCTest
@testable import GitBeek

final class StringEmojiTests: XCTestCase {

    // MARK: - hexToEmoji Tests

    func testHexToEmojiSingleCodePoint() {
        XCTAssertEqual("1f4d9".hexToEmoji(), "📙")  // Orange book
        XCTAssertEqual("1f680".hexToEmoji(), "🚀")  // Rocket
        XCTAssertEqual("2764".hexToEmoji(), "❤")   // Red heart
        XCTAssertEqual("1f389".hexToEmoji(), "🎉")  // Party popper
    }

    func testHexToEmojiUppercase() {
        XCTAssertEqual("1F4D9".hexToEmoji(), "📙")
        XCTAssertEqual("1F680".hexToEmoji(), "🚀")
    }

    func testHexToEmojiCompoundEmoji() {
        // Flag emojis use two regional indicator symbols
        XCTAssertEqual("1f1fa-1f1f8".hexToEmoji(), "🇺🇸")  // US flag
        XCTAssertEqual("1f1ef-1f1f5".hexToEmoji(), "🇯🇵")  // Japan flag
    }

    func testHexToEmojiInvalidInput() {
        XCTAssertNil("invalid".hexToEmoji())
        XCTAssertNil("gggggg".hexToEmoji())
        XCTAssertNil("".hexToEmoji())
    }

    // MARK: - isHexEmojiCode Tests

    func testIsHexEmojiCodeValid() {
        XCTAssertTrue("1f4d9".isHexEmojiCode)
        XCTAssertTrue("1F4D9".isHexEmojiCode)
        XCTAssertTrue("2764".isHexEmojiCode)
        XCTAssertTrue("1f1fa-1f1f8".isHexEmojiCode)  // Compound
        XCTAssertTrue("1F1FA-1F1F8".isHexEmojiCode)  // Compound uppercase
    }

    func testIsHexEmojiCodeInvalid() {
        XCTAssertFalse("hello".isHexEmojiCode)
        XCTAssertFalse("📙".isHexEmojiCode)
        XCTAssertFalse("".isHexEmojiCode)
        XCTAssertFalse("1f4d9-".isHexEmojiCode)      // Trailing dash
        XCTAssertFalse("-1f4d9".isHexEmojiCode)      // Leading dash
        XCTAssertFalse("1f4d9--1f680".isHexEmojiCode) // Double dash
    }

    // MARK: - asEmoji Tests

    func testAsEmojiConvertsHexCode() {
        XCTAssertEqual("1f4d9".asEmoji, "📙")
        XCTAssertEqual("1f680".asEmoji, "🚀")
        XCTAssertEqual("1f1fa-1f1f8".asEmoji, "🇺🇸")
    }

    func testAsEmojiPreservesNonHexStrings() {
        XCTAssertEqual("hello".asEmoji, "hello")
        XCTAssertEqual("📙".asEmoji, "📙")
        XCTAssertEqual("My Space".asEmoji, "My Space")
    }

    func testAsEmojiWithEmptyString() {
        XCTAssertEqual("".asEmoji, "")
    }

    // MARK: - Common GitBook Emoji Codes

    func testCommonGitBookEmojiCodes() {
        // Common emojis used in GitBook spaces
        XCTAssertEqual("1f4da".hexToEmoji(), "📚")  // Books
        XCTAssertEqual("1f4bb".hexToEmoji(), "💻")  // Laptop
        XCTAssertEqual("1f4d6".hexToEmoji(), "📖")  // Open book
        XCTAssertEqual("1f527".hexToEmoji(), "🔧")  // Wrench
        XCTAssertEqual("1f3e0".hexToEmoji(), "🏠")  // House
        XCTAssertEqual("2699".hexToEmoji(), "⚙")   // Gear
        XCTAssertEqual("1f4dd".hexToEmoji(), "📝")  // Memo
        XCTAssertEqual("1f4e6".hexToEmoji(), "📦")  // Package
    }
}
