//
//  OrganizationRepository.swift
//  GitBeek
//
//  Protocol for organization operations
//

import Foundation

/// Protocol defining organization operations
protocol OrganizationRepository: Sendable {
    /// Get all organizations for current user
    func getOrganizations() async throws -> [Organization]

    /// Get organization by ID
    func getOrganization(id: String) async throws -> Organization

    /// Get cached organizations
    func getCachedOrganizations() async -> [Organization]

    /// Clear organization cache
    func clearCache() async
}
