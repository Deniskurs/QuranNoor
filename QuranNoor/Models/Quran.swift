//
//  Quran.swift
//  QuraanNoor
//
//  Quran data models
//

import Foundation


// MARK: - Surah
struct Surah: Identifiable, Codable, Sendable {
    let id: Int  // Surah number (1-114)
    let name: String  // Arabic name
    let englishName: String
    let englishNameTranslation: String
    let numberOfVerses: Int
    let revelationType: RevelationType

    enum RevelationType: String, Codable {
        case meccan = "Meccan"
        case medinan = "Medinan"
    }
}

// MARK: - Verse
struct Verse: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let number: Int  // Absolute verse number (1-6236)
    let surahNumber: Int
    let verseNumber: Int  // Verse number within surah
    let text: String  // Arabic text
    let juz: Int  // Juz number (1-30)

    init(number: Int, surahNumber: Int, verseNumber: Int, text: String, juz: Int) {
        self.id = "\(surahNumber):\(verseNumber)"
        self.number = number
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.text = text
        self.juz = juz
    }
}

// MARK: - Translation
struct Translation: Identifiable, Codable, Sendable {
    let id: String
    let verseNumber: Int
    let language: String
    let text: String
    let author: String

    init(verseNumber: Int, language: String, text: String, author: String) {
        self.id = "\(verseNumber):\(language):\(author)"
        self.verseNumber = verseNumber
        self.language = language
        self.text = text
        self.author = author
    }
}

// MARK: - Bookmark Category
/// Default bookmark categories available in the app
enum BookmarkCategory {
    static let allBookmarks = "All Bookmarks"
    static let favorites = "Favorites"
    static let study = "Study"
    static let memorization = "Memorization"

    /// All predefined categories (excluding "All Bookmarks" which is a filter, not a stored value)
    static let predefined: [String] = [allBookmarks, favorites, study, memorization]

    /// Display-friendly short label for filter pills (strips "All Bookmarks" to "All")
    static func shortLabel(for category: String) -> String {
        if category == allBookmarks { return "All" }
        return category
    }
}

// MARK: - Bookmark
struct Bookmark: Identifiable, Codable, Sendable {
    let id: UUID
    let surahNumber: Int
    let verseNumber: Int
    let timestamp: Date
    let note: String?
    let category: String

    init(surahNumber: Int, verseNumber: Int, note: String? = nil, category: String = "All Bookmarks") {
        self.id = UUID()
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.timestamp = Date()
        self.note = note
        self.category = category
    }

    init(id: UUID, surahNumber: Int, verseNumber: Int, note: String?, category: String, timestamp: Date) {
        self.id = id
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.note = note
        self.category = category
        self.timestamp = timestamp
    }
}

// MARK: - Verse Read Data
/// Detailed information about a verse read event
struct VerseReadData: Codable, Equatable, Sendable {
    let timestamp: Date  // When verse was first read
    var readCount: Int   // How many times verse has been read
    let source: ReadSource  // How the verse was marked as read

    enum ReadSource: String, Codable {
        case autoTracked    // Automatically tracked via scroll
        case manualMark     // Manually marked by user
        case imported       // Imported from backup
    }
}

// MARK: - Progress Snapshot
/// Snapshot for undo/redo functionality
struct ProgressSnapshot: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let actionType: ProgressAction
    let readVerses: [String: VerseReadData]  // Full snapshot of progress at this point
    let streakDays: Int
    let lastReadDate: Date

    enum ProgressAction: String, Codable {
        case manualMarkRead
        case manualMarkUnread
        case resetSurah
        case resetAll
        case importData
    }

    init(
        actionType: ProgressAction,
        readVerses: [String: VerseReadData],
        streakDays: Int,
        lastReadDate: Date
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.actionType = actionType
        self.readVerses = readVerses
        self.streakDays = streakDays
        self.lastReadDate = lastReadDate
    }
}

// MARK: - Surah Progress Stats
/// Statistics for a single surah
struct SurahProgressStats: Identifiable {
    let id = UUID()
    let surahNumber: Int
    let totalVerses: Int
    let readVerses: Int
    let completionPercentage: Double
    let lastReadDate: Date?
    let firstReadDate: Date?

    var isCompleted: Bool {
        return readVerses == totalVerses
    }
}

// MARK: - Reading Progress
// FIXME: M28 - readVerses dictionary is stored in UserDefaults and can grow large (up to 6236 entries).
// This should be fully migrated to SwiftData (ReadingProgressRecord) in a future version.
// The SwiftData migration is partially complete — see DataMigrationService.
struct ReadingProgress: Codable, Equatable, Sendable {
    var lastReadSurah: Int
    var lastReadVerse: Int
    var readVerses: [String: VerseReadData]  // Changed from Set<String> to Dictionary with metadata
    var streakDays: Int
    var lastReadDate: Date
    // progressHistory moved to ProgressHistoryManager (FileManager-backed storage)

    // Computed property - total unique verses read
    var totalVersesRead: Int {
        return readVerses.count
    }

    // Progress percentage (out of 6236 total verses)
    var completionPercentage: Double {
        return min(Double(totalVersesRead) / 6236.0 * 100, 100)
    }

    // Custom initializer for new progress
    init(
        lastReadSurah: Int = 1,
        lastReadVerse: Int = 1,
        readVerses: [String: VerseReadData] = [:],
        streakDays: Int = 0,
        lastReadDate: Date = Date.distantPast
    ) {
        self.lastReadSurah = lastReadSurah
        self.lastReadVerse = lastReadVerse
        self.readVerses = readVerses
        self.streakDays = streakDays
        self.lastReadDate = lastReadDate
    }

    // MARK: - Helper Methods

    /// Build a per-surah index in a single pass over readVerses.
    /// Returns [surahNumber: [(verseId, VerseReadData)]] — O(n) where n = total read verses.
    /// Call once and reuse the result when you need stats for multiple surahs.
    func buildSurahIndex() -> [Int: [(String, VerseReadData)]] {
        var index: [Int: [(String, VerseReadData)]] = [:]
        for (key, data) in readVerses {
            // Keys are "surahNumber:verseNumber" — parse surah number from prefix
            if let colonIndex = key.firstIndex(of: ":"),
               let surahNumber = Int(key[key.startIndex..<colonIndex]) {
                index[surahNumber, default: []].append((key, data))
            }
        }
        return index
    }

    /// Get progress statistics for a specific surah.
    /// For single-surah lookups this parses the surah number from each key (O(n) over readVerses).
    /// When computing stats for many surahs, prefer `buildSurahIndex()` + `surahProgressFromIndex()`.
    func surahProgress(surahNumber: Int, totalVerses: Int) -> SurahProgressStats {
        let prefix = "\(surahNumber):"
        var count = 0
        var latestDate: Date?
        var earliestDate: Date?

        for (key, data) in readVerses {
            guard key.hasPrefix(prefix) else { continue }
            // Verify it's an exact surah match (e.g., "1:" shouldn't match "11:")
            // hasPrefix handles this correctly since "11:1".hasPrefix("1:") is false
            count += 1
            if latestDate == nil || data.timestamp > latestDate! {
                latestDate = data.timestamp
            }
            if earliestDate == nil || data.timestamp < earliestDate! {
                earliestDate = data.timestamp
            }
        }

        return SurahProgressStats(
            surahNumber: surahNumber,
            totalVerses: totalVerses,
            readVerses: count,
            completionPercentage: Double(count) / Double(totalVerses) * 100,
            lastReadDate: latestDate,
            firstReadDate: earliestDate
        )
    }

    /// Build SurahProgressStats from a pre-built index entry (O(m) where m = verses in that surah).
    func surahProgressFromIndex(surahNumber: Int, totalVerses: Int, indexEntry: [(String, VerseReadData)]) -> SurahProgressStats {
        let count = indexEntry.count
        let latestDate = indexEntry.map(\.1.timestamp).max()
        let earliestDate = indexEntry.map(\.1.timestamp).min()

        return SurahProgressStats(
            surahNumber: surahNumber,
            totalVerses: totalVerses,
            readVerses: count,
            completionPercentage: Double(count) / Double(totalVerses) * 100,
            lastReadDate: latestDate,
            firstReadDate: earliestDate
        )
    }

    /// Check if specific verse is read
    func isVerseRead(surahNumber: Int, verseNumber: Int) -> Bool {
        let verseId = "\(surahNumber):\(verseNumber)"
        return readVerses[verseId] != nil
    }

    /// Get read timestamp for specific verse
    func verseReadTimestamp(surahNumber: Int, verseNumber: Int) -> Date? {
        let verseId = "\(surahNumber):\(verseNumber)"
        return readVerses[verseId]?.timestamp
    }

    // MARK: - Migration Support
    enum CodingKeys: String, CodingKey {
        case lastReadSurah
        case lastReadVerse
        case readVerses
        case streakDays
        case lastReadDate
        case progressHistory
        case totalVersesRead  // Old format field
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode common fields with defaults
        lastReadSurah = try container.decodeIfPresent(Int.self, forKey: .lastReadSurah) ?? 1
        lastReadVerse = try container.decodeIfPresent(Int.self, forKey: .lastReadVerse) ?? 1
        streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastReadDate = try container.decodeIfPresent(Date.self, forKey: .lastReadDate) ?? Date.distantPast

        // Migration: Extract progressHistory and move to ProgressHistoryManager
        if let oldHistory = try? container.decodeIfPresent([ProgressSnapshot].self, forKey: .progressHistory), !oldHistory.isEmpty {
            #if DEBUG
            print("⚠️ Found \(oldHistory.count) snapshots in old format - will migrate to ProgressHistoryManager")
            #endif
            // ProgressHistoryManager will handle this migration in QuranService
        }

        // Migration logic: Handle both old Set<String> and new [String: VerseReadData]
        if let newFormat = try? container.decode([String: VerseReadData].self, forKey: .readVerses) {
            // New format with metadata - use as is
            readVerses = newFormat
            #if DEBUG
            print("✅ Loaded reading progress: \(newFormat.count) verses (enhanced format)")
            #endif
        } else if let oldFormat = try? container.decode(Set<String>.self, forKey: .readVerses) {
            // Old format (Set<String>) - migrate to new format
            readVerses = [:]
            let migrationDate = Date()  // Use current date as placeholder
            for verseId in oldFormat {
                readVerses[verseId] = VerseReadData(
                    timestamp: migrationDate,
                    readCount: 1,
                    source: .autoTracked
                )
            }
            #if DEBUG
            print("✅ Migrated \(oldFormat.count) verses from Set to Dictionary format")
            #endif
        } else if (try? container.decode(Int.self, forKey: .totalVersesRead)) != nil {
            // Very old format - reset progress
            readVerses = [:]
            #if DEBUG
            print("⚠️ Legacy format detected, resetting progress (streak preserved: \(streakDays) days)")
            #endif
        } else {
            // No data - start fresh
            readVerses = [:]
            #if DEBUG
            print("ℹ️ No progress data, starting fresh")
            #endif
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastReadSurah, forKey: .lastReadSurah)
        try container.encode(lastReadVerse, forKey: .lastReadVerse)
        try container.encode(readVerses, forKey: .readVerses)
        try container.encode(streakDays, forKey: .streakDays)
        try container.encode(lastReadDate, forKey: .lastReadDate)
        // progressHistory is no longer stored here - moved to ProgressHistoryManager
        // Don't encode totalVersesRead - it's computed
    }
}
