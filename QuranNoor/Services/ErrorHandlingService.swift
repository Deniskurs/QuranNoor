//
//  ErrorHandlingService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Centralized error handling with retry mechanisms and user-friendly messages
//

import Foundation
import SwiftUI
import Observation

/// Retry strategy for failed operations
enum RetryStrategy {
    case immediate
    case exponentialBackoff(maxAttempts: Int)
    case none

    var maxAttempts: Int {
        switch self {
        case .immediate: return 3
        case .exponentialBackoff(let max): return max
        case .none: return 1
        }
    }
}

/// Error recovery action
enum ErrorRecoveryAction {
    case retry
    case useOffline
    case useCached
    case dismiss
    case openSettings

    var title: String {
        switch self {
        case .retry: return "Try Again"
        case .useOffline: return "Use Offline Mode"
        case .useCached: return "Use Cached Data"
        case .dismiss: return "OK"
        case .openSettings: return "Open Settings"
        }
    }

    var icon: String {
        switch self {
        case .retry: return "arrow.clockwise"
        case .useOffline: return "airplane"
        case .useCached: return "archivebox.fill"
        case .dismiss: return "xmark.circle"
        case .openSettings: return "gear"
        }
    }
}

/// User-friendly error presentation
struct UserFriendlyError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let severity: ErrorSeverity
    let actions: [ErrorRecoveryAction]
    let originalError: Error?

    enum ErrorSeverity {
        case info
        case warning
        case error
        case critical

        var color: Color {
            switch self {
            case .info: return AppColors.primary.green // Theme-consistent info color
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
    }
}

/// Service for centralized error handling
@Observable
@MainActor
final class ErrorHandlingService {

    // MARK: - Singleton
    static let shared = ErrorHandlingService()

    // MARK: - Properties
    private(set) var currentError: UserFriendlyError?
    private(set) var errorHistory: [UserFriendlyError] = []
    private(set) var isShowingError: Bool = false

    private init() {}

    // MARK: - Error Handling

    /// Handle an error with appropriate user feedback
    func handle(
        _ error: Error,
        context: String = "",
        severity: UserFriendlyError.ErrorSeverity = .error,
        suggestedActions: [ErrorRecoveryAction]? = nil
    ) {
        print("❌ Error in \(context): \(error.localizedDescription)")

        let userFriendlyError = convertToUserFriendlyError(
            error,
            context: context,
            severity: severity,
            suggestedActions: suggestedActions
        )

        currentError = userFriendlyError
        errorHistory.append(userFriendlyError)
        isShowingError = true

        // Keep only last 50 errors in history
        if errorHistory.count > 50 {
            errorHistory.removeFirst(errorHistory.count - 50)
        }
    }

    /// Dismiss current error
    func dismissError() {
        currentError = nil
        isShowingError = false
    }

    /// Clear error history
    func clearErrorHistory() {
        errorHistory.removeAll()
    }

    // MARK: - Retry Mechanisms

    /// Retry an operation with exponential backoff
    func retry<T>(
        strategy: RetryStrategy = .exponentialBackoff(maxAttempts: 3),
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 1
        var lastError: Error?

        while attempt <= strategy.maxAttempts {
            do {
                let result = try await operation()
                if attempt > 1 {
                    print("✅ Retry succeeded on attempt \(attempt)")
                }
                return result
            } catch {
                lastError = error
                print("🔄 Attempt \(attempt) failed: \(error.localizedDescription)")

                if attempt < strategy.maxAttempts {
                    // Calculate backoff delay
                    let delay = calculateBackoffDelay(attempt: attempt, strategy: strategy)
                    print("⏳ Waiting \(delay)s before retry...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                attempt += 1
            }
        }

        // All retries failed
        throw lastError ?? NSError(domain: "RetryFailed", code: -1)
    }

    /// Retry with automatic fallback
    func retryWithFallback<T>(
        primary: @escaping () async throws -> T,
        fallback: @escaping () async throws -> T,
        strategy: RetryStrategy = .exponentialBackoff(maxAttempts: 2)
    ) async throws -> T {
        do {
            return try await retry(strategy: strategy, operation: primary)
        } catch {
            print("🔄 Primary operation failed, using fallback...")
            return try await fallback()
        }
    }

    // MARK: - Error Conversion

    private func convertToUserFriendlyError(
        _ error: Error,
        context: String,
        severity: UserFriendlyError.ErrorSeverity,
        suggestedActions: [ErrorRecoveryAction]?
    ) -> UserFriendlyError {

        // Handle specific error types
        if let prayerError = error as? PrayerTimeError {
            return handlePrayerTimeError(prayerError, context: context)
        }

        if let urlError = error as? URLError {
            return handleURLError(urlError, context: context)
        }

        if let mosqueError = error as? MosqueFinderError {
            return handleMosqueFinderError(mosqueError, context: context)
        }

        // Generic error
        return UserFriendlyError(
            title: "Something Went Wrong",
            message: context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)",
            icon: "exclamationmark.triangle.fill",
            severity: severity,
            actions: suggestedActions ?? [.retry, .dismiss],
            originalError: error
        )
    }

    private func handlePrayerTimeError(_ error: PrayerTimeError, context: String) -> UserFriendlyError {
        switch error {
        case .networkError:
            return UserFriendlyError(
                title: "Network Connection Issue",
                message: "Unable to connect to prayer time service. We'll use offline calculations instead.",
                icon: "wifi.slash",
                severity: .warning,
                actions: [.useOffline, .retry, .dismiss],
                originalError: error
            )

        case .calculationFailed:
            return UserFriendlyError(
                title: "Prayer Time Calculation Failed",
                message: "We couldn't calculate prayer times. Please check your location settings.",
                icon: "location.slash.fill",
                severity: .error,
                actions: [.openSettings, .useCached, .retry],
                originalError: error
            )

        case .invalidResponse:
            return UserFriendlyError(
                title: "Invalid Prayer Time Data",
                message: "The prayer time service returned invalid data. Please try again.",
                icon: "questionmark.circle.fill",
                severity: .error,
                actions: [.retry, .useOffline, .dismiss],
                originalError: error
            )

        case .offlineFallbackFailed:
            return UserFriendlyError(
                title: "Unable to Calculate Prayer Times",
                message: "Both online and offline calculations failed. Please check your location permissions.",
                icon: "exclamationmark.octagon.fill",
                severity: .critical,
                actions: [.openSettings, .useCached],
                originalError: error
            )
        }
    }

    private func handleURLError(_ error: URLError, context: String) -> UserFriendlyError {
        let message: String
        let actions: [ErrorRecoveryAction]

        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            message = "No internet connection. The app will work offline with cached data."
            actions = [.useOffline, .useCached, .dismiss]

        case .timedOut:
            message = "The request timed out. Please check your connection and try again."
            actions = [.retry, .useOffline, .dismiss]

        default:
            message = "Network error occurred. Using offline mode."
            actions = [.useOffline, .retry, .dismiss]
        }

        return UserFriendlyError(
            title: "Connection Problem",
            message: message,
            icon: "network.slash",
            severity: .warning,
            actions: actions,
            originalError: error
        )
    }

    private func handleMosqueFinderError(_ error: MosqueFinderError, context: String) -> UserFriendlyError {
        switch error {
        case .noResults:
            return UserFriendlyError(
                title: "No Mosques Found",
                message: "We couldn't find any mosques nearby. Try increasing the search radius or checking your location.",
                icon: "building.2.crop.circle",
                severity: .info,
                actions: [.retry, .openSettings, .dismiss],
                originalError: error
            )

        case .searchFailed:
            return UserFriendlyError(
                title: "Search Failed",
                message: "Unable to search for nearby mosques. Please try again.",
                icon: "magnifyingglass.circle.fill",
                severity: .error,
                actions: [.retry, .dismiss],
                originalError: error
            )

        case .locationUnavailable:
            return UserFriendlyError(
                title: "Location Required",
                message: "Please enable location services to find nearby mosques.",
                icon: "location.circle.fill",
                severity: .warning,
                actions: [.openSettings, .dismiss],
                originalError: error
            )
        }
    }

    // MARK: - Helper Methods

    private func calculateBackoffDelay(attempt: Int, strategy: RetryStrategy) -> TimeInterval {
        switch strategy {
        case .immediate:
            return 0.5
        case .exponentialBackoff:
            // Exponential backoff: 1s, 2s, 4s, 8s, etc.
            return min(pow(2.0, Double(attempt - 1)), 30.0)
        case .none:
            return 0
        }
    }

    /// Open iOS Settings app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Present user-friendly error alerts
    func errorAlert(
        error: Binding<UserFriendlyError?>,
        onAction: @escaping (ErrorRecoveryAction) -> Void
    ) -> some View {
        alert(
            error.wrappedValue?.title ?? "Error",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { userError in
            ForEach(userError.actions, id: \.self) { action in
                Button(action.title) {
                    onAction(action)
                }
            }
        } message: { userError in
            Text(userError.message)
        }
    }
}
