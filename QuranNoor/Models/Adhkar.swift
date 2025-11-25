//
//  Adhkar.swift
//  QuranNoor
//
//  Data models for Islamic adhkar (remembrances)
//

import Foundation

// MARK: - Adhkar Category

/// Categories of adhkar
enum AdhkarCategory: String, CaseIterable, Identifiable, Codable {
    case morning = "morning"
    case evening = "evening"
    case afterPrayer = "after_prayer"
    case beforeSleep = "before_sleep"
    case waking = "waking"
    case general = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning:
            return "Morning Adhkar"
        case .evening:
            return "Evening Adhkar"
        case .afterPrayer:
            return "After Prayer"
        case .beforeSleep:
            return "Before Sleep"
        case .waking:
            return "Upon Waking"
        case .general:
            return "General Adhkar"
        }
    }

    var description: String {
        switch self {
        case .morning:
            return "Remembrances to be recited in the morning"
        case .evening:
            return "Remembrances to be recited in the evening"
        case .afterPrayer:
            return "Remembrances after completing obligatory prayers"
        case .beforeSleep:
            return "Remembrances before going to sleep"
        case .waking:
            return "Remembrances upon waking up"
        case .general:
            return "General remembrances for daily life"
        }
    }

    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .evening:
            return "sunset.fill"
        case .afterPrayer:
            return "hands.sparkles.fill"
        case .beforeSleep:
            return "moon.stars.fill"
        case .waking:
            return "sun.max.fill"
        case .general:
            return "star.fill"
        }
    }

    var recommendedTime: String {
        switch self {
        case .morning:
            return "After Fajr until sunrise"
        case .evening:
            return "After Asr until sunset"
        case .afterPrayer:
            return "Immediately after prayer"
        case .beforeSleep:
            return "Before sleeping"
        case .waking:
            return "Upon waking"
        case .general:
            return "Anytime"
        }
    }
}

// MARK: - Dhikr Item

/// Individual dhikr (remembrance)
struct Dhikr: Identifiable, Codable, Hashable {
    let id: UUID
    let arabicText: String
    let transliteration: String
    let translation: String
    let reference: String
    let repetitions: Int
    let benefits: String?
    let category: AdhkarCategory
    let order: Int

    init(
        id: UUID = UUID(),
        arabicText: String,
        transliteration: String,
        translation: String,
        reference: String,
        repetitions: Int = 1,
        benefits: String? = nil,
        category: AdhkarCategory,
        order: Int
    ) {
        self.id = id
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.reference = reference
        self.repetitions = repetitions
        self.benefits = benefits
        self.category = category
        self.order = order
    }
}

// MARK: - Adhkar Progress

/// Tracks user's progress with adhkar
struct AdhkarProgress: Codable {
    var completedToday: Set<UUID>
    var lastCompletionDate: Date
    var streak: Int
    var totalCompletions: Int

    init() {
        self.completedToday = []
        self.lastCompletionDate = Date()
        self.streak = 0
        self.totalCompletions = 0
    }

    /// Check if progress needs to be reset for new day
    mutating func checkAndResetForNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastCompletionDate) {
            // New day, reset today's completions
            if calendar.isDate(lastCompletionDate, inSameDayAs: Date().addingTimeInterval(-86400)) {
                // Completed yesterday, increment streak
                streak += 1
            } else {
                // Missed a day, reset streak
                streak = 0
            }
            completedToday = []
        }
    }

    /// Mark dhikr as completed
    mutating func markCompleted(dhikrId: UUID) {
        checkAndResetForNewDay()

        if !completedToday.contains(dhikrId) {
            completedToday.insert(dhikrId)
            totalCompletions += 1
            lastCompletionDate = Date()
        }
    }

    /// Check if dhikr is completed today
    func isCompleted(dhikrId: UUID) -> Bool {
        let calendar = Calendar.current
        guard calendar.isDateInToday(lastCompletionDate) else {
            return false
        }
        return completedToday.contains(dhikrId)
    }

    /// Get completion percentage for a category
    func completionPercentage(for category: AdhkarCategory, totalInCategory: Int) -> Double {
        guard totalInCategory > 0 else { return 0 }

        let calendar = Calendar.current
        guard calendar.isDateInToday(lastCompletionDate) else {
            return 0
        }

        // This would need to be calculated with actual dhikr IDs for the category
        return 0.0
    }
}

// MARK: - Adhkar Statistics

/// Statistics for adhkar completion
struct AdhkarStatistics {
    let totalDhikr: Int
    let completedToday: Int
    let completionPercentage: Double
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int

    var isFullyCompleted: Bool {
        completionPercentage >= 100.0
    }
}
