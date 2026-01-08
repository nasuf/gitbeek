//
//  AppRouter.swift
//  GitBeek
//
//  Navigation router for the app
//

import SwiftUI

/// Navigation destinations in the app
enum AppDestination: Hashable {
    // Spaces
    case spaceList(organizationId: String)
    case spaceDetail(spaceId: String)
    case trash(organizationId: String)

    // Pages
    case pageDetail(spaceId: String, pageId: String)
    case pageEditor(spaceId: String, pageId: String?)

    // Change Requests
    case changeRequestList(spaceId: String)
    case changeRequestDetail(spaceId: String, changeRequestId: String)

    // Search
    case search(organizationId: String?)

    // Profile
    case profile
    case settings
}

/// App-wide navigation router
@MainActor
@Observable
final class AppRouter {
    // MARK: - Navigation State

    var path = NavigationPath()

    // MARK: - Tab Selection

    enum Tab: String, CaseIterable {
        case home
        case search
        case profile

        var title: String {
            switch self {
            case .home: return "Home"
            case .search: return "Search"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house"
            case .search: return "magnifyingglass"
            case .profile: return "person.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var selectedTab: Tab = .home

    // MARK: - Navigation Methods

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func switchTab(to tab: Tab) {
        selectedTab = tab
        // Clear navigation when switching tabs
        path = NavigationPath()
    }

    // MARK: - Deep Link Handling

    func handleDeepLink(_ url: URL) -> Bool {
        // Handle gitbeek:// URLs
        guard url.scheme == "gitbeek" else { return false }

        switch url.host {
        case "oauth":
            // OAuth callback is handled by AuthViewModel
            return true

        case "space":
            if let spaceId = url.pathComponents.dropFirst().first {
                navigate(to: .spaceDetail(spaceId: spaceId))
                return true
            }

        case "page":
            let components = url.pathComponents.dropFirst()
            if components.count >= 2 {
                let spaceId = String(components[components.startIndex])
                let pageId = String(components[components.index(after: components.startIndex)])
                navigate(to: .pageDetail(spaceId: spaceId, pageId: pageId))
                return true
            }

        default:
            break
        }

        return false
    }
}

// MARK: - Navigation View Builder

extension View {
    @ViewBuilder
    func navigationDestination(for destination: AppDestination) -> some View {
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

        case .pageEditor(let spaceId, let pageId):
            // TODO: Implement PageEditorView
            Text("Editor for Page \(pageId ?? "new") in Space \(spaceId)")

        case .changeRequestList(let spaceId):
            // TODO: Implement ChangeRequestListView
            Text("Change Requests for Space \(spaceId)")

        case .changeRequestDetail(let spaceId, let changeRequestId):
            // TODO: Implement ChangeRequestDetailView
            Text("Change Request \(changeRequestId) in Space \(spaceId)")

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
