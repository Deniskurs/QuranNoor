//
//  DailyStats.swift
//  QuranNoor
//
//  Created by Claude Code
//  Home page daily statistics model
//

import Foundation

/// Daily statistics for user activity tracking
struct DailyStats: Codable, Hashable {
    /// Current reading streak in days
    let streakDays: Int

    /// Total verses read today
    let versesReadToday: Int

    /// Prayers completed today (0-5)
    let prayersCompleted: Int

    /// Total reading time in minutes
    let readingTimeMinutes: Int

    /// Last read surah name (for quick resume)
    let lastReadSurahName: String?

    /// Last read verse number
    let lastReadVerseNumber: Int?

    /// Completion percentage for current Juz
    let juzProgress: Double

    /// Current Juz number (1-30)
    let currentJuz: Int

    /// Total verses read (all time)
    let totalVersesRead: Int

    /// Overall Quran completion percentage (0.0-1.0)
    let overallCompletion: Double

    init(
        streakDays: Int = 0,
        versesReadToday: Int = 0,
        prayersCompleted: Int = 0,
        readingTimeMinutes: Int = 0,
        lastReadSurahName: String? = nil,
        lastReadVerseNumber: Int? = nil,
        juzProgress: Double = 0.0,
        currentJuz: Int = 1,
        totalVersesRead: Int = 0,
        overallCompletion: Double = 0.0
    ) {
        self.streakDays = streakDays
        self.versesReadToday = versesReadToday
        self.prayersCompleted = prayersCompleted
        self.readingTimeMinutes = readingTimeMinutes
        self.lastReadSurahName = lastReadSurahName
        self.lastReadVerseNumber = lastReadVerseNumber
        self.juzProgress = juzProgress
        self.currentJuz = currentJuz
        self.totalVersesRead = totalVersesRead
        self.overallCompletion = overallCompletion
    }

    // MARK: - Computed Properties

    /// Formatted streak text for display
    var streakText: String {
        if streakDays == 0 {
            return "Start your streak!"
        } else if streakDays == 1 {
            return "1 day streak"
        } else {
            return "\(streakDays) day streak"
        }
    }

    /// Formatted verses read text
    var versesReadText: String {
        if versesReadToday == 0 {
            return "No verses yet"
        } else if versesReadToday == 1 {
            return "1 verse"
        } else {
            return "\(versesReadToday) verses"
        }
    }

    /// Formatted prayer completion text
    var prayersCompletedText: String {
        "\(prayersCompleted)/5"
    }

    /// Formatted reading time text
    var readingTimeText: String {
        if readingTimeMinutes == 0 {
            return "No reading today"
        } else if readingTimeMinutes < 60 {
            return "\(readingTimeMinutes)m"
        } else {
            let hours = readingTimeMinutes / 60
            let minutes = readingTimeMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }

    /// Formatted last read location
    var lastReadLocation: String {
        guard let surahName = lastReadSurahName, let verseNum = lastReadVerseNumber else {
            return "Start reading"
        }
        return "\(surahName), Verse \(verseNum)"
    }

    /// Progress percentage as string (0-100%)
    var progressPercentage: String {
        // overallCompletion is already 0-100 (e.g., 5.5 for 5.5%)
        // Don't multiply by 100 again!
        let percentage = Int(overallCompletion)
        return "\(percentage)%"
    }

    /// Is the user on a streak?
    var hasStreak: Bool {
        streakDays > 0
    }

    /// Has the user read anything today?
    var hasReadToday: Bool {
        versesReadToday > 0
    }

    /// Has the user completed all prayers today?
    var hasCompletedAllPrayers: Bool {
        prayersCompleted >= 5
    }
}

// MARK: - Mock Data for Previews
extension DailyStats {
    static let preview = DailyStats(
        streakDays: 7,
        versesReadToday: 15,
        prayersCompleted: 4,
        readingTimeMinutes: 23,
        lastReadSurahName: "Al-Baqarah",
        lastReadVerseNumber: 255,
        juzProgress: 0.4,
        currentJuz: 3,
        totalVersesRead: 342,
        overallCompletion: 5.5  // 342/6236 * 100 ≈ 5.5%
    )

    static let emptyState = DailyStats()

    static let activeUser = DailyStats(
        streakDays: 30,
        versesReadToday: 50,
        prayersCompleted: 5,
        readingTimeMinutes: 65,
        lastReadSurahName: "Al-Kahf",
        lastReadVerseNumber: 110,
        juzProgress: 0.75,
        currentJuz: 15,
        totalVersesRead: 1823,
        overallCompletion: 29.2  // 1823/6236 * 100 ≈ 29.2%
    )
}
