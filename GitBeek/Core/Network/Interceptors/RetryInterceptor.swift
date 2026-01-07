//
//  RetryInterceptor.swift
//  GitBeek
//
//  Handles automatic retry with exponential backoff
//

import Foundation

/// Interceptor that retries failed requests with exponential backoff
final class RetryInterceptor: RequestInterceptor, @unchecked Sendable {
    // MARK: - Configuration

    struct Configuration: Sendable {
        /// Maximum number of retry attempts
        let maxRetries: Int

        /// Base delay between retries (in seconds)
        let baseDelay: TimeInterval

        /// Maximum delay between retries (in seconds)
        let maxDelay: TimeInterval

        /// Multiplier for exponential backoff
        let multiplier: Double

        /// Jitter factor (0-1) to add randomness to delays
        let jitterFactor: Double

        /// HTTP status codes that should trigger a retry
        let retryableStatusCodes: Set<Int>

        static let `default` = Configuration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0,
            jitterFactor: 0.25,
            retryableStatusCodes: [408, 429, 500, 502, 503, 504]
        )
    }

    // MARK: - Properties

    private let configuration: Configuration
    private var retryCount: [String: Int] = [:]
    private let lock = NSLock()

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - RequestInterceptor

    func intercept(request: inout URLRequest) async throws {
        // No-op for request interception
    }

    func intercept(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest,
        retry: @Sendable @escaping () async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        // Check if this status code should be retried
        guard configuration.retryableStatusCodes.contains(response.statusCode) else {
            return (data, response)
        }

        // Get or create retry count for this request
        let requestKey = request.url?.absoluteString ?? UUID().uuidString
        let currentRetryCount = getRetryCount(for: requestKey)

        // Check if we've exceeded max retries
        guard currentRetryCount < configuration.maxRetries else {
            resetRetryCount(for: requestKey)
            return (data, response)
        }

        // Increment retry count
        incrementRetryCount(for: requestKey)

        // Calculate delay with exponential backoff
        let delay = calculateDelay(for: currentRetryCount, response: response)

        // Log retry attempt
        #if DEBUG
        print("🔄 Retry \(currentRetryCount + 1)/\(configuration.maxRetries) after \(String(format: "%.2f", delay))s for \(requestKey)")
        #endif

        // Wait before retrying
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        // Retry the request
        do {
            let result = try await retry()

            // Check if retry was successful
            if (200...299).contains(result.1.statusCode) {
                resetRetryCount(for: requestKey)
            }

            return result
        } catch {
            // If retry failed with a retryable error, try again
            if let apiError = error as? APIError, apiError.isRetryable {
                // Recursively retry
                return try await intercept(
                    response: response,
                    data: data,
                    request: request,
                    retry: retry
                )
            }
            throw error
        }
    }

    // MARK: - Private Methods

    private func calculateDelay(for retryCount: Int, response: HTTPURLResponse) -> TimeInterval {
        // Check for Retry-After header
        if let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
           let retryAfter = Double(retryAfterString) {
            return min(retryAfter, configuration.maxDelay)
        }

        // Calculate exponential backoff
        let exponentialDelay = configuration.baseDelay * pow(configuration.multiplier, Double(retryCount))
        let cappedDelay = min(exponentialDelay, configuration.maxDelay)

        // Add jitter
        let jitter = cappedDelay * configuration.jitterFactor * Double.random(in: -1...1)
        let finalDelay = max(0, cappedDelay + jitter)

        return finalDelay
    }

    private func getRetryCount(for key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return retryCount[key] ?? 0
    }

    private func incrementRetryCount(for key: String) {
        lock.lock()
        defer { lock.unlock() }
        retryCount[key] = (retryCount[key] ?? 0) + 1
    }

    private func resetRetryCount(for key: String) {
        lock.lock()
        defer { lock.unlock() }
        retryCount.removeValue(forKey: key)
    }
}
