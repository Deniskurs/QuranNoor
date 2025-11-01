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
    /// - Parameters:
    ///   - prayerTimes: Daily prayer times to schedule
    ///   - city: City name for notification title
    ///   - countryCode: Country code (e.g., "GB", "US") for notification title
    func schedulePrayerNotifications(
        _ prayerTimes: DailyPrayerTimes,
        city: String = "Unknown",
        countryCode: String = "Unknown"
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.permissionDenied
        }

        // Remove existing prayer notifications
        await cancelPrayerNotifications()

        // Schedule for each prayer
        for prayer in prayerTimes.prayerTimes {
            try await scheduleNotification(
                for: prayer,
                city: city,
                countryCode: countryCode
            )
        }
    }

    /// Schedule a single prayer notification with rich formatting
    /// - Parameters:
    ///   - prayer: Prayer time to schedule
    ///   - city: City name for notification title
    ///   - countryCode: Country code for notification title
    private func scheduleNotification(
        for prayer: PrayerTime,
        city: String,
        countryCode: String
    ) async throws {
        let content = UNMutableNotificationContent()

        // RICH TITLE: "Maghrib at 16:34 in Livingston, GB"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: prayer.time)

        content.title = "\(prayer.name.displayName) at \(timeString) in \(city), \(countryCode)"

        // EDUCATIONAL CONTENT: Get rotating Islamic quote/verse
        let islamicContent = await IslamicContentService.shared.getRotatingContent(for: prayer.name)
        if let subtitle = islamicContent.subtitle {
            content.subtitle = subtitle
        }
        content.body = islamicContent.formattedBody

        // Notification settings
        content.sound = .default
        content.categoryIdentifier = "PRAYER_TIME"
        content.relevanceScore = 1.0 // Highest priority for prayer times
        content.badge = 1 // Show badge on app icon

        // Add metadata
        content.userInfo = [
            "prayerName": prayer.name.rawValue,
            "prayerTime": prayer.time.timeIntervalSince1970,
            "contentIndex": islamicContent.index,
            "city": city,
            "country": countryCode
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
            print("✅ Scheduled rich notification: \(content.title)")
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
        content.relevanceScore = 0.7 // Medium-high priority for reminders

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "reminder-\(prayer.name.rawValue)-\(minutesBefore)min"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(request)
    }

    /// Schedule urgent notification when prayer period has < 30 minutes remaining
    /// - Parameters:
    ///   - prayer: Current prayer
    ///   - deadline: When the prayer period ends (e.g., Fajr deadline = Sunrise)
    ///   - isMidnight: Special case for Isha (ends at Islamic Midnight)
    func scheduleUrgentNotification(
        for prayer: PrayerName,
        deadline: Date,
        isMidnight: Bool = false
    ) async throws {
        guard isAuthorized else { return }

        // Calculate 30 minutes before deadline
        let urgentTime = deadline.addingTimeInterval(-1800) // -30 minutes

        // Don't schedule if urgent time is in the past
        guard urgentTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Prayer Time Ending Soon"

        // Choose motivational message based on prayer
        let messages = [
            "Only 30 minutes left for \(prayer.displayName)! Don't miss your connection with Allah ﷻ",
            "\(prayer.displayName) ends in 30 minutes. Pray now for maximum reward ✨",
            "Quick reminder: \(prayer.displayName) time is ending soon. Make your salah count! 🤲"
        ]

        content.body = messages.randomElement() ?? messages[0]
        content.sound = .defaultCritical // More attention-grabbing sound
        content.categoryIdentifier = "PRAYER_URGENT"
        content.interruptionLevel = .timeSensitive // iOS 15+ priority
        content.relevanceScore = 1.0 // Highest priority for urgent deadline alerts

        // Add metadata
        content.userInfo = [
            "prayerName": prayer.rawValue,
            "deadline": deadline.timeIntervalSince1970,
            "isMidnight": isMidnight
        ]

        // Create date components for trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: urgentTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create unique identifier to prevent duplicates
        let identifier = "urgent-\(prayer.rawValue)-\(deadline.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            throw NotificationError.schedulingFailed
        }
    }

    /// Cancel urgent notification for a specific prayer
    func cancelUrgentNotification(for prayer: PrayerName) {
        Task {
            let allIdentifiers = await center.pendingNotificationRequests().map { $0.identifier }
            let urgentIdentifiers = allIdentifiers.filter { $0.hasPrefix("urgent-\(prayer.rawValue)-") }
            center.removePendingNotificationRequests(withIdentifiers: urgentIdentifiers)
        }
    }

    /// Cancel all prayer-related notifications
    func cancelPrayerNotifications() async {
        let allIdentifiers = await center.pendingNotificationRequests().map { $0.identifier }
        let prayerIdentifiers = allIdentifiers.filter {
            $0.hasPrefix("prayer-") || $0.hasPrefix("reminder-") || $0.hasPrefix("urgent-")
        }
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

        // Urgent prayer ending actions
        let prayNowAction = UNNotificationAction(
            identifier: "PRAY_NOW",
            title: "Pray Now",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "I Already Prayed",
            options: []
        )

        let urgentCategory = UNNotificationCategory(
            identifier: "PRAYER_URGENT",
            actions: [prayNowAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([prayerCategory, reminderCategory, urgentCategory])
    }
}
