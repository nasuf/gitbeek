//
//  GlassToolbar.swift
//  GitBeek
//
//  Liquid Glass floating toolbar component
//

import SwiftUI

// MARK: - Glass Toolbar

/// A floating toolbar with Liquid Glass effect styling.
///
/// Usage:
/// ```swift
/// GlassToolbar {
///     GlassIconButton(systemImage: "bold") { }
///     GlassIconButton(systemImage: "italic") { }
///     ToolbarDivider()
///     GlassIconButton(systemImage: "list.bullet") { }
/// }
/// ```
struct GlassToolbar<Content: View>: View {
    let content: Content
    let position: ToolbarPosition

    enum ToolbarPosition {
        case top
        case bottom
        case floating
    }

    init(
        position: ToolbarPosition = .floating,
        @ViewBuilder content: () -> Content
    ) {
        self.position = position
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            content
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusGlass)
        .shadow(color: AppColors.glassShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Toolbar Divider

/// A vertical divider for use in toolbars
struct ToolbarDivider: View {
    var body: some View {
        Divider()
            .frame(height: 24)
            .padding(.horizontal, AppSpacing.xxs)
    }
}

// MARK: - Toolbar Spacer

/// A flexible spacer for toolbars
struct ToolbarFlexSpacer: View {
    var body: some View {
        Spacer(minLength: 0)
    }
}

// MARK: - Glass Toolbar Item

/// A single toolbar item with icon and optional label
struct GlassToolbarItem: View {
    let systemImage: String
    let label: String?
    let isSelected: Bool
    let tint: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        systemImage: String,
        label: String? = nil,
        isSelected: Bool = false,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.isSelected = isSelected
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .symbolVariant(isSelected ? .fill : .none)

                if let label = label {
                    Text(label)
                        .font(AppTypography.captionSmall)
                }
            }
            .foregroundStyle(isSelected ? (tint ?? AppColors.primaryFallback) : .primary)
            .frame(minWidth: AppSpacing.minTouchTarget, minHeight: AppSpacing.minTouchTarget)
            .background {
                if isSelected {
                    Circle()
                        .fill((tint ?? AppColors.primaryFallback).opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Segmented Glass Toolbar

/// A toolbar with segmented control-like behavior
struct SegmentedGlassToolbar<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let itemContent: (Item) -> (systemImage: String, label: String?)
    let tint: Color

    init(
        items: [Item],
        selection: Binding<Item>,
        tint: Color = AppColors.primaryFallback,
        @ViewBuilder itemContent: @escaping (Item) -> (systemImage: String, label: String?)
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.itemContent = itemContent
    }

    var body: some View {
        GlassToolbar {
            ForEach(items, id: \.self) { item in
                let content = itemContent(item)
                GlassToolbarItem(
                    systemImage: content.systemImage,
                    label: content.label,
                    isSelected: selection == item,
                    tint: tint
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item
                    }
                }
            }
        }
    }
}

// MARK: - Formatting Toolbar

/// A pre-configured toolbar for text formatting actions
struct FormattingGlassToolbar: View {
    let onBold: () -> Void
    let onItalic: () -> Void
    let onUnderline: () -> Void
    let onStrikethrough: () -> Void
    let onBulletList: () -> Void
    let onNumberedList: () -> Void
    let onLink: () -> Void
    let onCode: () -> Void

    var body: some View {
        GlassToolbar {
            Group {
                GlassToolbarItem(systemImage: "bold", action: onBold)
                GlassToolbarItem(systemImage: "italic", action: onItalic)
                GlassToolbarItem(systemImage: "underline", action: onUnderline)
                GlassToolbarItem(systemImage: "strikethrough", action: onStrikethrough)
            }

            ToolbarDivider()

            Group {
                GlassToolbarItem(systemImage: "list.bullet", action: onBulletList)
                GlassToolbarItem(systemImage: "list.number", action: onNumberedList)
            }

            ToolbarDivider()

            Group {
                GlassToolbarItem(systemImage: "link", action: onLink)
                GlassToolbarItem(systemImage: "chevron.left.forwardslash.chevron.right", action: onCode)
            }
        }
    }
}

// MARK: - Bottom Action Toolbar

/// A toolbar positioned at the bottom with primary actions
struct BottomActionGlassToolbar: View {
    let primaryTitle: String
    let primaryIcon: String?
    let primaryAction: () -> Void
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?

    init(
        primaryTitle: String,
        primaryIcon: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.primaryTitle = primaryTitle
        self.primaryIcon = primaryIcon
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let secondaryTitle = secondaryTitle, let secondaryAction = secondaryAction {
                GlassButton(secondaryTitle, action: secondaryAction)
            }

            Spacer()

            GlassButton(
                primaryTitle,
                systemImage: primaryIcon,
                isProminent: true,
                action: primaryAction
            )
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.md)
        .glassStyle(cornerRadius: 0)
    }
}

// MARK: - Preview

#Preview("Glass Toolbars") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            VStack(spacing: 30) {
                // Basic toolbar
                VStack {
                    Text("Basic Toolbar")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    GlassToolbar {
                        GlassToolbarItem(systemImage: "house") { }
                        GlassToolbarItem(systemImage: "magnifyingglass") { }
                        GlassToolbarItem(systemImage: "bell", isSelected: true) { }
                        GlassToolbarItem(systemImage: "person") { }
                    }
                }

                // Formatting toolbar
                VStack {
                    Text("Formatting Toolbar")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    FormattingGlassToolbar(
                        onBold: { },
                        onItalic: { },
                        onUnderline: { },
                        onStrikethrough: { },
                        onBulletList: { },
                        onNumberedList: { },
                        onLink: { },
                        onCode: { }
                    )
                }

                // Segmented toolbar
                VStack {
                    Text("Segmented Toolbar")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    StatefulPreviewWrapper(0) { selection in
                        SegmentedGlassToolbar(
                            items: [0, 1, 2],
                            selection: selection
                        ) { item in
                            switch item {
                            case 0: return ("doc.text", "Edit")
                            case 1: return ("eye", "Preview")
                            default: return ("square.split.2x1", "Split")
                            }
                        }
                    }
                }

                Spacer()

                // Bottom action toolbar
                BottomActionGlassToolbar(
                    primaryTitle: "Save",
                    primaryIcon: "checkmark",
                    primaryAction: { },
                    secondaryTitle: "Cancel",
                    secondaryAction: { }
                )
            }
            .padding(.top, 40)
        }
    }
}
