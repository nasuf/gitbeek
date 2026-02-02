//
//  NavigationDestinationBuilder.swift
//  GitBeek
//
//  Helper to build destination views for navigation
//

import SwiftUI

extension View {
    /// Add navigation destinations for AppDestination routes
    @MainActor
    func navigationDestinations() -> some View {
        navigationDestination(for: AppDestination.self) { destination in
            NavigationDestinationBuilder.view(for: destination)
        }
    }
}

/// Builder for creating destination views
@MainActor
enum NavigationDestinationBuilder {
    @ViewBuilder
    static func view(for destination: AppDestination) -> some View {
        switch destination {
        case .spaceList(let organizationId):
            SpaceListView(
                organizationId: organizationId,
                spaceRepository: DependencyContainer.shared.spaceRepository
            )

        case .spaceDetail(let spaceId):
            SpaceDetailView(
                spaceId: spaceId,
                spaceRepository: DependencyContainer.shared.spaceRepository,
                pageRepository: DependencyContainer.shared.pageRepository
            )

        case .trash(let organizationId):
            // Trash is handled as a sheet in SpaceListView
            Text("Trash for \(organizationId)")

        case .pageDetail(let spaceId, let pageId):
            PageDetailView(
                spaceId: spaceId,
                pageId: pageId,
                pageRepository: DependencyContainer.shared.pageRepository
            )

        case .allChangeRequests:
            AllChangeRequestsView(
                viewModel: DependencyContainer.shared.allChangeRequestsViewModel
            )

        case .changeRequestList(let spaceId):
            ChangeRequestListView(
                spaceId: spaceId,
                changeRequestRepository: DependencyContainer.shared.changeRequestRepository
            )

        case .changeRequestDetail(let spaceId, let changeRequestId):
            ChangeRequestDetailView(
                spaceId: spaceId,
                changeRequestId: changeRequestId,
                changeRequestRepository: DependencyContainer.shared.changeRequestRepository,
                spaceRepository: DependencyContainer.shared.spaceRepository
            )

        case .pageEditor(let spaceId, let pageId):
            // TODO: Implement PageEditorView
            Text("Editor for Page \(pageId ?? "new") in Space \(spaceId)")

        case .search(let organizationId):
            // TODO: Implement SearchView
            Text("Search in \(organizationId ?? "all")")

        case .profile:
            ProfileView()

        case .settings:
            SettingsView()
        }
    }
}
