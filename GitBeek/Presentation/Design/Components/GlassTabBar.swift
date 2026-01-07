//
//  GlassTabBar.swift
//  GitBeek
//
//  Liquid Glass bottom tab bar component (iOS 26)
//

import SwiftUI

// MARK: - Tab Item Definition

/// Defines a tab item for the glass tab bar
struct GlassTabItem: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    let badge: Int?

    init(
        id: String,
        title: String,
        systemImage: String,
        badge: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.badge = badge
    }
}

// MARK: - Glass Tab Bar

/// A custom tab bar with Liquid Glass styling.
/// For iOS 26, use the native TabView with `.tabBarMinimizeBehavior()`.
/// This component provides a custom implementation for additional control.
struct GlassTabBar: View {
    let items: [GlassTabItem]
    @Binding var selectedID: String
    let tint: Color

    @Namespace private var tabNamespace

    init(
        items: [GlassTabItem],
        selectedID: Binding<String>,
        tint: Color = AppColors.primaryFallback
    ) {
        self.items = items
        self._selectedID = selectedID
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusGlass)
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.bottom, AppSpacing.xs)
    }

    @ViewBuilder
    private func tabButton(for item: GlassTabItem) -> some View {
        let isSelected = selectedID == item.id

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedID = item.id
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .symbolVariant(isSelected ? .fill : .none)

                    // Badge
                    if let badge = item.badge, badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(AppColors.danger)
                            )
                            .offset(x: 10, y: -4)
                    }
                }

                Text(item.title)
                    .font(AppTypography.captionSmall)
            }
            .foregroundStyle(isSelected ? tint : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(tint.opacity(0.15))
                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Minimizable Glass Tab Bar

/// A tab bar that can minimize when scrolling (iOS 26 feature)
struct MinimizableGlassTabBar: View {
    let items: [GlassTabItem]
    @Binding var selectedID: String
    @Binding var isMinimized: Bool
    let tint: Color

    @Namespace private var tabNamespace

    init(
        items: [GlassTabItem],
        selectedID: Binding<String>,
        isMinimized: Binding<Bool>,
        tint: Color = AppColors.primaryFallback
    ) {
        self.items = items
        self._selectedID = selectedID
        self._isMinimized = isMinimized
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: isMinimized ? AppSpacing.xxs : 0) {
            ForEach(items) { item in
                tabButton(for: item, isMinimized: isMinimized)
            }
        }
        .padding(.horizontal, isMinimized ? AppSpacing.xs : AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .glassStyle(cornerRadius: isMinimized ? AppSpacing.buttonHeightMedium / 2 : AppSpacing.cornerRadiusGlass)
        .padding(.horizontal, isMinimized ? 0 : AppSpacing.screenPadding)
        .padding(.bottom, AppSpacing.xs)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMinimized)
    }

    @ViewBuilder
    private func tabButton(for item: GlassTabItem, isMinimized: Bool) -> some View {
        let isSelected = selectedID == item.id

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedID = item.id
            }
        } label: {
            if isMinimized {
                // Minimized: icon only, smaller
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundStyle(isSelected ? tint : .secondary)
                    .frame(width: 36, height: 36)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(tint.opacity(0.15))
                                .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                        }
                    }
            } else {
                // Full size: icon + label
                VStack(spacing: 4) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .symbolVariant(isSelected ? .fill : .none)

                    Text(item.title)
                        .font(AppTypography.captionSmall)
                }
                .foregroundStyle(isSelected ? tint : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(tint.opacity(0.15))
                            .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab View with Glass Tab Bar

/// A container view that combines content with a glass tab bar
struct GlassTabView<Content: View>: View {
    let items: [GlassTabItem]
    @Binding var selectedID: String
    let tint: Color
    let content: (String) -> Content

    init(
        items: [GlassTabItem],
        selectedID: Binding<String>,
        tint: Color = AppColors.primaryFallback,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self.items = items
        self._selectedID = selectedID
        self.tint = tint
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            content(selectedID)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar
            GlassTabBar(
                items: items,
                selectedID: $selectedID,
                tint: tint
            )
        }
    }
}

// MARK: - Accessory Tab Bar

/// A tab bar with a bottom accessory view (like Now Playing)
struct AccessoryGlassTabBar<Accessory: View>: View {
    let items: [GlassTabItem]
    @Binding var selectedID: String
    let tint: Color
    let accessory: Accessory

    init(
        items: [GlassTabItem],
        selectedID: Binding<String>,
        tint: Color = AppColors.primaryFallback,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.items = items
        self._selectedID = selectedID
        self.tint = tint
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Accessory
            accessory
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xs)

            // Tab bar
            GlassTabBar(
                items: items,
                selectedID: $selectedID,
                tint: tint
            )
        }
    }
}

// MARK: - Preview

#Preview("Glass Tab Bars") {
    let sampleItems = [
        GlassTabItem(id: "home", title: "Home", systemImage: "house"),
        GlassTabItem(id: "search", title: "Search", systemImage: "magnifyingglass"),
        GlassTabItem(id: "notifications", title: "Alerts", systemImage: "bell", badge: 3),
        GlassTabItem(id: "profile", title: "Profile", systemImage: "person")
    ]

    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            VStack {
                Spacer()

                // Standard tab bar
                VStack {
                    Text("Standard Tab Bar")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    StatefulPreviewWrapper("home") { selectedID in
                        GlassTabBar(
                            items: sampleItems,
                            selectedID: selectedID
                        )
                    }
                }

                Spacer().frame(height: 40)

                // Minimizable tab bar
                VStack {
                    Text("Minimized Tab Bar")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    StatefulPreviewWrapper("home") { selectedID in
                        MinimizableGlassTabBar(
                            items: sampleItems,
                            selectedID: selectedID,
                            isMinimized: .constant(true)
                        )
                    }
                }

                Spacer().frame(height: 40)

                // With accessory
                VStack {
                    Text("With Accessory")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(.white)

                    StatefulPreviewWrapper("home") { selectedID in
                        AccessoryGlassTabBar(
                            items: sampleItems,
                            selectedID: selectedID
                        ) {
                            HStack {
                                Image(systemName: "music.note")
                                Text("Now Playing")
                                    .font(AppTypography.bodySmall)
                                Spacer()
                                Image(systemName: "play.fill")
                            }
                        }
                    }
                }

                Spacer()
            }
        }
    }
}
