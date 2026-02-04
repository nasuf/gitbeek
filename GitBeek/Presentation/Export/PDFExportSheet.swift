//
//  PDFExportSheet.swift
//  GitBeek
//
//  Sheet UI for PDF export progress and sharing
//

import QuickLook
import SwiftUI

/// Sheet displaying PDF export progress and share options
struct PDFExportSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let title: String
    let markdown: String
    let isDarkCodeTheme: Bool

    @State private var viewModel = PDFExportViewModel()
    @State private var showShareSheet = false
    @State private var showPreview = false
    @State private var parsedBlocks: [MarkdownBlock] = []
    @State private var isParsing = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Progress indicator
                progressView

                // Status text
                Text(isParsing ? "Parsing content..." : viewModel.progressDescription)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                // Action buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isParsing || viewModel.isExporting)
                }
            }
            .task {
                // Parse markdown first
                parsedBlocks = await MarkdownParser.shared.parse(markdown)
                isParsing = false

                // Then export to PDF with user's code theme
                await viewModel.exportPDF(title: title, blocks: parsedBlocks, isDarkCodeTheme: isDarkCodeTheme)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = viewModel.exportedFileURL {
                    ShareSheet(url: url)
                }
            }
            .fullScreenCover(isPresented: $showPreview) {
                if let url = viewModel.exportedFileURL {
                    PDFPreviewView(url: url)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isParsing || viewModel.isExporting)
    }

    // MARK: - Progress View

    @ViewBuilder
    private var progressView: some View {
        if isParsing || viewModel.isExporting {
            ProgressView()
                .scaleEffect(1.5)
                .frame(width: 80, height: 80)
        } else if viewModel.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
        } else if viewModel.hasFailed {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
        } else {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            if viewModel.isCompleted {
                // Preview button (prominent)
                GlassButton("Preview PDF", systemImage: "eye", isProminent: true) {
                    showPreview = true
                }

                // Share button
                GlassButton("Share PDF", systemImage: "square.and.arrow.up") {
                    showShareSheet = true
                }

                Button("Done") {
                    dismiss()
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
            } else if viewModel.hasFailed {
                GlassButton("Retry", systemImage: "arrow.clockwise") {
                    Task {
                        await viewModel.exportPDF(title: title, blocks: parsedBlocks, isDarkCodeTheme: isDarkCodeTheme)
                    }
                }

                Button("Cancel") {
                    dismiss()
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - PDF Preview View

/// QuickLook-based PDF preview with close button
struct PDFPreviewView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        // Add close button
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.closeTapped)
        )
        closeButton.tintColor = .secondaryLabel
        controller.navigationItem.rightBarButtonItem = closeButton

        let nav = UINavigationController(rootViewController: controller)
        return nav
    }

    func updateUIViewController(_: UINavigationController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, dismiss: dismiss)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        let dismiss: DismissAction

        init(url: URL, dismiss: DismissAction) {
            self.url = url
            self.dismiss = dismiss
        }

        @objc func closeTapped() {
            dismiss()
        }

        func numberOfPreviewItems(in _: QLPreviewController) -> Int {
            1
        }

        func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

// MARK: - Share Sheet

/// UIActivityViewController wrapper for SwiftUI with PDF support
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        // Read PDF data and create a proper item provider
        let activityItems: [Any]

        if let pdfData = try? Data(contentsOf: url) {
            // Use both the data and URL for maximum compatibility
            activityItems = [PDFActivityItemSource(url: url, data: pdfData)]
        } else {
            activityItems = [url]
        }

        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude activities that don't make sense for PDFs
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo
        ]

        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

/// Custom activity item source for better PDF sharing
final class PDFActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    let data: Data
    let filename: String

    init(url: URL, data: Data) {
        self.url = url
        self.data = data
        self.filename = url.lastPathComponent
        super.init()
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        data
    }

    func activityViewController(
        _: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        // For Files app and AirDrop, use the URL
        if activityType == .init("com.apple.DocumentManagerUICore.SaveToFiles") ||
            activityType == .airDrop
        {
            return url
        }
        // For other activities, use the data
        return data
    }

    func activityViewController(
        _: UIActivityViewController,
        subjectForActivityType _: UIActivity.ActivityType?
    ) -> String {
        filename.replacingOccurrences(of: ".pdf", with: "")
    }

    func activityViewController(
        _: UIActivityViewController,
        dataTypeIdentifierForActivityType _: UIActivity.ActivityType?
    ) -> String {
        "com.adobe.pdf"
    }
}
