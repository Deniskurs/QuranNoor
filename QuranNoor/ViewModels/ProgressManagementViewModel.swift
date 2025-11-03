//
//  ProgressManagementViewModel.swift
//  QuranNoor
//
//  ViewModel for managing reading progress, statistics, and reset operations
//

import Foundation
import Combine

#if os(iOS)
import UIKit
#endif

@MainActor
class ProgressManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var readingProgress: ReadingProgress?
    @Published var surahs: [Surah] = []
    @Published var surahStats: [SurahProgressStats] = []
    @Published var filteredSurahStats: [SurahProgressStats] = []
    @Published var searchQuery: String = ""
    @Published var filterType: SurahFilterType = .all
    @Published var sortOrder: SurahSortOrder = .byNumber
    @Published var showingResetConfirmation = false
    @Published var resetType: ResetType?
    @Published var selectedSurahForReset: Int?
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var exportURL: URL?
    @Published var importError: String?
    // Toast properties (new API)
    @Published var toastMessage: String = ""
    @Published var toastStyle: ToastStyle = .success
    @Published var showToast = false

    // MARK: - Private Properties
    private let quranService = QuranService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Undo Support
    private var lastResetSurah: Int?
    private var lastResetSnapshot: [String: VerseReadData]?

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
        print("🆕 ProgressManagementViewModel INIT - using shared service")
        loadProgress()
        loadSurahs()
        setupSearchAndFilter()
        setupProgressObserver()
    }

    // MARK: - Combine Observers

    private func setupProgressObserver() {
        // Observe reading progress changes from QuranService
        quranService.$readingProgress
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Debounce to prevent cascade
            .sink { [weak self] newProgress in
                guard let self = self else { return }
                self.readingProgress = newProgress
                // Statistics update happens lazily when ProgressManagementView requests data
                print("🔄 ProgressManagementViewModel: Progress updated from service - \(newProgress?.totalVersesRead ?? 0) verses")
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadProgress() {
        readingProgress = quranService.getReadingProgress()
        updateSurahStatistics()
    }

    func loadSurahs() {
        surahs = quranService.getSampleSurahs()
        updateSurahStatistics()
    }

    func updateSurahStatistics() {
        guard !surahs.isEmpty else { return }

        surahStats = surahs.map { surah in
            quranService.getSurahStatistics(
                surahNumber: surah.id,
                totalVerses: surah.numberOfVerses
            )
        }

        applyFiltersAndSorting()
    }

    /// Async version of updateSurahStatistics - computes in background to avoid blocking UI
    @MainActor
    private func updateSurahStatisticsAsync() async {
        guard !surahs.isEmpty else { return }

        // Capture progress before entering detached task (Swift 6 concurrency requirement)
        let currentProgress = readingProgress ?? quranService.getReadingProgress()

        // Compute statistics on background thread
        let stats = await Task.detached(priority: .userInitiated) { [surahs] in
            surahs.map { surah in
                // Inline computation to avoid actor isolation issues
                let surahVerses = currentProgress.readVerses.filter { $0.key.starts(with: "\(surah.id):") }
                return SurahProgressStats(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses,
                    readVerses: surahVerses.count,
                    completionPercentage: Double(surahVerses.count) / Double(surah.numberOfVerses) * 100,
                    lastReadDate: surahVerses.values.map(\.timestamp).max(),
                    firstReadDate: surahVerses.values.map(\.timestamp).min()
                )
            }
        }.value

        // Update UI on main thread
        self.surahStats = stats
        self.applyFiltersAndSorting()
    }

    // MARK: - Search and Filter

    private func setupSearchAndFilter() {
        // React to search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFiltersAndSorting()
            }
            .store(in: &cancellables)

        // React to filter changes
        $filterType
            .sink { [weak self] _ in
                self?.applyFiltersAndSorting()
            }
            .store(in: &cancellables)

        // React to sort order changes
        $sortOrder
            .sink { [weak self] _ in
                self?.applyFiltersAndSorting()
            }
            .store(in: &cancellables)
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

        // Apply search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { stat in
                guard let surah = surahs.first(where: { $0.id == stat.surahNumber }) else {
                    return false
                }
                return surah.englishName.lowercased().contains(query) ||
                       surah.englishNameTranslation.lowercased().contains(query) ||
                       surah.name.contains(query) ||
                       "\(stat.surahNumber)".contains(query)
            }
        }

        // Apply sorting
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
                let aName = surahs.first(where: { $0.id == a.surahNumber })?.englishName ?? ""
                let bName = surahs.first(where: { $0.id == b.surahNumber })?.englishName ?? ""
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
        print("🔄 Reset completed - observers will update ViewModels")
        showingResetConfirmation = false
        resetType = nil
    }

    func cancelReset() {
        showingResetConfirmation = false
        resetType = nil
    }

    func resetSurah(_ surahNumber: Int) {
        // Store current state for undo
        let currentProgress = quranService.getReadingProgress()
        let surahVerses = currentProgress.readVerses.filter { $0.key.starts(with: "\(surahNumber):") }
        lastResetSurah = surahNumber
        lastResetSnapshot = surahVerses

        // Perform reset
        requestReset(type: .surah(surahNumber))

        // Show toast with undo
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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601

            let jsonData = try encoder.encode(progress)

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
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let importedProgress = try decoder.decode(ReadingProgress.self, from: jsonData)

            // Apply merge strategy
            var finalProgress: ReadingProgress

            switch strategy {
            case .replace:
                // Replace all - use imported data directly
                finalProgress = importedProgress

            case .merge:
                // Merge - keep most recent timestamp for each verse
                guard let currentProgress = readingProgress else {
                    finalProgress = importedProgress
                    break
                }

                var mergedVerses = currentProgress.readVerses
                for (verseId, importedData) in importedProgress.readVerses {
                    if let existingData = mergedVerses[verseId] {
                        // Keep the one with most recent timestamp
                        if importedData.timestamp > existingData.timestamp {
                            mergedVerses[verseId] = importedData
                        }
                    } else {
                        // New verse - add it
                        mergedVerses[verseId] = importedData
                    }
                }

                finalProgress = ReadingProgress(
                    lastReadSurah: max(currentProgress.lastReadSurah, importedProgress.lastReadSurah),
                    lastReadVerse: currentProgress.lastReadVerse,
                    readVerses: mergedVerses,
                    streakDays: max(currentProgress.streakDays, importedProgress.streakDays),
                    lastReadDate: max(currentProgress.lastReadDate, importedProgress.lastReadDate)
                    // progressHistory is now managed by ProgressHistoryManager
                )

            case .addOnly:
                // Add-only - only import verses not already read
                guard let currentProgress = readingProgress else {
                    finalProgress = importedProgress
                    break
                }

                var updatedVerses = currentProgress.readVerses
                for (verseId, importedData) in importedProgress.readVerses {
                    if updatedVerses[verseId] == nil {
                        updatedVerses[verseId] = importedData
                    }
                }

                finalProgress = ReadingProgress(
                    lastReadSurah: currentProgress.lastReadSurah,
                    lastReadVerse: currentProgress.lastReadVerse,
                    readVerses: updatedVerses,
                    streakDays: currentProgress.streakDays,
                    lastReadDate: currentProgress.lastReadDate
                    // progressHistory is now managed by ProgressHistoryManager
                )
            }

            // Save to UserDefaults
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(finalProgress)
            UserDefaults.standard.set(encodedData, forKey: "readingProgress")

            loadProgress()
            isImporting = false

            #if DEBUG
            print("📥 Imported \(finalProgress.totalVersesRead) verses with strategy: \(strategy)")
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
        // Use new Toast API
        toastMessage = "Progress reset for \(surahName)"
        toastStyle = .info
        showToast = true

        // Haptic feedback using HapticManager
        HapticManager.shared.trigger(.success)
    }

    private func undoSurahReset() {
        guard let surahNumber = lastResetSurah,
              let snapshot = lastResetSnapshot else {
            return
        }

        // Restore verses from snapshot
        var progress = quranService.getReadingProgress()
        for (verseId, verseData) in snapshot {
            progress.readVerses[verseId] = verseData
        }

        // Save without creating new undo snapshot
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(progress) {
            UserDefaults.standard.set(encodedData, forKey: "reading_progress")
            loadProgress()
        }

        // Show confirmation toast
        if let surah = getSurah(forNumber: surahNumber) {
            toastMessage = "Restored \(surah.englishName)"
            toastStyle = .success
            showToast = true
        }

        // Haptic feedback using HapticManager
        HapticManager.shared.trigger(.success)

        // Clear undo state
        lastResetSurah = nil
        lastResetSnapshot = nil
    }
}
