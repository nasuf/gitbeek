//
//  AppTypography.swift
//  GitBeek
//
//  Typography system using SF Pro for iOS 26
//

import SwiftUI

/// Typography definitions following Apple's Human Interface Guidelines
enum AppTypography {

    // MARK: - Display Styles (Large titles, hero text)

    /// Extra large display text
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)

    /// Large display text
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)

    /// Small display text
    static let displaySmall = Font.system(size: 24, weight: .semibold, design: .default)

    // MARK: - Headline Styles

    /// Primary headline
    static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)

    /// Secondary headline
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)

    /// Small headline
    static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .default)

    // MARK: - Title Styles

    /// Large title
    static let titleLarge = Font.system(size: 20, weight: .medium, design: .default)

    /// Medium title
    static let titleMedium = Font.system(size: 17, weight: .medium, design: .default)

    /// Small title
    static let titleSmall = Font.system(size: 15, weight: .medium, design: .default)

    // MARK: - Body Styles

    /// Primary body text
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Secondary body text
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// Small body text
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Label Styles

    /// Large label
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)

    /// Medium label
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)

    /// Small label
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Caption Styles

    /// Primary caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Secondary caption (smaller)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Code/Monospace Styles

    /// Code block text
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)

    /// Inline code
    static let codeInline = Font.system(size: 13, weight: .medium, design: .monospaced)

    /// Code caption
    static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply display large style
    func displayLargeStyle() -> some View {
        self.font(AppTypography.displayLarge)
    }

    /// Apply headline style
    func headlineStyle() -> some View {
        self.font(AppTypography.headlineLarge)
    }

    /// Apply body style
    func bodyStyle() -> some View {
        self.font(AppTypography.bodyLarge)
    }

    /// Apply caption style
    func captionStyle() -> some View {
        self.font(AppTypography.caption)
            .foregroundStyle(.secondary)
    }

    /// Apply code style
    func codeStyle() -> some View {
        self.font(AppTypography.code)
    }
}

// MARK: - Dynamic Type Support

extension AppTypography {
    /// Body text with dynamic type support
    static func dynamicBody(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// Headline with dynamic type support
    static func dynamicHeadline(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

// MARK: - Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Display Large")
                    .font(AppTypography.displayLarge)
                Text("Display Medium")
                    .font(AppTypography.displayMedium)
                Text("Display Small")
                    .font(AppTypography.displaySmall)
            }

            Divider()

            Group {
                Text("Headline Large")
                    .font(AppTypography.headlineLarge)
                Text("Headline Medium")
                    .font(AppTypography.headlineMedium)
                Text("Headline Small")
                    .font(AppTypography.headlineSmall)
            }

            Divider()

            Group {
                Text("Body Large - Main content text")
                    .font(AppTypography.bodyLarge)
                Text("Body Medium - Secondary content")
                    .font(AppTypography.bodyMedium)
                Text("Body Small - Tertiary content")
                    .font(AppTypography.bodySmall)
            }

            Divider()

            Group {
                Text("let code = \"Monospaced\"")
                    .font(AppTypography.code)
                Text("Caption text")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
