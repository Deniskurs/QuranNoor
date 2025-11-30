//
//  ReadingProgressRecord.swift
//  QuranNoor
//
//  SwiftData model for storing reading progress per verse
//

import Foundation
import SwiftData

/// SwiftData model for tracking individual verse reading progress
/// Replaces the UserDefaults-based readVerses dictionary
@Model
final class ReadingProgressRecord {
    // MARK: - Properties

    /// Unique verse identifier in format "surahNumber:verseNumber" (e.g., "1:1", "2:255")
    @Attribute(.unique) var verseId: String

    /// Surah number (1-114)
    var surahNumber: Int

    /// Verse number within the surah
    var verseNumber: Int

    /// Number of times this verse has been read
    var readCount: Int

    /// When the verse was first read
    var firstReadDate: Date

    /// When the verse was last read
    var lastReadDate: Date

    /// How the verse was marked as read
    var source: String  // "autoTracked", "manualMark", "imported"

    // MARK: - Initialization

    init(surahNumber: Int, verseNumber: Int, source: String = "autoTracked") {
        self.verseId = "\(surahNumber):\(verseNumber)"
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.readCount = 1
        self.firstReadDate = Date()
        self.lastReadDate = Date()
        self.source = source
    }

    /// Initialize from existing VerseReadData during migration
    init(verseId: String, data: VerseReadData) {
        self.verseId = verseId
        let parts = verseId.split(separator: ":")
        self.surahNumber = Int(parts.first ?? "1") ?? 1
        self.verseNumber = Int(parts.last ?? "1") ?? 1
        self.readCount = data.readCount
        self.firstReadDate = data.timestamp
        self.lastReadDate = data.timestamp
        self.source = data.source.rawValue
    }

    // MARK: - Methods

    /// Increment the read count and update last read date
    func markAsRead() {
        readCount += 1
        lastReadDate = Date()
    }
}

/// SwiftData model for storing global reading statistics
/// Replaces the UserDefaults-based ReadingProgress struct for global stats
@Model
final class ReadingStatsRecord {
    // MARK: - Properties

    /// Singleton identifier - always "global"
    @Attribute(.unique) var id: String

    /// Last read surah number
    var lastReadSurah: Int

    /// Last read verse number
    var lastReadVerse: Int

    /// Current reading streak in days
    var streakDays: Int

    /// Date of last reading activity
    var lastReadDate: Date

    // MARK: - Initialization

    init() {
        self.id = "global"
        self.lastReadSurah = 1
        self.lastReadVerse = 1
        self.streakDays = 0
        self.lastReadDate = Date.distantPast
    }

    /// Initialize from existing ReadingProgress during migration
    init(from progress: ReadingProgress) {
        self.id = "global"
        self.lastReadSurah = progress.lastReadSurah
        self.lastReadVerse = progress.lastReadVerse
        self.streakDays = progress.streakDays
        self.lastReadDate = progress.lastReadDate
    }
}
