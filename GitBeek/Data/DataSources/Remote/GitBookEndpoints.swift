//
//  GitBookEndpoints.swift
//  GitBeek
//
//  GitBook API endpoint definitions
//

import Foundation

/// GitBook API endpoints
enum GitBookEndpoint: APIEndpoint {
    // MARK: - Authentication

    /// Exchange authorization code for access token
    case exchangeToken(code: String, redirectUri: String, clientId: String)

    /// Refresh access token
    case refreshToken(refreshToken: String, clientId: String)

    // MARK: - User

    /// Get current authenticated user
    case getCurrentUser

    // MARK: - Organizations

    /// List organizations for current user
    case listOrganizations(page: String?)

    /// Get organization by ID
    case getOrganization(orgId: String)

    /// List organization members
    case listMembers(orgId: String, page: String?)

    // MARK: - Collections

    /// List collections in organization
    case listCollections(orgId: String, page: String?)

    /// Get collection by ID
    case getCollection(collectionId: String)

    /// Create collection in organization
    case createCollection(orgId: String, request: CreateCollectionRequestDTO)

    /// Update collection (rename)
    case updateCollection(collectionId: String, request: UpdateCollectionRequestDTO)

    /// Delete collection
    case deleteCollection(collectionId: String)

    /// Move collection to another parent
    case moveCollection(collectionId: String, request: MoveParentRequestDTO)

    // MARK: - Spaces

    /// List spaces in organization
    case listSpaces(orgId: String, page: String?)

    /// Get space by ID
    case getSpace(spaceId: String)

    /// Create new space
    case createSpace(orgId: String, request: SpaceRequestDTO)

    /// Update space
    case updateSpace(spaceId: String, request: SpaceRequestDTO)

    /// Move space to another parent
    case moveSpace(spaceId: String, request: MoveParentRequestDTO)

    /// Delete space (soft delete - moves to trash)
    case deleteSpace(spaceId: String)

    /// Restore deleted space from trash
    case restoreSpace(spaceId: String)

    // MARK: - Content

    /// Get content tree for space
    case getContent(spaceId: String)

    /// Get page by path
    case getPageByPath(spaceId: String, path: String)

    /// Get page by ID
    case getPage(spaceId: String, pageId: String)

    /// Create page
    case createPage(spaceId: String, request: PageRequestDTO)

    /// Update page
    case updatePage(spaceId: String, pageId: String, request: PageRequestDTO)

    /// Delete page
    case deletePage(spaceId: String, pageId: String)

    // MARK: - Change Requests

    /// List change requests for space
    case listChangeRequests(spaceId: String, status: String?, page: String?)

    /// Get change request by ID
    case getChangeRequest(spaceId: String, changeRequestId: String)

    /// Create change request
    case createChangeRequest(spaceId: String, request: CreateChangeRequestDTO)

    /// Update change request
    case updateChangeRequest(spaceId: String, changeRequestId: String, request: UpdateChangeRequestDTO)

    /// Merge change request
    case mergeChangeRequest(spaceId: String, changeRequestId: String)

    /// Get change request diff
    case getChangeRequestDiff(spaceId: String, changeRequestId: String)

    /// Get page content in change request context (after version)
    case getChangeRequestPageContent(spaceId: String, changeRequestId: String, pageId: String)

    /// Get page content at a specific revision (for before version of merged CRs)
    case getPageAtRevision(spaceId: String, revisionId: String, pageId: String)

    /// List reviews for a change request
    case listChangeRequestReviews(spaceId: String, changeRequestId: String)

    /// Submit a review for a change request
    case submitChangeRequestReview(spaceId: String, changeRequestId: String, request: SubmitReviewRequestDTO)

    /// List requested reviewers for a change request
    case listRequestedReviewers(spaceId: String, changeRequestId: String)

    /// Request reviewers for a change request
    case requestReviewers(spaceId: String, changeRequestId: String, request: RequestReviewersRequestDTO)

    // MARK: - Change Request Comments

    /// List comments on a change request
    case listComments(spaceId: String, changeRequestId: String)

    /// Create a comment on a change request
    case createComment(spaceId: String, changeRequestId: String, request: CommentRequestDTO)

    /// Update a comment
    case updateComment(spaceId: String, changeRequestId: String, commentId: String, request: CommentRequestDTO)

    /// Delete a comment
    case deleteComment(spaceId: String, changeRequestId: String, commentId: String)

    /// List replies to a comment
    case listReplies(spaceId: String, changeRequestId: String, commentId: String)

    /// Create a reply to a comment
    case createReply(spaceId: String, changeRequestId: String, commentId: String, request: CommentRequestDTO)

    /// Update a reply
    case updateReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String, request: CommentRequestDTO)

    /// Delete a reply
    case deleteReply(spaceId: String, changeRequestId: String, commentId: String, replyId: String)

    // MARK: - Search

    /// Search in organization
    case searchOrganization(orgId: String, query: String, page: String?)

    /// Search in space
    case searchSpace(spaceId: String, query: String, page: String?)

    // MARK: - APIEndpoint Protocol

    var path: String {
        switch self {
        // Auth
        case .exchangeToken, .refreshToken:
            return "/oauth/token"

        // User
        case .getCurrentUser:
            return "/user"

        // Organizations
        case .listOrganizations:
            return "/orgs"
        case .getOrganization(let orgId):
            return "/orgs/\(orgId)"
        case .listMembers(let orgId, _):
            return "/orgs/\(orgId)/members"

        // Collections
        case .listCollections(let orgId, _):
            return "/orgs/\(orgId)/collections"
        case .getCollection(let collectionId):
            return "/collections/\(collectionId)"
        case .createCollection(let orgId, _):
            return "/orgs/\(orgId)/collections"
        case .updateCollection(let collectionId, _):
            return "/collections/\(collectionId)"
        case .deleteCollection(let collectionId):
            return "/collections/\(collectionId)"
        case .moveCollection(let collectionId, _):
            return "/collections/\(collectionId)/move"

        // Spaces
        case .listSpaces(let orgId, _):
            return "/orgs/\(orgId)/spaces"
        case .getSpace(let spaceId):
            return "/spaces/\(spaceId)"
        case .createSpace(let orgId, _):
            return "/orgs/\(orgId)/spaces"
        case .updateSpace(let spaceId, _):
            return "/spaces/\(spaceId)"
        case .moveSpace(let spaceId, _):
            return "/spaces/\(spaceId)/move"
        case .deleteSpace(let spaceId):
            return "/spaces/\(spaceId)"
        case .restoreSpace(let spaceId):
            return "/spaces/\(spaceId)/restore"

        // Content
        case .getContent(let spaceId):
            return "/spaces/\(spaceId)/content"
        case .getPageByPath(let spaceId, let path):
            return "/spaces/\(spaceId)/content/page/\(path)"
        case .getPage(let spaceId, let pageId):
            return "/spaces/\(spaceId)/content/page/\(pageId)"
        case .createPage(let spaceId, _):
            return "/spaces/\(spaceId)/content/pages"
        case .updatePage(let spaceId, let pageId, _):
            return "/spaces/\(spaceId)/content/page/\(pageId)"
        case .deletePage(let spaceId, let pageId):
            return "/spaces/\(spaceId)/content/page/\(pageId)"

        // Change Requests
        case .listChangeRequests(let spaceId, _, _):
            return "/spaces/\(spaceId)/change-requests"
        case .getChangeRequest(let spaceId, let changeRequestId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)"
        case .createChangeRequest(let spaceId, _):
            return "/spaces/\(spaceId)/change-requests"
        case .updateChangeRequest(let spaceId, let changeRequestId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)"
        case .mergeChangeRequest(let spaceId, let changeRequestId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/merge"
        case .getChangeRequestDiff(let spaceId, let changeRequestId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/changes"
        case .getChangeRequestPageContent(let spaceId, let changeRequestId, let pageId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/content/page/\(pageId)"
        case .getPageAtRevision(let spaceId, let revisionId, let pageId):
            return "/spaces/\(spaceId)/revisions/\(revisionId)/page/\(pageId)"
        case .listChangeRequestReviews(let spaceId, let changeRequestId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/reviews"
        case .submitChangeRequestReview(let spaceId, let changeRequestId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/reviews"
        case .listRequestedReviewers(let spaceId, let changeRequestId),
             .requestReviewers(let spaceId, let changeRequestId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/requested-reviewers"

        // Comments
        case .listComments(let spaceId, let changeRequestId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments"
        case .createComment(let spaceId, let changeRequestId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments"
        case .updateComment(let spaceId, let changeRequestId, let commentId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)"
        case .deleteComment(let spaceId, let changeRequestId, let commentId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)"
        case .listReplies(let spaceId, let changeRequestId, let commentId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)/replies"
        case .createReply(let spaceId, let changeRequestId, let commentId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)/replies"
        case .updateReply(let spaceId, let changeRequestId, let commentId, let replyId, _):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)/replies/\(replyId)"
        case .deleteReply(let spaceId, let changeRequestId, let commentId, let replyId):
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/comments/\(commentId)/replies/\(replyId)"

        // Search
        case .searchOrganization(let orgId, _, _):
            return "/orgs/\(orgId)/search"
        case .searchSpace(let spaceId, _, _):
            return "/spaces/\(spaceId)/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .exchangeToken, .refreshToken,
             .createSpace, .createCollection, .createPage, .createChangeRequest,
             .mergeChangeRequest, .restoreSpace,
             .submitChangeRequestReview, .requestReviewers,
             .moveSpace, .moveCollection,
             .createComment, .createReply:
            return .post
        case .updateSpace, .updatePage, .updateChangeRequest, .updateCollection:
            return .patch
        case .updateComment, .updateReply:
            return .put
        case .deleteSpace, .deletePage, .deleteCollection,
             .deleteComment, .deleteReply:
            return .delete
        default:
            return .get
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .listOrganizations(let page),
             .listMembers(_, let page),
             .listCollections(_, let page),
             .listSpaces(_, let page):
            var params: [String: String] = [:]
            if let page = page { params["page"] = page }
            return params.isEmpty ? nil : params

        case .listChangeRequests(_, let status, let page):
            var params: [String: String] = [:]
            if let status = status { params["status"] = status }
            if let page = page { params["page"] = page }
            return params.isEmpty ? nil : params

        case .searchOrganization(_, let query, let page),
             .searchSpace(_, let query, let page):
            var params: [String: String] = ["query": query]
            if let page = page { params["page"] = page }
            return params

        case .getPage(_, _):
            return ["format": "markdown"]

        case .getPageByPath(_, _):
            return ["format": "markdown"]

        case .getChangeRequestPageContent(_, _, _):
            return ["format": "markdown"]

        case .getPageAtRevision(_, _, _):
            return ["format": "markdown"]

        default:
            return nil
        }
    }

    var body: Encodable? {
        switch self {
        case .exchangeToken(let code, let redirectUri, let clientId):
            return TokenExchangeRequestDTO(code: code, redirectUri: redirectUri, clientId: clientId)
        case .refreshToken(let refreshToken, let clientId):
            return TokenRefreshRequestDTO(refreshToken: refreshToken, clientId: clientId)
        case .createSpace(_, let request), .updateSpace(_, let request):
            return request
        case .createCollection(_, let request):
            return request
        case .updateCollection(_, let request):
            return request
        case .moveCollection(_, let request):
            return request
        case .moveSpace(_, let request):
            return request
        case .createPage(_, let request), .updatePage(_, _, let request):
            return request
        case .createChangeRequest(_, let request):
            return request
        case .updateChangeRequest(_, _, let request):
            return request
        case .submitChangeRequestReview(_, _, let request):
            return request
        case .requestReviewers(_, _, let request):
            return request
        case .createComment(_, _, let request), .updateComment(_, _, _, let request):
            return request
        case .createReply(_, _, _, let request), .updateReply(_, _, _, _, let request):
            return request
        default:
            return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .exchangeToken, .refreshToken:
            return false
        default:
            return true
        }
    }

    var contentType: ContentType {
        switch self {
        case .exchangeToken, .refreshToken:
            return .formURLEncoded
        default:
            return .json
        }
    }
}
