//
//  LoginView.swift
//  GitBeek
//
//  Liquid Glass Login - iOS 17 Keyboard Bug Workaround
//  See: https://developer.apple.com/forums/thread/731700
//  See: https://www.hackingwithswift.com/forums/swiftui/gesture-system-gesture-gate-timed-out/25114
//

import SwiftUI

/// Login view with liquid glass design
/// Uses VStack (not LazyVStack) to avoid iOS 17 keyboard bugs
/// Keyboard warmup happens at app level before this view appears
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isTokenVisible = false

    var body: some View {
        @Bindable var viewModel = authViewModel

        // iOS 17 Fix: Use simple ScrollView + VStack (NOT LazyVStack, NOT Form)
        ScrollView {
            VStack(spacing: 32) {
                // Top spacing
                Color.clear.frame(height: 60)

                // Branding
                VStack(spacing: 20) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppColors.primaryFallback.opacity(0.3), radius: 15)

                    VStack(spacing: 8) {
                        Text("Welcome to GitBeek")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Sign in with your GitBook API token")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text("v6.1 - Interactive Onboarding")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }

                // Input Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Token")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // UIKit-based TextField - fixes keyboard issues
                    NativeTokenInput(
                        text: $viewModel.apiToken,
                        isVisible: $isTokenVisible,
                        onSubmit: {
                            if !viewModel.apiToken.isEmpty {
                                Task { await authViewModel.loginWithToken() }
                            }
                        }
                    )

                    // Help text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your token is stored securely and never shared")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Link(destination: URL(string: "https://app.gitbook.com/account/developer")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "link.circle.fill")
                                Text("Get your token from Developer Settings")
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.primaryFallback)
                        }
                    }

                    // Sign In Button
                    Button {
                        Task { await authViewModel.loginWithToken() }
                    } label: {
                        HStack(spacing: 8) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text(authViewModel.isLoading ? "Signing In..." : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primaryFallback, AppColors.secondaryFallback],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(viewModel.apiToken.isEmpty || authViewModel.isLoading ? 0.6 : 1.0)
                    }
                    .disabled(viewModel.apiToken.isEmpty || authViewModel.isLoading)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 20)
                .padding(.horizontal, 24)

                // Footer
                VStack(spacing: 12) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 12) {
                        Link("Terms", destination: URL(string: "https://gitbook.com/terms")!)
                        Text("•").foregroundStyle(.tertiary)
                        Link("Privacy", destination: URL(string: "https://gitbook.com/privacy")!)
                    }
                    .font(.caption)
                    .foregroundStyle(AppColors.primaryFallback)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
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
        )
        .alert("Authentication Failed", isPresented: .constant(authViewModel.hasError)) {
            Button("OK") { authViewModel.clearError() }
        } message: {
            Text(authViewModel.errorMessage ?? "Please check your token and try again.")
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AuthViewModel(authRepository: MockAuthRepository()))
}

private actor MockAuthRepository: AuthRepository {
    var authState: AuthState { .unauthenticated }
    var isAuthenticated: Bool { false }
    func loginWithOAuth(code: String, redirectUri: String) async throws -> User {
        User(id: "1", displayName: "Test", email: "test@example.com", photoURL: nil, createdAt: nil, updatedAt: nil)
    }
    func loginWithToken(_ token: String) async throws -> User {
        User(id: "1", displayName: "Test", email: "test@example.com", photoURL: nil, createdAt: nil, updatedAt: nil)
    }
    func refreshToken() async throws {}
    func logout() async {}
    func getAccessToken() async -> String? { nil }
}
