//
//  DesignSystemPreviewView.swift
//  GitBeek
//
//  Preview and showcase for the Liquid Glass design system
//

import SwiftUI

/// A comprehensive preview of all design system components
struct DesignSystemPreviewView: View {
    @State private var selectedTab = "components"
    @State private var searchText = ""
    @State private var isToggleOn = false
    @State private var showSheet = false
    @State private var selectedSegment = 0

    private let tabItems = [
        GlassTabItem(id: "components", title: "Components", systemImage: "square.stack.3d.up"),
        GlassTabItem(id: "colors", title: "Colors", systemImage: "paintpalette"),
        GlassTabItem(id: "typography", title: "Typography", systemImage: "textformat"),
        GlassTabItem(id: "animations", title: "Animations", systemImage: "wand.and.stars")
    ]

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            GlassEffectContainer {
                VStack(spacing: 0) {
                    // Header
                    GlassLargeTitleHeader(
                        title: "Design System",
                        subtitle: "GitBeek Liquid Glass"
                    ) {
                        GlassIconButton(systemImage: "info.circle") {
                            showSheet = true
                        }
                    }

                    // Tab content
                    TabView(selection: $selectedTab) {
                        componentsTab
                            .tag("components")

                        colorsTab
                            .tag("colors")

                        typographyTab
                            .tag("typography")

                        animationsTab
                            .tag("animations")
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Tab bar
                    GlassTabBar(
                        items: tabItems,
                        selectedID: $selectedTab
                    )
                }
            }
        }
        .glassSheet(isPresented: $showSheet, detents: [.medium]) {
            GlassSheetContent(
                title: "About Design System",
                subtitle: "iOS 26 Liquid Glass",
                onClose: { showSheet = false }
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        aboutSection("Overview", text: "This design system implements iOS 26's Liquid Glass design language for the GitBeek app.")

                        aboutSection("Components", text: "Includes GlassCard, GlassButton, GlassToolbar, GlassTabBar, GlassSheet, and GlassNavigationBar.")

                        aboutSection("Animations", text: "Interactive effects, haptic feedback, shimmer loading, and spring animations.")

                        aboutSection("Theme", text: "Colors, typography, and spacing optimized for glass effects.")
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.5),
                Color(red: 0.3, green: 0.2, blue: 0.5),
                Color(red: 0.4, green: 0.2, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Components Tab

    private var componentsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Cards Section
                sectionHeader("Cards")

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Glass Card")
                            .font(AppTypography.headlineSmall)
                        Text("A card with Liquid Glass effect styling.")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                TappableGlassCard(action: { HapticFeedback.light() }) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Tappable Card")
                                .font(AppTypography.bodyLarge)
                            Text("Tap for haptic feedback")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                // Buttons Section
                sectionHeader("Buttons")

                HStack(spacing: 12) {
                    GlassButton("Glass") { }
                    GlassButton("Prominent", isProminent: true) { }
                    GlassButton("Tinted", tint: .green) { }
                }

                HStack(spacing: 16) {
                    GlassIconButton(systemImage: "plus") { }
                    GlassIconButton(systemImage: "heart.fill", tint: .red) { }
                    GlassIconButton(systemImage: "star.fill", tint: .yellow) { }
                    GlassIconButton(systemImage: "bell.fill", tint: .orange) { }
                }

                GlassToggleButton("Dark Mode", systemImage: "moon.fill", isOn: $isToggleOn)

                // Toolbar Section
                sectionHeader("Toolbars")

                GlassToolbar {
                    GlassToolbarItem(systemImage: "bold") { }
                    GlassToolbarItem(systemImage: "italic") { }
                    GlassToolbarItem(systemImage: "underline") { }
                    ToolbarDivider()
                    GlassToolbarItem(systemImage: "list.bullet") { }
                    GlassToolbarItem(systemImage: "link") { }
                }

                SegmentedGlassToolbar(
                    items: [0, 1, 2],
                    selection: $selectedSegment
                ) { item in
                    switch item {
                    case 0: return ("doc.text", "Edit")
                    case 1: return ("eye", "Preview")
                    default: return ("square.split.2x1", "Split")
                    }
                }

                // Navigation Section
                sectionHeader("Navigation")

                GlassBreadcrumb(
                    items: [
                        .init(title: "Home", systemImage: "house"),
                        .init(title: "Docs"),
                        .init(title: "Getting Started")
                    ],
                    onSelect: { _ in }
                )

                GlassSearchNavigationBar(
                    searchText: $searchText,
                    placeholder: "Search components..."
                )

                // Dialogs Section
                sectionHeader("Dialogs")

                GlassAlert(
                    title: "Alert Title",
                    message: "This is an alert message with important information.",
                    buttonTitle: "OK",
                    action: { }
                )
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Colors Tab

    private var colorsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Primary Colors")

                colorRow("Primary", AppColors.primaryFallback)
                colorRow("Secondary", AppColors.secondaryFallback)

                sectionHeader("Semantic Colors")

                colorRow("Success", AppColors.success)
                colorRow("Warning", AppColors.warning)
                colorRow("Danger", AppColors.danger)
                colorRow("Info", AppColors.info)

                sectionHeader("Text Colors")

                colorRow("Primary Text", AppColors.textPrimary)
                colorRow("Secondary Text", AppColors.textSecondary)
                colorRow("Tertiary Text", AppColors.textTertiary)

                sectionHeader("Gradients")

                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .fill(AppColors.primaryGradient)
                    .frame(height: 60)
                    .overlay {
                        Text("Primary Gradient")
                            .foregroundStyle(.white)
                    }

                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .fill(AppColors.glassGradient)
                    .frame(height: 60)
                    .overlay {
                        Text("Glass Gradient")
                    }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Typography Tab

    private var typographyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Display")

                Text("Display Large").font(AppTypography.displayLarge)
                Text("Display Medium").font(AppTypography.displayMedium)
                Text("Display Small").font(AppTypography.displaySmall)

                sectionHeader("Headlines")

                Text("Headline Large").font(AppTypography.headlineLarge)
                Text("Headline Medium").font(AppTypography.headlineMedium)
                Text("Headline Small").font(AppTypography.headlineSmall)

                sectionHeader("Body")

                Text("Body Large - Primary content text").font(AppTypography.bodyLarge)
                Text("Body Medium - Secondary content").font(AppTypography.bodyMedium)
                Text("Body Small - Tertiary content").font(AppTypography.bodySmall)

                sectionHeader("Labels & Captions")

                Text("Label Large").font(AppTypography.labelLarge)
                Text("Label Medium").font(AppTypography.labelMedium)
                Text("Caption").font(AppTypography.caption).foregroundStyle(.secondary)

                sectionHeader("Code")

                Text("let code = \"Monospaced\"").font(AppTypography.code)
                Text("inline code").font(AppTypography.codeInline)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Animations Tab

    private var animationsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                sectionHeader("Interactive Effects")

                HStack(spacing: 16) {
                    GlassCard {
                        Text("Interactive")
                            .frame(width: 80)
                    }
                    .interactive()

                    GlassCard {
                        Text("Press")
                            .frame(width: 80)
                    }
                    .pressEffect()
                }

                sectionHeader("Loading States")

                SkeletonView()
                    .frame(height: 60)

                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        SkeletonView()
                            .frame(width: 80, height: 80)
                    }
                }

                sectionHeader("Continuous Animations")

                HStack(spacing: 40) {
                    VStack {
                        Circle()
                            .fill(AppColors.primaryFallback)
                            .frame(width: 40, height: 40)
                            .pulse()
                        Text("Pulse")
                            .font(AppTypography.caption)
                    }

                    VStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(AppColors.info)
                            .bounce()
                        Text("Bounce")
                            .font(AppTypography.caption)
                    }

                    VStack {
                        Image(systemName: "gear")
                            .font(.largeTitle)
                            .foregroundStyle(AppColors.warning)
                            .rotate(duration: 3)
                        Text("Rotate")
                            .font(AppTypography.caption)
                    }
                }

                sectionHeader("Spring Appear")

                HStack(spacing: 12) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .springAppear(delay: Double(index) * 0.1)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.headlineSmall)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func colorRow(_ name: String, _ color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 50, height: 50)

            Text(name)
                .font(AppTypography.bodyMedium)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .glass(cornerRadius: AppSpacing.cornerRadiusMedium)
    }

    private func aboutSection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.headlineSmall)
            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    DesignSystemPreviewView()
}
