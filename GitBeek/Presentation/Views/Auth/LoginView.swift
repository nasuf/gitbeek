//
//  LoginView.swift
//  GitBeek
//
//  Login screen with Liquid Glass design
//

import SwiftUI

/// Login view with API token authentication
struct LoginView: View {
    // MARK: - Environment

    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = authViewModel

        GeometryReader { _ in
            ZStack {
                // Background gradient
                backgroundGradient

                // Content
                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // App branding
                    brandingSection

                    Spacer()

                    // Login options
                    loginOptionsSection(viewModel: viewModel)

                    Spacer()

                    // Footer
                    footerSection
                }
                .padding(.horizontal, AppSpacing.xl)
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Error", isPresented: .constant(authViewModel.hasError)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                AppColors.primaryFallback.opacity(0.3),
                AppColors.secondaryFallback.opacity(0.2),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // App icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.primaryFallback.opacity(0.3), radius: 20, y: 10)

            VStack(spacing: AppSpacing.sm) {
                Text("GitBeek")
                    .font(AppTypography.displayLarge)
                    .fontWeight(.bold)

                Text("Your GitBook companion")
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Login Options Section

    @ViewBuilder
    private func loginOptionsSection(viewModel: AuthViewModel) -> some View {
        tokenInputSection(viewModel: viewModel)
            .padding(AppSpacing.xl)
            .glassStyle(cornerRadius: AppSpacing.cornerRadiusMedium)
    }

    // MARK: - Token Input Section

    @ViewBuilder
    private func tokenInputSection(viewModel: AuthViewModel) -> some View {
        @Bindable var vm = viewModel

        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Enter your GitBook API token")
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(.primary)

                Text("Get your token from GitBook Developer Settings")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SecureField("API Token", text: $vm.apiToken)
                .textFieldStyle(.plain)
                .padding(AppSpacing.md)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.sm))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            GlassButton(
                "Sign In",
                systemImage: "key.fill",
                isProminent: true
            ) {
                Task {
                    await authViewModel.loginWithToken()
                }
            }
            .disabled(vm.apiToken.isEmpty || authViewModel.isLoading)
            .overlay {
                if authViewModel.isLoading {
                    ProgressView()
                }
            }

            // Help link - points to GitBook Developer Settings
            Link(destination: URL(string: "https://app.gitbook.com/account/developer")!) {
                Label("Open GitBook Developer Settings", systemImage: "arrow.up.right.square")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.primaryFallback)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("By continuing, you agree to our")
                .font(AppTypography.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: AppSpacing.sm) {
                Link("Terms of Service", destination: URL(string: "https://gitbook.com/terms")!)
                Text("and")
                    .foregroundStyle(.tertiary)
                Link("Privacy Policy", destination: URL(string: "https://gitbook.com/privacy")!)
            }
            .font(AppTypography.caption)
        }
        .padding(.bottom, AppSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AuthViewModel(authRepository: MockAuthRepository()))
}

// MARK: - Mock Repository for Preview

private actor MockAuthRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }

    func loginWithOAuth(code: String, redirectUri: String) async throws -> User {
        User(id: "1", displayName: "Test User", email: "test@example.com", photoURL: nil, createdAt: nil, updatedAt: nil)
    }

    func loginWithToken(_ token: String) async throws -> User {
        User(id: "1", displayName: "Test User", email: "test@example.com", photoURL: nil, createdAt: nil, updatedAt: nil)
    }

    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}
