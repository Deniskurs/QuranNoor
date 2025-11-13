//
//  PrayerTimeAdjustmentService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Service for managing manual prayer time adjustments
//

import Foundation
import Observation

/// Service for managing prayer time adjustments (offsets)
@Observable
@MainActor
final class PrayerTimeAdjustmentService {

    // MARK: - Singleton
    static let shared = PrayerTimeAdjustmentService()

    // MARK: - Properties

    /// Current adjustments for each prayer (in minutes)
    private(set) var adjustments: [PrayerName: Int] = [:]

    /// Whether any adjustments are currently active
    var hasAdjustments: Bool {
        adjustments.values.contains { $0 != 0 }
    }

    /// Total number of prayers with adjustments
    var adjustedPrayerCount: Int {
        adjustments.values.filter { $0 != 0 }.count
    }

    // MARK: - Constants

    /// Minimum adjustment in minutes
    static let minAdjustment = -30

    /// Maximum adjustment in minutes
    static let maxAdjustment = 30

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let adjustments = "prayerTimeAdjustments"
        static let adjustmentHistory = "prayerTimeAdjustmentHistory"
    }

    // MARK: - Initialization

    private init() {
        loadAdjustments()
    }

    // MARK: - Public Methods

    /// Get adjustment for a specific prayer
    /// - Parameter prayer: The prayer to get adjustment for
    /// - Returns: Adjustment in minutes (negative = earlier, positive = later)
    func getAdjustment(for prayer: PrayerName) -> Int {
        return adjustments[prayer] ?? 0
    }

    /// Set adjustment for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer to adjust
    ///   - minutes: Number of minutes to adjust (-30 to +30)
    func setAdjustment(for prayer: PrayerName, minutes: Int) {
        let clampedMinutes = min(max(minutes, Self.minAdjustment), Self.maxAdjustment)

        let oldValue = adjustments[prayer] ?? 0
        adjustments[prayer] = clampedMinutes

        saveAdjustments()

        // Log change
        if clampedMinutes != oldValue {
            let change = clampedMinutes - oldValue
            print("⚙️ Adjusted \(prayer.displayName): \(formatAdjustment(clampedMinutes)) (\(change > 0 ? "+" : "")\(change) min)")

            // Post notification to refresh prayer times
            NotificationCenter.default.post(name: .prayerAdjustmentsChanged, object: nil)
        }
    }

    /// Reset adjustment for a specific prayer to 0
    /// - Parameter prayer: The prayer to reset
    func resetAdjustment(for prayer: PrayerName) {
        adjustments[prayer] = 0
        saveAdjustments()
        print("↩️ Reset \(prayer.displayName) adjustment to 0")

        // Post notification to refresh prayer times
        NotificationCenter.default.post(name: .prayerAdjustmentsChanged, object: nil)
    }

    /// Reset all adjustments to 0
    func resetAllAdjustments() {
        adjustments = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, 0) })
        saveAdjustments()
        print("↩️ Reset all prayer time adjustments")

        // Post notification to refresh prayer times
        NotificationCenter.default.post(name: .prayerAdjustmentsChanged, object: nil)
    }

    /// Apply adjustment to a date
    /// - Parameters:
    ///   - date: The original prayer time
    ///   - prayer: The prayer type
    /// - Returns: Adjusted date
    func applyAdjustment(to date: Date, for prayer: PrayerName) -> Date {
        let adjustment = getAdjustment(for: prayer)
        guard adjustment != 0 else { return date }

        return Calendar.current.date(byAdding: .minute, value: adjustment, to: date) ?? date
    }

    /// Apply adjustments to a DailyPrayerTimes object
    /// - Parameter prayerTimes: The original prayer times
    /// - Returns: New DailyPrayerTimes with adjustments applied
    func applyAdjustments(to prayerTimes: DailyPrayerTimes) -> DailyPrayerTimes {
        guard hasAdjustments else { return prayerTimes }

        // Apply adjustments to each prayer time individually
        let adjustedFajr = applyAdjustment(to: prayerTimes.fajr, for: .fajr)
        let adjustedDhuhr = applyAdjustment(to: prayerTimes.dhuhr, for: .dhuhr)
        let adjustedAsr = applyAdjustment(to: prayerTimes.asr, for: .asr)
        let adjustedMaghrib = applyAdjustment(to: prayerTimes.maghrib, for: .maghrib)
        let adjustedIsha = applyAdjustment(to: prayerTimes.isha, for: .isha)

        return DailyPrayerTimes(
            date: prayerTimes.date,
            fajr: adjustedFajr,
            sunrise: prayerTimes.sunrise,
            dhuhr: adjustedDhuhr,
            asr: adjustedAsr,
            maghrib: adjustedMaghrib,
            isha: adjustedIsha,
            imsak: prayerTimes.imsak,
            sunset: prayerTimes.sunset,
            midnight: prayerTimes.midnight,
            firstThird: prayerTimes.firstThird,
            lastThird: prayerTimes.lastThird
        )
    }

    /// Format adjustment for display
    /// - Parameter minutes: Adjustment in minutes
    /// - Returns: Formatted string (e.g., "+5 min", "-10 min", "No adjustment")
    func formatAdjustment(_ minutes: Int) -> String {
        if minutes == 0 {
            return "No adjustment"
        } else if minutes > 0 {
            return "+\(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    /// Get a description of the adjustment
    /// - Parameter minutes: Adjustment in minutes
    /// - Returns: Human-readable description
    func adjustmentDescription(_ minutes: Int) -> String {
        if minutes == 0 {
            return "Prayer time is not adjusted"
        } else if minutes > 0 {
            return "Prayer time is \(minutes) minute\(minutes != 1 ? "s" : "") later than calculated"
        } else {
            return "Prayer time is \(abs(minutes)) minute\(abs(minutes) != 1 ? "s" : "") earlier than calculated"
        }
    }

    /// Check if a specific prayer has an adjustment
    /// - Parameter prayer: The prayer to check
    /// - Returns: True if adjusted (non-zero)
    func isAdjusted(_ prayer: PrayerName) -> Bool {
        return getAdjustment(for: prayer) != 0
    }

    /// Get summary of all adjustments
    /// - Returns: Dictionary of prayer names to formatted adjustment strings
    func getAdjustmentSummary() -> [PrayerName: String] {
        return Dictionary(uniqueKeysWithValues: adjustments.map { prayer, minutes in
            (prayer, formatAdjustment(minutes))
        })
    }

    // MARK: - Private Methods

    private func saveAdjustments() {
        // Convert to dictionary with string keys for UserDefaults
        let adjustmentsDict = Dictionary(uniqueKeysWithValues: adjustments.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(adjustmentsDict, forKey: Keys.adjustments)
    }

    private func loadAdjustments() {
        guard let adjustmentsDict = UserDefaults.standard.dictionary(forKey: Keys.adjustments) as? [String: Int] else {
            // Initialize with zero adjustments
            adjustments = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, 0) })
            return
        }

        // Convert back to PrayerName keys
        adjustments = Dictionary(uniqueKeysWithValues: adjustmentsDict.compactMap { key, value in
            guard let prayerName = PrayerName(rawValue: key) else { return nil }
            return (prayerName, value)
        })

        // Ensure all prayers have entries
        for prayer in PrayerName.allCases {
            if adjustments[prayer] == nil {
                adjustments[prayer] = 0
            }
        }

        // Log loaded adjustments
        let activeAdjustments = adjustments.filter { $0.value != 0 }
        if !activeAdjustments.isEmpty {
            print("⚙️ Loaded prayer time adjustments:")
            for (prayer, minutes) in activeAdjustments.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                print("   \(prayer.displayName): \(formatAdjustment(minutes))")
            }
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    /// Posted when prayer time adjustments change
    static let prayerAdjustmentsChanged = Notification.Name("prayerAdjustmentsChanged")
}
