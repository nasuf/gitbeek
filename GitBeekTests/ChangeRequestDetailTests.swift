//
//  ChangeRequestDetailTests.swift
//  GitBeekTests
//
//  Tests for Change Request review feature, DTO decoding, isMoveOnly logic,
//  and ChangeRequestDetailViewModel
//

import XCTest
@testable import GitBeek

// MARK: - ChangeRequestDiffDTO Decoding Tests

final class ChangeRequestDiffDTOTests: XCTestCase {

    // MARK: - Standard object format

    func testDecodeObjectFormat() throws {
        let json = """
        {"changes":[{"type":"page_edited","page":{"id":"p1","type":"document","title":"Title","path":"path"}}],"more":0}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 1)
        XCTAssertEqual(dto.changes[0].type, "page_edited")
        XCTAssertEqual(dto.changes[0].page?.id, "p1")
        XCTAssertEqual(dto.more, 0)
    }

    func testDecodeObjectFormatWithAttributes() throws {
        let json = """
        {"changes":[{"type":"page_edited","page":{"id":"p1","type":"document","title":"New","path":"a/b"},"attributes":{"title":{"before":"Old","after":"New"},"document":{"before":"rev1","after":"rev2"}}}],"more":0}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 1)
        let attrs = dto.changes[0].attributes
        XCTAssertEqual(attrs?.title?.before, "Old")
        XCTAssertEqual(attrs?.title?.after, "New")
        XCTAssertEqual(attrs?.document?.before, "rev1")
        XCTAssertEqual(attrs?.document?.after, "rev2")
    }

    func testDecodeTitleOnlyChange() throws {
        let json = """
        {"changes":[{"type":"page_edited","page":{"id":"p1","type":"document","title":"T [144]","path":"x"},"attributes":{"title":{"before":"T [145]","after":"T [144]"}}}],"more":0}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 1)
        XCTAssertNotNil(dto.changes[0].attributes?.title)
        XCTAssertNil(dto.changes[0].attributes?.document, "Title-only change should not have document attribute")
    }

    func testDecodeEmptyChanges() throws {
        let json = """
        {"changes":[],"more":0}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertTrue(dto.changes.isEmpty)
        XCTAssertEqual(dto.more, 0)
    }

    func testDecodeArrayFallback() throws {
        let json = """
        [{"type":"page_created","page":{"id":"p1","type":"document","title":"New","path":"new"}}]
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 1)
        XCTAssertNil(dto.more)
    }

    func testDecodeFileChange() throws {
        let json = """
        {"changes":[{"type":"file_created","file":{"id":"f1","name":"img.png","contentType":"image/png"}}],"more":0}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 1)
        XCTAssertNil(dto.changes[0].page)
        XCTAssertEqual(dto.changes[0].file?.id, "f1")
        XCTAssertEqual(dto.changes[0].file?.name, "img.png")
    }

    func testDecodeMultipleChanges() throws {
        let json = """
        {"changes":[{"type":"page_created","page":{"id":"p1","type":"document","title":"A","path":"a"}},{"type":"page_edited","page":{"id":"p2","type":"document","title":"B","path":"b"}},{"type":"page_removed","page":{"id":"p3","type":"document","title":"C","path":"c"}}],"more":2}
        """
        let dto = try JSONDecoder().decode(ChangeRequestDiffDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.changes.count, 3)
        XCTAssertEqual(dto.more, 2)
    }
}

// MARK: - MergeChangeRequestResponseDTO Tests

final class MergeChangeRequestResponseDTOTests: XCTestCase {

    func testDecodeMergeResponse() throws {
        let json = """
        {"result":"merge","revision":"abc123"}
        """
        let dto = try JSONDecoder().decode(MergeChangeRequestResponseDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.result, "merge")
        XCTAssertEqual(dto.revision, "abc123")
    }

    func testDecodeMergeResponseNilRevision() throws {
        let json = """
        {"result":"merge"}
        """
        let dto = try JSONDecoder().decode(MergeChangeRequestResponseDTO.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(dto.result, "merge")
        XCTAssertNil(dto.revision)
    }
}

// MARK: - ReviewStatus Tests

final class ReviewStatusTests: XCTestCase {

    func testDecodeApproved() throws {
        let json = """
        "approved"
        """
        let status = try JSONDecoder().decode(ReviewStatus.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(status, .approved)
    }

    func testDecodeChangesRequested() throws {
        let json = """
        "changes-requested"
        """
        let status = try JSONDecoder().decode(ReviewStatus.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(status, .changesRequested)
    }

    func testDisplayName() {
        XCTAssertEqual(ReviewStatus.approved.displayName, "Approved")
        XCTAssertEqual(ReviewStatus.changesRequested.displayName, "Changes Requested")
    }

    func testIcon() {
        XCTAssertEqual(ReviewStatus.approved.icon, "checkmark.circle.fill")
        XCTAssertEqual(ReviewStatus.changesRequested.icon, "exclamationmark.triangle.fill")
    }

    func testEncodeSubmitReviewRequest() throws {
        let request = SubmitReviewRequestDTO(status: .approved)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(dict?["status"], "approved")

        let request2 = SubmitReviewRequestDTO(status: .changesRequested)
        let data2 = try JSONEncoder().encode(request2)
        let dict2 = try JSONSerialization.jsonObject(with: data2) as? [String: String]
        XCTAssertEqual(dict2?["status"], "changes-requested")
    }
}

// MARK: - ChangeRequestReview Mapping Tests

final class ChangeRequestReviewMappingTests: XCTestCase {

    func testFromDTOWithReviewer() {
        let dto = ChangeRequestReviewDTO(
            id: "review1",
            reviewer: UserReferenceDTO(object: "user", id: "user1", displayName: "Alice", photoURL: nil),
            status: .approved,
            outdated: false,
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let review = ChangeRequestReview.from(dto: dto)
        XCTAssertEqual(review.id, "review1")
        XCTAssertEqual(review.reviewer?.id, "user1")
        XCTAssertEqual(review.reviewer?.displayName, "Alice")
        XCTAssertEqual(review.status, .approved)
        XCTAssertFalse(review.outdated)
        XCTAssertEqual(review.createdAt, Date(timeIntervalSince1970: 1000))
    }

    func testFromDTOWithoutReviewer() {
        let dto = ChangeRequestReviewDTO(
            id: "review2",
            reviewer: nil,
            status: .changesRequested,
            outdated: true,
            createdAt: nil
        )
        let review = ChangeRequestReview.from(dto: dto)
        XCTAssertEqual(review.id, "review2")
        XCTAssertNil(review.reviewer)
        XCTAssertEqual(review.status, .changesRequested)
        XCTAssertTrue(review.outdated)
        XCTAssertNil(review.createdAt)
    }

    func testFromDTOOutdatedNilDefaultsToFalse() {
        let dto = ChangeRequestReviewDTO(
            id: "review3",
            reviewer: nil,
            status: .approved,
            outdated: nil,
            createdAt: nil
        )
        let review = ChangeRequestReview.from(dto: dto)
        XCTAssertFalse(review.outdated, "nil outdated should default to false")
    }
}

// MARK: - Change.isMoveOnly Tests

final class ChangeIsMoveOnlyTests: XCTestCase {

    private func makeChange(
        type: ChangeType = .modified,
        titleChange: DocumentChange? = DocumentChange(before: "Old", after: "New"),
        hasDocumentChange: Bool = false,
        contentLoaded: Bool = false,
        contentBefore: String? = nil,
        contentAfter: String? = nil
    ) -> Change {
        Change(
            id: "test",
            type: type,
            path: "path",
            title: "Title",
            isFile: false,
            fileName: nil,
            titleChange: titleChange,
            hasDocumentChange: hasDocumentChange,
            contentBefore: contentBefore,
            contentAfter: contentAfter,
            contentLoaded: contentLoaded
        )
    }

    // Before content loaded - heuristic based

    func testMoveOnlyBeforeLoad_NoDocumentChange() {
        let change = makeChange(hasDocumentChange: false, contentLoaded: false)
        XCTAssertTrue(change.isMoveOnly, "Title change without document change should be move-only")
    }

    func testMoveOnlyBeforeLoad_WithDocumentChange() {
        let change = makeChange(hasDocumentChange: true, contentLoaded: false)
        XCTAssertFalse(change.isMoveOnly, "Title change with document change should not be move-only before load")
    }

    // After content loaded - content comparison based

    func testMoveOnlyAfterLoad_IdenticalContent() {
        let change = makeChange(
            hasDocumentChange: true,
            contentLoaded: true,
            contentBefore: "# Hello\nWorld",
            contentAfter: "# Hello\nWorld"
        )
        XCTAssertTrue(change.isMoveOnly, "Identical content after load should be move-only even with document change")
    }

    func testMoveOnlyAfterLoad_DifferentContent() {
        let change = makeChange(
            hasDocumentChange: true,
            contentLoaded: true,
            contentBefore: "# Hello",
            contentAfter: "# Hello World"
        )
        XCTAssertFalse(change.isMoveOnly, "Different content should not be move-only")
    }

    func testMoveOnlyAfterLoad_BothNilContent() {
        let change = makeChange(
            hasDocumentChange: true,
            contentLoaded: true,
            contentBefore: nil,
            contentAfter: nil
        )
        XCTAssertTrue(change.isMoveOnly, "Both nil content should be move-only")
    }

    // Non-modified types are never move-only

    func testNotMoveOnly_AddedType() {
        let change = makeChange(type: .added)
        XCTAssertFalse(change.isMoveOnly, "Added type should never be move-only")
    }

    func testNotMoveOnly_RemovedType() {
        let change = makeChange(type: .removed)
        XCTAssertFalse(change.isMoveOnly, "Removed type should never be move-only")
    }

    // No title change = not move-only

    func testNotMoveOnly_NoTitleChange() {
        let change = makeChange(titleChange: nil, hasDocumentChange: false)
        XCTAssertFalse(change.isMoveOnly, "No title change should not be move-only")
    }
}

// MARK: - Change.from(dto:) Mapping Tests

final class ChangeDTOMappingTests: XCTestCase {

    func testMapPageCreated() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "page_created",
            page: .init(id: "p1", type: "document", title: "New Page", path: "new"),
            file: nil,
            attributes: nil
        )
        let change = Change.from(dto: dto)
        XCTAssertNotNil(change)
        XCTAssertEqual(change?.type, .added)
        XCTAssertEqual(change?.title, "New Page")
        XCTAssertFalse(change?.isFile ?? true)
    }

    func testMapPageEdited() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "page_edited",
            page: .init(id: "p1", type: "document", title: "Edited", path: "edited"),
            file: nil,
            attributes: .init(
                title: .init(before: "Before", after: "After"),
                document: .init(before: "r1", after: "r2")
            )
        )
        let change = Change.from(dto: dto)
        XCTAssertNotNil(change)
        XCTAssertEqual(change?.type, .modified)
        XCTAssertEqual(change?.titleChange?.before, "Before")
        XCTAssertEqual(change?.titleChange?.after, "After")
        XCTAssertTrue(change?.hasDocumentChange ?? false)
    }

    func testMapPageRemoved() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "page_removed",
            page: .init(id: "p1", type: "document", title: "Deleted", path: "del"),
            file: nil,
            attributes: nil
        )
        let change = Change.from(dto: dto)
        XCTAssertEqual(change?.type, .removed)
    }

    func testMapFileCreated() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "file_created",
            page: nil,
            file: .init(id: "f1", name: "image.png", contentType: "image/png", downloadURL: nil),
            attributes: nil
        )
        let change = Change.from(dto: dto)
        XCTAssertNotNil(change)
        XCTAssertTrue(change?.isFile ?? false)
        XCTAssertEqual(change?.type, .added)
        XCTAssertTrue(change?.contentLoaded ?? false, "File changes should have contentLoaded=true")
    }

    func testMapMissingPageAndFile() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "page_edited",
            page: nil,
            file: nil,
            attributes: nil
        )
        let change = Change.from(dto: dto)
        XCTAssertNil(change, "Should return nil when both page and file are missing")
    }

    func testMapTitleOnlyChange() {
        let dto = ChangeRequestDiffDTO.ChangeDTO(
            type: "page_edited",
            page: .init(id: "p1", type: "document", title: "New Title", path: "path"),
            file: nil,
            attributes: .init(
                title: .init(before: "Old Title", after: "New Title"),
                document: nil
            )
        )
        let change = Change.from(dto: dto)
        XCTAssertNotNil(change)
        XCTAssertEqual(change?.titleChange?.before, "Old Title")
        XCTAssertFalse(change?.hasDocumentChange ?? true, "Title-only should not have document change")
        XCTAssertTrue(change?.isMoveOnly ?? false, "Title-only change should be isMoveOnly before content load")
    }
}

// MARK: - ChangeRequestDetailViewModel Tests

@MainActor
final class ChangeRequestDetailViewModelTests: XCTestCase {

    private func makeViewModel(
        spaceId: String = "space1",
        changeRequestId: String = "cr1",
        repository: DetailMockChangeRequestRepository = DetailMockChangeRequestRepository()
    ) -> (ChangeRequestDetailViewModel, DetailMockChangeRequestRepository) {
        let vm = ChangeRequestDetailViewModel(
            spaceId: spaceId,
            changeRequestId: changeRequestId,
            changeRequestRepository: repository,
            spaceRepository: DetailMockSpaceRepository()
        )
        return (vm, repository)
    }

    // MARK: - Initial State

    func testInitialState() {
        let (vm, _) = makeViewModel()
        XCTAssertNil(vm.changeRequest)
        XCTAssertNil(vm.diff)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isLoadingDiff)
        XCTAssertFalse(vm.isMerging)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.didMerge)
        XCTAssertFalse(vm.didArchive)
        XCTAssertTrue(vm.reviews.isEmpty)
        XCTAssertTrue(vm.requestedReviewers.isEmpty)
        XCTAssertFalse(vm.isLoadingReviews)
        XCTAssertFalse(vm.isSubmittingReview)
    }

    // MARK: - Load

    func testLoadSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()

        XCTAssertNotNil(vm.changeRequest)
        XCTAssertEqual(vm.changeRequest?.status, .open)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadError() async {
        let repo = DetailMockChangeRequestRepository()
        repo.shouldThrowOnGet = true
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()

        XCTAssertNil(vm.changeRequest)
        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Load Diff

    func testLoadDiffSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open, revision: "rev1", revisionInitial: "rev0")
        repo.mockDiff = ChangeRequestDiff(changes: [
            Change(id: "p1", type: .modified, path: "path", title: "Title",
                   isFile: false, fileName: nil,
                   titleChange: nil, hasDocumentChange: true,
                   contentBefore: nil, contentAfter: nil, contentLoaded: false)
        ])
        repo.mockPageContentAtRevision = "# Content"
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.loadDiff()

        XCTAssertNotNil(vm.diff)
        XCTAssertEqual(vm.diff?.changes.count, 1)
        XCTAssertFalse(vm.isLoadingDiff)
    }

    func testLoadDiffSkipsMoveOnly() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open, revision: "rev1", revisionInitial: "rev0")
        // Title-only change without document attribute → isMoveOnly=true before load
        repo.mockDiff = ChangeRequestDiff(changes: [
            Change(id: "p1", type: .modified, path: "path", title: "Title",
                   isFile: false, fileName: nil,
                   titleChange: DocumentChange(before: "Old", after: "New"),
                   hasDocumentChange: false,
                   contentBefore: nil, contentAfter: nil, contentLoaded: false)
        ])
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.loadDiff()

        XCTAssertNotNil(vm.diff)
        // Content should NOT have been loaded for move-only change
        XCTAssertFalse(vm.diff?.changes[0].contentLoaded ?? true,
                       "Move-only change should not have content loaded")
        XCTAssertEqual(repo.getPageContentAtRevisionCallCount, 0,
                       "Should not fetch content for move-only changes")
    }

    // MARK: - Merge

    func testMergeSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        repo.mockMergedChangeRequest = makeChangeRequest(status: .merged)
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.merge()

        XCTAssertTrue(vm.didMerge)
        XCTAssertEqual(vm.changeRequest?.status, .merged)
        XCTAssertFalse(vm.isMerging)
    }

    func testMergeGuardNotOpen() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .draft)
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.merge()

        XCTAssertFalse(vm.didMerge, "Should not merge a draft CR")
    }

    func testMergeError() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        repo.shouldThrowOnMerge = true
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.merge()

        XCTAssertFalse(vm.didMerge)
        XCTAssertNotNil(vm.error)
    }

    // MARK: - Archive

    func testArchiveSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        repo.mockArchivedChangeRequest = makeChangeRequest(status: .archived)
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.archive()

        XCTAssertTrue(vm.didArchive)
        XCTAssertEqual(vm.changeRequest?.status, .archived)
    }

    func testArchiveGuardNotMerged() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .merged)
        let (vm, _) = makeViewModel(repository: repo)

        await vm.load()
        await vm.archive()

        XCTAssertFalse(vm.didArchive, "Should not archive a merged CR")
    }

    // MARK: - Load Reviews

    func testLoadReviewsSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockReviews = [
            ChangeRequestReview(id: "r1", reviewer: UserReference(id: "u1", displayName: "Alice", photoURL: nil), status: .approved, outdated: false, createdAt: nil)
        ]
        repo.mockRequestedReviewers = [
            UserReference(id: "u2", displayName: "Bob", photoURL: nil)
        ]
        let (vm, _) = makeViewModel(repository: repo)

        await vm.loadReviews()

        XCTAssertEqual(vm.reviews.count, 1)
        XCTAssertEqual(vm.reviews[0].status, .approved)
        XCTAssertEqual(vm.requestedReviewers.count, 1)
        XCTAssertEqual(vm.requestedReviewers[0].displayName, "Bob")
        XCTAssertFalse(vm.isLoadingReviews)
    }

    func testLoadReviewsError() async {
        let repo = DetailMockChangeRequestRepository()
        repo.shouldThrowOnListReviews = true
        let (vm, _) = makeViewModel(repository: repo)

        await vm.loadReviews()

        // Error is printed but not set on self.error
        XCTAssertTrue(vm.reviews.isEmpty)
        XCTAssertFalse(vm.isLoadingReviews)
    }

    // MARK: - Approve

    func testApproveSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockSubmittedReview = ChangeRequestReview(
            id: "r1", reviewer: nil, status: .approved, outdated: false, createdAt: nil
        )
        let (vm, _) = makeViewModel(repository: repo)

        await vm.approve()

        XCTAssertEqual(vm.reviews.count, 1)
        XCTAssertEqual(vm.reviews[0].status, .approved)
        XCTAssertFalse(vm.isSubmittingReview)
        XCTAssertNil(vm.error)
    }

    func testApproveError() async {
        let repo = DetailMockChangeRequestRepository()
        repo.shouldThrowOnSubmitReview = true
        let (vm, _) = makeViewModel(repository: repo)

        await vm.approve()

        XCTAssertTrue(vm.reviews.isEmpty)
        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isSubmittingReview)
    }

    // MARK: - Request Changes

    func testRequestChangesSuccess() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockSubmittedReview = ChangeRequestReview(
            id: "r1", reviewer: nil, status: .changesRequested, outdated: false, createdAt: nil
        )
        let (vm, _) = makeViewModel(repository: repo)

        await vm.requestChanges()

        XCTAssertEqual(vm.reviews.count, 1)
        XCTAssertEqual(vm.reviews[0].status, .changesRequested)
    }

    // MARK: - Computed Properties

    func testCanMerge() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        let (vm, _) = makeViewModel(repository: repo)
        await vm.load()
        XCTAssertTrue(vm.canMerge)
    }

    func testCannotMergeDraft() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .draft)
        let (vm, _) = makeViewModel(repository: repo)
        await vm.load()
        XCTAssertFalse(vm.canMerge)
    }

    func testCanArchiveOpen() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .open)
        let (vm, _) = makeViewModel(repository: repo)
        await vm.load()
        XCTAssertTrue(vm.canArchive)
    }

    func testCannotArchiveMerged() async {
        let repo = DetailMockChangeRequestRepository()
        repo.mockChangeRequest = makeChangeRequest(status: .merged)
        let (vm, _) = makeViewModel(repository: repo)
        await vm.load()
        XCTAssertFalse(vm.canArchive)
    }

    func testClearError() async {
        let repo = DetailMockChangeRequestRepository()
        repo.shouldThrowOnGet = true
        let (vm, _) = makeViewModel(repository: repo)
        await vm.load()
        XCTAssertNotNil(vm.error)

        vm.clearError()
        XCTAssertNil(vm.error)
    }

    // MARK: - Helpers

    private func makeChangeRequest(
        status: ChangeRequestStatus,
        revision: String? = nil,
        revisionInitial: String? = nil
    ) -> ChangeRequest {
        ChangeRequest(
            id: "cr1",
            number: 1,
            subject: "Test CR",
            status: status,
            createdAt: Date(),
            updatedAt: Date(),
            mergedAt: status == .merged ? Date() : nil,
            closedAt: nil,
            revision: revision,
            revisionInitial: revisionInitial,
            createdBy: UserReference(id: "user1", displayName: "Test User", photoURL: nil),
            urls: nil
        )
    }
}

// MARK: - Mock for ChangeRequestDetailViewModel

final class DetailMockChangeRequestRepository: ChangeRequestRepository, @unchecked Sendable {
    var mockChangeRequest: ChangeRequest?
    var mockMergedChangeRequest: ChangeRequest?
    var mockArchivedChangeRequest: ChangeRequest?
    var mockDiff: ChangeRequestDiff?
    var mockPageContentAtRevision: String?
    var mockReviews: [ChangeRequestReview] = []
    var mockRequestedReviewers: [UserReference] = []
    var mockSubmittedReview: ChangeRequestReview?

    var shouldThrowOnGet = false
    var shouldThrowOnMerge = false
    var shouldThrowOnListReviews = false
    var shouldThrowOnSubmitReview = false

    var getPageContentAtRevisionCallCount = 0

    private let mockError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    func listChangeRequests(spaceId: String, page: String?) async throws -> [ChangeRequest] {
        return []
    }

    func getChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        if shouldThrowOnGet { throw mockError }
        guard let cr = mockChangeRequest else { throw mockError }
        return cr
    }

    func getChangeRequestDiff(spaceId: String, changeRequestId: String) async throws -> ChangeRequestDiff {
        guard let diff = mockDiff else { throw mockError }
        return diff
    }

    func mergeChangeRequest(spaceId: String, changeRequestId: String) async throws -> ChangeRequest {
        if shouldThrowOnMerge { throw mockError }
        guard let cr = mockMergedChangeRequest else { throw mockError }
        return cr
    }

    func updateChangeRequestStatus(spaceId: String, changeRequestId: String, status: ChangeRequestStatus) async throws -> ChangeRequest {
        if let cr = mockArchivedChangeRequest { return cr }
        throw mockError
    }

    func updateChangeRequestSubject(spaceId: String, changeRequestId: String, subject: String) async throws -> ChangeRequest {
        throw mockError
    }

    func getPageContent(spaceId: String, pageId: String) async throws -> String? {
        return nil
    }

    func getChangeRequestPageContent(spaceId: String, changeRequestId: String, pageId: String) async throws -> String? {
        return nil
    }

    func getPageContentAtRevision(spaceId: String, revisionId: String, pageId: String) async throws -> String? {
        getPageContentAtRevisionCallCount += 1
        return mockPageContentAtRevision
    }

    func listReviews(spaceId: String, changeRequestId: String) async throws -> [ChangeRequestReview] {
        if shouldThrowOnListReviews { throw mockError }
        return mockReviews
    }

    func submitReview(spaceId: String, changeRequestId: String, status: ReviewStatus) async throws -> ChangeRequestReview {
        if shouldThrowOnSubmitReview { throw mockError }
        guard let review = mockSubmittedReview else { throw mockError }
        return review
    }

    func listRequestedReviewers(spaceId: String, changeRequestId: String) async throws -> [UserReference] {
        if shouldThrowOnListReviews { throw mockError }
        return mockRequestedReviewers
    }

    func listComments(spaceId: String, changeRequestId: String) async throws -> [Comment] { [] }
    func createComment(spaceId: String, changeRequestId: String, markdown: String) async throws -> Comment { throw mockError }
    func updateComment(spaceId: String, changeRequestId: String, commentId: String, markdown: String) async throws -> Comment { throw mockError }
    func deleteComment(spaceId: String, changeRequestId: String, commentId: String) async throws { throw mockError }
    func listReplies(spaceId: String, changeRequestId: String, commentId: String) async throws -> [CommentReply] { [] }
    func createReply(spaceId: String, changeRequestId: String, commentId: String, markdown: String) async throws -> CommentReply { throw mockError }
    func updateReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String, markdown: String) async throws -> CommentReply { throw mockError }
    func deleteReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String) async throws { throw mockError }
}

final class DetailMockSpaceRepository: SpaceRepository, @unchecked Sendable {
    private let mockError = NSError(domain: "test", code: 1)

    func getCollections(organizationId: String) async throws -> [Collection] { [] }
    func getSpaces(organizationId: String) async throws -> [Space] { [] }
    func getSpace(id: String) async throws -> Space { throw mockError }
    func createSpace(organizationId: String, title: String, emoji: String?, visibility: Space.Visibility, parentId: String?) async throws -> Space { throw mockError }
    func createCollection(organizationId: String, title: String, parentId: String?) async throws -> Collection { throw mockError }
    func updateSpace(id: String, title: String?, emoji: String?, visibility: Space.Visibility?, parentId: String?) async throws -> Space { throw mockError }
    func moveSpace(id: String, parentId: String?) async throws {}
    func deleteSpace(id: String) async throws {}
    func restoreSpace(id: String) async throws -> Space { throw mockError }
    func renameCollection(id: String, title: String) async throws -> Collection { throw mockError }
    func deleteCollection(id: String) async throws {}
    func moveCollection(id: String, parentId: String?) async throws {}
    func getCachedSpaces(organizationId: String) async -> [Space] { [] }
    func clearCache() async {}
}
