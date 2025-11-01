//
//  NotificationService.swift
//  QuranNoor
//
//  Manages prayer time notifications and reminders
//

import Foundation
import UserNotifications
import Combine

// MARK: - Notification Error
enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied. Please enable notifications in Settings."
        case .schedulingFailed:
            return "Failed to schedule notifications. Please try again."
        }
    }
}

// MARK: - Notification Service
@MainActor
class NotificationService: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var notificationsEnabled: Bool = false

    // MARK: - Private Properties
    private let center = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let notificationsEnabledKey = "notificationsEnabled"

    // MARK: - Initializer
    init() {
        loadNotificationSettings()
        checkAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// Request notification permission
    func requestPermission() async throws -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted

            if granted {
                notificationsEnabled = true
                saveNotificationSettings()
            }

            return granted
        } catch {
            throw NotificationError.permissionDenied
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    /// Schedule notifications for all prayers
    /// - Parameter prayerTimes: Daily prayer times to schedule
    func schedulePrayerNotifications(_ prayerTimes: DailyPrayerTimes) async throws {
        guard isAuthorized else {
            throw NotificationError.permissionDenied
        }

        // Remove existing prayer notifications
        await cancelPrayerNotifications()

        // Schedule for each prayer
        for prayer in prayerTimes.prayerTimes {
            try await scheduleNotification(for: prayer)
        }
    }

    /// Schedule a single prayer notification
    private func scheduleNotification(for prayer: PrayerTime) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Prayer Time"
        content.body = "It's time for \(prayer.name.displayName) prayer"
        content.sound = .default
        content.categoryIdentifier = "PRAYER_TIME"

        // Add prayer-specific icon
        content.userInfo = [
            "prayerName": prayer.name.rawValue,
            "prayerTime": prayer.time.timeIntervalSince1970
        ]

        // Create date components for trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: prayer.time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let identifier = "prayer-\(prayer.name.rawValue)-\(prayer.time.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            throw NotificationError.schedulingFailed
        }
    }

    /// Schedule reminder before prayer (e.g., 10 minutes before)
    /// - Parameters:
    ///   - prayer: Prayer time
    ///   - minutesBefore: Minutes before prayer to notify
    func scheduleReminderNotification(for prayer: PrayerTime, minutesBefore: Int) async throws {
        guard isAuthorized else { return }

        let reminderTime = prayer.time.addingTimeInterval(-Double(minutesBefore * 60))

        // Don't schedule if reminder time is in the past
        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Prayer Reminder"
        content.body = "\(prayer.name.displayName) prayer in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "reminder-\(prayer.name.rawValue)-\(minutesBefore)min"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(request)
    }

    /// Cancel all prayer-related notifications
    func cancelPrayerNotifications() async {
        let allIdentifiers = await center.pendingNotificationRequests().map { $0.identifier }
        let prayerIdentifiers = allIdentifiers.filter { $0.hasPrefix("prayer-") || $0.hasPrefix("reminder-") }
        center.removePendingNotificationRequests(withIdentifiers: prayerIdentifiers)
    }

    /// Cancel all notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Toggle notifications on/off
    func toggleNotifications() async throws {
        if notificationsEnabled {
            // Disable
            await cancelPrayerNotifications()
            notificationsEnabled = false
        } else {
            // Enable (will need prayer times from ViewModel)
            notificationsEnabled = true
        }

        saveNotificationSettings()
    }

    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    // MARK: - Private Methods

    private func loadNotificationSettings() {
        notificationsEnabled = userDefaults.bool(forKey: notificationsEnabledKey)
    }

    private func saveNotificationSettings() {
        userDefaults.set(notificationsEnabled, forKey: notificationsEnabledKey)
    }
}

// MARK: - Notification Categories
extension NotificationService {
    /// Register notification categories for interactive notifications
    func registerNotificationCategories() {
        // Prayer time actions
        let prayedAction = UNNotificationAction(
            identifier: "PRAYED",
            title: "Mark as Prayed",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind me in 5 min",
            options: []
        )

        let prayerCategory = UNNotificationCategory(
            identifier: "PRAYER_TIME",
            actions: [prayedAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Reminder category
        let reminderCategory = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([prayerCategory, reminderCategory])
    }
}
