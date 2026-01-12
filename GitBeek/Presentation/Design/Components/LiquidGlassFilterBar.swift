//
//  LiquidGlassFilterBar.swift
//  GitBeek
//
//  Liquid Glass style filter bar with iOS 18 fallback
//

import SwiftUI

/// Filter option with title and count
struct FilterOption<Value: Equatable>: Identifiable {
    let id: String
    let title: String
    let count: Int
    let value: Value?
    let isLoading: Bool

    init(id: String = UUID().uuidString, title: String, count: Int, value: Value?, isLoading: Bool = false) {
        self.id = id
        self.title = title
        self.count = count
        self.value = value
        self.isLoading = isLoading
    }
}

/// Liquid Glass style filter bar
struct LiquidGlassFilterBar<Value: Equatable>: View {
    // MARK: - Properties

    let options: [FilterOption<Value>]
    @Binding var selectedValue: Value?
    let onFilterTap: ((Value?) -> Void)?

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(options) { option in
                        filterChip(option: option, scrollProxy: proxy)
                            .id(option.id)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
            .onAppear {
                if let selected = selectedValue,
                   let index = options.firstIndex(where: { $0.value == selected }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(options[index].id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Chip

    private func filterChip(option: FilterOption<Value>, scrollProxy: ScrollViewProxy) -> some View {
        let isSelected = (option.value == nil && selectedValue == nil) ||
                        (option.value != nil && option.value == selectedValue)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedValue = option.value
                scrollProxy.scrollTo(option.id, anchor: .center)
            }
            HapticFeedback.selection()
            onFilterTap?(option.value)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(option.title)
                    .font(AppTypography.labelMedium)
                    .fontWeight(isSelected ? .semibold : .regular)

                // Show loading indicator or count
                if option.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Text("\(option.count)")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                chipBackground(isSelected: isSelected)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chip Background

    @ViewBuilder
    private func chipBackground(isSelected: Bool) -> some View {
        if #available(iOS 18.0, *) {
            // iOS 26 Liquid Glass style
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(.thinMaterial)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 2)
                        .overlay(
                            Capsule()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                        )
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        } else {
            // iOS 18 fallback - simpler style
            if isSelected {
                Capsule()
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
            } else {
                Capsule()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.lg) {
        LiquidGlassFilterBar(
            options: [
                FilterOption(title: "All", count: 66, value: nil as ChangeRequestStatus?, isLoading: false),
                FilterOption(title: "Open", count: 0, value: ChangeRequestStatus.open, isLoading: true),
                FilterOption(title: "Draft", count: 9, value: ChangeRequestStatus.draft, isLoading: false),
                FilterOption(title: "Merged", count: 54, value: ChangeRequestStatus.merged, isLoading: false),
                FilterOption(title: "Archived", count: 3, value: ChangeRequestStatus.archived, isLoading: false)
            ],
            selectedValue: .constant(.open),
            onFilterTap: { status in
                print("Filter tapped: \(status?.rawValue ?? "all")")
            }
        )
        .padding()
        .background(Color(.systemGroupedBackground))

        Spacer()
    }
}
