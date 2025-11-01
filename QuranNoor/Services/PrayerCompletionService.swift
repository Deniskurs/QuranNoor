//
//  PrayerCompletionService.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Tracks prayer completion with daily reset and persistence
//

import Foundation

/// Service for tracking daily prayer completion
@MainActor
class PrayerCompletionService {
    // MARK: - Singleton

    static let shared = PrayerCompletionService()

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard
    private let completionKey = "prayerCompletionData"
    private let lastResetDateKey = "lastResetDate"

    // MARK: - Private Init

    private init() {
        checkAndResetIfNeeded()
    }

    // MARK: - Public Methods

    /// Check if a prayer is marked as completed for today
    func isCompleted(_ prayer: PrayerName) -> Bool {
        let completions = loadTodayCompletions()
        return completions[prayer.rawValue] ?? false
    }

    /// Mark a prayer as completed or not completed
    func setCompleted(_ prayer: PrayerName, completed: Bool) {
        var completions = loadTodayCompletions()
        completions[prayer.rawValue] = completed
        saveCompletions(completions)

        print(completed ? "✅ \(prayer.displayName) marked as completed" : "⭕ \(prayer.displayName) marked as incomplete")
    }

    /// Toggle completion status for a prayer
    func toggleCompletion(_ prayer: PrayerName) {
        let currentStatus = isCompleted(prayer)
        setCompleted(prayer, completed: !currentStatus)
    }

    /// Get all completions for today
    func getTodayCompletions() -> [PrayerName: Bool] {
        let rawCompletions = loadTodayCompletions()
        var completions: [PrayerName: Bool] = [:]

        for prayer in PrayerName.allCases {
            completions[prayer] = rawCompletions[prayer.rawValue] ?? false
        }

        return completions
    }

    /// Get completion count for today
    func getTodayCompletionCount() -> Int {
        let completions = getTodayCompletions()
        return completions.values.filter { $0 }.count
    }

    /// Get completion percentage for today (0-100)
    func getTodayCompletionPercentage() -> Int {
        let count = getTodayCompletionCount()
        let total = PrayerName.allCases.count
        return total > 0 ? Int((Double(count) / Double(total)) * 100) : 0
    }

    /// Check if all prayers are completed today
    func isAllCompleted() -> Bool {
        getTodayCompletionCount() == PrayerName.allCases.count
    }

    /// Reset all completions (for testing or manual reset)
    func resetCompletions() {
        let emptyCompletions: [String: Bool] = [:]
        saveCompletions(emptyCompletions)
        setLastResetDate(Date())
        print("🔄 Prayer completions reset")
    }

    /// Get streak information (future enhancement)
    func getStreakDays() -> Int {
        // TODO: Implement streak tracking across multiple days
        // This would require storing historical completion data
        return 0
    }

    // MARK: - Private Methods

    /// Load today's completions from UserDefaults
    private func loadTodayCompletions() -> [String: Bool] {
        // Check if we need to reset for new day
        checkAndResetIfNeeded()

        guard let data = userDefaults.dictionary(forKey: completionKey) as? [String: Bool] else {
            return [:]
        }
        return data
    }

    /// Save completions to UserDefaults
    private func saveCompletions(_ completions: [String: Bool]) {
        userDefaults.set(completions, forKey: completionKey)
    }

    /// Check if we need to reset for a new day
    private func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get last reset date
        if let lastResetTimestamp = userDefaults.object(forKey: lastResetDateKey) as? TimeInterval {
            let lastResetDate = Date(timeIntervalSince1970: lastResetTimestamp)
            let lastResetDay = calendar.startOfDay(for: lastResetDate)

            // If last reset was not today, reset completions
            if today > lastResetDay {
                print("🌙 New day detected, resetting prayer completions")
                resetCompletions()
            }
        } else {
            // First time, set last reset date
            setLastResetDate(today)
        }
    }

    /// Set the last reset date
    private func setLastResetDate(_ date: Date) {
        userDefaults.set(date.timeIntervalSince1970, forKey: lastResetDateKey)
    }

    /// Get the last reset date
    private func getLastResetDate() -> Date? {
        guard let timestamp = userDefaults.object(forKey: lastResetDateKey) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
}

// MARK: - Statistics Extension

extension PrayerCompletionService {
    /// Get detailed completion statistics for today
    func getTodayStatistics() -> PrayerCompletionStatistics {
        let completions = getTodayCompletions()
        let completed = completions.values.filter { $0 }.count
        let total = PrayerName.allCases.count
        let percentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0

        return PrayerCompletionStatistics(
            completedCount: completed,
            totalCount: total,
            percentage: percentage,
            isAllCompleted: completed == total,
            completions: completions
        )
    }
}

// MARK: - Statistics Model

/// Statistics for prayer completions
struct PrayerCompletionStatistics {
    let completedCount: Int
    let totalCount: Int
    let percentage: Int
    let isAllCompleted: Bool
    let completions: [PrayerName: Bool]

    /// Formatted completion string (e.g., "3/5")
    var formattedCompletion: String {
        "\(completedCount)/\(totalCount)"
    }

    /// Formatted percentage string (e.g., "60%")
    var formattedPercentage: String {
        "\(percentage)%"
    }
}
