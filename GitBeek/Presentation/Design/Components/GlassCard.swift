//
//  GlassCard.swift
//  GitBeek
//
//  Liquid Glass card component
//

import SwiftUI

// MARK: - Glass Card

/// A card component with Liquid Glass effect styling.
///
/// Usage:
/// ```swift
/// GlassCard {
///     VStack {
///         Text("Card Title")
///         Text("Card content goes here")
///     }
/// }
/// ```
struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: CGFloat
    let tint: Color?
    let isInteractive: Bool

    init(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusLarge,
        padding: CGFloat = AppSpacing.cardPadding,
        tint: Color? = nil,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tint = tint
        self.isInteractive = isInteractive
    }

    var body: some View {
        content
            .padding(padding)
            .glassStyle(
                cornerRadius: cornerRadius,
                isInteractive: isInteractive,
                tint: tint
            )
    }
}

// MARK: - Glass Card Variants

extension GlassCard {
    /// Creates a compact card with smaller padding
    static func compact(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) -> GlassCard {
        GlassCard(
            cornerRadius: cornerRadius,
            padding: AppSpacing.sm,
            tint: tint,
            content: content
        )
    }

    /// Creates a large card with more padding
    static func large(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusXL,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) -> GlassCard {
        GlassCard(
            cornerRadius: cornerRadius,
            padding: AppSpacing.xl,
            tint: tint,
            content: content
        )
    }
}

// MARK: - Tappable Glass Card

/// A glass card that responds to tap gestures with interactive feedback
struct TappableGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: CGFloat
    let tint: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusLarge,
        padding: CGFloat = AppSpacing.cardPadding,
        tint: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tint = tint
        self.action = action
    }

    var body: some View {
        GlassCard(
            cornerRadius: cornerRadius,
            padding: padding,
            tint: tint,
            isInteractive: true,
            content: { content }
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Glass List Card

/// A card designed for list items with leading icon and trailing accessory
struct GlassListCard<LeadingContent: View, TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let leading: LeadingContent
    let trailing: TrailingContent
    let tint: Color?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> LeadingContent,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        let cardContent = HStack(spacing: AppSpacing.iconTextSpacing) {
            leading

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            trailing
        }

        if let action = action {
            TappableGlassCard(
                cornerRadius: AppSpacing.cornerRadiusMedium,
                padding: AppSpacing.sm,
                tint: tint,
                action: action,
                content: { cardContent }
            )
        } else {
            GlassCard(
                cornerRadius: AppSpacing.cornerRadiusMedium,
                padding: AppSpacing.sm,
                tint: tint,
                content: { cardContent }
            )
        }
    }
}

// Convenience initializer without trailing content
extension GlassListCard where TrailingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> LeadingContent
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            tint: tint,
            action: action,
            leading: leading,
            trailing: { EmptyView() }
        )
    }
}

// Convenience initializer without leading content
extension GlassListCard where LeadingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            tint: tint,
            action: action,
            leading: { EmptyView() },
            trailing: trailing
        )
    }
}

// MARK: - Preview

#Preview("Glass Cards") {
    ZStack {
        // Colorful background to show glass effect
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            ScrollView {
                VStack(spacing: 16) {
                    // Basic card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Basic Glass Card")
                                .font(AppTypography.headlineSmall)
                            Text("This is a standard glass card with default styling.")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Compact card
                    GlassCard.compact {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Compact Card")
                        }
                    }

                    // Tinted card
                    GlassCard(tint: .blue) {
                        Text("Tinted Glass Card")
                            .foregroundStyle(.white)
                    }

                    // Tappable card
                    TappableGlassCard(action: { print("Tapped!") }) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                            Text("Tap me!")
                        }
                    }

                    // List card
                    GlassListCard(
                        title: "Settings",
                        subtitle: "Manage your preferences",
                        action: { }
                    ) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    } trailing: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
    }
}
