//
//  ReadingSettingsSheet.swift
//  GitBeek
//
//  Quick reading settings sheet for page view
//

import SwiftUI
import Highlightr

/// Quick settings sheet for adjusting reading preferences
struct ReadingSettingsSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @AppStorage("fontScale") private var fontScale: FontScale = .default
    @AppStorage("codeTheme") private var codeTheme: CodeHighlightTheme = .xcode

    // MARK: - State

    @State private var highlightedCode: AttributedString?

    // MARK: - Constants

    private let previewCode = "func greet(_ name: String) -> String {\n    return \"Hello, \\(name)!\"\n}"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                fontSizeSection
                codeThemeSection
                previewSection
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await highlightPreviewCode() }
            .onChange(of: codeTheme) { _, _ in
                Task { await highlightPreviewCode() }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Font Size Section

    private var fontSizeSection: some View {
        Section {
            Picker("Font Size", selection: $fontScale) {
                ForEach(FontScale.allCases) { scale in
                    Text(scale.displayName).tag(scale)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Label("Font Size", systemImage: "textformat.size")
        }
    }

    // MARK: - Code Theme Section

    private var codeThemeSection: some View {
        Section {
            ForEach(CodeHighlightTheme.allCases) { theme in
                Button {
                    codeTheme = theme
                } label: {
                    HStack {
                        Circle()
                            .fill(theme.isDark ? Color.black : Color.white)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                            .frame(width: 20, height: 20)

                        Text(theme.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if codeTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.primaryFallback)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Label("Code Theme", systemImage: "chevron.left.forwardslash.chevron.right")
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        Section("Preview") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Sample Text")
                    .font(.system(size: 17 * fontScale.multiplier, weight: .semibold))

                Text("Body text preview.")
                    .font(.system(size: 15 * fontScale.multiplier))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    codePreview
                }
                .padding(AppSpacing.sm)
                .background(codeTheme.isDark ? Color.black.opacity(0.85) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
        }
    }

    @ViewBuilder
    private var codePreview: some View {
        if let highlighted = highlightedCode {
            Text(highlighted)
                .font(.system(size: 12 * fontScale.multiplier, design: .monospaced))
        } else {
            Text(previewCode)
                .font(.system(size: 12 * fontScale.multiplier, design: .monospaced))
                .foregroundStyle(codeTheme.isDark ? .white : .primary)
        }
    }

    // MARK: - Syntax Highlighting

    private func highlightPreviewCode() async {
        let highlightr = Highlightr()
        highlightr?.setTheme(to: codeTheme.highlightrThemeName)

        guard let highlighted = highlightr?.highlight(previewCode, as: "swift") else { return }

        await MainActor.run {
            highlightedCode = AttributedString(highlighted)
        }
    }
}

#Preview {
    ReadingSettingsSheet()
}
