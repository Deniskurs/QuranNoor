//
//  QuranService.swift
//  QuranNoor
//
//  Manages Quran data from AlQuran.cloud API, bookmarks, and reading progress
//

import Foundation
import Observation
import SwiftData

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
@Observable
@MainActor
class QuranService {
    // MARK: - Singleton
    static let shared = QuranService()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Observable Properties
    private(set) var readingProgress: ReadingProgress?
    private(set) var bookmarks: [Bookmark] = []

    // MARK: - SwiftData Context
    private var modelContext: ModelContext?

    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let userDefaults = UserDefaults.standard

    // Default editions
    private let arabicEdition = "quran-simple" // Simple Arabic text
    private let audioEdition = "ar.alafasy" // Alafasy recitation

    // Translation preferences (stored in UserDefaults)
    private let translationPrefsKey = "translation_preferences"
    private var translationPreferences: TranslationPreferences {
        get {
            guard let data = userDefaults.data(forKey: translationPrefsKey),
                  let prefs = try? Self.decoder.decode(TranslationPreferences.self, from: data) else {
                return TranslationPreferences() // Default to Sahih International
            }
            return prefs
        }
        set {
            if let encoded = try? Self.encoder.encode(newValue) {
                userDefaults.set(encoded, forKey: translationPrefsKey)
                // Translation preferences saved
            }
        }
    }

    // Preload guard — prevents redundant network calls
    private var hasPreloaded = false

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
        // Initial data will be loaded when SwiftData context is set via setupWithContext()
        // Initialization happens when SwiftData context is set via setupWithContext()
    }

    /// Setup QuranService with SwiftData ModelContext
    /// Call this from QuranNoorApp after ModelContainer is initialized
    @MainActor
    func setupWithContext(_ context: ModelContext) {
        guard modelContext == nil else { return }
        self.modelContext = context

        // Load initial data from SwiftData
        loadProgressFromSwiftData()
        loadBookmarksFromSwiftData()
    }

    /// Load reading progress from SwiftData
    @MainActor
    private func loadProgressFromSwiftData() {
        guard let context = modelContext else { return }

        do {
            // Fetch global stats
            let statsDescriptor = FetchDescriptor<ReadingStatsRecord>(
                predicate: #Predicate { $0.id == "global" }
            )
            let statsRecords = try context.fetch(statsDescriptor)
            let stats = statsRecords.first

            // Fetch all verse progress records
            let progressDescriptor = FetchDescriptor<ReadingProgressRecord>()
            let progressRecords = try context.fetch(progressDescriptor)

            // Convert to ReadingProgress struct for API compatibility
            var readVerses: [String: VerseReadData] = [:]
            for record in progressRecords {
                readVerses[record.verseId] = VerseReadData(
                    timestamp: record.firstReadDate,
                    readCount: record.readCount,
                    source: VerseReadData.ReadSource(rawValue: record.source) ?? .autoTracked
                )
            }

            self.readingProgress = ReadingProgress(
                lastReadSurah: stats?.lastReadSurah ?? 1,
                lastReadVerse: stats?.lastReadVerse ?? 1,
                readVerses: readVerses,
                streakDays: stats?.streakDays ?? 0,
                lastReadDate: stats?.lastReadDate ?? Date.distantPast
            )

            // Progress loaded successfully
        } catch {
            #if DEBUG
            print("❌ Failed to load progress from SwiftData: \(error)")
            #endif
            self.readingProgress = nil
        }
    }

    /// Load bookmarks from SwiftData
    @MainActor
    private func loadBookmarksFromSwiftData() {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<BookmarkRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let records = try context.fetch(descriptor)

            self.bookmarks = records.map { $0.toBookmark() }
        } catch {
            #if DEBUG
            print("❌ Failed to load bookmarks from SwiftData: \(error)")
            #endif
            self.bookmarks = []
        }
    }

    // MARK: - Bundled Data

    /// Cached bundled surahs — loaded once from quran_metadata.json and reused
    private var cachedBundledSurahs: [Surah]?

    /// Load all 114 surahs from the bundled quran_metadata.json file.
    /// This is the PRIMARY source of surah metadata — instant, no network needed.
    /// Returns all 114 surahs on success, or an empty array if the bundle is missing.
    func loadBundledSurahs() -> [Surah] {
        // Return cached result if already loaded
        if let cached = cachedBundledSurahs {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "quran_metadata", withExtension: "json") else {
            #if DEBUG
            print("WARNING: quran_metadata.json not found in bundle")
            #endif
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try Self.decoder.decode([QuranSurahListResponse].self, from: data)

            let surahs = items.map { item in
                Surah(
                    id: item.number,
                    name: item.name,
                    englishName: item.englishName,
                    englishNameTranslation: item.englishNameTranslation,
                    numberOfVerses: item.numberOfAyahs,
                    revelationType: item.revelationType.lowercased() == "meccan" ? .meccan : .medinan
                )
            }

            cachedBundledSurahs = surahs
            return surahs
        } catch {
            #if DEBUG
            print("Failed to decode quran_metadata.json: \(error)")
            #endif
            return []
        }
    }

    // MARK: - Surah Methods

    /// Get list of all 114 surahs.
    /// Uses bundled data as the primary source (instant, offline).
    /// Falls back to API fetch which can update the cache for enrichment.
    func getSurahs() async throws -> [Surah] {
        // Primary source: bundled data (always available, all 114 surahs)
        // The surah list is static — no need to refresh from API.
        let bundled = loadBundledSurahs()
        if !bundled.isEmpty {
            return bundled
        }

        // Fallback: fetch from API if bundled data is somehow missing
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
            // Return empty if both bundled and API fail
            return []
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
            // Return fallback sample data if API fails
            return getSampleVerses(forSurah: surahNumber)
        }
    }

    /// Get translation for a verse from API using stored preferences
    func getTranslation(forVerse verse: Verse, edition: TranslationEdition? = nil) async throws -> Translation {
        let selectedEdition = edition ?? translationPreferences.primaryTranslation
        let editionId = selectedEdition.rawValue

        do {
            let response: QuranAyahResponse = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/ayah/\(verse.surahNumber):\(verse.verseNumber)/\(editionId)",
                cacheKey: "\(editionId)_\(verse.surahNumber)_\(verse.verseNumber)"
            )

            return Translation(
                verseNumber: verse.number,
                language: selectedEdition.language,
                text: response.text,
                author: selectedEdition.author
            )
        } catch {
            // Return fallback translation if API fails
            return getSampleTranslation(forVerse: verse)
        }
    }

    /// Get multiple translations for a verse (for side-by-side comparison)
    func getMultipleTranslations(forVerse verse: Verse, editions: [TranslationEdition]) async throws -> [Translation] {
        var translations: [Translation] = []

        for edition in editions {
            do {
                let translation = try await getTranslation(forVerse: verse, edition: edition)
                translations.append(translation)
            } catch {
                // Skip failed translation
            }
        }

        return translations
    }

    // MARK: - Translation Preferences

    /// Get current translation preferences
    func getTranslationPreferences() -> TranslationPreferences {
        return translationPreferences
    }

    /// Set primary translation
    func setPrimaryTranslation(_ edition: TranslationEdition) {
        var prefs = translationPreferences
        prefs.primaryTranslation = edition
        translationPreferences = prefs
    }

    /// Add secondary translation
    func addSecondaryTranslation(_ edition: TranslationEdition) {
        var prefs = translationPreferences
        if !prefs.secondaryTranslations.contains(edition) {
            prefs.secondaryTranslations.append(edition)
            translationPreferences = prefs
        }
    }

    /// Remove secondary translation
    func removeSecondaryTranslation(_ edition: TranslationEdition) {
        var prefs = translationPreferences
        prefs.secondaryTranslations.removeAll { $0 == edition }
        translationPreferences = prefs
    }

    /// Toggle multiple translations display
    func toggleMultipleTranslations() {
        var prefs = translationPreferences
        prefs.showMultipleTranslations.toggle()
        translationPreferences = prefs
    }

    /// Get audio URL for a specific verse
    func getAudioURL(forVerse verse: Verse) async throws -> String? {
        do {
            let response: QuranAyahResponse = try await apiClient.fetchDirect(
                url: "https://api.alquran.cloud/v1/ayah/\(verse.surahNumber):\(verse.verseNumber)/\(audioEdition)"
            )
            return response.audio
        } catch {
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
            return []
        }
    }

    /// Clear all cached Quran data (useful for debugging or forcing fresh data)
    func clearAllCache() {
        // APIClient now uses file-based cache — clear it all at once
        apiClient.clearCache()
    }

    /// Preload commonly-read Quran data (last 4 surahs only — most frequently read).
    /// Guarded to run only once per app session — subsequent calls are no-ops.
    /// Fetches are serialized with a short delay between each to avoid API rate limits.
    func preloadQuranData() async {
        guard !hasPreloaded else { return }
        hasPreloaded = true

        // Preload only the last 4 surahs (most commonly read, small payload)
        // Serialized to avoid flooding the API and triggering 429 rate limits
        let prioritySurahs = [112, 113, 114, 111]

        for surahNumber in prioritySurahs {
            _ = try? await getVerses(forSurah: surahNumber)
            // Stagger requests to stay under API rate limits
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    // MARK: - Bookmarks

    /// Get all bookmarks (uses cached @Published property)
    func getBookmarks() -> [Bookmark] {
        return bookmarks
    }

    /// Get bookmarks filtered by category
    /// - Parameter category: The category to filter by. Pass `BookmarkCategory.allBookmarks` or `nil` to return all.
    func getBookmarks(filteredBy category: String?) -> [Bookmark] {
        guard let category = category, category != BookmarkCategory.allBookmarks else {
            return bookmarks
        }
        return bookmarks.filter { $0.category == category }
    }

    /// Get all unique bookmark categories currently in use
    func getBookmarkCategories() -> [String] {
        var categories: [String] = [BookmarkCategory.allBookmarks]
        let uniqueUsed = Set(bookmarks.map { $0.category }).sorted()
        for cat in uniqueUsed {
            if cat != BookmarkCategory.allBookmarks && !categories.contains(cat) {
                categories.append(cat)
            }
        }
        // Ensure predefined categories appear even if unused
        for cat in BookmarkCategory.predefined {
            if !categories.contains(cat) {
                categories.append(cat)
            }
        }
        return categories
    }

    /// Add a bookmark
    @MainActor
    func addBookmark(surahNumber: Int, verseNumber: Int, note: String? = nil, category: String = "All Bookmarks") {
        guard let context = modelContext else { return }

        // Create new bookmark record
        let record = BookmarkRecord(surahNumber: surahNumber, verseNumber: verseNumber, note: note, category: category)
        context.insert(record)

        // Save context
        do {
            try context.save()
            // Update published property
            loadBookmarksFromSwiftData()
            // Bookmark saved
        } catch {
            #if DEBUG
            print("❌ Failed to save bookmark: \(error)")
            #endif
        }
    }

    /// Remove a bookmark
    @MainActor
    func removeBookmark(id: UUID) {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<BookmarkRecord>(
                predicate: #Predicate { $0.id == id }
            )
            let records = try context.fetch(descriptor)

            for record in records {
                context.delete(record)
            }

            try context.save()
            // Update published property
            loadBookmarksFromSwiftData()
            // Bookmark removed
        } catch {
            #if DEBUG
            print("❌ Failed to remove bookmark: \(error)")
            #endif
        }
    }

    /// Check if verse is bookmarked
    func isBookmarked(surahNumber: Int, verseNumber: Int) -> Bool {
        return bookmarks.contains { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }
    }

    /// Delete all bookmarks and reading progress (GDPR compliance)
    func deleteAllData() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: BookmarkRecord.self)
            try context.delete(model: ReadingProgressRecord.self)
            try context.save()
            bookmarks = []
            readingProgress = nil
        } catch {
            #if DEBUG
            print("Failed to delete all data: \(error)")
            #endif
        }
    }

    // MARK: - Reading Progress

    /// Get reading progress (uses cached @Published property or fetches from SwiftData)
    func getReadingProgress() -> ReadingProgress {
        if let cached = readingProgress {
            return cached
        }

        // Return default if no data available
        return ReadingProgress(
            lastReadSurah: 1,
            lastReadVerse: 1,
            readVerses: [:],
            streakDays: 0,
            lastReadDate: Date.distantPast
        )
    }

    /// Update reading progress (called by auto-tracking system)
    @MainActor
    func updateReadingProgress(surahNumber: Int, verseNumber: Int) {
        guard let context = modelContext else { return }

        let verseId = "\(surahNumber):\(verseNumber)"

        do {
            // Check if verse record already exists
            let descriptor = FetchDescriptor<ReadingProgressRecord>(
                predicate: #Predicate { $0.verseId == verseId }
            )
            let existingRecords = try context.fetch(descriptor)

            let now = Date()
            if let existingRecord = existingRecords.first {
                // Update existing record
                existingRecord.markAsRead()
            } else {
                // Create new record
                let newRecord = ReadingProgressRecord(
                    surahNumber: surahNumber,
                    verseNumber: verseNumber,
                    source: "autoTracked"
                )
                context.insert(newRecord)
            }

            // Update global stats
            updateGlobalStats(surahNumber: surahNumber, verseNumber: verseNumber, context: context)

            try context.save()

            // Incrementally update in-memory progress instead of refetching all records
            if var progress = readingProgress {
                let existing = progress.readVerses[verseId]
                progress.readVerses[verseId] = VerseReadData(
                    timestamp: now,
                    readCount: (existing?.readCount ?? 0) + 1,
                    source: existing?.source ?? .autoTracked
                )
                progress.lastReadSurah = surahNumber
                progress.lastReadVerse = verseNumber
                progress.lastReadDate = now
                self.readingProgress = progress
            } else {
                // No existing progress — do a full load (first time only)
                loadProgressFromSwiftData()
            }

        } catch {
            #if DEBUG
            print("❌ Failed to update progress: \(error)")
            #endif
        }
    }

    /// Update global reading stats (streak, last read position)
    @MainActor
    private func updateGlobalStats(surahNumber: Int, verseNumber: Int, context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ReadingStatsRecord>(
                predicate: #Predicate { $0.id == "global" }
            )
            let existingStats = try context.fetch(descriptor)

            let stats: ReadingStatsRecord
            if let existing = existingStats.first {
                stats = existing
            } else {
                stats = ReadingStatsRecord()
                context.insert(stats)
            }

            // Update last read position
            stats.lastReadSurah = surahNumber
            stats.lastReadVerse = verseNumber

            // Update streak logic
            let calendar = Calendar.current
            let today = Date()

            if stats.lastReadDate == Date.distantPast || stats.streakDays == 0 {
                stats.streakDays = 1
                stats.lastReadDate = today
            } else if calendar.isDateInToday(stats.lastReadDate) {
                stats.lastReadDate = today
            } else if calendar.isDateInYesterday(stats.lastReadDate) {
                stats.streakDays += 1
                stats.lastReadDate = today
            } else {
                stats.streakDays = 1
                stats.lastReadDate = today
            }
        } catch {
            #if DEBUG
            print("❌ Failed to update global stats: \(error)")
            #endif
        }
    }

    // MARK: - Progress Management

    /// Manually mark a verse as read
    @MainActor
    func markVerseAsRead(surahNumber: Int, verseNumber: Int, manual: Bool = true) {
        guard let context = modelContext else { return }

        let verseId = "\(surahNumber):\(verseNumber)"

        // Create snapshot if manual action
        if manual {
            let progress = getReadingProgress()
            let snapshot = ProgressSnapshot(
                actionType: .manualMarkRead,
                readVerses: progress.readVerses,
                streakDays: progress.streakDays,
                lastReadDate: progress.lastReadDate
            )
            ProgressHistoryManager.shared.addSnapshot(snapshot)
        }

        do {
            let descriptor = FetchDescriptor<ReadingProgressRecord>(
                predicate: #Predicate { $0.verseId == verseId }
            )
            let existingRecords = try context.fetch(descriptor)

            let now = Date()
            let source: String = manual ? "manualMark" : "autoTracked"
            if let existingRecord = existingRecords.first {
                existingRecord.markAsRead()
                if manual {
                    existingRecord.source = source
                }
            } else {
                let newRecord = ReadingProgressRecord(
                    surahNumber: surahNumber,
                    verseNumber: verseNumber,
                    source: source
                )
                context.insert(newRecord)
            }

            try context.save()

            // Incrementally update in-memory progress instead of refetching all records
            if var progress = readingProgress {
                let existing = progress.readVerses[verseId]
                progress.readVerses[verseId] = VerseReadData(
                    timestamp: now,
                    readCount: (existing?.readCount ?? 0) + 1,
                    source: VerseReadData.ReadSource(rawValue: source) ?? existing?.source ?? .autoTracked
                )
                progress.lastReadSurah = surahNumber
                progress.lastReadVerse = verseNumber
                progress.lastReadDate = now
                self.readingProgress = progress
            } else {
                loadProgressFromSwiftData()
            }

        } catch {
            #if DEBUG
            print("❌ Failed to mark verse as read: \(error)")
            #endif
        }
    }

    /// Manually mark a verse as unread
    @MainActor
    func markVerseAsUnread(surahNumber: Int, verseNumber: Int) {
        guard let context = modelContext else { return }

        let verseId = "\(surahNumber):\(verseNumber)"

        // Create snapshot
        let progress = getReadingProgress()
        let snapshot = ProgressSnapshot(
            actionType: .manualMarkUnread,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        do {
            let descriptor = FetchDescriptor<ReadingProgressRecord>(
                predicate: #Predicate { $0.verseId == verseId }
            )
            let records = try context.fetch(descriptor)

            for record in records {
                context.delete(record)
            }

            try context.save()

            // Incrementally update in-memory progress instead of refetching all records
            if var progress = readingProgress {
                progress.readVerses.removeValue(forKey: verseId)
                self.readingProgress = progress
            } else {
                loadProgressFromSwiftData()
            }

        } catch {
            #if DEBUG
            print("❌ Failed to mark verse as unread: \(error)")
            #endif
        }
    }

    /// Toggle verse read status
    @MainActor
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
    @MainActor
    func resetAllProgress() {
        guard let context = modelContext else { return }

        do {
            // Delete all progress records
            let progressDescriptor = FetchDescriptor<ReadingProgressRecord>()
            let progressRecords = try context.fetch(progressDescriptor)
            for record in progressRecords {
                context.delete(record)
            }

            // Reset global stats
            let statsDescriptor = FetchDescriptor<ReadingStatsRecord>()
            let statsRecords = try context.fetch(statsDescriptor)
            for record in statsRecords {
                context.delete(record)
            }

            // Create fresh stats
            let freshStats = ReadingStatsRecord()
            context.insert(freshStats)

            try context.save()
            loadProgressFromSwiftData()
            ProgressHistoryManager.shared.clearHistory()
        } catch {
            #if DEBUG
            print("❌ Failed to reset progress: \(error)")
            #endif
        }
    }

    /// Reset progress for a specific surah
    @MainActor
    func resetSurahProgress(surahNumber: Int) {
        guard let context = modelContext else { return }

        // Create snapshot
        let progress = getReadingProgress()
        let snapshot = ProgressSnapshot(
            actionType: .resetSurah,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        do {
            let descriptor = FetchDescriptor<ReadingProgressRecord>(
                predicate: #Predicate { $0.surahNumber == surahNumber }
            )
            let records = try context.fetch(descriptor)

            for record in records {
                context.delete(record)
            }

            try context.save()
            loadProgressFromSwiftData()
        } catch {
            #if DEBUG
            print("❌ Failed to reset surah progress: \(error)")
            #endif
        }
    }

    /// Reset progress for specific verse range
    @MainActor
    func resetVerseRange(surahNumber: Int, fromVerse: Int, toVerse: Int) {
        guard let context = modelContext else { return }

        // Create snapshot
        let progress = getReadingProgress()
        let snapshot = ProgressSnapshot(
            actionType: .resetSurah,
            readVerses: progress.readVerses,
            streakDays: progress.streakDays,
            lastReadDate: progress.lastReadDate
        )
        ProgressHistoryManager.shared.addSnapshot(snapshot)

        do {
            // Fetch all records for this surah
            let descriptor = FetchDescriptor<ReadingProgressRecord>(
                predicate: #Predicate { $0.surahNumber == surahNumber }
            )
            let records = try context.fetch(descriptor)

            // Delete only records in the specified range
            for record in records where record.verseNumber >= fromVerse && record.verseNumber <= toVerse {
                context.delete(record)
            }

            try context.save()
            loadProgressFromSwiftData()
        } catch {
            #if DEBUG
            print("❌ Failed to reset verse range: \(error)")
            #endif
        }
    }

    /// Undo last progress action
    @MainActor
    @discardableResult
    func undoLastAction() -> Bool {
        guard let context = modelContext else { return false }

        guard let lastSnapshot = ProgressHistoryManager.shared.getLastSnapshot() else {
            return false
        }

        do {
            // Clear current progress
            let progressDescriptor = FetchDescriptor<ReadingProgressRecord>()
            let currentRecords = try context.fetch(progressDescriptor)
            for record in currentRecords {
                context.delete(record)
            }

            // Restore from snapshot
            for (verseId, verseData) in lastSnapshot.readVerses {
                let record = ReadingProgressRecord(verseId: verseId, data: verseData)
                context.insert(record)
            }

            // Update global stats
            let statsDescriptor = FetchDescriptor<ReadingStatsRecord>()
            let statsRecords = try context.fetch(statsDescriptor)
            let stats = statsRecords.first ?? ReadingStatsRecord()
            if statsRecords.isEmpty {
                context.insert(stats)
            }

            stats.streakDays = lastSnapshot.streakDays
            stats.lastReadDate = lastSnapshot.lastReadDate

            try context.save()
            loadProgressFromSwiftData()
            ProgressHistoryManager.shared.removeLastSnapshot()
            return true
        } catch {
            #if DEBUG
            print("❌ Failed to undo: \(error)")
            #endif
            return false
        }
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
        let progress = readingProgress ?? getReadingProgress()
        return progress.surahProgress(surahNumber: surahNumber, totalVerses: totalVerses)
    }

    // MARK: - Import/Export Support

    /// Import reading progress from external ReadingProgress data
    /// - Parameters:
    ///   - importedProgress: The progress to import
    ///   - strategy: How to handle conflicts (replace, merge, addOnly)
    @MainActor
    func importProgress(_ importedProgress: ReadingProgress, strategy: ImportStrategy = .replace) {
        guard let context = modelContext else { return }

        do {
            switch strategy {
            case .replace:
                // Clear existing progress first
                let progressDescriptor = FetchDescriptor<ReadingProgressRecord>()
                let existingRecords = try context.fetch(progressDescriptor)
                for record in existingRecords {
                    context.delete(record)
                }

                // Import all new records
                for (verseId, verseData) in importedProgress.readVerses {
                    let record = ReadingProgressRecord(verseId: verseId, data: verseData)
                    context.insert(record)
                }

                // Update global stats
                let statsDescriptor = FetchDescriptor<ReadingStatsRecord>()
                let statsRecords = try context.fetch(statsDescriptor)
                let stats = statsRecords.first ?? ReadingStatsRecord()
                if statsRecords.isEmpty {
                    context.insert(stats)
                }
                stats.lastReadSurah = importedProgress.lastReadSurah
                stats.lastReadVerse = importedProgress.lastReadVerse
                stats.streakDays = importedProgress.streakDays
                stats.lastReadDate = importedProgress.lastReadDate

            case .merge:
                // Merge - keep most recent timestamp for each verse
                for (verseId, importedData) in importedProgress.readVerses {
                    let descriptor = FetchDescriptor<ReadingProgressRecord>(
                        predicate: #Predicate { $0.verseId == verseId }
                    )
                    let existingRecords = try context.fetch(descriptor)

                    if let existingRecord = existingRecords.first {
                        // Keep the one with most recent timestamp
                        if importedData.timestamp > existingRecord.firstReadDate {
                            existingRecord.firstReadDate = importedData.timestamp
                            existingRecord.lastReadDate = importedData.timestamp
                            existingRecord.readCount = importedData.readCount
                            existingRecord.source = importedData.source.rawValue
                        }
                    } else {
                        // New verse - add it
                        let record = ReadingProgressRecord(verseId: verseId, data: importedData)
                        context.insert(record)
                    }
                }

            case .addOnly:
                // Add only verses not already read
                for (verseId, importedData) in importedProgress.readVerses {
                    let descriptor = FetchDescriptor<ReadingProgressRecord>(
                        predicate: #Predicate { $0.verseId == verseId }
                    )
                    let existingRecords = try context.fetch(descriptor)

                    if existingRecords.isEmpty {
                        let record = ReadingProgressRecord(verseId: verseId, data: importedData)
                        context.insert(record)
                    }
                }
            }

            try context.save()
            loadProgressFromSwiftData()
        } catch {
            #if DEBUG
            print("❌ Failed to import progress: \(error)")
            #endif
        }
    }

    /// Restore verses from a snapshot (for undo operations)
    /// - Parameter snapshot: Dictionary of verseId to VerseReadData
    @MainActor
    func restoreVersesFromSnapshot(_ snapshot: [String: VerseReadData]) {
        guard let context = modelContext else { return }

        do {
            // Add or update verses from snapshot
            for (verseId, verseData) in snapshot {
                let descriptor = FetchDescriptor<ReadingProgressRecord>(
                    predicate: #Predicate { $0.verseId == verseId }
                )
                let existingRecords = try context.fetch(descriptor)

                if let existingRecord = existingRecords.first {
                    existingRecord.firstReadDate = verseData.timestamp
                    existingRecord.lastReadDate = verseData.timestamp
                    existingRecord.readCount = verseData.readCount
                    existingRecord.source = verseData.source.rawValue
                } else {
                    let record = ReadingProgressRecord(verseId: verseId, data: verseData)
                    context.insert(record)
                }
            }

            try context.save()
            loadProgressFromSwiftData()
        } catch {
            #if DEBUG
            print("❌ Failed to restore snapshot: \(error)")
            #endif
        }
    }

    /// Import strategy for merging progress data
    enum ImportStrategy {
        case replace    // Replace all existing data
        case merge      // Keep most recent for each verse
        case addOnly    // Only add new verses
    }

    // MARK: - Fallback Sample Data

    /// Get sample surahs for fallback when API/cache fails.
    /// Now loads all 114 surahs from the bundled quran_metadata.json.
    func getSampleSurahs() -> [Surah] {
        return loadBundledSurahs()
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

    // MARK: - Fuzzy Search

    /// Search surahs by name (fuzzy matching)
    /// - Parameter query: Search query
    /// - Returns: Array of matching surahs sorted by relevance
    func searchSurahs(query: String) async -> [SearchResult<Surah>] {
        guard !query.isEmpty else { return [] }

        do {
            let allSurahs = try await getSurahs()

            // Search across multiple fields (English name, Arabic name, translation)
            return FuzzySearchUtility.searchMultipleFields(
                allSurahs,
                query: query,
                keyPaths: [\.englishName, \.name, \.englishNameTranslation],
                threshold: 0.3
            )
        } catch {
            return []
        }
    }

    /// Search verses by text content (fuzzy matching) with pagination
    /// - Parameters:
    ///   - query: Search query
    ///   - surahNumber: Optional surah number to limit search scope
    ///   - limit: Maximum number of results to return (default: 50)
    /// - Returns: Array of matching verses sorted by relevance (limited to `limit` results)
    func searchVerses(query: String, inSurah surahNumber: Int? = nil, limit: Int = 50) async -> [SearchResult<Verse>] {
        guard !query.isEmpty else { return [] }

        do {
            var results: [SearchResult<Verse>] = []

            if let surahNumber = surahNumber {
                // Search within specific surah (fast path)
                let verses = try await getVerses(forSurah: surahNumber)
                results = FuzzySearchUtility.search(
                    verses,
                    query: query,
                    keyPath: \.text,
                    threshold: 0.4
                )
            } else {
                // Search with early termination - stop when we have enough results
                let surahs = try await getSurahs()

                for surah in surahs {
                    // Stop searching if we have enough high-quality results
                    if results.count >= limit * 2 {
                        break
                    }

                    let verses = try await getVerses(forSurah: surah.id)
                    let surahResults = FuzzySearchUtility.search(
                        verses,
                        query: query,
                        keyPath: \.text,
                        threshold: 0.4
                    )
                    results.append(contentsOf: surahResults)
                }

                // Sort all results by score
                results.sort { $0.score > $1.score }
            }

            // Return limited results
            return Array(results.prefix(limit))
        } catch {
            return []
        }
    }

    /// Search translations by text content (fuzzy matching) with pagination
    /// - Important: This method only searches within a specific surah to avoid excessive API calls.
    ///              For full Quran translation search, use `smartSearch` which searches surah names first.
    /// - Parameters:
    ///   - query: Search query
    ///   - edition: Translation edition to search
    ///   - surahNumber: Surah number to search within (REQUIRED for performance)
    ///   - limit: Maximum number of results to return (default: 30)
    /// - Returns: Array of matching translations sorted by relevance (limited to `limit` results)
    func searchTranslations(
        query: String,
        edition: TranslationEdition = .sahihInternational,
        inSurah surahNumber: Int,
        limit: Int = 30
    ) async -> [SearchResult<Translation>] {
        guard !query.isEmpty else { return [] }

        do {
            var translations: [Translation] = []

            // Only search within the specified surah to prevent API abuse
            let verses = try await getVerses(forSurah: surahNumber)

            // Limit the number of API calls
            let versesToSearch = Array(verses.prefix(min(verses.count, 300)))

            for verse in versesToSearch {
                let translation = try await getTranslation(forVerse: verse, edition: edition)
                translations.append(translation)
            }

            // Search translation text
            let results = FuzzySearchUtility.wordSearch(
                translations,
                query: query,
                keyPath: \.text,
                requireAll: false
            )

            return Array(results.prefix(limit))
        } catch {
            return []
        }
    }

    /// Search translations across multiple surahs (limited scope for performance)
    /// - Parameters:
    ///   - query: Search query
    ///   - edition: Translation edition to search
    ///   - surahNumbers: Array of surah numbers to search (max 10 surahs for performance)
    ///   - limit: Maximum number of results to return (default: 50)
    /// - Returns: Array of matching translations sorted by relevance
    func searchTranslationsMultipleSurahs(
        query: String,
        edition: TranslationEdition = .sahihInternational,
        inSurahs surahNumbers: [Int],
        limit: Int = 50
    ) async -> [SearchResult<Translation>] {
        guard !query.isEmpty else { return [] }

        // Limit to max 10 surahs to prevent excessive API calls
        let limitedSurahs = Array(surahNumbers.prefix(10))
        var allResults: [SearchResult<Translation>] = []

        for surahNumber in limitedSurahs {
            let results = await searchTranslations(
                query: query,
                edition: edition,
                inSurah: surahNumber,
                limit: 20
            )
            allResults.append(contentsOf: results)

            // Early termination if we have enough results
            if allResults.count >= limit {
                break
            }
        }

        // Sort by score and limit
        allResults.sort { $0.score > $1.score }
        return Array(allResults.prefix(limit))
    }

    /// Smart search that searches surahs first, then translations in matching surahs
    /// - Parameters:
    ///   - query: Search query
    ///   - edition: Translation edition to search
    ///   - translationLimit: Maximum translation results (default: 30)
    /// - Returns: Tuple of surah results and translation results
    func smartSearch(
        query: String,
        edition: TranslationEdition = .sahihInternational,
        translationLimit: Int = 30
    ) async -> (surahs: [SearchResult<Surah>], translations: [SearchResult<Translation>]) {
        // First, search surah names (fast operation)
        let surahResults = await searchSurahs(query: query)

        // If we found matching surahs, search translations only in those surahs
        // Otherwise, search in first 5 surahs as a fallback (Al-Fatiha to Al-Ma'idah)
        let surahsToSearch: [Int]
        if !surahResults.isEmpty {
            // Search in matched surahs (max 5 for performance)
            surahsToSearch = Array(surahResults.prefix(5).map { $0.item.id })
        } else {
            // Fallback: search in commonly read surahs
            surahsToSearch = [1, 2, 18, 36, 67] // Al-Fatiha, Al-Baqarah, Al-Kahf, Ya-Sin, Al-Mulk
        }

        // Search translations in selected surahs
        let translationResults = await searchTranslationsMultipleSurahs(
            query: query,
            edition: edition,
            inSurahs: surahsToSearch,
            limit: translationLimit
        )

        return (surahs: surahResults, translations: translationResults)
    }
}
