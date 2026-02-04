//
//  ImagePreloader.swift
//  GitBeek
//
//  Preload remote images and convert to Base64 Data URIs
//

import Foundation

/// Preloads remote images and converts them to Base64 Data URIs for PDF embedding
actor ImagePreloader {
    // MARK: - Types

    /// Image loading result
    struct ImageResult {
        let originalURL: String
        let dataURI: String?
        let error: Error?
    }

    // MARK: - Properties

    private let session: URLSession

    // MARK: - Initialization

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Extract all image URLs from markdown blocks
    func extractImageURLs(from blocks: [MarkdownBlock]) -> [String] {
        var urls: [String] = []
        extractURLsRecursively(from: blocks, into: &urls)
        return urls
    }

    /// Preload all images and return a mapping of original URL to Data URI
    func preloadImages(from blocks: [MarkdownBlock]) async -> [String: String] {
        let urls = extractImageURLs(from: blocks)
        guard !urls.isEmpty else { return [:] }

        var imageMap: [String: String] = [:]

        await withTaskGroup(of: ImageResult.self) { group in
            for url in urls {
                group.addTask {
                    await self.loadImage(from: url)
                }
            }

            for await result in group {
                if let dataURI = result.dataURI {
                    imageMap[result.originalURL] = dataURI
                }
            }
        }

        return imageMap
    }

    // MARK: - Private Methods

    private func extractURLsRecursively(from blocks: [MarkdownBlock], into urls: inout [String]) {
        for block in blocks {
            switch block.content {
            case let .image(source, _):
                if isRemoteURL(source) {
                    urls.append(source)
                }

            case let .blockquote(nestedBlocks):
                extractURLsRecursively(from: nestedBlocks, into: &urls)

            case let .hint(_, content):
                extractURLsRecursively(from: content, into: &urls)

            case let .tabs(items):
                for item in items {
                    extractURLsRecursively(from: item.content, into: &urls)
                }

            case let .expandable(_, content):
                extractURLsRecursively(from: content, into: &urls)

            case let .unorderedList(items):
                for item in items {
                    extractURLsRecursively(from: item.content, into: &urls)
                }

            case let .orderedList(items, _):
                for item in items {
                    extractURLsRecursively(from: item.content, into: &urls)
                }

            default:
                break
            }
        }
    }

    private func isRemoteURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    private func loadImage(from urlString: String) async -> ImageResult {
        guard let url = URL(string: urlString) else {
            return ImageResult(
                originalURL: urlString,
                dataURI: nil,
                error: URLError(.badURL)
            )
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                return ImageResult(
                    originalURL: urlString,
                    dataURI: nil,
                    error: URLError(.badServerResponse)
                )
            }

            let mimeType = detectMimeType(from: data, response: httpResponse)
            let base64 = data.base64EncodedString()
            let dataURI = "data:\(mimeType);base64,\(base64)"

            return ImageResult(
                originalURL: urlString,
                dataURI: dataURI,
                error: nil
            )
        } catch {
            return ImageResult(
                originalURL: urlString,
                dataURI: nil,
                error: error
            )
        }
    }

    private func detectMimeType(from data: Data, response: HTTPURLResponse) -> String {
        // Try Content-Type header first
        if let contentType = response.mimeType {
            return contentType
        }

        // Fallback: detect from magic bytes
        guard data.count >= 4 else { return "image/png" }

        let bytes = [UInt8](data.prefix(4))

        // PNG: 89 50 4E 47
        if bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47 {
            return "image/png"
        }

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
            return "image/jpeg"
        }

        // GIF: 47 49 46 38
        if bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x38 {
            return "image/gif"
        }

        // WebP: 52 49 46 46 (RIFF)
        if bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46 {
            return "image/webp"
        }

        // SVG: starts with < (check for XML/SVG)
        if bytes[0] == 0x3C {
            return "image/svg+xml"
        }

        return "image/png"
    }
}
