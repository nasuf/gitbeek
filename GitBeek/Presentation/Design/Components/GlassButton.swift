//
//  GlassButton.swift
//  GitBeek
//
//  Liquid Glass button styles and components
//

import SwiftUI

// MARK: - Glass Button Style

/// A button style that applies Liquid Glass effect
struct GlassButtonStyle: ButtonStyle {
    let tint: Color?
    let isProminent: Bool

    init(tint: Color? = nil, isProminent: Bool = false) {
        self.tint = tint
        self.isProminent = isProminent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                if #available(iOS 26.0, *) {
                    if isProminent {
                        Capsule()
                            .fill((tint ?? AppColors.primaryFallback).gradient)
                    } else {
                        Capsule()
                            .glassEffect()
                            .tint(tint ?? .clear)
                    }
                } else {
                    // Fallback
                    if isProminent {
                        Capsule()
                            .fill((tint ?? AppColors.primaryFallback).gradient)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                if let tint = tint {
                                    Capsule()
                                        .fill(tint.opacity(0.2))
                                }
                            }
                    }
                }
            }
            .foregroundStyle(isProminent ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == GlassButtonStyle {
    /// Standard glass button style
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }

    /// Prominent glass button style with filled background
    static var glassProminent: GlassButtonStyle {
        GlassButtonStyle(isProminent: true)
    }

    /// Glass button with custom tint
    static func glass(tint: Color) -> GlassButtonStyle {
        GlassButtonStyle(tint: tint)
    }

    /// Prominent glass button with custom tint
    static func glassProminent(tint: Color) -> GlassButtonStyle {
        GlassButtonStyle(tint: tint, isProminent: true)
    }
}

// MARK: - Glass Button

/// A pre-styled button with Liquid Glass effect
struct GlassButton: View {
    let title: String
    let systemImage: String?
    let tint: Color?
    let isProminent: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        tint: Color? = nil,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isProminent = isProminent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.iconTextSpacing) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(AppTypography.labelLarge)
        }
        .buttonStyle(GlassButtonStyle(tint: tint, isProminent: isProminent))
    }
}

// MARK: - Glass Icon Button

/// A circular icon-only glass button
struct GlassIconButton: View {
    let systemImage: String
    let size: CGFloat
    let tint: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        systemImage: String,
        size: CGFloat = AppSpacing.buttonHeightMedium,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.size = size
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4))
                .frame(width: size, height: size)
                .glassStyle(cornerRadius: size / 2, tint: tint)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Glass Pill Button

/// A pill-shaped button with icon and optional badge
struct GlassPillButton: View {
    let title: String
    let systemImage: String
    let badge: Int?
    let tint: Color?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        badge: Int? = nil,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.badge = badge
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)

                Text(title)
                    .font(AppTypography.labelMedium)

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(AppTypography.captionSmall)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(AppColors.danger)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(GlassButtonStyle(tint: tint))
    }
}

// MARK: - Glass Toggle Button

/// A toggle button with glass styling
struct GlassToggleButton: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let tint: Color

    init(
        _ title: String,
        systemImage: String,
        isOn: Binding<Bool>,
        tint: Color = AppColors.primaryFallback
    ) {
        self.title = title
        self.systemImage = systemImage
        self._isOn = isOn
        self.tint = tint
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: AppSpacing.iconTextSpacing) {
                Image(systemName: systemImage)
                Text(title)
                    .font(AppTypography.labelMedium)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                Capsule()
                    .fill(isOn ? tint : Color.clear)
            }
            .glassStyle(cornerRadius: AppSpacing.buttonHeightMedium / 2, tint: isOn ? nil : tint)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isOn ? .white : .primary)
    }
}

// MARK: - Destructive Glass Button

/// A glass button styled for destructive actions
struct DestructiveGlassButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = "trash",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        GlassButton(
            title,
            systemImage: systemImage,
            tint: AppColors.danger,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Glass Buttons") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            ScrollView {
                VStack(spacing: 20) {
                    // Standard buttons
                    Group {
                        Text("Standard Buttons")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.white)

                        GlassButton("Glass Button") { }

                        GlassButton("With Icon", systemImage: "star.fill") { }

                        GlassButton("Prominent", isProminent: true) { }

                        GlassButton("Tinted", tint: .green) { }
                    }

                    Divider()

                    // Icon buttons
                    Group {
                        Text("Icon Buttons")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.white)

                        HStack(spacing: 16) {
                            GlassIconButton(systemImage: "plus") { }
                            GlassIconButton(systemImage: "heart.fill", tint: .red) { }
                            GlassIconButton(systemImage: "gear") { }
                            GlassIconButton(systemImage: "bell.fill", tint: .orange) { }
                        }
                    }

                    Divider()

                    // Pill buttons
                    Group {
                        Text("Pill Buttons")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.white)

                        GlassPillButton("Notifications", systemImage: "bell", badge: 5) { }

                        GlassPillButton("Messages", systemImage: "message", badge: nil, tint: .blue) { }
                    }

                    Divider()

                    // Toggle & Destructive
                    Group {
                        Text("Special Buttons")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.white)

                        StatefulPreviewWrapper(false) { isOn in
                            GlassToggleButton("Toggle", systemImage: "moon.fill", isOn: isOn)
                        }

                        DestructiveGlassButton("Delete") { }
                    }
                }
                .padding()
            }
        }
    }
}

// Helper for stateful previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
