//
//  BreadcrumbNavigationView.swift
//  GitBeek
//
//  Liquid Glass breadcrumb navigation
//

import SwiftUI

/// Breadcrumb item for navigation
struct BreadcrumbItem: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String?

    var displayTitle: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }
}

/// Horizontal breadcrumb navigation with Liquid Glass styling
struct BreadcrumbNavigationView: View {
    // MARK: - Properties

    let items: [BreadcrumbItem]
    let onItemTap: (BreadcrumbItem) -> Void

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    // Breadcrumb item
                    BreadcrumbItemView(
                        item: item,
                        isLast: index == items.count - 1,
                        onTap: {
                            onItemTap(item)
                        }
                    )

                    // Chevron separator (not after last item)
                    if index < items.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Breadcrumb Item View

private struct BreadcrumbItemView: View {
    let item: BreadcrumbItem
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if let emoji = item.emoji {
                    Text(emoji)
                        .font(.caption)
                }

                Text(item.title)
                    .font(AppTypography.caption)
                    .fontWeight(isLast ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundStyle(isLast ? .primary : .secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background {
                if isLast {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLast)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.lg) {
        // Single item
        BreadcrumbNavigationView(
            items: [
                BreadcrumbItem(id: "1", title: "Getting Started", emoji: nil)
            ],
            onItemTap: { _ in }
        )
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))

        // Multiple items
        BreadcrumbNavigationView(
            items: [
                BreadcrumbItem(id: "1", title: "API Reference", emoji: nil),
                BreadcrumbItem(id: "2", title: "Authentication", emoji: nil),
                BreadcrumbItem(id: "3", title: "OAuth 2.0", emoji: nil)
            ],
            onItemTap: { _ in }
        )
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))

        // With emojis
        BreadcrumbNavigationView(
            items: [
                BreadcrumbItem(id: "1", title: "Guides", emoji: "📚"),
                BreadcrumbItem(id: "2", title: "Getting Started", emoji: "🚀"),
                BreadcrumbItem(id: "3", title: "Installation", emoji: "📦")
            ],
            onItemTap: { _ in }
        )
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
    }
    .padding()
}
