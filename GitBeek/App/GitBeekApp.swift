//
//  GitBeekApp.swift
//  GitBeek
//
//  Created for GitBook iOS App
//

import SwiftUI
import UIKit

// MARK: - Keyboard Warmup (iOS 26 Beta Fix)

/// Invisible view that warms up the keyboard service on app launch
/// Fixes iOS 26 beta keyboard initialization bug
struct KeyboardWarmupView: UIViewRepresentable {
    let onComplete: () -> Void

    private static let warmupDelay: TimeInterval = 0.1
    private static let completeDelay: TimeInterval = 0.2

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.isHidden = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none

        // Trigger keyboard service initialization
        DispatchQueue.main.async {
            textField.becomeFirstResponder()

            DispatchQueue.main.asyncAfter(deadline: .now() + Self.warmupDelay) {
                textField.resignFirstResponder()

                DispatchQueue.main.asyncAfter(deadline: .now() + Self.completeDelay) {
                    onComplete()
                }
            }
        }

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {}
}

// MARK: - Onboarding

/// Onboarding view with 3 pages that user can swipe through
/// Performs keyboard warmup while user explores features
struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var keyboardWarmedUp = false

    private static let pageCount = 3
    private static let offScreenOffset: CGFloat = -2000
    private static let transitionDuration: TimeInterval = 0.4
    private static let safetyDelay: TimeInterval = 0.5

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                pageIndicator
                onboardingPages
            }

            hiddenKeyboardWarmup
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                AppColors.primaryFallback.opacity(0.15),
                AppColors.secondaryFallback.opacity(0.1),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<Self.pageCount, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? AppColors.primaryFallback : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private var onboardingPages: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(
                icon: "book.closed.fill",
                title: "Welcome to GitBeek",
                description: "Your beautiful companion for GitBook. Access your documentation anywhere, anytime.",
                accentColor: AppColors.primaryFallback
            )
            .tag(0)

            OnboardingPage(
                icon: "sparkles",
                title: "Elegant & Fast",
                description: "Liquid glass design meets powerful features. Browse spaces, search content, and read documentation with ease.",
                accentColor: AppColors.secondaryFallback
            )
            .tag(1)

            OnboardingPage(
                icon: "key.fill",
                title: "Let's Get Started",
                description: "Sign in with your GitBook API token to access all your documentation.",
                accentColor: AppColors.primaryFallback,
                showButton: true,
                buttonAction: completeOnboarding
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }

    private var hiddenKeyboardWarmup: some View {
        KeyboardWarmupView {
            keyboardWarmedUp = true
        }
        .frame(width: 1, height: 1)
        .offset(x: Self.offScreenOffset, y: Self.offScreenOffset)
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        let delay = keyboardWarmedUp ? 0 : Self.safetyDelay

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: Self.transitionDuration)) {
                isComplete = true
            }
        }
    }
}

/// Individual onboarding page
struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    var showButton = false
    var buttonAction: (() -> Void)?

    @State private var iconScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0

    private static let iconSize: CGFloat = 100
    private static let titleSize: CGFloat = 32
    private static let shadowRadius: CGFloat = 25
    private static let buttonRadius: CGFloat = 16

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            iconView
            contentView
            Spacer()
            bottomView
        }
        .onAppear(perform: animateEntrance)
    }

    // MARK: - Subviews

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: Self.iconSize))
            .foregroundStyle(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: accentColor.opacity(0.4), radius: Self.shadowRadius)
            .scaleEffect(iconScale)
    }

    private var contentView: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: Self.titleSize, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .opacity(contentOpacity)
    }

    @ViewBuilder
    private var bottomView: some View {
        if showButton {
            getStartedButton
        } else {
            swipeHint
        }
    }

    private var getStartedButton: some View {
        Button(action: { buttonAction?() }) {
            HStack(spacing: 12) {
                Text("Get Started")
                    .font(.title3)
                    .fontWeight(.semibold)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Self.buttonRadius))
            .shadow(color: AppColors.primaryFallback.opacity(0.4), radius: 15, y: 8)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 50)
        .opacity(contentOpacity)
    }

    private var swipeHint: some View {
        HStack(spacing: 8) {
            Text("Swipe to continue")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 50)
        .opacity(contentOpacity)
    }

    // MARK: - Actions

    private func animateEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            iconScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            contentOpacity = 1.0
        }
    }
}

// MARK: - App

@main
struct GitBeekApp: App {
    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container.authViewModel)
                .environment(container.profileViewModel)
                .environment(container.appRouter)
        }
    }
}

/// Root view that handles authentication state
struct RootView: View {
    // MARK: - Environment

    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingComplete = false

    // MARK: - Body

    var body: some View {
        Group {
            if !hasCompletedOnboarding && !onboardingComplete {
                // Show onboarding on first launch with keyboard warmup
                OnboardingView(isComplete: $onboardingComplete)
                    .transition(.opacity)
            } else {
                // Main app content
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingComplete)
        .onChange(of: onboardingComplete) { _, newValue in
            if newValue {
                // Save that user has completed onboarding
                hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        Group {
            switch authViewModel.authState {
            case .unknown:
                // Loading state - checking auth
                loadingView

            case .authenticated:
                // Main content
                GlassEffectContainer {
                    ContentView()
                }
                .transition(.opacity)

            case .unauthenticated:
                // Login screen
                LoginViewWrapper()
                    .environment(authViewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
        .task {
            await authViewModel.checkAuthState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            // Handle session expiration - logout automatically
            Task {
                await authViewModel.logout()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading...")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    RootView()
        .environment(AuthViewModel(authRepository: PreviewAuthenticatedRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewUserRepository(),
            organizationRepository: PreviewOrganizationRepository()
        ))
        .environment(AppRouter())
}

#Preview("Unauthenticated") {
    RootView()
        .environment(AuthViewModel(authRepository: PreviewUnauthenticatedRepository()))
        .environment(ProfileViewModel(
            userRepository: PreviewUserRepository(),
            organizationRepository: PreviewOrganizationRepository()
        ))
        .environment(AppRouter())
}

// Preview mocks
private actor PreviewAuthenticatedRepository: AuthRepository {
    var authState: AuthState {
        .authenticated(User(from: CurrentUserDTO(
            object: "user",
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            photoURL: nil,
            urls: nil
        )))
    }
    var isAuthenticated: Bool { true }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { "token" }
}

private actor PreviewUnauthenticatedRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User { fatalError() }
    func loginWithToken(_ token: String) async throws -> User { fatalError() }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}

private actor PreviewUserRepository: UserRepository {
    func getCurrentUser() async throws -> User {
        User(from: CurrentUserDTO(
            object: "user",
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            photoURL: nil,
            urls: nil
        ))
    }
    func getCachedUser() async -> User? { nil }
    func clearCache() async {}
}

private actor PreviewOrganizationRepository: OrganizationRepository {
    func getOrganizations() async throws -> [Organization] {
        [
            Organization(from: OrganizationDTO(
                object: "organization",
                id: "1",
                title: "Acme Inc",
                createdAt: nil,
                updatedAt: nil,
                urls: nil
            ))
        ]
    }
    func getOrganization(id: String) async throws -> Organization { fatalError() }
    func getCachedOrganizations() async -> [Organization] { [] }
    func clearCache() async {}
}

// MARK: - Login Wrapper (iOS 17 Keyboard Bug Workaround)

/// Isolated wrapper for LoginView to avoid iOS 17 keyboard bugs
/// See: https://developer.apple.com/forums/thread/731700
/// See: https://www.hackingwithswift.com/forums/swiftui/gesture-system-gesture-gate-timed-out/25114
struct LoginViewWrapper: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        // Completely isolated - no TabView, no GlassEffect, no complex modifiers
        LoginView()
            .id("login") // Force identity to prevent gesture conflicts
    }
}
