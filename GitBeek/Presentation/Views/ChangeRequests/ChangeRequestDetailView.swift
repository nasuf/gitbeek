//
//  ChangeRequestDetailView.swift
//  GitBeek
//
//  View for displaying change request details
//

import SwiftUI

/// View for displaying change request details
struct ChangeRequestDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel: ChangeRequestDetailViewModel

    // MARK: - Initialization

    init(
        spaceId: String,
        changeRequestId: String,
        changeRequestRepository: ChangeRequestRepository
    ) {
        let vm = ChangeRequestDetailViewModel(
            spaceId: spaceId,
            changeRequestId: changeRequestId,
            changeRequestRepository: changeRequestRepository
        )
        self._viewModel = State(initialValue: vm)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Content
            if viewModel.isLoading && viewModel.changeRequest == nil {
                ProgressView("Loading...")
            } else if let changeRequest = viewModel.changeRequest {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header card
                        headerCard(changeRequest: changeRequest)
                            .padding(.horizontal)
                            .padding(.top, AppSpacing.sm)

                        // Actions
                        if changeRequest.isActive {
                            actionsSection(changeRequest: changeRequest)
                                .padding(.horizontal)
                        }

                        // Reviews section
                        reviewsSection
                            .padding(.horizontal)

                        // Review actions (only for non-authors)
                        if changeRequest.status == .open,
                           let currentUserId = authViewModel.currentUser?.id,
                           changeRequest.createdBy?.id != currentUserId {
                            reviewActionsSection
                                .padding(.horizontal)
                        }

                        // Diff section
                        diffSection
                            .padding(.horizontal)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.bottom, AppSpacing.lg)
                }
            }
        }
        .navigationTitle("Change Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if let urlString = viewModel.changeRequest?.urls?.app,
               let url = URL(string: urlString) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
        .task {
            await viewModel.load()
            await viewModel.loadDiff()
            await viewModel.loadReviews()
        }
        .onChange(of: viewModel.didMerge) { _, didMerge in
            if didMerge {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .onChange(of: viewModel.didArchive) { _, didArchive in
            if didArchive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            }
        }
        .alert("Merge Change Request?", isPresented: $viewModel.showMergeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Merge", role: .destructive) {
                Task {
                    await viewModel.merge()
                }
            }
        } message: {
            Text("This will merge all changes into the main content. This action cannot be undone.")
        }
        .alert("Archive Change Request?", isPresented: $viewModel.showArchiveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                Task {
                    await viewModel.archive()
                }
            }
        } message: {
            Text("This will archive the change request. You can reopen it later if needed.")
        }
        .alert("Approve Change Request?", isPresented: $viewModel.showApproveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                Task {
                    await viewModel.approve()
                }
            }
        } message: {
            Text("This will approve the change request.")
        }
        .alert("Request Changes?", isPresented: $viewModel.showRequestChangesConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Request Changes", role: .destructive) {
                Task {
                    await viewModel.requestChanges()
                }
            }
        } message: {
            Text("This will request changes on the change request.")
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Header Card

    @ViewBuilder
    private func headerCard(changeRequest: ChangeRequest) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Title and number
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text("#\(changeRequest.number)")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(.secondary)

                        statusBadge(status: changeRequest.status)
                    }

                    Text(changeRequest.displayTitle)
                        .font(AppTypography.titleMedium)
                        .fontWeight(.semibold)
                }

                Spacer()

                Image(systemName: changeRequest.status.icon)
                    .font(.title)
                    .foregroundStyle(statusColor(changeRequest.status))
            }

            Divider()

            // Metadata
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let createdBy = changeRequest.createdBy {
                    MetadataRow(
                        icon: "person.circle",
                        label: "Created by",
                        value: createdBy.displayName
                    )
                }

                if let createdAt = changeRequest.createdAt {
                    MetadataRow(
                        icon: "calendar",
                        label: "Created",
                        value: formatDate(createdAt)
                    )
                }

                if let updatedAt = changeRequest.updatedAt {
                    MetadataRow(
                        icon: "clock",
                        label: "Updated",
                        value: formatDate(updatedAt)
                    )
                }

                if changeRequest.status == .merged, let mergedAt = changeRequest.mergedAt {
                    MetadataRow(
                        icon: "checkmark.circle",
                        label: "Merged",
                        value: formatDate(mergedAt)
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLarge)
        )
    }

    // MARK: - Actions Section

    @ViewBuilder
    private func actionsSection(changeRequest: ChangeRequest) -> some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.canMerge {
                Button {
                    viewModel.showMergeConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isMerging {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.merge")
                        }

                        Text("Merge Changes")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
                .disabled(viewModel.isMerging || viewModel.isUpdatingStatus)
            }

            if viewModel.canArchive {
                Button {
                    viewModel.showArchiveConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isUpdatingStatus {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "archivebox")
                        }

                        Text("Archive")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.red)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
                .disabled(viewModel.isMerging || viewModel.isUpdatingStatus)
            }
        }
    }

    // MARK: - Reviews Section

    @ViewBuilder
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("Reviews", systemImage: "person.2")
                    .font(AppTypography.headlineMedium)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoadingReviews {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !viewModel.reviews.isEmpty || !viewModel.requestedReviewers.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    // Show submitted reviews
                    ForEach(viewModel.reviews) { review in
                        reviewRow(review: review)
                    }

                    // Show pending requested reviewers (not yet reviewed)
                    let reviewedUserIds = Set(viewModel.reviews.compactMap { $0.reviewer?.id })
                    ForEach(viewModel.requestedReviewers.filter { !reviewedUserIds.contains($0.id) }, id: \.id) { reviewer in
                        pendingReviewerRow(reviewer: reviewer)
                    }
                }
                .padding(AppSpacing.md)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                )
            } else if !viewModel.isLoadingReviews {
                Text("No reviews yet")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func reviewRow(review: ChangeRequestReview) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: review.status.icon)
                .foregroundStyle(review.status == .approved ? .green : .orange)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(review.reviewer?.displayName ?? "Unknown")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)

                HStack(spacing: AppSpacing.xs) {
                    Text(review.status.displayName)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(review.status == .approved ? .green : .orange)

                    if review.outdated {
                        Text("(outdated)")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let createdAt = review.createdAt {
                Text(formatDate(createdAt))
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func pendingReviewerRow(reviewer: UserReference) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(reviewer.displayName)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)

                Text("Pending")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Review Actions Section

    @ViewBuilder
    private var reviewActionsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                viewModel.showApproveConfirmation = true
            } label: {
                HStack {
                    if viewModel.isSubmittingReview {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }

                    Text("Approve")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
            .disabled(viewModel.isSubmittingReview)

            Button {
                viewModel.showRequestChangesConfirmation = true
            } label: {
                HStack {
                    if viewModel.isSubmittingReview {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "exclamationmark.triangle")
                    }

                    Text("Request Changes")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.orange)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
            .disabled(viewModel.isSubmittingReview)
        }
    }

    // MARK: - Diff Section

    @ViewBuilder
    private var diffSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("Changes", systemImage: "doc.text.magnifyingglass")
                    .font(AppTypography.headlineMedium)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoadingDiff {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let diff = viewModel.diff {
                if diff.hasChanges {
                    // Summary
                    HStack(spacing: AppSpacing.md) {
                        if diff.addedCount > 0 {
                            ChangeCountBadge(
                                count: diff.addedCount,
                                type: .added
                            )
                        }

                        if diff.modifiedCount > 0 {
                            ChangeCountBadge(
                                count: diff.modifiedCount,
                                type: .modified
                            )
                        }

                        if diff.removedCount > 0 {
                            ChangeCountBadge(
                                count: diff.removedCount,
                                type: .removed
                            )
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    )

                    // Changes list (filter out file-only entries like images embedded in pages)
                    ForEach(diff.changes.filter { !$0.isFile }) { change in
                        ChangeRow(change: change)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Changes", systemImage: "doc.text")
                    } description: {
                        Text("This change request has no changes.")
                    }
                }
            } else if !viewModel.isLoadingDiff {
                Text("Unable to load changes")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Functions

    private func statusBadge(status: ChangeRequestStatus) -> some View {
        Text(status.displayName)
            .font(AppTypography.captionSmall)
            .fontWeight(.medium)
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(
                statusColor(status).opacity(0.15),
                in: Capsule()
            )
    }

    private func statusColor(_ status: ChangeRequestStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .open: return .blue
        case .merged: return .green
        case .archived: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppTypography.bodySmall)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Change Count Badge

private struct ChangeCountBadge: View {
    let count: Int
    let type: ChangeType

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: type.icon)
                .font(AppTypography.captionSmall)

            Text("\(count) \(type.displayName.lowercased())")
                .font(AppTypography.captionSmall)
                .fontWeight(.medium)
        }
        .foregroundStyle(typeColor)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 4)
        .background(
            typeColor.opacity(0.15),
            in: Capsule()
        )
    }

    private var typeColor: Color {
        switch type {
        case .added: return .green
        case .modified: return .orange
        case .removed: return .red
        }
    }
}

// MARK: - Change Row

private struct ChangeRow: View {
    let change: Change
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: tap to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)

                    Image(systemName: change.isFile ? "doc" : "doc.text")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(typeColor)

                    Text(change.displayTitle)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(change.type.displayName)
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            typeColor.opacity(0.15),
                            in: Capsule()
                        )
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // Path info
                    if !change.isFile && !change.path.isEmpty {
                        Text(change.displayPath)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.md)
                    }

                    // Move-only indicator
                    if change.isMoveOnly {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text("This page has been moved without any changes.")
                                .font(AppTypography.captionSmall)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // Title change
                    if let titleChange = change.titleChange, titleChange.hasChanges {
                        titleChangeSection(titleChange)
                            .padding(.horizontal, AppSpacing.md)
                    }

                    // Content diff (skip for move-only changes)
                    if !change.isFile && !change.isMoveOnly {
                        contentDiffSection
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
                .padding(.bottom, AppSpacing.md)
            }
        }
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
        )
    }

    // MARK: - Title Change

    @ViewBuilder
    private func titleChangeSection(_ titleChange: DocumentChange) -> some View {
        if let before = titleChange.before, let after = titleChange.after {
            HStack(spacing: AppSpacing.xs) {
                Text(before)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .strikethrough()

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(after)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(AppSpacing.cornerRadiusSmall)
        }
    }

    // MARK: - Content Diff

    @ViewBuilder
    private var contentDiffSection: some View {
        if !change.contentLoaded {
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading content...")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(.secondary)
            }
        } else if change.type == .added {
            if let content = change.contentAfter, !content.isEmpty {
                DiffContentBlock(markdown: content, diffType: .added)
            } else {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus.circle")
                        .font(.caption2)
                    Text("New page created.")
                        .font(AppTypography.captionSmall)
                }
                .foregroundStyle(.green.opacity(0.8))
                .padding(.horizontal, AppSpacing.md)
            }
        } else if change.type == .removed {
            if let content = change.contentBefore, !content.isEmpty {
                DiffContentBlock(markdown: content, diffType: .removed)
            } else {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "trash")
                        .font(.caption2)
                    Text("This page has been deleted.")
                        .font(AppTypography.captionSmall)
                }
                .foregroundStyle(.red.opacity(0.8))
                .padding(.horizontal, AppSpacing.md)
            }
        } else {
            // Modified: do paragraph-level diff between before and after
            let beforeContent = change.contentBefore ?? ""
            let afterContent = change.contentAfter ?? ""

            if afterContent.isEmpty && beforeContent.isEmpty && change.titleChange == nil {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("Content changes could not be loaded.")
                        .font(AppTypography.captionSmall)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.md)
            } else {
                let diffBlocks = computeBlockDiff(before: beforeContent, after: afterContent)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(diffBlocks.enumerated()), id: \.offset) { _, block in
                        switch block.type {
                        case .unchanged:
                            MarkdownContentView(markdown: block.text)
                                .padding(.vertical, AppSpacing.xs)
                        case .added:
                            DiffContentBlock(markdown: block.text, diffType: .added)
                        case .removed:
                            DiffContentBlock(markdown: block.text, diffType: .removed)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Block Diff

    private struct DiffBlock {
        let text: String
        let type: DiffBlockKind
    }

    private enum DiffBlockKind {
        case unchanged, added, removed
    }

    /// Split markdown into paragraphs and diff them
    private func computeBlockDiff(before: String, after: String) -> [DiffBlock] {
        let beforeBlocks = splitIntoBlocks(before)
        let afterBlocks = splitIntoBlocks(after)

        if beforeBlocks.isEmpty && afterBlocks.isEmpty { return [] }
        if beforeBlocks.isEmpty {
            return afterBlocks.map { DiffBlock(text: $0, type: .added) }
        }
        if afterBlocks.isEmpty {
            return beforeBlocks.map { DiffBlock(text: $0, type: .removed) }
        }

        // LCS on blocks
        let lcs = lcsBlocks(beforeBlocks, afterBlocks)
        var result: [DiffBlock] = []
        var bi = 0, ai = 0, li = 0

        while bi < beforeBlocks.count || ai < afterBlocks.count {
            if li < lcs.count {
                while bi < beforeBlocks.count && beforeBlocks[bi] != lcs[li] {
                    result.append(DiffBlock(text: beforeBlocks[bi], type: .removed))
                    bi += 1
                }
                while ai < afterBlocks.count && afterBlocks[ai] != lcs[li] {
                    result.append(DiffBlock(text: afterBlocks[ai], type: .added))
                    ai += 1
                }
                if bi < beforeBlocks.count && ai < afterBlocks.count {
                    result.append(DiffBlock(text: beforeBlocks[bi], type: .unchanged))
                    bi += 1
                    ai += 1
                    li += 1
                }
            } else {
                while bi < beforeBlocks.count {
                    result.append(DiffBlock(text: beforeBlocks[bi], type: .removed))
                    bi += 1
                }
                while ai < afterBlocks.count {
                    result.append(DiffBlock(text: afterBlocks[ai], type: .added))
                    ai += 1
                }
            }
        }

        return result
    }

    /// Split markdown into logical blocks (by double newlines, preserving code blocks)
    private func splitIntoBlocks(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var blocks: [String] = []
        var current: [String] = []
        var inCodeBlock = false

        for line in trimmed.components(separatedBy: "\n") {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    current.append(line)
                    blocks.append(current.joined(separator: "\n"))
                    current = []
                    inCodeBlock = false
                } else {
                    // Start of code block — flush current
                    if !current.isEmpty {
                        let block = current.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !block.isEmpty { blocks.append(block) }
                        current = []
                    }
                    current.append(line)
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                current.append(line)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Blank line — flush current block
                if !current.isEmpty {
                    let block = current.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !block.isEmpty { blocks.append(block) }
                    current = []
                }
            } else {
                current.append(line)
            }
        }

        if !current.isEmpty {
            let block = current.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !block.isEmpty { blocks.append(block) }
        }

        return blocks
    }

    private func lcsBlocks(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }
        var result: [String] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i - 1] == b[j - 1] {
                result.append(a[i - 1])
                i -= 1; j -= 1
            } else if dp[i - 1][j] > dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        return result.reversed()
    }

    private var typeColor: Color {
        switch change.type {
        case .added: return .green
        case .modified: return .orange
        case .removed: return .red
        }
    }
}

// MARK: - Diff Content Block

/// Renders markdown content with a colored left border to indicate added/removed
private struct DiffContentBlock: View {
    let markdown: String
    let diffType: DiffBlockType

    enum DiffBlockType {
        case added, removed

        var borderColor: Color {
            switch self {
            case .added: return .green
            case .removed: return .red
            }
        }

        var bgColor: Color {
            switch self {
            case .added: return .green.opacity(0.05)
            case .removed: return .red.opacity(0.05)
            }
        }
    }

    var body: some View {
        MarkdownContentView(markdown: markdown)
            .padding(AppSpacing.sm)
            .padding(.leading, AppSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(diffType.bgColor)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(diffType.borderColor)
                    .frame(width: 3)
            }
            .cornerRadius(AppSpacing.cornerRadiusSmall)
    }
}

// MARK: - Preview

#Preview("Change Request Detail") {
    NavigationStack {
        ChangeRequestDetailView(
            spaceId: "preview-space",
            changeRequestId: "preview-cr",
            changeRequestRepository: DependencyContainer.shared.changeRequestRepository
        )
    }
}
