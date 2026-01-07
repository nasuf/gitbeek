//
//  AppColors.swift
//  GitBeek
//
//  Color system adapted for iOS 26 Liquid Glass design
//

import SwiftUI

/// App color palette optimized for Liquid Glass design
enum AppColors {

    // MARK: - Primary Colors

    /// Primary brand color - GitBook blue
    static let primary = Color("Primary", bundle: .main)
    static let primaryFallback = Color(red: 0.25, green: 0.47, blue: 0.85)

    /// Secondary accent color
    static let secondary = Color("Secondary", bundle: .main)
    static let secondaryFallback = Color(red: 0.55, green: 0.35, blue: 0.85)

    // MARK: - Semantic Colors (Vibrant for Liquid Glass)

    /// Success - green tint for positive actions
    static let success = Color.green

    /// Warning - orange tint for caution
    static let warning = Color.orange

    /// Error/Danger - red tint for errors
    static let danger = Color.red

    /// Info - blue tint for informational content
    static let info = Color.blue

    // MARK: - Text Colors

    /// Primary text color
    static let textPrimary = Color.primary

    /// Secondary text color
    static let textSecondary = Color.secondary

    /// Tertiary/muted text
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Background Colors

    /// Main background - typically transparent for glass effect
    static let background = Color(uiColor: .systemBackground)

    /// Secondary background
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)

    /// Grouped background
    static let backgroundGrouped = Color(uiColor: .systemGroupedBackground)

    // MARK: - Glass Specific Colors

    /// Glass tint for navigation elements
    static let glassTint = Color.white.opacity(0.1)

    /// Glass highlight
    static let glassHighlight = Color.white.opacity(0.2)

    /// Glass shadow color
    static let glassShadow = Color.black.opacity(0.1)

    // MARK: - Functional Colors

    /// Separator color
    static let separator = Color(uiColor: .separator)

    /// Border color
    static let border = Color(uiColor: .opaqueSeparator)

    /// Disabled state color
    static let disabled = Color.gray.opacity(0.5)
}

// MARK: - Color Extensions for Liquid Glass

extension Color {
    /// Creates a vibrant version suitable for glass overlays
    var vibrant: Color {
        self.opacity(0.8)
    }

    /// Creates a subtle version for backgrounds
    var subtle: Color {
        self.opacity(0.3)
    }

    /// Creates a glass-compatible tint
    var glassTint: Color {
        self.opacity(0.15)
    }
}

// MARK: - Gradient Definitions

extension AppColors {
    /// Primary gradient for prominent elements
    static let primaryGradient = LinearGradient(
        colors: [primaryFallback, secondaryFallback],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle glass gradient
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Mesh gradient for rich backgrounds
    @available(iOS 18.0, *)
    static func meshBackground() -> MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                .blue.opacity(0.3), .purple.opacity(0.2), .pink.opacity(0.3),
                .cyan.opacity(0.2), .white.opacity(0.1), .orange.opacity(0.2),
                .green.opacity(0.3), .yellow.opacity(0.2), .red.opacity(0.3)
            ]
        )
    }
}

// MARK: - Preview

#Preview("App Colors") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                colorSwatch("Primary", AppColors.primaryFallback)
                colorSwatch("Secondary", AppColors.secondaryFallback)
                colorSwatch("Success", AppColors.success)
                colorSwatch("Warning", AppColors.warning)
                colorSwatch("Danger", AppColors.danger)
                colorSwatch("Info", AppColors.info)
            }
        }
        .padding()
    }
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    HStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 50, height: 50)
        Text(name)
            .font(.headline)
        Spacer()
    }
}
