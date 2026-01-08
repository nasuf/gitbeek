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

    // MARK: - Spaces

    /// List spaces in organization
    case listSpaces(orgId: String, page: String?)

    /// Get space by ID
    case getSpace(spaceId: String)

    /// Create new space
    case createSpace(orgId: String, request: SpaceRequestDTO)

    /// Update space
    case updateSpace(spaceId: String, request: SpaceRequestDTO)

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
    case listChangeRequests(spaceId: String, page: String?)

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

        // Spaces
        case .listSpaces(let orgId, _):
            return "/orgs/\(orgId)/spaces"
        case .getSpace(let spaceId):
            return "/spaces/\(spaceId)"
        case .createSpace(let orgId, _):
            return "/orgs/\(orgId)/spaces"
        case .updateSpace(let spaceId, _):
            return "/spaces/\(spaceId)"
        case .deleteSpace(let spaceId):
            return "/spaces/\(spaceId)"
        case .restoreSpace(let spaceId):
            return "/spaces/\(spaceId)/restore"

        // Content
        case .getContent(let spaceId):
            return "/spaces/\(spaceId)/content"
        case .getPageByPath(let spaceId, let path):
            return "/spaces/\(spaceId)/content/path/\(path)"
        case .getPage(let spaceId, let pageId):
            return "/spaces/\(spaceId)/content/\(pageId)"
        case .createPage(let spaceId, _):
            return "/spaces/\(spaceId)/content"
        case .updatePage(let spaceId, let pageId, _):
            return "/spaces/\(spaceId)/content/\(pageId)"
        case .deletePage(let spaceId, let pageId):
            return "/spaces/\(spaceId)/content/\(pageId)"

        // Change Requests
        case .listChangeRequests(let spaceId, _):
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
            return "/spaces/\(spaceId)/change-requests/\(changeRequestId)/diff"

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
             .createSpace, .createPage, .createChangeRequest,
             .mergeChangeRequest, .restoreSpace:
            return .post
        case .updateSpace, .updatePage, .updateChangeRequest:
            return .patch
        case .deleteSpace, .deletePage:
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
             .listSpaces(_, let page),
             .listChangeRequests(_, let page):
            var params: [String: String] = [:]
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
        case .createPage(_, let request), .updatePage(_, _, let request):
            return request
        case .createChangeRequest(_, let request):
            return request
        case .updateChangeRequest(_, _, let request):
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
