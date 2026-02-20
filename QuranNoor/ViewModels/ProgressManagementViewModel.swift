//
//  ProgressManagementViewModel.swift
//  QuranNoor
//
//  ViewModel for managing reading progress, statistics, and reset operations
//

import Foundation
import Observation

@Observable
@MainActor
class ProgressManagementViewModel {
    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // MARK: - Observable Properties
    /// Single source of truth: reads directly from QuranService (no duplicate copy)
    var readingProgress: ReadingProgress? {
        quranService.readingProgress
    }
    var surahs: [Surah] = []
    var surahStats: [SurahProgressStats] = []
    var filteredSurahStats: [SurahProgressStats] = []
    var searchQuery: String = "" {
        didSet { debouncedApplyFilters() }
    }
    var filterType: SurahFilterType = .all {
        didSet { applyFiltersAndSorting() }
    }
    var sortOrder: SurahSortOrder = .byNumber {
        didSet { applyFiltersAndSorting() }
    }
    var showingResetConfirmation = false
    var resetType: ResetType?
    var selectedSurahForReset: Int?
    var isExporting = false
    var isImporting = false
    var exportURL: URL?
    var importError: String?
    // Toast properties
    var toastMessage: String = ""
    var toastStyle: ToastStyle = .success
    var showToast = false

    // MARK: - Private Properties
    private let quranService = QuranService.shared
    private var searchDebounceTask: Task<Void, Never>?

    // MARK: - Enums

    enum SurahFilterType: String, CaseIterable {
        case all = "All"
        case started = "Started"
        case completed = "Completed"
        case notStarted = "Not Started"
    }

    enum SurahSortOrder: String, CaseIterable {
        case byNumber = "Surah Number"
        case byProgress = "Progress %"
        case byLastRead = "Last Read"
        case byName = "Name (A-Z)"
    }

    enum ResetType: Equatable {
        case all
        case surah(Int)
        case verseRange(surahNumber: Int, fromVerse: Int, toVerse: Int)
    }

    enum ImportStrategy {
        case replace        // Delete existing, use imported
        case merge          // Keep most recent timestamp per verse
        case addOnly        // Only add verses not already read
    }

    // MARK: - Computed Properties

    var totalVersesInQuran: Int { 6236 }

    var totalVersesRead: Int {
        readingProgress?.totalVersesRead ?? 0
    }

    var overallCompletionPercentage: Double {
        readingProgress?.completionPercentage ?? 0
    }

    var currentStreak: Int {
        readingProgress?.streakDays ?? 0
    }

    var lastReadDate: Date {
        readingProgress?.lastReadDate ?? Date.distantPast
    }

    var completedSurahsCount: Int {
        surahStats.filter { $0.isCompleted }.count
    }

    var startedSurahsCount: Int {
        surahStats.filter { $0.readVerses > 0 && !$0.isCompleted }.count
    }

    var notStartedSurahsCount: Int {
        surahStats.filter { $0.readVerses == 0 }.count
    }

    var canUndo: Bool {
        quranService.canUndo()
    }

    var undoHistoryCount: Int {
        quranService.undoHistoryCount()
    }

    // MARK: - Statistics

    var averageVersesPerDay: Double {
        guard totalVersesRead > 0, currentStreak > 0 else { return 0 }
        return Double(totalVersesRead) / Double(currentStreak)
    }

    var estimatedDaysToComplete: Int {
        guard averageVersesPerDay > 0 else { return 0 }
        let remainingVerses = totalVersesInQuran - totalVersesRead
        return Int(ceil(Double(remainingVerses) / averageVersesPerDay))
    }

    var readingVelocity: String {
        let avgPerDay = averageVersesPerDay
        if avgPerDay < 10 {
            return "Steady Pace"
        } else if avgPerDay < 30 {
            return "Good Progress"
        } else if avgPerDay < 60 {
            return "Excellent Speed"
        } else {
            return "Amazing Dedication!"
        }
    }

    // MARK: - Initialization

    init() {
        loadProgress()
        loadSurahs()
    }

    // MARK: - Debounced Search

    private func debouncedApplyFilters() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            self?.applyFiltersAndSorting()
        }
    }

    // MARK: - Data Loading

    func loadProgress() {
        // readingProgress is a computed property reading from QuranService — no assignment needed
        updateSurahStatistics()
    }

    func loadSurahs() {
        surahs = quranService.getSampleSurahs()
        rebuildSurahLookup()
        updateSurahStatistics()
    }

    func updateSurahStatistics() {
        guard !surahs.isEmpty else { return }
        guard let progress = readingProgress else {
            surahStats = surahs.map { surah in
                SurahProgressStats(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses,
                    readVerses: 0,
                    completionPercentage: 0,
                    lastReadDate: nil,
                    firstReadDate: nil
                )
            }
            applyFiltersAndSorting()
            return
        }

        // Single-pass index build: O(n) where n = total read verses
        // Then O(1) per surah lookup instead of O(n) per surah
        let index = progress.buildSurahIndex()

        surahStats = surahs.map { surah in
            if let entry = index[surah.id] {
                return progress.surahProgressFromIndex(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses,
                    indexEntry: entry
                )
            } else {
                return SurahProgressStats(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses,
                    readVerses: 0,
                    completionPercentage: 0,
                    lastReadDate: nil,
                    firstReadDate: nil
                )
            }
        }

        applyFiltersAndSorting()
    }

    // MARK: - Search and Filter

    // MARK: - Surah Lookup (O(1) instead of O(n) per lookup)
    private var surahLookup: [Int: Surah] = [:]

    /// Rebuild the lookup dictionary when surahs change
    private func rebuildSurahLookup() {
        surahLookup = Dictionary(uniqueKeysWithValues: surahs.map { ($0.id, $0) })
    }

    func applyFiltersAndSorting() {
        var filtered = surahStats

        // Apply filter
        switch filterType {
        case .all:
            break
        case .started:
            filtered = filtered.filter { $0.readVerses > 0 && !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .notStarted:
            filtered = filtered.filter { $0.readVerses == 0 }
        }

        // Apply search using O(1) dictionary lookup instead of O(n) .first(where:)
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { stat in
                guard let surah = surahLookup[stat.surahNumber] else {
                    return false
                }
                return surah.englishName.lowercased().contains(query) ||
                       surah.englishNameTranslation.lowercased().contains(query) ||
                       surah.name.contains(query) ||
                       "\(stat.surahNumber)".contains(query)
            }
        }

        // Apply sorting using O(1) dictionary lookup instead of O(n) .first(where:)
        switch sortOrder {
        case .byNumber:
            filtered.sort { $0.surahNumber < $1.surahNumber }
        case .byProgress:
            filtered.sort { $0.completionPercentage > $1.completionPercentage }
        case .byLastRead:
            filtered.sort { (a, b) in
                guard let aDate = a.lastReadDate, let bDate = b.lastReadDate else {
                    return a.lastReadDate != nil
                }
                return aDate > bDate
            }
        case .byName:
            filtered.sort { a, b in
                let aName = surahLookup[a.surahNumber]?.englishName ?? ""
                let bName = surahLookup[b.surahNumber]?.englishName ?? ""
                return aName < bName
            }
        }

        filteredSurahStats = filtered
    }

    // MARK: - Reset Operations

    func requestReset(type: ResetType) {
        resetType = type
        showingResetConfirmation = true
    }

    func confirmReset() {
        guard let type = resetType else { return }

        switch type {
        case .all:
            quranService.resetAllProgress()
        case .surah(let surahNumber):
            quranService.resetSurahProgress(surahNumber: surahNumber)
        case .verseRange(let surahNumber, let fromVerse, let toVerse):
            quranService.resetVerseRange(
                surahNumber: surahNumber,
                fromVerse: fromVerse,
                toVerse: toVerse
            )
        }

        // Note: No need to call loadProgress() - observers will update automatically
        #if DEBUG
        print("🔄 Reset completed - observers will update ViewModels")
        #endif
        showingResetConfirmation = false
        resetType = nil
    }

    func cancelReset() {
        showingResetConfirmation = false
        resetType = nil
    }

    func resetSurah(_ surahNumber: Int) {
        requestReset(type: .surah(surahNumber))

        if let surah = getSurah(forNumber: surahNumber) {
            showResetToast(for: surah.englishName, surahNumber: surahNumber)
        }
    }

    func resetAllProgress() {
        requestReset(type: .all)
    }

    // MARK: - Undo Operations

    func undoLastAction() {
        if quranService.undoLastAction() {
            loadProgress()
        }
    }

    func clearUndoHistory() {
        quranService.clearUndoHistory()
    }

    // MARK: - Export / Import

    func exportProgress() {
        guard let progress = readingProgress else {
            importError = "No progress data to export"
            return
        }

        isExporting = true

        do {
            let jsonData = try Self.encoder.encode(progress)

            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "QuranNoor_Progress_\(Date().formatted(date: .abbreviated, time: .omitted)).json"
            let fileURL = tempDir.appendingPathComponent(fileName)

            try jsonData.write(to: fileURL)

            exportURL = fileURL
            isExporting = false

            #if DEBUG
            print("📤 Exported progress to: \(fileURL.path)")
            #endif
        } catch {
            importError = "Failed to export: \(error.localizedDescription)"
            isExporting = false
        }
    }

    func importProgress(from url: URL, strategy: ImportStrategy = .replace) {
        isImporting = true
        importError = nil

        do {
            let jsonData = try Data(contentsOf: url)

            let importedProgress = try Self.decoder.decode(ReadingProgress.self, from: jsonData)

            // Convert ViewModel strategy to QuranService strategy and delegate import
            let serviceStrategy: QuranService.ImportStrategy
            switch strategy {
            case .replace:
                serviceStrategy = .replace
            case .merge:
                serviceStrategy = .merge
            case .addOnly:
                serviceStrategy = .addOnly
            }

            // Delegate to QuranService (uses SwiftData)
            quranService.importProgress(importedProgress, strategy: serviceStrategy)

            loadProgress()
            isImporting = false

            #if DEBUG
            print("📥 Imported \(importedProgress.totalVersesRead) verses with strategy: \(strategy)")
            #endif
        } catch {
            importError = "Failed to import: \(error.localizedDescription)"
            isImporting = false
        }
    }

    // MARK: - Helper Methods

    func getSurah(forNumber number: Int) -> Surah? {
        return surahs.first(where: { $0.id == number })
    }

    func getRecentActivity(limit: Int = 10) -> [(surahNumber: Int, verseNumber: Int, timestamp: Date)] {
        guard let progress = readingProgress else { return [] }

        return progress.readVerses
            .map { (key, value) -> (surahNumber: Int, verseNumber: Int, timestamp: Date) in
                let components = key.split(separator: ":")
                let surahNumber = Int(components[0]) ?? 0
                let verseNumber = Int(components[1]) ?? 0
                return (surahNumber, verseNumber, value.timestamp)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    func getReadingStreakCalendar(days: Int = 365) -> [Date: Int] {
        guard let progress = readingProgress else { return [:] }

        var calendar: [Date: Int] = [:]

        // Group verses by read date
        for (_, verseData) in progress.readVerses {
            let dateOnly = Calendar.current.startOfDay(for: verseData.timestamp)
            calendar[dateOnly, default: 0] += 1
        }

        return calendar
    }

    func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    // MARK: - Toast Methods

    private func showResetToast(for surahName: String, surahNumber: Int) {
        toastMessage = "Progress reset for \(surahName)"
        toastStyle = .info
        showToast = true
        HapticManager.shared.trigger(.success)
    }
}
