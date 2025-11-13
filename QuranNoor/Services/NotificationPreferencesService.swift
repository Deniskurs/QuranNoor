//
//  NotificationPreferencesService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Service for managing per-prayer notification preferences
//

import Foundation
import Observation

/// Service for managing notification preferences per prayer
@Observable
@MainActor
final class NotificationPreferencesService {

    // MARK: - Singleton
    static let shared = NotificationPreferencesService()

    // MARK: - Properties

    /// Whether notifications are enabled for each prayer
    private(set) var prayerNotificationsEnabled: [PrayerName: Bool] = [:]

    /// Whether urgent notifications are enabled for each prayer
    private(set) var urgentNotificationsEnabled: [PrayerName: Bool] = [:]

    /// Reminder time before prayer (in minutes, 0 = disabled)
    private(set) var reminderMinutes: [PrayerName: Int] = [:]

    /// Global notification toggle (master switch)
    var globalNotificationsEnabled: Bool {
        prayerNotificationsEnabled.values.contains(true)
    }

    // MARK: - Constants

    /// Available reminder times (in minutes before prayer)
    static let availableReminderTimes: [Int] = [0, 5, 10, 15, 20, 30]

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let prayerNotifications = "prayerNotificationsEnabled"
        static let urgentNotifications = "urgentNotificationsEnabled"
        static let reminderMinutes = "reminderMinutesBeforePrayer"
    }

    // MARK: - Initialization

    private init() {
        loadPreferences()
    }

    // MARK: - Public Methods

    /// Check if notifications are enabled for a specific prayer
    /// - Parameter prayer: The prayer to check
    /// - Returns: True if notifications are enabled
    func isNotificationEnabled(for prayer: PrayerName) -> Bool {
        return prayerNotificationsEnabled[prayer] ?? true // Default: enabled
    }

    /// Set notification enabled/disabled for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer to configure
    ///   - enabled: Whether notifications should be enabled
    func setNotificationEnabled(for prayer: PrayerName, enabled: Bool) {
        prayerNotificationsEnabled[prayer] = enabled
        savePreferences()
        print("🔔 \(prayer.displayName) notifications: \(enabled ? "enabled" : "disabled")")

        // Post notification to reschedule
        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    /// Check if urgent notifications are enabled for a specific prayer
    /// - Parameter prayer: The prayer to check
    /// - Returns: True if urgent notifications are enabled
    func isUrgentNotificationEnabled(for prayer: PrayerName) -> Bool {
        return urgentNotificationsEnabled[prayer] ?? true // Default: enabled
    }

    /// Set urgent notification enabled/disabled for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer to configure
    ///   - enabled: Whether urgent notifications should be enabled
    func setUrgentNotificationEnabled(for prayer: PrayerName, enabled: Bool) {
        urgentNotificationsEnabled[prayer] = enabled
        savePreferences()
        print("⚠️ \(prayer.displayName) urgent notifications: \(enabled ? "enabled" : "disabled")")

        // Post notification to reschedule
        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    /// Get reminder time for a specific prayer
    /// - Parameter prayer: The prayer to check
    /// - Returns: Minutes before prayer (0 = no reminder)
    func getReminderMinutes(for prayer: PrayerName) -> Int {
        return reminderMinutes[prayer] ?? 0 // Default: no reminder
    }

    /// Set reminder time for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer to configure
    ///   - minutes: Minutes before prayer (0 = no reminder)
    func setReminderMinutes(for prayer: PrayerName, minutes: Int) {
        let validMinutes = Self.availableReminderTimes.contains(minutes) ? minutes : 0
        reminderMinutes[prayer] = validMinutes
        savePreferences()

        if validMinutes > 0 {
            print("⏰ \(prayer.displayName) reminder: \(validMinutes) minutes before")
        } else {
            print("⏰ \(prayer.displayName) reminder: disabled")
        }

        // Post notification to reschedule
        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    /// Enable all prayers' notifications
    func enableAllNotifications() {
        for prayer in PrayerName.allCases {
            prayerNotificationsEnabled[prayer] = true
        }
        savePreferences()
        print("🔔 All prayer notifications enabled")

        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    /// Disable all prayers' notifications
    func disableAllNotifications() {
        for prayer in PrayerName.allCases {
            prayerNotificationsEnabled[prayer] = false
        }
        savePreferences()
        print("🔕 All prayer notifications disabled")

        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    /// Get count of enabled notifications
    /// - Returns: Number of prayers with notifications enabled
    func getEnabledNotificationCount() -> Int {
        return prayerNotificationsEnabled.values.filter { $0 }.count
    }

    /// Get count of enabled reminders
    /// - Returns: Number of prayers with reminders configured
    func getEnabledReminderCount() -> Int {
        return reminderMinutes.values.filter { $0 > 0 }.count
    }

    /// Reset all preferences to defaults (all enabled, no reminders)
    func resetToDefaults() {
        prayerNotificationsEnabled = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, true) })
        urgentNotificationsEnabled = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, true) })
        reminderMinutes = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, 0) })
        savePreferences()
        print("↩️ Reset notification preferences to defaults")

        NotificationCenter.default.post(name: .notificationPreferencesChanged, object: nil)
    }

    // MARK: - Private Methods

    private func savePreferences() {
        // Convert to dictionaries with string keys for UserDefaults
        let prayerNotifsDict = Dictionary(uniqueKeysWithValues: prayerNotificationsEnabled.map { ($0.key.rawValue, $0.value) })
        let urgentNotifsDict = Dictionary(uniqueKeysWithValues: urgentNotificationsEnabled.map { ($0.key.rawValue, $0.value) })
        let remindersDict = Dictionary(uniqueKeysWithValues: reminderMinutes.map { ($0.key.rawValue, $0.value) })

        UserDefaults.standard.set(prayerNotifsDict, forKey: Keys.prayerNotifications)
        UserDefaults.standard.set(urgentNotifsDict, forKey: Keys.urgentNotifications)
        UserDefaults.standard.set(remindersDict, forKey: Keys.reminderMinutes)
    }

    private func loadPreferences() {
        // Load prayer notifications
        if let prayerNotifsDict = UserDefaults.standard.dictionary(forKey: Keys.prayerNotifications) as? [String: Bool] {
            prayerNotificationsEnabled = Dictionary(uniqueKeysWithValues: prayerNotifsDict.compactMap { key, value in
                guard let prayerName = PrayerName(rawValue: key) else { return nil }
                return (prayerName, value)
            })
        }

        // Load urgent notifications
        if let urgentNotifsDict = UserDefaults.standard.dictionary(forKey: Keys.urgentNotifications) as? [String: Bool] {
            urgentNotificationsEnabled = Dictionary(uniqueKeysWithValues: urgentNotifsDict.compactMap { key, value in
                guard let prayerName = PrayerName(rawValue: key) else { return nil }
                return (prayerName, value)
            })
        }

        // Load reminder minutes
        if let remindersDict = UserDefaults.standard.dictionary(forKey: Keys.reminderMinutes) as? [String: Int] {
            reminderMinutes = Dictionary(uniqueKeysWithValues: remindersDict.compactMap { key, value in
                guard let prayerName = PrayerName(rawValue: key) else { return nil }
                return (prayerName, value)
            })
        }

        // Ensure all prayers have entries (default to enabled, no reminders)
        for prayer in PrayerName.allCases {
            if prayerNotificationsEnabled[prayer] == nil {
                prayerNotificationsEnabled[prayer] = true
            }
            if urgentNotificationsEnabled[prayer] == nil {
                urgentNotificationsEnabled[prayer] = true
            }
            if reminderMinutes[prayer] == nil {
                reminderMinutes[prayer] = 0
            }
        }

        // Log loaded preferences
        let enabledCount = getEnabledNotificationCount()
        let reminderCount = getEnabledReminderCount()
        print("🔔 Loaded notification preferences: \(enabledCount)/5 prayers enabled, \(reminderCount) reminders configured")
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    /// Posted when notification preferences change
    static let notificationPreferencesChanged = Notification.Name("notificationPreferencesChanged")
}
