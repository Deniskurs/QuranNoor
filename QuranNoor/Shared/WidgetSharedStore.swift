//
//  WidgetSharedStore.swift
//  QuranNoor
//
//  Bridge between the main app and widget extension via App Group UserDefaults.
//  Both targets must have the same App Group entitlement.
//

import Foundation

/// Shared data store for widget ↔ app communication via App Group
enum WidgetSharedStore {

    // MARK: - App Group

    /// App Group identifier — must match the entitlement in both targets
    static let appGroupID = "group.com.qurannoor.shared"

    /// Shared UserDefaults suite
    static let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            assertionFailure("App Group '\(appGroupID)' is not configured. Check entitlements.")
            return .standard
        }
        return defaults
    }()

    // MARK: - Keys

    private static let prayerEntryKey = "widget_prayer_entry"
    private static let readingEntryKey = "widget_reading_entry"

    // MARK: - Codecs (reuse to avoid repeated allocation)

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    // MARK: - Prayer Data

    /// Write prayer data from the main app
    static func savePrayerEntry(_ entry: WidgetPrayerEntry) {
        guard let data = try? encoder.encode(entry) else { return }
        defaults.set(data, forKey: prayerEntryKey)
    }

    /// Read prayer data from the widget
    static func loadPrayerEntry() -> WidgetPrayerEntry? {
        guard let data = defaults.data(forKey: prayerEntryKey),
              let entry = try? decoder.decode(WidgetPrayerEntry.self, from: data) else {
            return nil
        }
        return entry
    }

    // MARK: - Reading Progress Data

    /// Write reading progress from the main app
    static func saveReadingEntry(_ entry: WidgetReadingEntry) {
        guard let data = try? encoder.encode(entry) else { return }
        defaults.set(data, forKey: readingEntryKey)
    }

    /// Read reading progress from the widget
    static func loadReadingEntry() -> WidgetReadingEntry? {
        guard let data = defaults.data(forKey: readingEntryKey),
              let entry = try? decoder.decode(WidgetReadingEntry.self, from: data) else {
            return nil
        }
        return entry
    }
}
