//
//  PermissionManager.swift
//  QuranNoor
//
//  Created by Claude on 11/3/24.
//  Centralized permission management for location and notifications

import Foundation
import CoreLocation
import UserNotifications
import Observation
import UIKit

/// Manages app permissions with status tracking and persistence
@Observable
@MainActor
final class PermissionManager {

    // MARK: - Shared Instance

    static let shared = PermissionManager()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Observable State

    var locationStatus: PermissionStatus = .notDetermined
    var notificationStatus: PermissionStatus = .notDetermined

    // MARK: - Permission Status

    enum PermissionStatus: String, Codable {
        case notDetermined
        case granted
        case denied
        case restricted

        var isGranted: Bool {
            self == .granted
        }

        var canRetry: Bool {
            self == .notDetermined
        }

        var needsSettingsRedirect: Bool {
            self == .denied
        }

        var description: String {
            rawValue
        }
    }

    // MARK: - Dependencies

    private let locationService: LocationService
    private let userDefaults: UserDefaults
    private var notificationObserver: NSObjectProtocol?

    // Persistence keys
    private let locationStatusKey = "permission_location_status"
    private let notificationStatusKey = "permission_notification_status"
    private let locationRequestCountKey = "permission_location_request_count"

    // MARK: - Initialization

    private init() {
        self.userDefaults = .standard
        self.locationService = LocationService.shared

        // Setup will be called after initialization
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Load persisted statuses
            self.loadPersistedStatuses()

            // Observe system changes
            self.observeSystemChanges()

            // Sync location status from LocationService
            self.locationStatus = self.mapCLAuthStatus(self.locationService.authorizationStatus)
        }
    }

    // MARK: - Location Permission

    /// Request location permission
    func requestLocationPermission() async -> PermissionStatus {
        // Check if already granted
        let currentStatus = await checkLocationStatus()
        guard currentStatus.canRetry else {
            return currentStatus
        }

        // Increment request count
        incrementLocationRequestCount()

        // Request permission
        locationService.requestLocationPermission()

        // Wait for authorization to change from notDetermined using polling
        // This avoids the race condition where withTaskGroup + timeout
        // could misreport status while the user is still deciding
        let startTime = Date()
        let maxWait: TimeInterval = 60 // Give user up to 60s to decide

        while Date().timeIntervalSince(startTime) < maxWait {
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms intervals

            let status = await checkLocationStatus()
            if status != .notDetermined {
                return status
            }
        }

        // User didn't respond within timeout — return current status without forcing
        return await checkLocationStatus()
    }

    /// Check current location permission status
    func checkLocationStatus() async -> PermissionStatus {
        let clStatus = locationService.authorizationStatus
        let status = mapCLAuthStatus(clStatus)

        // Update published property
        await MainActor.run {
            locationStatus = status
            persistLocationStatus(status)
        }

        return status
    }

    /// Map CLAuthorizationStatus to PermissionStatus
    private func mapCLAuthStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }

    /// Get location request count (for analytics)
    func getLocationRequestCount() -> Int {
        return userDefaults.integer(forKey: locationRequestCountKey)
    }

    private func incrementLocationRequestCount() {
        let count = getLocationRequestCount() + 1
        userDefaults.set(count, forKey: locationRequestCountKey)
    }

    // MARK: - Notification Permission

    /// Request notification permission
    func requestNotificationPermission() async -> PermissionStatus {
        // Check current status
        let currentStatus = await checkNotificationStatus()
        guard currentStatus.canRetry else {
            return currentStatus
        }

        // Add timeout handling for notification permission request
        return await withTaskGroup(of: PermissionStatus.self) { group in
            // Main permission request task
            group.addTask {
                do {
                    let granted = try await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])

                    let status: PermissionStatus = granted ? .granted : .denied

                    await MainActor.run {
                        self.notificationStatus = status
                        self.persistNotificationStatus(status)
                    }

                    return status
                } catch {
                    #if DEBUG
                    print("⚠️ Notification permission error: \(error)")
                    #endif
                    let status: PermissionStatus = .denied
                    await MainActor.run {
                        self.notificationStatus = status
                        self.persistNotificationStatus(status)
                    }
                    return status
                }
            }

            // Timeout task (10 seconds - should never hit this, but safety measure)
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                #if DEBUG
                print("⚠️ Notification permission request timed out")
                #endif
                return await self.checkNotificationStatus()
            }

            // Return first result
            guard let result = await group.next() else {
                group.cancelAll()
                return await checkNotificationStatus()
            }
            group.cancelAll()
            return result
        }
    }

    /// Check current notification permission status
    func checkNotificationStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        let status: PermissionStatus = switch settings.authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized, .provisional, .ephemeral:
            .granted
        @unknown default:
            .notDetermined
        }

        await MainActor.run {
            notificationStatus = status
            persistNotificationStatus(status)
        }

        return status
    }

    // MARK: - Settings Deep Link

    /// Open iOS Settings app
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            #if DEBUG
            print("⚠️ Unable to create settings URL")
            #endif
            return
        }

        Task { @MainActor in
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
                #if DEBUG
                print("🔧 Opening Settings app")
                #endif
            } else {
                #if DEBUG
                print("⚠️ Cannot open settings URL")
                #endif
            }
        }
    }

    // MARK: - Persistence

    private func loadPersistedStatuses() {
        // Load location status
        if let locationData = userDefaults.data(forKey: locationStatusKey),
           let status = try? Self.decoder.decode(PermissionStatus.self, from: locationData) {
            locationStatus = status
        }

        // Load notification status
        if let notificationData = userDefaults.data(forKey: notificationStatusKey),
           let status = try? Self.decoder.decode(PermissionStatus.self, from: notificationData) {
            notificationStatus = status
        }
    }

    private func persistLocationStatus(_ status: PermissionStatus) {
        if let encoded = try? Self.encoder.encode(status) {
            userDefaults.set(encoded, forKey: locationStatusKey)
            #if DEBUG
            print("💾 Location status persisted: \(status.description)")
            #endif
        }
    }

    private func persistNotificationStatus(_ status: PermissionStatus) {
        if let encoded = try? Self.encoder.encode(status) {
            userDefaults.set(encoded, forKey: notificationStatusKey)
            #if DEBUG
            print("💾 Notification status persisted: \(status.description)")
            #endif
        }
    }

    // MARK: - System Changes Observer

    private func observeSystemChanges() {
        // Re-check permissions when app becomes active
        // (user may have changed settings in iOS Settings app)
        notificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                _ = await self?.checkLocationStatus()
                _ = await self?.checkNotificationStatus()
            }
        }
    }

    // MARK: - Diagnostic Methods

    /// Get summary of all permission statuses
    func getPermissionSummary() -> String {
        """
        📊 Permission Summary:
        - Location: \(locationStatus.description)
        - Notifications: \(notificationStatus.description)
        - Location Requests: \(getLocationRequestCount())
        """
    }

    /// Check if all critical permissions are granted
    func areAllCriticalPermissionsGranted() -> Bool {
        return locationStatus.isGranted && notificationStatus.isGranted
    }

    /// Reset all persisted permission data (for testing)
    func resetAllPermissions() {
        userDefaults.removeObject(forKey: locationStatusKey)
        userDefaults.removeObject(forKey: notificationStatusKey)
        userDefaults.removeObject(forKey: locationRequestCountKey)

        locationStatus = .notDetermined
        notificationStatus = .notDetermined

        #if DEBUG
        print("🔄 All permission data reset")
        #endif
    }
}

// MARK: - Permission Error

enum PermissionError: LocalizedError {
    case locationDenied
    case locationRestricted
    case locationServicesDisabled
    case notificationDenied
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Location permission was denied. Please enable it in Settings to get accurate prayer times."
        case .locationRestricted:
            return "Location services are restricted on this device."
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .notificationDenied:
            return "Notification permission was denied. You can still use the app, but won't receive prayer reminders."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .locationDenied, .locationServicesDisabled, .locationRestricted:
            return "Go to Settings > Privacy & Security > Location Services"
        case .notificationDenied:
            return "Go to Settings > Notifications > Qur'an Noor"
        case .networkError:
            return "Check your internet connection and try again."
        case .timeout:
            return "Please try again in a moment."
        }
    }
}
