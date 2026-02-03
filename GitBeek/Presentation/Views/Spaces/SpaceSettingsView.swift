//
//  SpaceSettingsView.swift
//  GitBeek
//
//  Settings view for editing space properties
//

import SwiftUI
import ElegantEmojiPicker

/// View for editing space settings
struct SpaceSettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let space: Space
    let collections: [Collection]
    let onSave: (String?, String?, Space.Visibility?) async throws -> Void
    let onMove: (String?) -> Void
    let onDelete: () -> Void

    @State private var title: String
    @State private var selectedEmoji: Emoji?
    @State private var hasSelectedNewEmoji = false  // Track if user selected a new emoji
    @State private var visibility: Space.Visibility
    @State private var isSaving = false
    @State private var error: Error?
    @State private var showDeleteConfirmation = false
    @State private var isEmojiPickerPresented = false
    @State private var selectedParentId: String?
    @State private var selectedCopyAction: CopyAction?

    private enum CopyAction: String, Identifiable {
        case link = "Copy Link"
        case id = "Copy ID"
        case title = "Copy Title"
        case titleAsLink = "Copy Title as Link"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .link: return "link"
            case .id: return "number"
            case .title: return "doc.on.doc"
            case .titleAsLink: return "link.badge.plus"
            }
        }
    }

    // MARK: - Initialization

    init(
        space: Space,
        collections: [Collection],
        onSave: @escaping (String?, String?, Space.Visibility?) async throws -> Void,
        onMove: @escaping (String?) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.space = space
        self.collections = collections
        self.onSave = onSave
        self.onMove = onMove
        self.onDelete = onDelete
        self._title = State(initialValue: space.title)
        self._visibility = State(initialValue: space.visibility)
        // selectedEmoji starts as nil - we use space.emoji for display until user selects a new one
        self._selectedEmoji = State(initialValue: nil)
        self._hasSelectedNewEmoji = State(initialValue: false)
    }

    // MARK: - Computed

    /// The emoji to display (either newly selected or original)
    private var displayEmoji: String? {
        if hasSelectedNewEmoji {
            return selectedEmoji?.emoji
        }
        return space.emoji
    }

    /// The emoji value to save (nil if cleared, emoji string if selected)
    private var currentEmoji: String? {
        if hasSelectedNewEmoji {
            return selectedEmoji?.emoji
        }
        return space.emoji
    }

    private var hasChanges: Bool {
        title != space.title
            || hasSelectedNewEmoji  // Any emoji change counts
            || visibility != space.visibility
    }

    private var canSave: Bool {
        !title.isEmpty && hasChanges && !isSaving
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Details section
                detailsSection

                // Visibility section
                visibilitySection

                // Move & Copy section
                moveAndCopySection

                // Danger Zone
                dangerZoneSection
            }
            .navigationTitle("Edit Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
            .confirmationDialog(
                "Move to Trash?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Move to Trash", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This space will be moved to trash and permanently deleted after 7 days.")
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        Section("Details") {
            TextField("Title", text: $title)
                .textContentType(.name)

            Button {
                isEmojiPickerPresented = true
            } label: {
                HStack {
                    Text("Emoji")
                        .foregroundStyle(.primary)
                    Spacer()
                    if let emoji = displayEmoji {
                        Text(emoji)
                            .font(.title2)
                    } else {
                        Text("Optional")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .emojiPicker(
                isPresented: $isEmojiPickerPresented,
                selectedEmoji: $selectedEmoji,
                configuration: ElegantConfiguration(showReset: true)
            )
            .onChange(of: selectedEmoji) { _, _ in
                hasSelectedNewEmoji = true
            }
        }
    }

    // MARK: - Visibility Section

    private var visibilitySection: some View {
        Section {
            Picker("Visibility", selection: $visibility) {
                ForEach(visibilityOptions, id: \.self) { option in
                    Label {
                        Text(option.displayName)
                    } icon: {
                        Image(systemName: option.icon)
                    }
                    .tag(option)
                }
            }
        } header: {
            Text("Visibility")
        } footer: {
            Text(visibilityDescription)
        }
    }

    // MARK: - Move & Copy Section

    private var moveAndCopySection: some View {
        Section("Move & Copy") {
            // Move to picker
            Picker(selection: $selectedParentId) {
                Label("None (Top Level)", systemImage: "arrow.up.to.line")
                    .tag(nil as String?)

                ForEach(collections.filter { $0.id != space.parentId }) { collection in
                    Label {
                        Text(collection.displayTitle)
                    } icon: {
                        if let emoji = collection.emoji {
                            Text(emoji)
                        } else {
                            Image(systemName: "folder")
                        }
                    }
                    .tag(collection.id as String?)
                }
            } label: {
                Label("Move to", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
            }
            .onChange(of: selectedParentId) { _, newValue in
                // Only trigger if user actually selected something different
                if newValue != space.parentId {
                    onMove(newValue)
                    dismiss()
                }
            }

            // Copy picker (same style as Move to)
            Picker(selection: $selectedCopyAction) {
                Text("Select...")
                    .tag(nil as CopyAction?)

                if space.appURL != nil {
                    Label(CopyAction.link.rawValue, systemImage: CopyAction.link.icon)
                        .tag(CopyAction.link as CopyAction?)
                }

                Label(CopyAction.id.rawValue, systemImage: CopyAction.id.icon)
                    .tag(CopyAction.id as CopyAction?)

                Label(CopyAction.title.rawValue, systemImage: CopyAction.title.icon)
                    .tag(CopyAction.title as CopyAction?)

                if space.appURL != nil {
                    Label(CopyAction.titleAsLink.rawValue, systemImage: CopyAction.titleAsLink.icon)
                        .tag(CopyAction.titleAsLink as CopyAction?)
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .onChange(of: selectedCopyAction) { _, newValue in
                guard let action = newValue else { return }
                performCopyAction(action)
                // Reset selection after action
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedCopyAction = nil
                }
            }
        }
    }

    private func performCopyAction(_ action: CopyAction) {
        switch action {
        case .link:
            if let appURL = space.appURL {
                UIPasteboard.general.string = appURL.absoluteString
            }
        case .id:
            UIPasteboard.general.string = space.id
        case .title:
            UIPasteboard.general.string = space.title
        case .titleAsLink:
            if let appURL = space.appURL {
                UIPasteboard.general.string = "[\(space.title)](\(appURL.absoluteString))"
            }
        }
        HapticFeedback.success()
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Move to Trash")
                }
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Deleted spaces are kept for 7 days before permanent deletion.")
        }
    }

    // MARK: - Visibility Options

    private var visibilityOptions: [Space.Visibility] {
        [.public, .unlisted, .private, .shareLinkOnly]
    }

    private var visibilityDescription: String {
        switch visibility {
        case .public:
            return "Anyone can find and view this space."
        case .unlisted:
            return "Only people with the link can view this space."
        case .private:
            return "Only organization members can view this space."
        case .shareLinkOnly:
            return "Only people with a share link can view this space."
        case .inCollection:
            return "Visibility is inherited from the parent collection."
        case .visitor:
            return "Visitors can view this space."
        }
    }

    // MARK: - Actions

    private func save() async {
        guard canSave else { return }

        isSaving = true
        error = nil
        HapticFeedback.selection()

        do {
            let newTitle = title != space.title ? title : nil
            let newEmoji: String?
            if hasSelectedNewEmoji {
                // User selected a new emoji (or cleared it)
                newEmoji = selectedEmoji?.emoji ?? ""  // Empty string to clear
            } else {
                newEmoji = nil  // No change
            }
            let newVisibility = visibility != space.visibility ? visibility : nil

            try await onSave(newTitle, newEmoji, newVisibility)
            HapticFeedback.success()
            dismiss()
        } catch {
            self.error = error
            HapticFeedback.error()
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    SpaceSettingsView(
        space: Space(
            id: "1",
            title: "API Documentation",
            emoji: "📚",
            visibility: .public,
            type: .document,
            appURL: nil,
            publishedURL: nil,
            parentId: nil,
            organizationId: nil,
            createdAt: nil,
            updatedAt: nil,
            deletedAt: nil
        ),
        collections: [],
        onSave: { _, _, _ in },
        onMove: { _ in },
        onDelete: {}
    )
}
