//
//  GlassSheet.swift
//  GitBeek
//
//  Liquid Glass modal sheet components
//

import SwiftUI

// MARK: - Glass Sheet Modifier

/// A view modifier that presents a sheet with Liquid Glass styling
struct GlassSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let showsIndicator: Bool
    let sheetContent: () -> SheetContent

    init(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        showsIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.showsIndicator = showsIndicator
        self.sheetContent = content
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .presentationDetents(detents)
                    .presentationDragIndicator(showsIndicator ? .visible : .hidden)
                    .presentationCornerRadius(AppSpacing.cornerRadiusXL)
                    .presentationBackground(.ultraThinMaterial)
            }
    }
}

extension View {
    /// Present a glass-styled sheet
    func glassSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        showsIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(GlassSheetModifier(
            isPresented: isPresented,
            detents: detents,
            showsIndicator: showsIndicator,
            content: content
        ))
    }
}

// MARK: - Glass Sheet Content

/// A container for glass sheet content with standard layout
struct GlassSheetContent<Content: View>: View {
    let title: String?
    let subtitle: String?
    let showCloseButton: Bool
    let onClose: (() -> Void)?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        showCloseButton: Bool = true,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showCloseButton = showCloseButton
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if title != nil || showCloseButton {
                sheetHeader
            }

            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var sheetHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(AppTypography.headlineMedium)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if showCloseButton {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
    }
}

// MARK: - Glass Action Sheet

/// An action sheet styled with Liquid Glass
struct GlassActionSheet: View {
    let title: String?
    let message: String?
    let actions: [ActionItem]
    let cancelAction: ActionItem?

    struct ActionItem: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String?
        let role: ButtonRole?
        let action: () -> Void

        init(
            _ title: String,
            systemImage: String? = nil,
            role: ButtonRole? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.role = role
            self.action = action
        }

        static func destructive(_ title: String, systemImage: String? = "trash", action: @escaping () -> Void) -> ActionItem {
            ActionItem(title, systemImage: systemImage, role: .destructive, action: action)
        }

        static func cancel(_ title: String = "Cancel", action: @escaping () -> Void = {}) -> ActionItem {
            ActionItem(title, role: .cancel, action: action)
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Header
            if title != nil || message != nil {
                VStack(spacing: 4) {
                    if let title = title {
                        Text(title)
                            .font(AppTypography.headlineSmall)
                    }
                    if let message = message {
                        Text(message)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }

            // Actions
            VStack(spacing: AppSpacing.xs) {
                ForEach(actions) { actionItem in
                    actionButton(actionItem)
                }
            }

            // Cancel (separate group)
            if let cancelAction = cancelAction {
                actionButton(cancelAction)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.md)
    }

    @ViewBuilder
    private func actionButton(_ item: ActionItem) -> some View {
        Button {
            item.action()
        } label: {
            HStack {
                if let systemImage = item.systemImage {
                    Image(systemName: systemImage)
                }
                Text(item.title)
                    .font(AppTypography.bodyLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(GlassButtonStyle(
            tint: item.role == .destructive ? AppColors.danger : nil,
            isProminent: item.role == .cancel
        ))
    }
}

// MARK: - Glass Confirmation Dialog

/// A confirmation dialog with Liquid Glass styling
struct GlassConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmRole = confirmRole
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon
            Image(systemName: confirmRole == .destructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(confirmRole == .destructive ? AppColors.danger : AppColors.info)

            // Text
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.headlineMedium)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Actions
            HStack(spacing: AppSpacing.md) {
                GlassButton("Cancel", action: onCancel)

                GlassButton(
                    confirmTitle,
                    tint: confirmRole == .destructive ? AppColors.danger : nil,
                    isProminent: true,
                    action: onConfirm
                )
            }
        }
        .padding(AppSpacing.xl)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusXL)
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - Glass Alert View

/// An alert view with Liquid Glass styling
struct GlassAlert: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(title)
                .font(AppTypography.headlineMedium)

            Text(message)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassButton(buttonTitle, isProminent: true, action: action)
        }
        .padding(AppSpacing.xl)
        .glassStyle(cornerRadius: AppSpacing.cornerRadiusXL)
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - Preview

#Preview("Glass Sheets") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            VStack(spacing: 30) {
                // Confirmation dialog
                GlassConfirmationDialog(
                    title: "Delete Space?",
                    message: "This action cannot be undone. All content will be permanently deleted.",
                    confirmTitle: "Delete",
                    confirmRole: .destructive,
                    onConfirm: { },
                    onCancel: { }
                )

                // Alert
                GlassAlert(
                    title: "Success!",
                    message: "Your changes have been saved successfully.",
                    buttonTitle: "OK",
                    action: { }
                )
            }
        }
    }
}

#Preview("Action Sheet") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GlassEffectContainer {
            GlassActionSheet(
                title: "Space Options",
                message: "Choose an action for this space",
                actions: [
                    .init("Edit", systemImage: "pencil") { },
                    .init("Share", systemImage: "square.and.arrow.up") { },
                    .init("Duplicate", systemImage: "doc.on.doc") { },
                    .destructive("Delete") { }
                ],
                cancelAction: .cancel { }
            )
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusXL)
            .padding()
        }
    }
}
