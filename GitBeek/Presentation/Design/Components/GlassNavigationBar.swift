//
//  GlassNavigationBar.swift
//  GitBeek
//
//  Liquid Glass navigation bar styles and components
//

import SwiftUI

// MARK: - Glass Navigation Bar Style

/// Configures the navigation bar to use Liquid Glass styling
struct GlassNavigationBarModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    let showBackground: Bool

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(showBackground ? .visible : .automatic, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

extension View {
    /// Apply glass navigation bar styling
    func glassNavigationBar(
        title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .automatic,
        showBackground: Bool = true
    ) -> some View {
        modifier(GlassNavigationBarModifier(
            title: title,
            displayMode: displayMode,
            showBackground: showBackground
        ))
    }
}

// MARK: - Custom Glass Navigation Header

/// A custom navigation header with Liquid Glass effect
struct GlassNavigationHeader: View {
    let title: String
    let subtitle: String?
    let leadingAction: (() -> Void)?
    let leadingIcon: String?
    let trailingActions: [NavigationAction]

    struct NavigationAction: Identifiable {
        let id = UUID()
        let systemImage: String
        let badge: Int?
        let action: () -> Void

        init(systemImage: String, badge: Int? = nil, action: @escaping () -> Void) {
            self.systemImage = systemImage
            self.badge = badge
            self.action = action
        }
    }

    init(
        title: String,
        subtitle: String? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingIcon: String? = nil,
        trailingActions: [NavigationAction] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingAction = leadingAction
        self.leadingIcon = leadingIcon
        self.trailingActions = trailingActions
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Leading
            if let leadingAction = leadingAction {
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon ?? "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            // Title
            VStack(alignment: leadingAction == nil ? .leading : .center, spacing: 0) {
                Text(title)
                    .font(AppTypography.headlineSmall)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: leadingAction == nil ? .leading : .center)

            // Trailing
            HStack(spacing: AppSpacing.sm) {
                ForEach(trailingActions) { action in
                    navActionButton(action)
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.sm)
        .glassStyle(cornerRadius: 0)
    }

    @ViewBuilder
    private func navActionButton(_ action: NavigationAction) -> some View {
        Button(action: action.action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 17, weight: .medium))

                if let badge = action.badge, badge > 0 {
                    Text(badge > 9 ? "9+" : "\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Circle().fill(AppColors.danger))
                        .offset(x: 6, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Search Navigation Bar

/// A navigation bar with integrated search field
struct GlassSearchNavigationBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onCancel: (() -> Void)?
    let leadingAction: (() -> Void)?
    let leadingIcon: String?

    @FocusState private var isSearchFocused: Bool

    init(
        searchText: Binding<String>,
        placeholder: String = "Search",
        onCancel: (() -> Void)? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingIcon: String? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onCancel = onCancel
        self.leadingAction = leadingAction
        self.leadingIcon = leadingIcon
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Leading
            if let leadingAction = leadingAction {
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon ?? "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            // Search field
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $searchText)
                    .font(AppTypography.bodyMedium)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)

            // Cancel button
            if isSearchFocused || !searchText.isEmpty {
                Button("Cancel") {
                    searchText = ""
                    isSearchFocused = false
                    onCancel?()
                }
                .font(AppTypography.bodyMedium)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.sm)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
    }
}

// MARK: - Glass Large Title Header

/// A large title header similar to iOS settings/navigation
struct GlassLargeTitleHeader: View {
    let title: String
    let subtitle: String?
    let trailingContent: AnyView?

    init(
        title: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = nil
    }

    init<Trailing: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(AppTypography.displayLarge)
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.md)
    }
}

// MARK: - Glass Breadcrumb Navigation

/// Breadcrumb navigation with glass styling
struct GlassBreadcrumb: View {
    let items: [BreadcrumbItem]
    let onSelect: (BreadcrumbItem) -> Void

    struct BreadcrumbItem: Identifiable {
        let id: String
        let title: String
        let systemImage: String?

        init(id: String = UUID().uuidString, title: String, systemImage: String? = nil) {
            self.id = id
            self.title = title
            self.systemImage = systemImage
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xxs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: AppSpacing.xxs) {
                        // Separator (except for first item)
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        // Item button
                        Button {
                            onSelect(item)
                        } label: {
                            HStack(spacing: 4) {
                                if let systemImage = item.systemImage {
                                    Image(systemName: systemImage)
                                        .font(.caption)
                                }
                                Text(item.title)
                                    .font(AppTypography.caption)
                            }
                            .foregroundStyle(index == items.count - 1 ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
        }
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
    }
}

// MARK: - Preview

#Preview("Navigation Headers") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            ScrollView {
                VStack(spacing: 30) {
                    // Standard header
                    VStack(alignment: .leading) {
                        Text("Standard Header")
                            .font(AppTypography.caption)
                            .foregroundStyle(.white)

                        GlassNavigationHeader(
                            title: "Spaces",
                            subtitle: "My Organization",
                            leadingAction: { },
                            trailingActions: [
                                .init(systemImage: "plus") { },
                                .init(systemImage: "bell", badge: 3) { }
                            ]
                        )
                    }

                    // Search header
                    VStack(alignment: .leading) {
                        Text("Search Header")
                            .font(AppTypography.caption)
                            .foregroundStyle(.white)

                        StatefulPreviewWrapper("") { searchText in
                            GlassSearchNavigationBar(
                                searchText: searchText,
                                placeholder: "Search spaces...",
                                leadingAction: { }
                            )
                        }
                    }

                    // Large title
                    VStack(alignment: .leading) {
                        Text("Large Title")
                            .font(AppTypography.caption)
                            .foregroundStyle(.white)

                        GlassLargeTitleHeader(
                            title: "Settings",
                            subtitle: "Customize your experience"
                        ) {
                            GlassIconButton(systemImage: "gear") { }
                        }
                    }

                    // Breadcrumb
                    VStack(alignment: .leading) {
                        Text("Breadcrumb")
                            .font(AppTypography.caption)
                            .foregroundStyle(.white)

                        GlassBreadcrumb(
                            items: [
                                .init(title: "Home", systemImage: "house"),
                                .init(title: "Documentation"),
                                .init(title: "Getting Started"),
                                .init(title: "Installation")
                            ],
                            onSelect: { _ in }
                        )
                    }
                }
                .padding(.top, 60)
            }
        }
    }
}
