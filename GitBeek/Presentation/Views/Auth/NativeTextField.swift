//
//  NativeTextField.swift
//  GitBeek
//
//  UIKit-based TextField wrapper to fix iOS keyboard bugs
//  Workaround for: https://fatbobman.com/en/posts/textfield-event-focus-keyboard/
//

import SwiftUI
import UIKit

/// Native UITextField wrapper that fixes SwiftUI keyboard issues
/// Based on: https://github.com/lukeredpath/swift-responsive-textfield
struct NativeTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    let onReturn: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        // Configure appearance
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.borderStyle = .none
        textField.textColor = UIColor.label
        textField.tintColor = UIColor.systemBlue
        textField.font = .systemFont(ofSize: 16)

        // Prevent size expansion from content
        textField.contentVerticalAlignment = .center
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always

        // Set initial text
        textField.text = text

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update if text actually changed
        if uiView.text != text {
            uiView.text = text
        }
        uiView.isSecureTextEntry = isSecure
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onReturn: onReturn)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onReturn: () -> Void

        init(text: Binding<String>, onReturn: @escaping () -> Void) {
            _text = text
            self.onReturn = onReturn
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onReturn()
            return true
        }
    }
}

/// Container for NativeTextField with icon and toggle
struct NativeTokenInput: View {
    @Binding var text: String
    @Binding var isVisible: Bool
    let onSubmit: () -> Void

    private static let inputHeight: CGFloat = 44
    private static let iconSize: CGFloat = 20
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 8
    private static let cornerRadius: CGFloat = 12

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon
            textField
            trailingButton
        }
        .frame(height: Self.inputHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }

    // MARK: - Subviews

    private var leadingIcon: some View {
        Image(systemName: "key.fill")
            .foregroundStyle(AppColors.primaryFallback)
            .frame(width: Self.iconSize, height: Self.iconSize)
    }

    private var textField: some View {
        NativeTextField(
            text: $text,
            placeholder: "Enter your API token",
            isSecure: !isVisible,
            onReturn: onSubmit
        )
        .layoutPriority(-1)
    }

    private var trailingButton: some View {
        Button(action: { isVisible.toggle() }) {
            Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                .foregroundStyle(.secondary)
                .frame(width: Self.iconSize, height: Self.iconSize)
        }
        .buttonStyle(.borderless)
    }
}
