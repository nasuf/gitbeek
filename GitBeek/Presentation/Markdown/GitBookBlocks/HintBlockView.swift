//
//  HintBlockView.swift
//  GitBeek
//
//  GitBook hint/callout block
//

import SwiftUI

/// View for rendering GitBook hint blocks (info, warning, danger, success)
struct HintBlockView: View {
    // MARK: - Properties

    let type: HintType
    let content: [MarkdownBlock]

    // MARK: - Computed

    private var icon: String {
        switch type {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.1)
    }

    private var borderColor: Color {
        iconColor.opacity(0.3)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(content) { block in
                    MarkdownBlockView(block: block)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            HintBlockView(
                type: .info,
                content: [.paragraph(text: AttributedString("This is an information hint. It provides helpful context."))]
            )

            HintBlockView(
                type: .success,
                content: [.paragraph(text: AttributedString("Great job! Your changes have been saved successfully."))]
            )

            HintBlockView(
                type: .warning,
                content: [.paragraph(text: AttributedString("Be careful! This action might have side effects."))]
            )

            HintBlockView(
                type: .danger,
                content: [.paragraph(text: AttributedString("Danger! This action cannot be undone."))]
            )
        }
        .padding()
    }
}
