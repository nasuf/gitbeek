//
//  PDFExportService.swift
//  GitBeek
//
//  Core PDF export service using WKWebView
//

import Foundation
import PDFKit
import UIKit
import WebKit

/// Service for exporting markdown content to PDF
@MainActor
final class PDFExportService {
    // MARK: - Types

    enum ExportError: LocalizedError {
        case renderingFailed
        case saveFailed
        case noContent
        case webViewTimeout

        var errorDescription: String? {
            switch self {
            case .renderingFailed:
                return "Failed to render PDF"
            case .saveFailed:
                return "Failed to save PDF file"
            case .noContent:
                return "No content to export"
            case .webViewTimeout:
                return "PDF rendering timed out"
            }
        }
    }

    /// Export progress state
    enum ExportProgress: Sendable {
        case idle
        case loadingImages(current: Int, total: Int)
        case generatingHTML
        case renderingPDF
        case saving
        case completed(URL)
        case failed(String)

        var description: String {
            switch self {
            case .idle:
                return "Ready"
            case let .loadingImages(current, total):
                return "Loading images (\(current)/\(total))..."
            case .generatingHTML:
                return "Generating document..."
            case .renderingPDF:
                return "Rendering PDF..."
            case .saving:
                return "Saving file..."
            case let .completed(url):
                return "Saved to \(url.lastPathComponent)"
            case let .failed(error):
                return "Error: \(error)"
            }
        }

        var isInProgress: Bool {
            switch self {
            case .idle, .completed, .failed:
                return false
            default:
                return true
            }
        }
    }

    // MARK: - Properties

    private let imagePreloader = ImagePreloader()

    // A4 paper size in points (72 dpi)
    private let pageWidth: CGFloat = 595.28
    private let pageHeight: CGFloat = 841.89
    private let pageMargin: CGFloat = 36 // 0.5 inch margins

    // MARK: - Public Methods

    /// Export page content to PDF
    /// - Parameters:
    ///   - title: Page title
    ///   - blocks: Parsed markdown blocks
    ///   - isDarkCodeTheme: Whether to use dark code theme
    ///   - progressHandler: Callback for progress updates
    /// - Returns: URL of the saved PDF file
    func exportToPDF(
        title: String,
        blocks: [MarkdownBlock],
        isDarkCodeTheme: Bool = false,
        progressHandler: @escaping (ExportProgress) -> Void
    ) async throws -> URL {
        guard !blocks.isEmpty else {
            throw ExportError.noContent
        }

        // Step 1: Preload images
        let imageURLs = await imagePreloader.extractImageURLs(from: blocks)
        let totalImages = imageURLs.count

        if totalImages > 0 {
            progressHandler(.loadingImages(current: 0, total: totalImages))
        }

        let imageMap = await imagePreloader.preloadImages(from: blocks)
        if totalImages > 0 {
            progressHandler(.loadingImages(current: imageMap.count, total: totalImages))
        }

        // Step 2: Generate HTML
        progressHandler(.generatingHTML)
        let converter = MarkdownToHTMLConverter(imageMap: imageMap, isDarkCodeTheme: isDarkCodeTheme)
        let bodyHTML = converter.convert(blocks: blocks)
        let fullHTML = PDFStyleSheet.wrapInHTML(body: bodyHTML, title: title, isDarkCodeTheme: isDarkCodeTheme)

        // Step 3: Render PDF using UIPrintPageRenderer for better compatibility
        progressHandler(.renderingPDF)
        var pdfData = try await renderPDFWithPrintRenderer(html: fullHTML)

        // Step 3.5: Remove trailing blank pages
        pdfData = removeTrailingBlankPages(from: pdfData)

        // Step 4: Save to temp directory
        progressHandler(.saving)
        let fileURL = try savePDFToTemp(data: pdfData, filename: title)

        progressHandler(.completed(fileURL))
        return fileURL
    }

    // MARK: - Private Methods

    private func renderPDFWithPrintRenderer(html: String) async throws -> Data {
        // Create an offscreen window that is completely invisible
        // This prevents any visual artifacts during PDF rendering
        let offscreenWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        offscreenWindow.windowLevel = UIWindow.Level(rawValue: -1000) // Below everything
        offscreenWindow.isHidden = true
        offscreenWindow.alpha = 0
        offscreenWindow.rootViewController = UIViewController()

        // Create configuration
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        // Create webview with proper size for rendering
        let contentWidth = pageWidth - (pageMargin * 2)
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: pageHeight), configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // Add webview to offscreen window's view hierarchy
        offscreenWindow.rootViewController?.view.addSubview(webView)

        // Load HTML and wait for completion
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = WebViewLoadDelegate { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            objc_setAssociatedObject(webView, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            webView.navigationDelegate = delegate
            webView.loadHTMLString(html, baseURL: nil)
        }

        // Wait for highlight.js to execute and content to render
        try await Task.sleep(for: .milliseconds(1000))

        // Use UIPrintPageRenderer for standard PDF output
        let renderer = UIPrintPageRenderer()
        let printFormatter = webView.viewPrintFormatter()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        // Set paper size and printable rect
        let paperRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let printableRect = CGRect(
            x: pageMargin,
            y: pageMargin,
            width: pageWidth - (pageMargin * 2),
            height: pageHeight - (pageMargin * 2)
        )

        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")

        // Render to PDF data
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)

        for pageIndex in 0 ..< renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: pageIndex, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        // Clean up - remove webview from hierarchy
        webView.removeFromSuperview()

        return pdfData as Data
    }

    /// Remove trailing blank pages from PDF data
    private func removeTrailingBlankPages(from pdfData: Data) -> Data {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return pdfData
        }

        let pageCount = pdfDocument.pageCount
        guard pageCount > 1 else {
            return pdfData
        }

        // Check pages from the end and remove blank ones
        var pagesToRemove: [Int] = []

        for pageIndex in stride(from: pageCount - 1, through: 1, by: -1) {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            if isPageBlank(page) {
                pagesToRemove.append(pageIndex)
            } else {
                // Stop at first non-blank page from the end
                break
            }
        }

        // Remove blank pages (from highest index to lowest to maintain indices)
        for pageIndex in pagesToRemove {
            pdfDocument.removePage(at: pageIndex)
        }

        // Return the modified PDF data
        return pdfDocument.dataRepresentation() ?? pdfData
    }

    /// Check if a PDF page is blank (mostly white)
    private func isPageBlank(_ page: PDFPage) -> Bool {
        let pageRect = page.bounds(for: .mediaBox)

        // Render page to bitmap at reduced resolution for performance
        let scale: CGFloat = 0.25
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)

        guard width > 0, height > 0 else { return true }

        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return true
        }

        // Fill with white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Scale and draw the page
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)

        // Get pixel data
        guard let data = context.data else { return true }

        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let totalPixels = width * height

        // Sample pixels to check for non-white content
        // Check every 10th pixel for performance
        var nonWhitePixels = 0
        let sampleStep = 10
        let threshold = 250 // Pixels with RGB values below this are considered non-white

        for i in stride(from: 0, to: totalPixels, by: sampleStep) {
            let offset = i * 4
            let r = pixelData[offset]
            let g = pixelData[offset + 1]
            let b = pixelData[offset + 2]

            // Check if pixel is not white (allowing some tolerance)
            if r < threshold || g < threshold || b < threshold {
                nonWhitePixels += 1
            }
        }

        // If less than 0.5% of sampled pixels are non-white, consider page blank
        let sampledPixels = totalPixels / sampleStep
        let nonWhiteRatio = Double(nonWhitePixels) / Double(sampledPixels)

        return nonWhiteRatio < 0.005
    }

    private func savePDFToTemp(data: Data, filename: String) throws -> URL {
        let sanitizedFilename = sanitizeFilename(filename)

        // Use Caches directory instead of tmp - more accessible
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let exportDir = cacheDir.appendingPathComponent("PDFExports", isDirectory: true)

        // Create export directory if needed
        if !FileManager.default.fileExists(atPath: exportDir.path) {
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        }

        let fileURL = exportDir.appendingPathComponent("\(sanitizedFilename).pdf")

        // Remove existing file if present
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        // Write with no file protection so it can be accessed by other apps
        try data.write(to: fileURL, options: [.atomic])

        // Set file to be readable by other apps
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.none],
            ofItemAtPath: fileURL.path
        )

        return fileURL
    }

    private func sanitizeFilename(_ filename: String) -> String {
        // Remove problematic characters: / \ : * ? " < > | [ ] and control characters
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|[]").union(.controlCharacters)
        var sanitized = filename.components(separatedBy: invalidChars).joined(separator: "_")

        // Replace spaces with underscores for better compatibility
        sanitized = sanitized.replacingOccurrences(of: " ", with: "_")

        // Remove consecutive underscores
        while sanitized.contains("__") {
            sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
        }

        let trimmed = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return trimmed.isEmpty ? "export" : String(trimmed.prefix(100))
    }
}

// MARK: - WebView Load Delegate

private final class WebViewLoadDelegate: NSObject, WKNavigationDelegate {
    private let completion: (Error?) -> Void
    private var didComplete = false

    init(completion: @escaping (Error?) -> Void) {
        self.completion = completion
        super.init()
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        guard !didComplete else { return }
        didComplete = true
        completion(nil)
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        guard !didComplete else { return }
        didComplete = true
        completion(error)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        guard !didComplete else { return }
        didComplete = true
        completion(error)
    }
}
