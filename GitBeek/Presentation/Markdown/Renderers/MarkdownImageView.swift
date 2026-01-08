//
//  MarkdownImageView.swift
//  GitBeek
//
//  Image renderer with SDWebImageSwiftUI
//

import SwiftUI
import SDWebImageSwiftUI

/// View for rendering markdown images
struct MarkdownImageView: View {
    // MARK: - Properties

    let source: String
    let altText: String?

    @State private var showFullscreen = false
    @State private var imageLoadFailed = false

    // MARK: - Computed

    private var imageURL: URL? {
        URL(string: source)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            imageContent
                .onTapGesture {
                    if !imageLoadFailed {
                        showFullscreen = true
                    }
                }

            // Caption (alt text)
            if let alt = altText, !alt.isEmpty {
                Text(alt)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageView(source: source, altText: altText)
        }
    }

    // MARK: - Image Content

    @ViewBuilder
    private var imageContent: some View {
        if let url = imageURL {
            WebImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                placeholderView
            }
            .onFailure { _ in
                imageLoadFailed = true
            }
            .transition(.fade(duration: 0.3))
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous))
        } else {
            errorView
        }
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .overlay {
                ProgressView()
            }
            .shimmer()
    }

    // MARK: - Error View

    private var errorView: some View {
        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall, style: .continuous)
            .fill(Color(.systemGray6))
            .frame(height: 100)
            .overlay {
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.tertiary)

                    Text("Failed to load image")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

// MARK: - Fullscreen Image View

private struct FullscreenImageView: View {
    @Environment(\.dismiss) private var dismiss

    let source: String
    let altText: String?

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Image
            if let url = URL(string: source) {
                WebImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }

                Spacer()

                // Caption
                if let alt = altText, !alt.isEmpty {
                    Text(alt)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Capsule())
                        .padding()
                }
            }
        }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { value in
                lastScale = scale
                if scale < 1 {
                    withAnimation(.spring()) {
                        scale = 1
                        lastScale = 1
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
                if scale <= 1 {
                    withAnimation(.spring()) {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            MarkdownImageView(
                source: "https://via.placeholder.com/600x400",
                altText: "A placeholder image"
            )

            MarkdownImageView(
                source: "https://picsum.photos/800/600",
                altText: "Random nature photo from Picsum"
            )

            MarkdownImageView(
                source: "invalid-url",
                altText: "This will fail to load"
            )
        }
        .padding()
    }
}
