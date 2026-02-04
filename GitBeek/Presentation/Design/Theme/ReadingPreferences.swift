//
//  ReadingPreferences.swift
//  GitBeek
//
//  Reading preferences: font scale and code highlight theme
//

import SwiftUI

// MARK: - Font Scale

/// Font scale options for reading preferences
enum FontScale: String, CaseIterable, Identifiable {
    case small
    case `default`
    case large
    case extraLarge

    var id: String { rawValue }

    /// Multiplier applied to base font sizes
    var multiplier: CGFloat {
        switch self {
        case .small: 0.85
        case .default: 1.0
        case .large: 1.15
        case .extraLarge: 1.3
        }
    }

    /// Display name shown in settings
    var displayName: String {
        switch self {
        case .small: "Small"
        case .default: "Default"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }
}

// MARK: - Code Highlight Theme

/// Code syntax highlighting theme options
enum CodeHighlightTheme: String, CaseIterable, Identifiable {
    // Light themes
    case xcode
    case atomOneLight
    case github
    case solarizedLight

    // Dark themes
    case atomOneDark
    case githubDark
    case monokai
    case dracula
    case solarizedDark

    var id: String { rawValue }

    /// Highlightr theme name (must match available themes)
    var highlightrThemeName: String {
        switch self {
        case .xcode: "xcode"
        case .atomOneLight: "atom-one-light"
        case .github: "github"
        case .solarizedLight: "solarized-light"
        case .atomOneDark: "atom-one-dark"
        case .githubDark: "github-dark"
        case .monokai: "monokai"
        case .dracula: "dracula"
        case .solarizedDark: "solarized-dark"
        }
    }

    /// Display name shown in settings
    var displayName: String {
        switch self {
        case .xcode: "Xcode"
        case .atomOneLight: "Atom One Light"
        case .github: "GitHub"
        case .solarizedLight: "Solarized Light"
        case .atomOneDark: "Atom One Dark"
        case .githubDark: "GitHub Dark"
        case .monokai: "Monokai"
        case .dracula: "Dracula"
        case .solarizedDark: "Solarized Dark"
        }
    }

    /// Whether this is a dark theme (affects code block background)
    var isDark: Bool {
        switch self {
        case .xcode, .atomOneLight, .github, .solarizedLight:
            false
        case .atomOneDark, .githubDark, .monokai, .dracula, .solarizedDark:
            true
        }
    }

    /// Light themes only
    static var lightThemes: [CodeHighlightTheme] {
        [.xcode, .atomOneLight, .github, .solarizedLight]
    }

    /// Dark themes only
    static var darkThemes: [CodeHighlightTheme] {
        [.atomOneDark, .githubDark, .monokai, .dracula, .solarizedDark]
    }
}
