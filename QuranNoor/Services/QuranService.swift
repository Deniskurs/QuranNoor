//
//  QuranService.swift
//  QuranNoor
//
//  Manages Quran data from AlQuran.cloud API, bookmarks, and reading progress
//

import Foundation
import Combine

// MARK: - API Response Models

struct QuranSurahListResponse: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
}

struct QuranSurahResponse: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    let ayahs: [QuranAyahResponse]
    let edition: QuranEditionResponse?  // Edition info returned by API
}

// MARK: - Sajda Info
/// Represents sajda (prostration) information which can be either a boolean or detailed object
enum SajdaInfo: Codable {
    case none                      // When sajda is false
    case detail(SajdaDetail)       // When sajda is an object with details

    struct SajdaDetail: Codable {
        let id: Int
        let recommended: Bool
        let obligatory: Bool
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as Bool first
        if let _ = try? container.decode(Bool.self) {
            self = .none
            return
        }

        // Try to decode as detailed object
        if let detail = try? container.decode(SajdaDetail.self) {
            self = .detail(detail)
            return
        }

        // Default to none if both fail
        self = .none
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encode(false)
        case .detail(let detail):
            try container.encode(detail)
        }
    }

    /// Check if this verse has a sajda
    var hasSajda: Bool {
        if case .detail = self {
            return true
        }
        return false
    }
}

struct QuranAyahResponse: Codable {
    let number: Int
    let text: String
    let numberInSurah: Int
    let juz: Int
    let manzil: Int?
    let page: Int?
    let ruku: Int?
    let hizbQuarter: Int?
    let sajda: SajdaInfo?  // Can be Bool (false) or detailed object
    let audio: String?
    let audioSecondary: [String]?

    // Additional fields when fetching single verse
    let edition: QuranEditionResponse?
    let surah: QuranSurahInfo?

    // Nested surah info for single verse response
    struct QuranSurahInfo: Codable {
        let number: Int
        let name: String
        let englishName: String
        let englishNameTranslation: String
        let numberOfAyahs: Int
        let revelationType: String
    }
}

struct QuranEditionResponse: Codable {
    let identifier: String
    let language: String
    let name: String
    let englishName: String
    let format: String
    let type: String
}

// MARK: - Quran Service
class QuranService: ObservableObject {
    // MARK: - Singleton
    static let shared = QuranService()

    // MARK: - Published Properties
    @Published private(set) var readingProgress: ReadingProgress?
    @Published private(set) var bookmarks: [Bookmark] = []

    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "quran_bookmarks"
    private let progressKey = "reading_progress"

    // Default editions
    private let arabicEdition = "quran-simple" // Simple Arabic text
    private let translationEdition = "en.sahih" // Sahih International English
    private let audioEdition = "ar.alafasy" // Alafasy recitation

    // Cache keys
    private let surahListCacheKey = "surah_list"
    private func surahCacheKey(_ number: Int) -> String {
        return "surah_\(number)"
    }
    private func translationCacheKey(_ surahNumber: Int, _ verseNumber: Int) -> String {
        return "translation_\(surahNumber)_\(verseNumber)"
    }

    // MARK: - Initialization

    private init() {
        // Load initial data from UserDefaults
        self.readingProgress = loadProgressFromDefaults()
        self.bookmarks = loadBookmarksFromDefaults()

        // Migrate old progress history to ProgressHistoryManager (one-time migration)
        migrateProgressHistoryIfNeeded()

        print("✅ QuranService.shared initialized")
    }

    private func loadProgressFromDefaults() -> ReadingProgress? {
        guard let data = userDefaults.data(forKey: progressKey) else {
            print("⚠️ No progress data found in UserDefaults")
            return nil
        }

        do {
            let progress = try JSONDecoder().decode(ReadingProgress.self, from: data)
            print("✅ Loaded progress from defaults: \(progress.readVerses.count) verses")
            return progress
        } catch {
            print("❌ Failed to decode progress: \(error)")
            return nil
        }
    }

    /// Migrate old progressHistory from UserDefaults to ProgressHistoryManager (one-time migration)
    private func migrateProgressHistoryIfNeeded() {
        // Check if we've already migrated
        let migrationKey = "progressHistoryMigrated_v2"
        guard !userDefaults.bool(forKey: migrationKey) else {
            print("ℹ️ Progress history already migrated to ProgressHistoryManager")
            return
        }

        // Try to load old format with progressHistory
        guard let data = userDefaults.data(forKey: progressKey) else { return }

        do {
            // Temporarily decode to a structure that includes progressHistory
            struct OldReadingProgress: Codable {
                var readVerses: [String: VerseReadData]
                var progressHistory: [ProgressSnapshot]?
            }

            let decoder = JSONDecoder()
            let oldFormat = try decoder.decode(OldReadingProgress.self, from: data)

            if let history = oldFormat.progressHistory, !history.isEmpty {
                print("🔄 Migrating \(history.count) snapshots to ProgressHistoryManager...")

                // Migrate to FileManager
                ProgressHistoryManager.shared.migrateFromUserDefaults(oldHistory: history)

                // Re-save progress without history (will be much smaller)
                if var progress = readingProgress {
                    saveProgress(progress)
                    print("✅ Saved cleaned progress to UserDefaults (removed \(history.count) snapshots)")
                }
            }

            // Mark migration as complete
            userDefaults.set(true, forKey: migrationKey)
            print("✅ Progress history migration complete")
        } catch {
            // If decoding fails, it's already in the new format
            print("ℹ️ No old progress history to migrate: \(error.localizedDescription)")
            userDefaults.set(true, forKey: migrationKey)
        }
    }

    private func loadBookmarksFromDefaults() -> [Bookmark] {
        guard let data = userDefaults.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }

    // MARK: - Surah Methods

    /// Get list of all 114 surahs from API
    func getSurahs() async throws -> [Surah] {
        // Try to fetch from API with caching
        do {
            let response: [QuranSurahListResponse] = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/surah",
                cacheKey: surahListCacheKey
            )

            return response.map { item in
                Surah(
                    id: item.number,
                    name: item.name,
                    englishName: item.englishName,
                    englishNameTranslation: item.englishNameTranslation,
                    numberOfVerses: item.numberOfAyahs,
                    revelationType: item.revelationType.lowercased() == "meccan" ? .meccan : .medinan
                )
            }
        } catch {
            print("Failed to fetch surahs from API: \(error)")
            // Return fallback sample data if API fails
            return getSampleSurahs()
        }
    }

    /// Get verses for a specific surah from API
    func getVerses(forSurah surahNumber: Int) async throws -> [Verse] {
        do {
            let response: QuranSurahResponse = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/surah/\(surahNumber)/\(arabicEdition)",
                cacheKey: surahCacheKey(surahNumber)
            )

            return response.ayahs.map { ayah in
                Verse(
                    number: ayah.number,
                    surahNumber: surahNumber,
                    verseNumber: ayah.numberInSurah,
                    text: ayah.text,
                    juz: ayah.juz
                )
            }
        } catch {
            print("Failed to fetch verses from API: \(error)")
            // Return fallback sample data if API fails
            return getSampleVerses(forSurah: surahNumber)
        }
    }

    /// Get translation for a verse from API
    func getTranslation(forVerse verse: Verse, edition: String = "en.sahih") async throws -> Translation {
        do {
            let response: QuranAyahResponse = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/ayah/\(verse.surahNumber):\(verse.verseNumber)/\(edition)",
                cacheKey: translationCacheKey(verse.surahNumber, verse.verseNumber)
            )

            return Translation(
                verseNumber: verse.number,
                language: "English",
                text: response.text,
                author: "Sahih International"
            )
        } catch {
            print("Failed to fetch translation from API: \(error)")
            // Return fallback translation if API fails
            return getSampleTranslation(forVerse: verse)
        }
    }

    /// Get audio URL for a specific verse
    func getAudioURL(forVerse verse: Verse) async throws -> String? {
        do {
            let response: QuranAyahResponse = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/ayah/\(verse.surahNumber):\(verse.verseNumber)/\(audioEdition)"
            )
            return response.audio
        } catch {
            print("Failed to fetch audio URL: \(error)")
            return nil
        }
    }

    /// Get available translation editions
    func getAvailableTranslations() async throws -> [QuranEditionResponse] {
        do {
            let response: [QuranEditionResponse] = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/edition?format=text&language=en",
                cacheKey: "translation_editions"
            )
            return response
        } catch {
            print("Failed to fetch translation editions: \(error)")
            return []
        }
    }

    /// Clear all cached Quran data (useful for debugging or forcing fresh data)
    func clearAllCache() {
        print("🗑️  Clearing all Quran cache...")

        // Clear surah list cache
        userDefaults.removeObject(forKey: "cache_\(surahListCacheKey)")

        // Clear all surah caches (1-114)
        for surahNumber in 1...114 {
            userDefaults.removeObject(forKey: "cache_\(surahCacheKey(surahNumber))")
        }

        // Clear translation caches - this is trickier since we don't know all combinations
        // So we'll use the APIClient's clearCache method for those
        apiClient.clearCache()

        print("✅ Cache cleared successfully")
    }

    /// Preload entire Quran data (call this on first app launch)
    func preloadQuranData() async {
        print("📖 Starting Quran data preload...")

        // Load all surahs first
        do {
            let surahs = try await getSurahs()
            print("✅ Loaded \(surahs.count) surahs list")
        } catch {
            print("❌ Failed to load surahs list: \(error)")
        }

        // Load first 10 surahs and last 4 surahs (most commonly read)
        let prioritySurahs = Array(1...10) + [111, 112, 113, 114]
        var successCount = 0
        var failedSurahs: [Int] = []

        for surahNumber in prioritySurahs {
            do {
                let verses = try await getVerses(forSurah: surahNumber)
                // Check if we got real data or fallback error message
                if verses.count == 1 && verses[0].text.contains("Failed to load") {
                    print("❌ Surah \(surahNumber): Got fallback error message")
                    failedSurahs.append(surahNumber)
                } else {
                    print("✅ Surah \(surahNumber): Loaded \(verses.count) verses")
                    // Note: Translations are loaded on-demand to avoid API rate limiting
                    successCount += 1
                }
            } catch {
                print("❌ Surah \(surahNumber): \(error)")
                failedSurahs.append(surahNumber)
            }
        }

        print("📊 Preload Summary: \(successCount)/\(prioritySurahs.count) surahs loaded successfully")
        if !failedSurahs.isEmpty {
            print("⚠️  Failed surahs: \(failedSurahs)")
        }
        print("✅ Preload process completed")
    }

    // MARK: - Bookmarks

    /// Get all bookmarks
    func getBookmarks() -> [Bookmark] {
        guard let data = userDefaults.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }

    /// Add a bookmark
    func addBookmark(surahNumber: Int, verseNumber: Int, note: String? = nil) {
        var bookmarks = getBookmarks()
        let bookmark = Bookmark(surahNumber: surahNumber, verseNumber: verseNumber, note: note)
        bookmarks.append(bookmark)
        saveBookmarks(bookmarks)
    }

    /// Remove a bookmark
    func removeBookmark(id: UUID) {
        var bookmarks = getBookmarks()
        bookmarks.removeAll { $0.id == id }
        saveBookmarks(bookmarks)
    }

    /// Check if verse is bookmarked
    func isBookmarked(surahNumber: Int, verseNumber: Int) -> Bool {
        return getBookmarks().contains { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }
    }

    private func saveBookmarks(_ bookmarks: [Bookmark]) {
        // Update @Published property immediately for UI responsiveness
        self.bookmarks = bookmarks

        // Capture values needed for background task
        let key = bookmarksKey
        let count = bookmarks.count

        // Perform encoding and UserDefaults write on background queue
        Task.detached(priority: .utility) {
            if let encoded = try? JSONEncoder().encode(bookmarks) {
                UserDefaults.standard.set(encoded, forKey: key)
                print("✅ Bookmarks saved to disk: \(count) bookmarks")
            }
        }

        print("✅ Bookmarks published to observers: \(count) bookmarks")
    }

    // MARK: - Reading Progress

    /// Get reading progress
    func getReadingProgress() -> ReadingProgress {
        guard let data = userDefaults.data(forKey: progressKey) else {
            print("⚠️ No progress data found in UserDefaults - returning default")
            return ReadingProgress(
                lastReadSurah: 1,
                lastReadVerse: 1,
                readVerses: [:],
                streakDays: 0,
                lastReadDate: Date.distantPast
            )
        }

        do {
            let progress = try JSONDecoder().decode(ReadingProgress.self, from: data)
            print("✅ Loaded progress: \(progress.readVerses.count) verses, streak: \(progress.streakDays) days")
            return progress
        } catch {
            print("❌ Failed to decode progress: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   Saved data: \(jsonString)")
            }
            print("   Returning default progress")
            return ReadingProgress(
                lastReadSurah: 1,
                lastReadVerse: 1,
                readVerses: [:],
                streakDays: 0,
                lastReadDate: Date.distantPast
            )
        }
    }

    /// Update reading progress (called by auto-tracking system)
    func updateReadingProgress(surahNumber: Int, verseNumber: Int) {
        var progress = getReadingProgress()

        // Create unique verse identifier
        let verseId = "\(surahNumber):\(verseNumber)"

        // Check if this is a new verse or update existing
        if let existingData = progress.readVerses[verseId] {
            // Verse already read - increment read count
            progress.readVerses[verseId] = VerseReadData(
                timestamp: existingData.timestamp,  // Keep original timestamp
                readCount: existingData.readCount + 1,
                source: existingData.source  // Keep original source
            )
        } else {
            // New verse - add with timestamp
            progress.readVerses[verseId] = VerseReadData(
                timestamp: Date(),
                readCount: 1,
                source: .autoTracked
            )
        }

        // Always update last read position
        progress.lastReadSurah = surahNumber
        progress.lastReadVerse = verseNumber

        // Update streak logic
        let calendar = Calendar.current
        let today = Date()

        // Check if this is the first ever read OR if streak is at 0 (needs initialization)
        if progress.lastReadDate == Date.distantPast || progress.streakDays == 0 {
            // First time reading OR streak was reset to 0 - start streak at 1
            progress.streakDays = 1
            progress.lastReadDate = today
        } else if calendar.isDateInToday(progress.lastReadDate) {
            // Already read today, no change to streak
            // But update the timestamp
            progress.lastReadDate = today
        } else if calendar.isDateInYesterday(progress.lastReadDate) {
            // Reading for the first time today after reading yesterday - increment streak
            progress.streakDays += 1
            progress.lastReadDate = today
        } else {
            // Gap in reading - streak broken, restart at 1
            progress.streakDays = 1
            progress.lastReadDate = today
        }

        // Save progress
        saveProgress(progress)
        print("✅ Auto-tracked: \(verseId), total: \(progress.readVerses.count) verses, streak: \(progress.streakDays) days")
    }

    // MARK: - Progress Management

    /// Manually mark a verse as read
    func markVerseAsRead(surahNumber: Int, verseNumber: Int, manual: Bool = true) {
        var progress = getReadingProgress()
        let verseId = "\(surahNumber):\(verseNumber)"

        // Create snapshot if manual action (stored in ProgressHistoryManager - FileManager-backed)
        if manual {
            let snapshot = ProgressSnapshot(
                actionType: .manualMarkRead,
                readVerses: progress.readVerses,
                streakDays: progress.streakDays,
                lastReadDate: progress.lastReadDate
            )
            ProgressHistoryManager.shared.addSnapshot(snapshot)
        }

        if let existingData = progress.readVerses[verseId] {
            // Increment read count
            progress.readVerses[verseId] = VerseReadData(
                timestamp: existingData.timestamp,
                readCount: existingData.readCount + 1,
                source: manual ? .manualMark : existingData.source
            )
        } else {
            // First time reading
            progress.readVerses[verseId] = VerseReadData(
                timestamp: Date(),
                readCount: 1,
                source: manual ? .manualMark : .autoTracked
            )
        }

        saveProgress(progress)
        print("✅ Manually marked \(verseId) as read")
    }

    /// Manually mark a verse as unread
    func markVerseAsUnread(surahNumber: Int, verseNumber: Int) {
        var progress = getReadingProgress()
        let verseId = "\(surahNumber):\(verseNumber)"

        // Create snapshot (stored in ProgressHistoryManager - FileManager-backed)
        let snapshot = ProgressSnapshot(
            actionType: .manualMarkUnread,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        progress.readVerses.removeValue(forKey: verseId)
        saveProgress(progress)
        print("❌ Marked \(verseId) as unread")
    }

    /// Toggle verse read status
    func toggleVerseReadStatus(surahNumber: Int, verseNumber: Int) {
        let progress = getReadingProgress()
        let verseId = "\(surahNumber):\(verseNumber)"

        if progress.readVerses[verseId] != nil {
            markVerseAsUnread(surahNumber: surahNumber, verseNumber: verseNumber)
        } else {
            markVerseAsRead(surahNumber: surahNumber, verseNumber: verseNumber, manual: true)
        }
    }

    /// Reset all reading progress
    func resetAllProgress() {
        let progress = ReadingProgress(
            lastReadSurah: 1,
            lastReadVerse: 1,
            readVerses: [:],
            streakDays: 0,
            lastReadDate: Date.distantPast
            // progressHistory is now managed by ProgressHistoryManager
        )
        saveProgress(progress)
        ProgressHistoryManager.shared.clearHistory()  // Also clear undo history
        print("🔄 All reading progress reset")
    }

    /// Reset progress for a specific surah
    func resetSurahProgress(surahNumber: Int) {
        var progress = getReadingProgress()

        // Create snapshot (stored in ProgressHistoryManager - FileManager-backed)
        let snapshot = ProgressSnapshot(
            actionType: .resetSurah,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        // Remove all verses from this surah
        progress.readVerses = progress.readVerses.filter { verseId, _ in
            !verseId.starts(with: "\(surahNumber):")
        }

        saveProgress(progress)
        print("🔄 Reset progress for Surah \(surahNumber)")
    }

    /// Reset progress for specific verse range
    func resetVerseRange(surahNumber: Int, fromVerse: Int, toVerse: Int) {
        var progress = getReadingProgress()

        // Create snapshot (stored in ProgressHistoryManager - FileManager-backed)
        let snapshot = ProgressSnapshot(
            actionType: .resetSurah,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        // Remove verses in range
        for verseNumber in fromVerse...toVerse {
            let verseId = "\(surahNumber):\(verseNumber)"
            progress.readVerses.removeValue(forKey: verseId)
        }

        saveProgress(progress)
        print("🔄 Reset verses \(fromVerse)-\(toVerse) in Surah \(surahNumber)")
    }

    /// Undo last progress action
    @discardableResult
    func undoLastAction() -> Bool {
        guard let lastSnapshot = ProgressHistoryManager.shared.getLastSnapshot() else {
            print("⚠️ No actions to undo")
            return false
        }

        // Restore from snapshot
        var progress = ReadingProgress(
            lastReadSurah: lastSnapshot.readVerses.keys.compactMap { verseId -> Int? in
                let components = verseId.split(separator: ":")
                return components.first.flatMap { Int($0) }
            }.max() ?? 1,
            lastReadVerse: 1,
            readVerses: lastSnapshot.readVerses,
            streakDays: lastSnapshot.streakDays,
            lastReadDate: lastSnapshot.lastReadDate
        )

        saveProgress(progress)
        ProgressHistoryManager.shared.removeLastSnapshot()
        print("⏪ Undone action: \(lastSnapshot.actionType.rawValue)")
        return true
    }

    /// Check if undo is available
    func canUndo() -> Bool {
        return ProgressHistoryManager.shared.getLastSnapshot() != nil
    }

    /// Get undo history count
    func undoHistoryCount() -> Int {
        return ProgressHistoryManager.shared.history.count
    }

    /// Clear undo history (to save space)
    func clearUndoHistory() {
        ProgressHistoryManager.shared.clearHistory()
        print("🗑️ Cleared undo history")
    }

    /// Check if a verse is marked as read
    func isVerseRead(surahNumber: Int, verseNumber: Int) -> Bool {
        let progress = getReadingProgress()
        return progress.isVerseRead(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Get verse read timestamp
    func getVerseReadTimestamp(surahNumber: Int, verseNumber: Int) -> Date? {
        let progress = getReadingProgress()
        return progress.verseReadTimestamp(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Get surah-specific statistics
    func getSurahStatistics(surahNumber: Int, totalVerses: Int) -> SurahProgressStats {
        // Use cached readingProgress to avoid repeated UserDefaults reads (performance optimization)
        let progress = readingProgress ?? getReadingProgress()
        return progress.surahProgress(surahNumber: surahNumber, totalVerses: totalVerses)
    }

    // MARK: - Private Helper Methods

    /// Save progress to UserDefaults and publish changes
    private func saveProgress(_ progress: ReadingProgress) {
        // Update @Published property immediately for UI responsiveness
        self.readingProgress = progress

        // Capture values needed for background task
        let key = progressKey
        let count = progress.readVerses.count

        // Encode on main thread (required for Encodable conformance)
        do {
            let encoded = try JSONEncoder().encode(progress)

            // Perform UserDefaults write on background queue (encoding already done)
            Task.detached(priority: .utility) {
                UserDefaults.standard.set(encoded, forKey: key)
                print("✅ Progress saved to disk: \(count) verses")
            }
        } catch {
            print("❌ Failed to encode progress: \(error)")
        }

        print("✅ Progress published to observers: \(count) verses")
    }

    // MARK: - Fallback Sample Data

    /// Get sample surahs for fallback when API/cache fails
    func getSampleSurahs() -> [Surah] {
        return [
            Surah(id: 1, name: "الفاتحة", englishName: "Al-Fatihah", englishNameTranslation: "The Opening", numberOfVerses: 7, revelationType: .meccan),
            Surah(id: 2, name: "البقرة", englishName: "Al-Baqarah", englishNameTranslation: "The Cow", numberOfVerses: 286, revelationType: .medinan),
            Surah(id: 3, name: "آل عمران", englishName: "Ali 'Imran", englishNameTranslation: "Family of Imran", numberOfVerses: 200, revelationType: .medinan),
            Surah(id: 4, name: "النساء", englishName: "An-Nisa", englishNameTranslation: "The Women", numberOfVerses: 176, revelationType: .medinan),
            Surah(id: 5, name: "المائدة", englishName: "Al-Ma'idah", englishNameTranslation: "The Table Spread", numberOfVerses: 120, revelationType: .medinan),
            Surah(id: 6, name: "الأنعام", englishName: "Al-An'am", englishNameTranslation: "The Cattle", numberOfVerses: 165, revelationType: .meccan),
            Surah(id: 7, name: "الأعراف", englishName: "Al-A'raf", englishNameTranslation: "The Heights", numberOfVerses: 206, revelationType: .meccan),
            Surah(id: 8, name: "الأنفال", englishName: "Al-Anfal", englishNameTranslation: "The Spoils of War", numberOfVerses: 75, revelationType: .medinan),
            Surah(id: 9, name: "التوبة", englishName: "At-Tawbah", englishNameTranslation: "The Repentance", numberOfVerses: 129, revelationType: .medinan),
            Surah(id: 10, name: "يونس", englishName: "Yunus", englishNameTranslation: "Jonah", numberOfVerses: 109, revelationType: .meccan),
            Surah(id: 111, name: "المسد", englishName: "Al-Masad", englishNameTranslation: "The Palm Fiber", numberOfVerses: 5, revelationType: .meccan),
            Surah(id: 112, name: "الإخلاص", englishName: "Al-Ikhlas", englishNameTranslation: "The Sincerity", numberOfVerses: 4, revelationType: .meccan),
            Surah(id: 113, name: "الفلق", englishName: "Al-Falaq", englishNameTranslation: "The Daybreak", numberOfVerses: 5, revelationType: .meccan),
            Surah(id: 114, name: "الناس", englishName: "An-Nas", englishNameTranslation: "Mankind", numberOfVerses: 6, revelationType: .meccan)
        ]
    }

    /// Get sample verses for fallback when API/cache fails
    func getSampleVerses(forSurah surahNumber: Int) -> [Verse] {
        switch surahNumber {
        case 1:
            return [
                Verse(number: 1, surahNumber: 1, verseNumber: 1, text: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ", juz: 1),
                Verse(number: 2, surahNumber: 1, verseNumber: 2, text: "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ", juz: 1),
                Verse(number: 3, surahNumber: 1, verseNumber: 3, text: "ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ", juz: 1),
                Verse(number: 4, surahNumber: 1, verseNumber: 4, text: "مَـٰلِكِ یَوۡمِ ٱلدِّینِ", juz: 1),
                Verse(number: 5, surahNumber: 1, verseNumber: 5, text: "إِیَّاكَ نَعۡبُدُ وَإِیَّاكَ نَسۡتَعِینُ", juz: 1),
                Verse(number: 6, surahNumber: 1, verseNumber: 6, text: "ٱهۡدِنَا ٱلصِّرَ ٰ⁠طَ ٱلۡمُسۡتَقِیمَ", juz: 1),
                Verse(number: 7, surahNumber: 1, verseNumber: 7, text: "صِرَ ٰ⁠طَ ٱلَّذِینَ أَنۡعَمۡتَ عَلَیۡهِمۡ غَیۡرِ ٱلۡمَغۡضُوبِ عَلَیۡهِمۡ وَلَا ٱلضَّاۤلِّینَ", juz: 1)
            ]
        case 112:
            return [
                Verse(number: 1, surahNumber: 112, verseNumber: 1, text: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ", juz: 30),
                Verse(number: 2, surahNumber: 112, verseNumber: 2, text: "ٱللَّهُ ٱلصَّمَدُ", juz: 30),
                Verse(number: 3, surahNumber: 112, verseNumber: 3, text: "لَمۡ یَلِدۡ وَلَمۡ یُولَدۡ", juz: 30),
                Verse(number: 4, surahNumber: 112, verseNumber: 4, text: "وَلَمۡ یَكُن لَّهُۥ كُفُوًا أَحَدٌۢ", juz: 30)
            ]
        default:
            // Return single placeholder verse indicating data needs to be loaded
            return [
                Verse(
                    number: 1,
                    surahNumber: surahNumber,
                    verseNumber: 1,
                    text: "⚠️ Failed to load Quran data. Please check your internet connection and try again.",
                    juz: 1
                )
            ]
        }
    }

    /// Get sample translation for fallback when API/cache fails
    func getSampleTranslation(forVerse verse: Verse) -> Translation {
        let translations: [Int: String] = [
            1: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            2: "[All] praise is [due] to Allah, Lord of the worlds -",
            3: "The Entirely Merciful, the Especially Merciful,",
            4: "Sovereign of the Day of Recompense.",
            5: "It is You we worship and You we ask for help.",
            6: "Guide us to the straight path -",
            7: "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."
        ]

        let text = translations[verse.verseNumber] ?? "Translation loading... Please connect to internet."

        return Translation(
            verseNumber: verse.number,
            language: "English",
            text: text,
            author: "Sahih International"
        )
    }
}
