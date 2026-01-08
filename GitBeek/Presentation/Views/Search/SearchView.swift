//
//  SearchView.swift
//  GitBeek
//
//  Search view for finding content
//

import SwiftUI

/// Search view for finding spaces and content
struct SearchView: View {
    // MARK: - Environment

    @Environment(ProfileViewModel.self) private var profileViewModel

    // MARK: - State

    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    // Recent searches placeholder
                    Section("Recent Searches") {
                        Text("Your recent searches will appear here")
                            .foregroundStyle(.secondary)
                    }

                    // Quick access
                    Section("Quick Access") {
                        Label("All Spaces", systemImage: "square.grid.2x2")
                        Label("Change Requests", systemImage: "arrow.triangle.branch")
                        Label("Recent Pages", systemImage: "clock")
                    }
                } else {
                    // Search results placeholder
                    Section {
                        ContentUnavailableView(
                            "Search GitBook",
                            systemImage: "magnifyingglass",
                            description: Text("Search for spaces, pages, and content across your organization.")
                        )
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search spaces and content")
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environment(ProfileViewModel(
            userRepository: PreviewSearchMockUserRepository(),
            organizationRepository: PreviewSearchMockOrganizationRepository()
        ))
}

private actor PreviewSearchMockUserRepository: UserRepository {
    func getCurrentUser() async throws -> User { fatalError() }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewSearchMockOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] { [] }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}
