//
//  QuranViewModel.swift
//  QuranNoor
//
//  ViewModel for Quran reader with surah list and verse management
//

import Foundation
import Combine

@MainActor
class QuranViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var surahs: [Surah] = []
    @Published var selectedSurah: Surah?
    @Published var searchQuery: String = ""
    @Published var filteredSurahs: [Surah] = []
    @Published var readingProgress: ReadingProgress?
    @Published var bookmarks: [Bookmark] = []

    // MARK: - Private Properties
    private let quranService = QuranService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        let instanceId = UUID().uuidString.prefix(8)
        print("🆕 QuranViewModel INIT [\(instanceId)] - using shared service")

        loadSurahs()
        loadProgress()
        loadBookmarks()

        // Setup observers for automatic updates
        setupObservers()

        print("   Initial progress: \(readingProgress?.totalVersesRead ?? 0) verses, streak: \(readingProgress?.streakDays ?? 0)")

        // Fetch data from API in background
        Task {
            await fetchSurahsFromAPI()
            await preloadCommonSurahs()
        }
    }

    // MARK: - Combine Observers

    private func setupObservers() {
        // Observe reading progress changes from QuranService
        quranService.$readingProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProgress in
                guard let self = self else { return }
                self.readingProgress = newProgress
                self.objectWillChange.send()
                print("🔄 QuranViewModel: Progress updated from service - \(newProgress?.totalVersesRead ?? 0) verses")
            }
            .store(in: &cancellables)

        // Observe bookmark changes
        quranService.$bookmarks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBookmarks in
                guard let self = self else { return }
                self.bookmarks = newBookmarks
                print("🔄 QuranViewModel: Bookmarks updated from service - \(newBookmarks.count) bookmarks")
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load surahs from sample data (fallback until API loads)
    func loadSurahs() {
        surahs = quranService.getSampleSurahs()
        filteredSurahs = surahs
    }

    /// Fetch surahs from API (async)
    func fetchSurahsFromAPI() async {
        do {
            let fetchedSurahs = try await quranService.getSurahs()
            surahs = fetchedSurahs
            filteredSurahs = fetchedSurahs
        } catch {
            print("Failed to fetch surahs from API: \(error)")
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

    /// Select a surah
    func selectSurah(_ surah: Surah) {
        selectedSurah = surah
    }

    /// Load reading progress
    func loadProgress() {
        readingProgress = quranService.getReadingProgress()
    }

    /// Update reading progress (observers will handle UI update automatically)
    func updateProgress(surahNumber: Int, verseNumber: Int) {
        print("📝 QuranViewModel.updateProgress called: \(surahNumber):\(verseNumber)")
        print("   Before: \(readingProgress?.totalVersesRead ?? 0) verses")

        quranService.updateReadingProgress(surahNumber: surahNumber, verseNumber: verseNumber)

        // Note: No need to call loadProgress() - observers will update automatically
        print("   After: \(readingProgress?.totalVersesRead ?? 0) verses (will update via observer)")
    }

    /// Load bookmarks
    func loadBookmarks() {
        bookmarks = quranService.getBookmarks()
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

    /// Get surah progress percentage
    func getSurahProgress(surahNumber: Int, totalVerses: Int) -> Double {
        let stats = getSurahStatistics(surahNumber: surahNumber, totalVerses: totalVerses)
        return stats.completionPercentage
    }
}
