//
//  EmbedBlockView.swift
//  GitBeek
//
//  GitBook embed block (YouTube, Twitter, GitHub, etc.)
//

import SwiftUI
import WebKit

/// View for rendering embedded content
struct EmbedBlockView: View {
    // MARK: - Properties

    let type: EmbedType
    let url: String
    let title: String?

    @State private var isLoading = true
    @State private var hasError = false

    // MARK: - Constants

    private static let defaultHeight: CGFloat = 400
    private static let youtubeHeight: CGFloat = 250
    private static let twitterHeight: CGFloat = 600
    private static let cornerRadius: CGFloat = 12

    // MARK: - Computed

    private var embedHeight: CGFloat {
        switch type {
        case .youtube, .vimeo, .loom:
            return Self.youtubeHeight
        case .twitter:
            return Self.twitterHeight
        default:
            return Self.defaultHeight
        }
    }

    private var embedURL: URL? {
        switch type {
        case .youtube:
            return convertToYouTubeEmbedURL(url)
        case .vimeo:
            return convertToVimeoEmbedURL(url)
        case .twitter:
            return URL(string: url)
        case .github:
            return convertToGitHubEmbedURL(url)
        case .loom:
            return convertToLoomEmbedURL(url)
        default:
            return URL(string: url)
        }
    }

    private var icon: String {
        switch type {
        case .youtube: return "play.rectangle.fill"
        case .vimeo: return "video.fill"
        case .twitter: return "bubble.left.and.bubble.right.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .codepen: return "paintbrush.fill"
        case .figma: return "square.and.pencil"
        case .loom: return "video.circle.fill"
        case .generic: return "link.circle.fill"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            if let title = title {
                header(title: title)
            }

            // Embed content
            ZStack {
                if let embedURL = embedURL {
                    WebView(
                        url: embedURL,
                        isLoading: $isLoading,
                        hasError: $hasError
                    )
                    .frame(height: embedHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))

                    // Loading overlay
                    if isLoading {
                        loadingOverlay
                    }

                    // Error overlay
                    if hasError {
                        errorOverlay
                    }
                } else {
                    invalidURLView
                }
            }
        }
    }

    // MARK: - Subviews

    private func header(title: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.8)

            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                Text("Loading...")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: embedHeight)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }

    private var errorOverlay: some View {
        ZStack {
            Color(.systemBackground)

            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)

                Text("Failed to load embed")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.primary)

                if let embedURL = embedURL {
                    Link("Open in Browser", destination: embedURL)
                        .font(AppTypography.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(height: embedHeight)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var invalidURLView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Invalid embed URL")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)

            Text(url)
                .font(AppTypography.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
        }
        .frame(height: embedHeight)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }

    // MARK: - URL Conversion

    private func convertToYouTubeEmbedURL(_ urlString: String) -> URL? {
        // Extract video ID from various YouTube URL formats
        if let url = URL(string: urlString) {
            // Handle youtu.be/VIDEO_ID
            if url.host?.contains("youtu.be") == true {
                let videoId = url.lastPathComponent
                return URL(string: "https://www.youtube.com/embed/\(videoId)")
            }
            // Handle youtube.com/watch?v=VIDEO_ID
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return URL(string: "https://www.youtube.com/embed/\(videoId)")
            }
        }
        return URL(string: urlString)
    }

    private func convertToVimeoEmbedURL(_ urlString: String) -> URL? {
        // Extract video ID from Vimeo URL
        if let url = URL(string: urlString) {
            let videoId = url.lastPathComponent
            return URL(string: "https://player.vimeo.com/video/\(videoId)")
        }
        return URL(string: urlString)
    }

    private func convertToGitHubEmbedURL(_ urlString: String) -> URL? {
        // For GitHub gists
        if urlString.contains("gist.github.com") {
            // Gists need to be embedded using GitHub's embed script
            // We'll just return the original URL
            return URL(string: urlString)
        }
        return URL(string: urlString)
    }

    private func convertToLoomEmbedURL(_ urlString: String) -> URL? {
        // Convert Loom share URL to embed URL
        if let url = URL(string: urlString),
           url.host?.contains("loom.com") == true {
            let videoId = url.lastPathComponent
            return URL(string: "https://www.loom.com/embed/\(videoId)")
        }
        return URL(string: urlString)
    }
}

// MARK: - WebView Wrapper

/// UIKit WebView wrapper for embedding web content
private struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, hasError: $hasError)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var hasError: Bool

        init(isLoading: Binding<Bool>, hasError: Binding<Bool>) {
            _isLoading = isLoading
            _hasError = hasError
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
            hasError = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            hasError = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            hasError = true
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            EmbedBlockView(
                type: .youtube,
                url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                title: "YouTube Video"
            )

            EmbedBlockView(
                type: .twitter,
                url: "https://twitter.com/username/status/123456789",
                title: "Tweet"
            )

            EmbedBlockView(
                type: .github,
                url: "https://gist.github.com/username/abc123",
                title: "GitHub Gist"
            )
        }
        .padding()
    }
}
