//
//  ReadingPreferencesTests.swift
//  GitBeekTests
//
//  Tests for reading preferences: FontScale and CodeHighlightTheme
//

import XCTest
@testable import GitBeek

final class ReadingPreferencesTests: XCTestCase {

    // MARK: - FontScale Tests

    func testFontScaleMultipliers() {
        XCTAssertEqual(FontScale.small.multiplier, 0.85, accuracy: 0.001)
        XCTAssertEqual(FontScale.default.multiplier, 1.0, accuracy: 0.001)
        XCTAssertEqual(FontScale.large.multiplier, 1.15, accuracy: 0.001)
        XCTAssertEqual(FontScale.extraLarge.multiplier, 1.3, accuracy: 0.001)
    }

    func testFontScaleDisplayNames() {
        XCTAssertEqual(FontScale.small.displayName, "Small")
        XCTAssertEqual(FontScale.default.displayName, "Default")
        XCTAssertEqual(FontScale.large.displayName, "Large")
        XCTAssertEqual(FontScale.extraLarge.displayName, "Extra Large")
    }

    func testFontScaleCaseIterable() {
        let allCases = FontScale.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.small))
        XCTAssertTrue(allCases.contains(.default))
        XCTAssertTrue(allCases.contains(.large))
        XCTAssertTrue(allCases.contains(.extraLarge))
    }

    func testFontScaleIdentifiable() {
        XCTAssertEqual(FontScale.small.id, "small")
        XCTAssertEqual(FontScale.default.id, "default")
        XCTAssertEqual(FontScale.large.id, "large")
        XCTAssertEqual(FontScale.extraLarge.id, "extraLarge")
    }

    func testFontScaleRawValue() {
        XCTAssertEqual(FontScale(rawValue: "small"), .small)
        XCTAssertEqual(FontScale(rawValue: "default"), .default)
        XCTAssertEqual(FontScale(rawValue: "large"), .large)
        XCTAssertEqual(FontScale(rawValue: "extraLarge"), .extraLarge)
        XCTAssertNil(FontScale(rawValue: "invalid"))
    }

    func testFontScaleMultiplierOrdering() {
        // Multipliers should increase as scale increases
        XCTAssertLessThan(FontScale.small.multiplier, FontScale.default.multiplier)
        XCTAssertLessThan(FontScale.default.multiplier, FontScale.large.multiplier)
        XCTAssertLessThan(FontScale.large.multiplier, FontScale.extraLarge.multiplier)
    }

    // MARK: - CodeHighlightTheme Tests

    func testCodeThemeHighlightrNames() {
        // Light themes
        XCTAssertEqual(CodeHighlightTheme.xcode.highlightrThemeName, "xcode")
        XCTAssertEqual(CodeHighlightTheme.atomOneLight.highlightrThemeName, "atom-one-light")
        XCTAssertEqual(CodeHighlightTheme.github.highlightrThemeName, "github")
        XCTAssertEqual(CodeHighlightTheme.solarizedLight.highlightrThemeName, "solarized-light")

        // Dark themes
        XCTAssertEqual(CodeHighlightTheme.atomOneDark.highlightrThemeName, "atom-one-dark")
        XCTAssertEqual(CodeHighlightTheme.githubDark.highlightrThemeName, "github-dark")
        XCTAssertEqual(CodeHighlightTheme.monokai.highlightrThemeName, "monokai")
        XCTAssertEqual(CodeHighlightTheme.dracula.highlightrThemeName, "dracula")
        XCTAssertEqual(CodeHighlightTheme.solarizedDark.highlightrThemeName, "solarized-dark")
    }

    func testCodeThemeDisplayNames() {
        XCTAssertEqual(CodeHighlightTheme.xcode.displayName, "Xcode")
        XCTAssertEqual(CodeHighlightTheme.atomOneLight.displayName, "Atom One Light")
        XCTAssertEqual(CodeHighlightTheme.github.displayName, "GitHub")
        XCTAssertEqual(CodeHighlightTheme.solarizedLight.displayName, "Solarized Light")
        XCTAssertEqual(CodeHighlightTheme.atomOneDark.displayName, "Atom One Dark")
        XCTAssertEqual(CodeHighlightTheme.githubDark.displayName, "GitHub Dark")
        XCTAssertEqual(CodeHighlightTheme.monokai.displayName, "Monokai")
        XCTAssertEqual(CodeHighlightTheme.dracula.displayName, "Dracula")
        XCTAssertEqual(CodeHighlightTheme.solarizedDark.displayName, "Solarized Dark")
    }

    func testCodeThemeIsDark() {
        // Light themes should return false
        XCTAssertFalse(CodeHighlightTheme.xcode.isDark)
        XCTAssertFalse(CodeHighlightTheme.atomOneLight.isDark)
        XCTAssertFalse(CodeHighlightTheme.github.isDark)
        XCTAssertFalse(CodeHighlightTheme.solarizedLight.isDark)

        // Dark themes should return true
        XCTAssertTrue(CodeHighlightTheme.atomOneDark.isDark)
        XCTAssertTrue(CodeHighlightTheme.githubDark.isDark)
        XCTAssertTrue(CodeHighlightTheme.monokai.isDark)
        XCTAssertTrue(CodeHighlightTheme.dracula.isDark)
        XCTAssertTrue(CodeHighlightTheme.solarizedDark.isDark)
    }

    func testCodeThemeLightThemesCollection() {
        let lightThemes = CodeHighlightTheme.lightThemes
        XCTAssertEqual(lightThemes.count, 4)
        XCTAssertTrue(lightThemes.contains(.xcode))
        XCTAssertTrue(lightThemes.contains(.atomOneLight))
        XCTAssertTrue(lightThemes.contains(.github))
        XCTAssertTrue(lightThemes.contains(.solarizedLight))

        // Verify all are actually light
        for theme in lightThemes {
            XCTAssertFalse(theme.isDark, "\(theme) should be a light theme")
        }
    }

    func testCodeThemeDarkThemesCollection() {
        let darkThemes = CodeHighlightTheme.darkThemes
        XCTAssertEqual(darkThemes.count, 5)
        XCTAssertTrue(darkThemes.contains(.atomOneDark))
        XCTAssertTrue(darkThemes.contains(.githubDark))
        XCTAssertTrue(darkThemes.contains(.monokai))
        XCTAssertTrue(darkThemes.contains(.dracula))
        XCTAssertTrue(darkThemes.contains(.solarizedDark))

        // Verify all are actually dark
        for theme in darkThemes {
            XCTAssertTrue(theme.isDark, "\(theme) should be a dark theme")
        }
    }

    func testCodeThemeCaseIterable() {
        let allCases = CodeHighlightTheme.allCases
        XCTAssertEqual(allCases.count, 9)

        // Verify light + dark = all
        let lightCount = CodeHighlightTheme.lightThemes.count
        let darkCount = CodeHighlightTheme.darkThemes.count
        XCTAssertEqual(lightCount + darkCount, allCases.count)
    }

    func testCodeThemeIdentifiable() {
        XCTAssertEqual(CodeHighlightTheme.xcode.id, "xcode")
        XCTAssertEqual(CodeHighlightTheme.atomOneLight.id, "atomOneLight")
        XCTAssertEqual(CodeHighlightTheme.dracula.id, "dracula")
    }

    func testCodeThemeRawValue() {
        XCTAssertEqual(CodeHighlightTheme(rawValue: "xcode"), .xcode)
        XCTAssertEqual(CodeHighlightTheme(rawValue: "atomOneDark"), .atomOneDark)
        XCTAssertEqual(CodeHighlightTheme(rawValue: "dracula"), .dracula)
        XCTAssertNil(CodeHighlightTheme(rawValue: "invalid"))
    }

    // MARK: - Integration Tests

    func testAllThemesHaveValidHighlightrNames() {
        // Highlightr theme names should use kebab-case
        for theme in CodeHighlightTheme.allCases {
            let name = theme.highlightrThemeName
            XCTAssertFalse(name.isEmpty, "\(theme) should have a non-empty highlightr name")
            // Highlightr uses lowercase with hyphens
            XCTAssertEqual(name, name.lowercased(), "\(theme) highlightr name should be lowercase")
        }
    }

    func testAllThemesHaveDisplayNames() {
        for theme in CodeHighlightTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty, "\(theme) should have a display name")
        }

        for scale in FontScale.allCases {
            XCTAssertFalse(scale.displayName.isEmpty, "\(scale) should have a display name")
        }
    }

    func testFontScaleMultipliersAreReasonable() {
        for scale in FontScale.allCases {
            // Multipliers should be positive and within reasonable range
            XCTAssertGreaterThan(scale.multiplier, 0.5, "\(scale) multiplier too small")
            XCTAssertLessThan(scale.multiplier, 2.0, "\(scale) multiplier too large")
        }
    }
}
