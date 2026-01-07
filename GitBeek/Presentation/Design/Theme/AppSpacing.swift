//
//  AppSpacing.swift
//  GitBeek
//
//  Spacing system for consistent layout
//

import SwiftUI

/// Spacing constants for consistent layout throughout the app
enum AppSpacing {

    // MARK: - Base Scale

    /// 4pt - Minimal spacing
    static let xxs: CGFloat = 4

    /// 8pt - Extra small spacing
    static let xs: CGFloat = 8

    /// 12pt - Small spacing
    static let sm: CGFloat = 12

    /// 16pt - Medium spacing (default)
    static let md: CGFloat = 16

    /// 20pt - Large spacing
    static let lg: CGFloat = 20

    /// 24pt - Extra large spacing
    static let xl: CGFloat = 24

    /// 32pt - Extra extra large spacing
    static let xxl: CGFloat = 32

    /// 48pt - Huge spacing
    static let huge: CGFloat = 48

    // MARK: - Semantic Spacing

    /// Padding inside cards and containers
    static let cardPadding: CGFloat = 16

    /// Padding for screen edges
    static let screenPadding: CGFloat = 20

    /// Spacing between list items
    static let listItemSpacing: CGFloat = 12

    /// Spacing between sections
    static let sectionSpacing: CGFloat = 24

    /// Spacing between form fields
    static let formFieldSpacing: CGFloat = 16

    /// Icon to text spacing
    static let iconTextSpacing: CGFloat = 8

    // MARK: - Corner Radius

    /// Small corner radius (buttons, tags)
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius (cards, inputs)
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius (sheets, modals)
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large corner radius (full cards)
    static let cornerRadiusXL: CGFloat = 20

    /// Continuous corner radius for glass effects
    static let cornerRadiusGlass: CGFloat = 24

    // MARK: - Component Sizes

    /// Small button height
    static let buttonHeightSmall: CGFloat = 32

    /// Medium button height
    static let buttonHeightMedium: CGFloat = 44

    /// Large button height
    static let buttonHeightLarge: CGFloat = 56

    /// Icon size small
    static let iconSizeSmall: CGFloat = 16

    /// Icon size medium
    static let iconSizeMedium: CGFloat = 24

    /// Icon size large
    static let iconSizeLarge: CGFloat = 32

    /// Avatar size small
    static let avatarSizeSmall: CGFloat = 32

    /// Avatar size medium
    static let avatarSizeMedium: CGFloat = 44

    /// Avatar size large
    static let avatarSizeLarge: CGFloat = 64

    // MARK: - Touch Targets

    /// Minimum touch target size (Apple HIG: 44pt)
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Spacing View Modifiers

extension View {
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(AppSpacing.cardPadding)
    }

    /// Apply screen edge padding
    func screenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.screenPadding)
    }

    /// Apply standard section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, AppSpacing.sectionSpacing)
    }
}

// MARK: - EdgeInsets Presets

extension EdgeInsets {
    /// Standard card insets
    static let card = EdgeInsets(
        top: AppSpacing.cardPadding,
        leading: AppSpacing.cardPadding,
        bottom: AppSpacing.cardPadding,
        trailing: AppSpacing.cardPadding
    )

    /// Screen edge insets
    static let screen = EdgeInsets(
        top: AppSpacing.md,
        leading: AppSpacing.screenPadding,
        bottom: AppSpacing.md,
        trailing: AppSpacing.screenPadding
    )

    /// List item insets
    static let listItem = EdgeInsets(
        top: AppSpacing.sm,
        leading: AppSpacing.md,
        bottom: AppSpacing.sm,
        trailing: AppSpacing.md
    )
}

// MARK: - Preview

#Preview("Spacing Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            spacingPreview("xxs (4pt)", AppSpacing.xxs)
            spacingPreview("xs (8pt)", AppSpacing.xs)
            spacingPreview("sm (12pt)", AppSpacing.sm)
            spacingPreview("md (16pt)", AppSpacing.md)
            spacingPreview("lg (20pt)", AppSpacing.lg)
            spacingPreview("xl (24pt)", AppSpacing.xl)
            spacingPreview("xxl (32pt)", AppSpacing.xxl)
            spacingPreview("huge (48pt)", AppSpacing.huge)
        }
        .padding()
    }
}

private func spacingPreview(_ name: String, _ size: CGFloat) -> some View {
    HStack {
        Text(name)
            .font(.caption)
            .frame(width: 100, alignment: .leading)
        Rectangle()
            .fill(Color.blue)
            .frame(width: size, height: 20)
        Spacer()
    }
}
