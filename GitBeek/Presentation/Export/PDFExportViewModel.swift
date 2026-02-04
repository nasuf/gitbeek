//
//  PDFExportViewModel.swift
//  GitBeek
//
//  ViewModel for PDF export progress management
//

import Foundation

/// ViewModel for managing PDF export state
@MainActor
@Observable
final class PDFExportViewModel {
    // MARK: - Properties

    private(set) var progress: PDFExportService.ExportProgress = .idle
    private(set) var exportedFileURL: URL?

    private let exportService = PDFExportService()

    // MARK: - Computed Properties

    var isExporting: Bool {
        progress.isInProgress
    }

    var isCompleted: Bool {
        if case .completed = progress {
            return true
        }
        return false
    }

    var hasFailed: Bool {
        if case .failed = progress {
            return true
        }
        return false
    }

    var progressDescription: String {
        progress.description
    }

    // MARK: - Actions

    /// Start PDF export
    func exportPDF(title: String, blocks: [MarkdownBlock], isDarkCodeTheme: Bool = false) async {
        progress = .idle
        exportedFileURL = nil

        do {
            let fileURL = try await exportService.exportToPDF(
                title: title,
                blocks: blocks,
                isDarkCodeTheme: isDarkCodeTheme
            ) { [weak self] newProgress in
                self?.progress = newProgress
            }

            exportedFileURL = fileURL
            progress = .completed(fileURL)
        } catch {
            progress = .failed(error.localizedDescription)
        }
    }

    /// Reset state for new export
    func reset() {
        progress = .idle
        exportedFileURL = nil
    }
}
