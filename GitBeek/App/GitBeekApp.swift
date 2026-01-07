//
//  GitBeekApp.swift
//  GitBeek
//
//  Created for GitBook iOS App
//

import SwiftUI

@main
struct GitBeekApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

/// Global application state
@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var currentEnvironment: AppEnvironment = .development
    var colorScheme: ColorScheme? = nil // nil means follow system
}

/// Simple content view for initial setup
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GlassEffectContainer {
            NavigationStack {
                DesignSystemPreviewView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
