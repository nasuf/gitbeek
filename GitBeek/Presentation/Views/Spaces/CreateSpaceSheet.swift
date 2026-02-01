//
//  CreateSpaceSheet.swift
//  GitBeek
//
//  Sheet for creating new spaces or collections
//

import SwiftUI
import ElegantEmojiPicker

/// Sheet view for creating a new space or collection
struct CreateSpaceSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var viewModel: SpaceListViewModel
    let organizationId: String

    // MARK: - State

    @State private var title = ""
    @State private var spaceType: SpaceTypeOption = .space
    @State private var visibility: Space.Visibility = .private
    @State private var parentCollection: Collection?
    @State private var isCreating = false
    @State private var isEmojiPickerPresented = false
    @State private var selectedEmoji: Emoji?
    @State private var error: Error?

    // MARK: - Types

    enum SpaceTypeOption: String, CaseIterable {
        case space = "Space"
        case collection = "Collection"

        var icon: String {
            switch self {
            case .space: return "doc.fill"
            case .collection: return "folder.fill"
            }
        }

        var description: String {
            switch self {
            case .space: return "A single documentation site"
            case .collection: return "A container for organizing spaces"
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var availableCollections: [Collection] {
        viewModel.activeCollectionsList
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Type selection
                typeSection

                // Details section
                detailsSection

                // Parent collection
                parentSection

                // Visibility section (spaces only)
                if spaceType == .space {
                    visibilitySection
                }
            }
            .navigationTitle("New \(spaceType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSpace()
                    }
                    .disabled(!isValid || isCreating)
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.localizedDescription ?? "An unknown error occurred.")
            }
            .interactiveDismissDisabled(isCreating)
            .task {
                // Ensure collections are loaded when sheet appears
                if viewModel.allCollections.isEmpty && !viewModel.isLoading {
                    await viewModel.loadSpaces(organizationId: organizationId)
                }
            }
        }
    }

    // MARK: - Type Section

    private var typeSection: some View {
        Section {
            Picker("Type", selection: $spaceType) {
                ForEach(SpaceTypeOption.allCases, id: \.self) { option in
                    Label {
                        VStack(alignment: .leading) {
                            Text(option.rawValue)
                        }
                    } icon: {
                        Image(systemName: option.icon)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("What would you like to create?")
        } footer: {
            Text(spaceType.description)
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
                    if let emoji = selectedEmoji?.emoji {
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
        }
    }

    // MARK: - Parent Section

    private var parentSection: some View {
        Section {
            if viewModel.isLoading && availableCollections.isEmpty {
                HStack {
                    Text("Parent Collection")
                    Spacer()
                    ProgressView()
                }
            } else {
                Picker("Parent Collection", selection: $parentCollection) {
                    Text("None (Top Level)")
                        .tag(nil as Collection?)

                    ForEach(availableCollections) { collection in
                        Label {
                            Text(collection.displayTitle)
                        } icon: {
                            if let emoji = collection.emoji {
                                Text(emoji)
                            } else {
                                Image(systemName: "folder.fill")
                            }
                        }
                        .tag(collection as Collection?)
                    }
                }
            }
        } header: {
            Text("Organization")
        } footer: {
            if viewModel.isLoading && availableCollections.isEmpty {
                Text("Loading collections...")
            } else if availableCollections.isEmpty {
                Text("No collections available.")
            } else {
                Text("Optionally place this \(spaceType == .space ? "space" : "collection") inside a collection.")
            }
        }
    }

    // MARK: - Visibility Section

    private var visibilitySection: some View {
        Section {
            Picker("Visibility", selection: $visibility) {
                ForEach([Space.Visibility.public, .unlisted, .private], id: \.self) { vis in
                    Label {
                        VStack(alignment: .leading) {
                            Text(vis.displayName)
                        }
                    } icon: {
                        Image(systemName: vis.icon)
                    }
                    .tag(vis)
                }
            }
        } header: {
            Text("Visibility")
        } footer: {
            Text(visibilityDescription)
        }
    }

    private var visibilityDescription: String {
        switch visibility {
        case .public:
            return "Anyone can view this space"
        case .unlisted:
            return "Only people with the link can view"
        case .private:
            return "Only organization members can view"
        default:
            return ""
        }
    }

    // MARK: - Create Action

    private func createSpace() {
        isCreating = true
        error = nil

        Task {
            do {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

                if spaceType == .collection {
                    try await viewModel.createCollection(
                        title: trimmedTitle,
                        parentId: parentCollection?.id
                    )
                } else {
                    try await viewModel.createSpace(
                        title: trimmedTitle,
                        emoji: selectedEmoji?.emoji,
                        visibility: visibility,
                        parentId: parentCollection?.id
                    )
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateSpaceSheet(
        viewModel: SpaceListViewModel(spaceRepository: PreviewSpaceRepository()),
        organizationId: "org1"
    )
}

private actor PreviewSpaceRepository: SpaceRepository {
    func getCollections(organizationId: String) async throws -> [Collection] { [] }
    func getSpaces(organizationId: String) async throws -> [Space] { [] }
    func getSpace(id: String) async throws -> Space { fatalError() }
    func createSpace(organizationId: String, title: String, emoji: String?, visibility: Space.Visibility, parentId: String?) async throws -> Space { fatalError() }
    func createCollection(organizationId: String, title: String, parentId: String?) async throws -> Collection { fatalError() }
    func updateSpace(id: String, title: String?, emoji: String?, visibility: Space.Visibility?, parentId: String?) async throws -> Space { fatalError() }
    func moveSpace(id: String, parentId: String?) async throws {}
    func deleteSpace(id: String) async throws {}
    func restoreSpace(id: String) async throws -> Space { fatalError() }
    func renameCollection(id: String, title: String) async throws -> Collection { fatalError() }
    func deleteCollection(id: String) async throws {}
    func moveCollection(id: String, parentId: String?) async throws {}
    func getCachedSpaces(organizationId: String) async -> [Space] { [] }
    func clearCache() async {}
}
