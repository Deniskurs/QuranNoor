//
//  QuranViewModel.swift
//  QuranNoor
//
//  ViewModel for Quran reader with surah list and verse management
//

import Foundation
import Observation

@Observable
@MainActor
class QuranViewModel {
    // MARK: - Observable Properties
    var surahs: [Surah] = []
    var selectedSurah: Surah?
    var searchQuery: String = ""
    var filteredSurahs: [Surah] = []

    /// Verse search results from full-text translation search
    var verseSearchResults: [VerseSearchResult] = []

    /// Whether a verse search is currently in progress
    var isSearchingVerses: Bool = false

    /// Error message for user-facing data loading failures
    var errorMessage: String?

    /// Reading progress — reads directly from QuranService (single source of truth)
    var readingProgress: ReadingProgress? {
        quranService.readingProgress
    }

    /// Bookmarks — reads directly from QuranService (single source of truth)
    var bookmarks: [Bookmark] {
        quranService.bookmarks
    }

    // MARK: - Private Properties
    private let quranService = QuranService.shared

    // Performance optimization: Cache surah progress to avoid repeated computation
    private var surahProgressCache: [Int: Double] = [:] // surahNumber -> completion percentage
    private var lastProgressVersion: Int = 0 // Track when cache needs rebuild

    // MARK: - Initialization
    init() {
        // Load all 114 surahs from the bundled quran_metadata.json — instant,
        // no network calls needed. This guarantees the full Quran is always
        // available on launch, even completely offline.
        let bundled = quranService.loadBundledSurahs()
        if !bundled.isEmpty {
            surahs = bundled
            filteredSurahs = bundled
        }
    }

    // MARK: - Public Methods

    /// Load surahs: uses bundled data immediately (all 114 surahs), then refreshes from API
    func loadSurahs() {
        // Ensure bundled data is loaded (instant, synchronous, all 114 surahs)
        if surahs.isEmpty {
            let bundled = quranService.loadBundledSurahs()
            if !bundled.isEmpty {
                surahs = bundled
                filteredSurahs = surahs
            }
        }

        rebuildSurahProgressCache()

        // Defer preloading briefly so critical UI data (prayer times, hijri date) loads first.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await preloadCommonSurahs()
        }
    }

    /// Fetch surahs from API (async, background refresh for enrichment)
    /// Note: With bundled quran_metadata.json providing all 114 surahs,
    /// this is only needed if bundled data was somehow missing.
    func fetchSurahsFromAPI() async {
        // Skip if bundled data already loaded (always the case)
        guard surahs.isEmpty else { return }

        do {
            let fetchedSurahs = try await quranService.getSurahs()
            if !fetchedSurahs.isEmpty {
                surahs = fetchedSurahs
                filteredSurahs = fetchedSurahs
                rebuildSurahProgressCache()
            }
            errorMessage = nil
        } catch {
            #if DEBUG
            print("API refresh skipped (offline). Bundled data is active with \(surahs.count) surahs.")
            #endif
        }
    }

    /// Preload commonly read surahs (first 10 and last 4)
    func preloadCommonSurahs() async {
        await quranService.preloadQuranData()
    }

    /// Search surahs by name
    func searchSurahs(_ query: String) {
        searchQuery = query

        if query.isEmpty {
            filteredSurahs = surahs
        } else {
            filteredSurahs = surahs.filter { surah in
                surah.englishName.localizedCaseInsensitiveContains(query) ||
                surah.englishNameTranslation.localizedCaseInsensitiveContains(query) ||
                surah.name.contains(query)
            }
        }
    }

    // MARK: - Verse Search with Cancellation Support

    /// Active search task for cancellation when new search is initiated
    private var currentSearchTask: Task<Void, Never>?

    /// Search verses by translation text across multiple surahs
    /// Uses QuranService.searchTranslationsMultipleSurahs for broad coverage
    /// Now searches all 114 surahs with Task cancellation for performance
    func searchVerses(_ query: String) async {
        // Cancel previous search if user is typing rapidly
        currentSearchTask?.cancel()

        guard !query.isEmpty else {
            verseSearchResults = []
            isSearchingVerses = false
            return
        }

        isSearchingVerses = true

        // Create a new search task with cancellation support
        currentSearchTask = Task {
            // Search across all 114 surahs for comprehensive results
            let surahsToSearch = Array(1...114)

            let results = await quranService.searchTranslationsMultipleSurahs(
                query: query,
                edition: quranService.getTranslationPreferences().primaryTranslation,
                inSurahs: surahsToSearch,
                limit: 30
            )

            // Check if task was cancelled before updating UI
            guard !Task.isCancelled else {
                await MainActor.run {
                    isSearchingVerses = false
                }
                return
            }

            // Map SearchResult<Translation> to VerseSearchResult with surah info
            var mappedResults: [VerseSearchResult] = []
            for result in results {
                let translation = result.item
                // translation.verseNumber is the absolute verse number;
                // we need to find the surah it belongs to
                let surahInfo = findSurahForAbsoluteVerse(translation.verseNumber)
                mappedResults.append(VerseSearchResult(
                    surahNumber: surahInfo.surahNumber,
                    verseNumber: surahInfo.verseInSurah,
                    surahName: surahInfo.surahName,
                    matchedText: translation.text,
                    score: result.score
                ))
            }

            await MainActor.run {
                verseSearchResults = mappedResults
                isSearchingVerses = false
            }
        }

        await currentSearchTask?.value
    }

    /// Find which surah an absolute verse number belongs to
    private func findSurahForAbsoluteVerse(_ absoluteNumber: Int) -> (surahNumber: Int, verseInSurah: Int, surahName: String) {
        var cumulativeVerses = 0
        for surah in surahs {
            if absoluteNumber <= cumulativeVerses + surah.numberOfVerses {
                let verseInSurah = absoluteNumber - cumulativeVerses
                return (surah.id, verseInSurah, surah.englishName)
            }
            cumulativeVerses += surah.numberOfVerses
        }
        // Fallback: return the number as-is
        return (1, absoluteNumber, "Unknown")
    }

    /// Select a surah
    func selectSurah(_ surah: Surah) {
        selectedSurah = surah
    }

    /// Refresh surah progress cache from current reading progress
    func loadProgress() {
        rebuildSurahProgressCache()
    }

    /// Rebuild the surah progress cache using a single-pass index.
    /// O(n) where n = total read verses, instead of O(n * 114) with the old approach.
    private func rebuildSurahProgressCache() {
        guard let progress = readingProgress else {
            surahProgressCache.removeAll()
            return
        }

        // Single pass over all read verses to group by surah
        let index = progress.buildSurahIndex()

        // Build cache from index — O(1) per surah
        var newCache: [Int: Double] = [:]
        newCache.reserveCapacity(surahs.count)

        for surah in surahs {
            let count = index[surah.id]?.count ?? 0
            newCache[surah.id] = Double(count) / Double(surah.numberOfVerses) * 100
        }

        surahProgressCache = newCache
    }

    /// Update reading progress (observers will handle UI update automatically)
    func updateProgress(surahNumber: Int, verseNumber: Int) {
        quranService.updateReadingProgress(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Get recent bookmarks (last 3)
    func getRecentBookmarks() -> [Bookmark] {
        return Array(bookmarks.prefix(3))
    }

    /// Get progress percentage
    func getProgressPercentage() -> Double {
        guard let progress = readingProgress else { return 0 }
        // Total verses in Quran: 6236
        return min(Double(progress.totalVersesRead) / 6236.0 * 100, 100)
    }

    /// Get progress text
    func getProgressText() -> String {
        guard let progress = readingProgress else { return "Start reading" }
        return "\(progress.totalVersesRead) verses read"
    }

    /// Get streak text
    func getStreakText() -> String {
        guard let progress = readingProgress else { return "0 days" }
        return "\(progress.streakDays) day\(progress.streakDays == 1 ? "" : "s")"
    }

    /// Get last read surah name
    func getLastReadSurahName() -> String {
        guard let progress = readingProgress,
              let surah = surahs.first(where: { $0.id == progress.lastReadSurah }) else {
            return "None"
        }
        return surah.englishName
    }

    /// Filter surahs by revelation type
    func filterByRevelationType(_ type: Surah.RevelationType?) {
        if let type = type {
            filteredSurahs = surahs.filter { $0.revelationType == type }
        } else {
            filteredSurahs = surahs
        }
    }

    /// Get total number of surahs
    var totalSurahs: Int {
        return surahs.count
    }

    /// Get Meccan surahs count
    var meccanCount: Int {
        return surahs.filter { $0.revelationType == .meccan }.count
    }

    /// Get Medinan surahs count
    var medinanCount: Int {
        return surahs.filter { $0.revelationType == .medinan }.count
    }

    // MARK: - Progress Management Helpers

    /// Check if verse is read
    func isVerseRead(surahNumber: Int, verseNumber: Int) -> Bool {
        return quranService.isVerseRead(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Get verse read timestamp
    func getVerseReadTimestamp(surahNumber: Int, verseNumber: Int) -> Date? {
        return quranService.getVerseReadTimestamp(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Toggle verse read status (observers will handle UI update automatically)
    func toggleVerseReadStatus(surahNumber: Int, verseNumber: Int) {
        quranService.toggleVerseReadStatus(surahNumber: surahNumber, verseNumber: verseNumber)
        // Note: No need to call loadProgress() - observers will update automatically
    }

    /// Get surah statistics
    func getSurahStatistics(surahNumber: Int, totalVerses: Int) -> SurahProgressStats {
        return quranService.getSurahStatistics(surahNumber: surahNumber, totalVerses: totalVerses)
    }

    /// Get surah progress percentage (uses cached value for performance)
    func getSurahProgress(surahNumber: Int, totalVerses: Int) -> Double {
        // Return cached value if available (99% of calls)
        if let cachedProgress = surahProgressCache[surahNumber] {
            return cachedProgress
        }

        // Fallback to live calculation if cache miss (should be rare)
        let stats = getSurahStatistics(surahNumber: surahNumber, totalVerses: totalVerses)
        surahProgressCache[surahNumber] = stats.completionPercentage
        return stats.completionPercentage
    }
}

// MARK: - Verse Search Result

/// Represents a single verse search result with surah context
struct VerseSearchResult: Identifiable {
    let id = UUID()
    let surahNumber: Int
    let verseNumber: Int
    let surahName: String
    let matchedText: String
    let score: Double
}
