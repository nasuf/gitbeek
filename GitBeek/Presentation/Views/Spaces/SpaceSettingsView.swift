//
//  SpaceSettingsView.swift
//  GitBeek
//
//  Settings view for editing space properties
//

import SwiftUI

/// View for editing space settings
struct SpaceSettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let space: Space
    let onSave: (String?, String?, Space.Visibility?) async throws -> Void

    @State private var title: String
    @State private var emoji: String
    @State private var visibility: Space.Visibility
    @State private var isSaving = false
    @State private var error: Error?
    @State private var showDeleteConfirmation = false

    // MARK: - Initialization

    init(space: Space, onSave: @escaping (String?, String?, Space.Visibility?) async throws -> Void) {
        self.space = space
        self.onSave = onSave
        self._title = State(initialValue: space.title)
        self._emoji = State(initialValue: space.emoji ?? "")
        self._visibility = State(initialValue: space.visibility)
    }

    // MARK: - Computed

    private var hasChanges: Bool {
        title != space.title
            || emoji != (space.emoji ?? "")
            || visibility != space.visibility
    }

    private var canSave: Bool {
        !title.isEmpty && hasChanges && !isSaving
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    // Title
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("Space title", text: $title)
                            .multilineTextAlignment(.trailing)
                    }

                    // Emoji
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("Optional", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                } header: {
                    Text("General")
                }

                // Visibility
                Section {
                    Picker("Visibility", selection: $visibility) {
                        ForEach(visibilityOptions, id: \.self) { option in
                            Label {
                                VStack(alignment: .leading) {
                                    Text(option.displayName)
                                }
                            } icon: {
                                Image(systemName: option.icon)
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Access")
                } footer: {
                    Text(visibilityDescription)
                }

                // Danger Zone
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
            .navigationTitle("Settings")
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
                    // Handle delete via parent
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This space will be moved to trash and permanently deleted after 7 days.")
            }
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
            let newEmoji = emoji != (space.emoji ?? "") ? (emoji.isEmpty ? nil : emoji) : nil
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
        onSave: { _, _, _ in }
    )
}
