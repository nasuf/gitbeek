//
//  ReadingEnvironment.swift
//  GitBeek
//
//  Environment keys for reading preferences
//

import SwiftUI

// MARK: - Font Scale Environment Key

private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

// MARK: - Code Theme Environment Key

private struct CodeThemeKey: EnvironmentKey {
    static let defaultValue: CodeHighlightTheme = .xcode
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    /// Font scale multiplier for reading content
    var fontScale: CGFloat {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }

    /// Code syntax highlighting theme
    var codeTheme: CodeHighlightTheme {
        get { self[CodeThemeKey.self] }
        set { self[CodeThemeKey.self] = newValue }
    }
}
