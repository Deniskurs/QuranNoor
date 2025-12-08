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
    // MARK: - Cached Formatters (Performance: avoid repeated allocation)
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var notificationsEnabled: Bool = false

    // MARK: - Private Properties
    private let center = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let notificationsEnabledKey = "notificationsEnabled"

    // MARK: - Dynamic Notification Titles
    /// Prayer-specific dynamic titles with emojis
    private let prayerTitles: [PrayerName: [String]] = [
        .fajr: [
            "🌅 Rise for Fajr at",
            "🌙 Dawn Breaks at",
            "✨ Fajr Awaits at"
        ],
        .dhuhr: [
            "☀️ Dhuhr is Calling at",
            "🕌 Midday Prayer at",
            "📿 Time for Dhuhr at"
        ],
        .asr: [
            "🌤️ Asr Has Entered at",
            "⏰ Afternoon Salah at",
            "🤲 Asr Awaits You at"
        ],
        .maghrib: [
            "🌅 Maghrib at Sunset",
            "🍽️ Break Fast & Pray at",
            "🌙 Maghrib is Here at"
        ],
        .isha: [
            "🌙 Isha Under Stars at",
            "✨ Night Prayer at",
            "🌌 Isha Has Arrived at"
        ]
    ]

    /// Prayer-specific reminder messages
    private let reminderMessages: [PrayerName: String] = [
        .fajr: "angels are gathering to witness your prayer",
        .dhuhr: "your good deeds rise to Allah at this hour",
        .asr: "the angels witness Asr and Fajr",
        .maghrib: "prepare to break fast and connect with Allah",
        .isha: "half the night's reward awaits you"
    ]

    /// Prayer-specific reminder emojis
    private let reminderEmojis: [PrayerName: String] = [
        .fajr: "🌅",
        .dhuhr: "☀️",
        .asr: "🌤️",
        .maghrib: "🌅",
        .isha: "🌙"
    ]

    /// Urgent notification titles
    private let urgentTitles: [String] = [
        "⚡ Don't Miss",
        "⏰",
        "🚨 Last Call for"
    ]

    /// Urgent notification body messages
    private let urgentMessages: [String] = [
        "Only 30 min left! The Prophet ﷺ never missed a single prayer.",
        "Your Lord awaits - prayer window is closing 🤲",
        "Rush to salah! Every prayer is priceless ✨",
        "Angels are recording - you still have time!",
        "30 minutes remaining - pray now, regret nothing 💎",
        "Don't let this slip away - your soul needs this connection 🕌"
    ]

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

        // Get per-prayer preferences
        let prefs = NotificationPreferencesService.shared

        // Schedule for each prayer (respecting per-prayer preferences)
        for prayer in prayerTimes.prayerTimes {
            // Check if this prayer has notifications enabled
            guard prefs.isNotificationEnabled(for: prayer.name) else {
                print("⏭️ Skipping \(prayer.name.displayName) notification (disabled in preferences)")
                continue
            }

            // Schedule main notification
            try await scheduleNotification(
                for: prayer,
                city: city,
                countryCode: countryCode
            )

            // Schedule reminder if configured
            let reminderMinutes = prefs.getReminderMinutes(for: prayer.name)
            if reminderMinutes > 0 {
                try await scheduleReminderNotification(for: prayer, minutesBefore: reminderMinutes)
                print("⏰ Scheduled \(reminderMinutes)min reminder for \(prayer.name.displayName)")
            }
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

        // Format time
        let timeString = Self.timeFormatter.string(from: prayer.time)

        // DYNAMIC TITLE: Pick a random engaging phrase for this prayer
        let titles = prayerTitles[prayer.name] ?? ["🕌 \(prayer.name.displayName) at"]
        let titlePhrase = titles.randomElement() ?? titles[0]
        content.title = "\(titlePhrase) \(timeString)"

        // EDUCATIONAL CONTENT: Get rotating Islamic quote/verse
        let islamicContent = await IslamicContentService.shared.getRotatingContent(for: prayer.name)

        // SUBTITLE: Show hadith/verse source (e.g., "Sahih Bukhari 645")
        if let source = islamicContent.subtitle {
            content.subtitle = source
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

        // DYNAMIC TITLE: Prayer emoji + name + time remaining
        let emoji = reminderEmojis[prayer.name] ?? "🕌"
        content.title = "\(emoji) \(prayer.name.displayName) in \(minutesBefore) min"

        // DYNAMIC BODY: Prayer-specific motivational message
        let message = reminderMessages[prayer.name] ?? "time to prepare for prayer"
        content.body = "\(prayer.name.displayName) is approaching - \(message)"

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

        // DYNAMIC TITLE: Rotating urgent phrases with prayer name
        let titleIndex = Int.random(in: 0..<urgentTitles.count)
        let titlePhrase = urgentTitles[titleIndex]

        // Special formatting for middle title (just emoji + prayer + "Ending Soon!")
        if titleIndex == 1 {
            content.title = "\(titlePhrase) \(prayer.displayName) Ending Soon!"
        } else {
            content.title = "\(titlePhrase) \(prayer.displayName)!"
        }

        // DYNAMIC BODY: 6 rotating motivational messages
        content.body = urgentMessages.randomElement() ?? urgentMessages[0]
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

    func saveNotificationSettings() {
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

// MARK: - Debug Helpers
#if DEBUG
extension NotificationService {
    /// Send a test notification (for debugging)
    /// Fires in 5 seconds to give time to lock the phone
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "If you see this, notifications are working! Auth: \(isAuthorized), Enabled: \(notificationsEnabled)"
        content.sound = .default
        content.categoryIdentifier = "PRAYER_TIME"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Test notification scheduled for 5 seconds from now")
        } catch {
            print("❌ Failed to schedule test notification: \(error)")
        }
    }

    /// Get debug info about pending notifications
    func getDebugInfo() async -> String {
        let pending = await center.pendingNotificationRequests()
        let prayerNotifs = pending.filter { $0.identifier.hasPrefix("prayer-") }
        let reminderNotifs = pending.filter { $0.identifier.hasPrefix("reminder-") }
        let urgentNotifs = pending.filter { $0.identifier.hasPrefix("urgent-") }

        return """
        📊 Notification Debug Info:
        - Permission: \(isAuthorized ? "✅ Granted" : "❌ Denied")
        - Enabled: \(notificationsEnabled ? "✅ Yes" : "❌ No")
        - Total pending: \(pending.count)
        - Prayer notifications: \(prayerNotifs.count)
        - Reminder notifications: \(reminderNotifs.count)
        - Urgent notifications: \(urgentNotifs.count)
        """
    }
}
#endif
