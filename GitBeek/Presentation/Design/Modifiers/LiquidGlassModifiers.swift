//
//  LiquidGlassModifiers.swift
//  GitBeek
//
//  iOS 26 Liquid Glass effect modifiers and utilities
//

import SwiftUI

// MARK: - Glass Effect Container

/// Container that provides consistent glass effect sampling for child elements.
/// All glass elements should be wrapped in this container for visual consistency.
///
/// Usage:
/// ```swift
/// GlassEffectContainer {
///     GlassCard { ... }
///     GlassButton("Action") { }
/// }
/// ```
struct GlassEffectContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .glassEffectContainerModifier()
    }
}

// MARK: - Glass Effect Modifier

/// Core glass effect modifier that wraps iOS 26's native glassEffect()
struct GlassEffectModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isInteractive: Bool
    let tint: Color?

    init(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusGlass,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.tint = tint
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(in: .rect(cornerRadius: cornerRadius))
                .applyInteractiveIfNeeded(isInteractive)
                .applyTintIfNeeded(tint)
        } else {
            // Fallback for iOS < 26
            content
                .background(
                    GlassFallbackBackground(cornerRadius: cornerRadius, tint: tint)
                )
        }
    }
}

// MARK: - Fallback Glass Background (Pre-iOS 26)

/// Fallback glass effect for iOS versions before 26
struct GlassFallbackBackground: View {
    let cornerRadius: CGFloat
    let tint: Color?

    var body: some View {
        ZStack {
            // Base blur effect
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            // Optional tint overlay
            if let tint = tint {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.1))
            }

            // Subtle border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - View Extensions for Glass Effects

extension View {
    /// Apply the glass effect container modifier
    func glassEffectContainerModifier() -> some View {
        self
    }

    /// Apply glass effect with customizable parameters
    func glassStyle(
        cornerRadius: CGFloat = AppSpacing.cornerRadiusGlass,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(GlassEffectModifier(
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            tint: tint
        ))
    }

    /// Apply glass effect with default settings
    func glass() -> some View {
        glassStyle()
    }

    /// Apply interactive glass effect (responds to touch)
    func interactiveGlass() -> some View {
        glassStyle(isInteractive: true)
    }

    /// Apply tinted glass effect
    func tintedGlass(_ color: Color) -> some View {
        glassStyle(tint: color)
    }

    /// Apply glass effect with specific corner radius
    func glass(cornerRadius: CGFloat) -> some View {
        glassStyle(cornerRadius: cornerRadius)
    }

    // MARK: - iOS 26 Specific Helpers

    @ViewBuilder
    fileprivate func applyInteractiveIfNeeded(_ isInteractive: Bool) -> some View {
        if #available(iOS 26.0, *), isInteractive {
            self.interactive()
        } else {
            self
        }
    }

    @ViewBuilder
    fileprivate func applyTintIfNeeded(_ tint: Color?) -> some View {
        if let tint = tint {
            self.tint(tint)
        } else {
            self
        }
    }
}

// MARK: - Glass Effect ID for Transitions

extension View {
    /// Apply glass effect ID for morphing transitions between views
    /// Note: Use this modifier with a namespace created in your view using @Namespace
    func glassTransitionID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(self.glassEffectID(id, in: namespace))
        } else {
            return AnyView(self.matchedGeometryEffect(id: id, in: namespace))
        }
    }
}

// MARK: - Background Extension Effect

/// Modifier for background extension effect (content extends behind glass)
struct BackgroundExtensionModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), isEnabled {
            content.backgroundExtensionEffect()
        } else {
            content
        }
    }
}

extension View {
    /// Enable background extension effect
    func extendBackground(_ enabled: Bool = true) -> some View {
        modifier(BackgroundExtensionModifier(isEnabled: enabled))
    }
}

// MARK: - Scroll Edge Effect

/// Modifier for scroll edge effect styling
struct ScrollEdgeEffectModifier: ViewModifier {
    enum Style {
        case automatic
        case soft
        case hard
    }

    let style: Style

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch style {
            case .automatic:
                content.scrollEdgeEffectStyle(.automatic, for: .all)
            case .soft:
                content.scrollEdgeEffectStyle(.soft, for: .all)
            case .hard:
                content.scrollEdgeEffectStyle(.hard, for: .all)
            }
        } else {
            content
        }
    }
}

extension View {
    /// Apply scroll edge effect style
    func scrollEdgeStyle(_ style: ScrollEdgeEffectModifier.Style) -> some View {
        modifier(ScrollEdgeEffectModifier(style: style))
    }
}

// MARK: - Corner Concentricity

/// Modifier for concentric corner styling
struct ConcentricCornerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusGlass, style: .continuous))
    }
}

extension View {
    /// Apply concentric corner styling
    func concentricCorners() -> some View {
        modifier(ConcentricCornerModifier())
    }
}

// MARK: - Preview

#Preview("Glass Effects") {
    ZStack {
        // Background
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            VStack(spacing: 20) {
                // Basic glass
                Text("Basic Glass")
                    .padding()
                    .glass()

                // Interactive glass
                Text("Interactive Glass")
                    .padding()
                    .interactiveGlass()

                // Tinted glass
                Text("Tinted Glass")
                    .padding()
                    .tintedGlass(.blue)

                // Custom corner radius
                Text("Custom Corners")
                    .padding()
                    .glass(cornerRadius: 8)
            }
        }
    }
}
