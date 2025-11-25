//
//  HomeViewModel.swift
//  QuranNoor
//
//  Created by Claude Code
//  ViewModel for home page data management
//

import Foundation
import Observation
import SwiftUI

// Typealias to avoid HijriDate ambiguity in @Observable macro expansion
typealias AppHijriDate = HijriDate

/// Home page view model managing daily stats, prayer times, and spiritual content
@Observable
@MainActor
final class HomeViewModel {
    // MARK: - Dependencies

    private let hijriService = HijriCalendarService()
    private let islamicContentService = IslamicContentService.shared
    private let apiClient = APIClient.shared

    // MARK: - Published State

    var dailyStats: DailyStats?
    var currentHijriDate: AppHijriDate?
    var verseOfDay: IslamicQuote?
    var hadithOfDay: IslamicQuote?
    var greeting: String = ""

    // MARK: - Loading States

    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var showError: Bool = false
    var errorMessage: String?

    // MARK: - Cache

    private let cacheKey = "homeView_dailyData_v1"
    private let cacheExpiry: TimeInterval = 3600 // 1 hour

    // MARK: - Initialization

    init() {
        updateGreeting()
    }

    // MARK: - Public Methods

    /// Initialize home page data - loads cached data first, then fetches fresh data
    func initialize() async {
        // Load cached data immediately (synchronous, instant)
        loadCachedData()

        // Fetch fresh data in parallel
        await loadFreshData()
    }

    /// Refresh all data sources (pull-to-refresh)
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await loadFreshData()
    }

    /// Update greeting with Islamic greeting (personalized if name is set)
    func updateGreeting() {
        if let userName = UserDefaults.standard.string(forKey: "userName"),
           !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            greeting = "As Salamu Alaykum, \(userName)"
        } else {
            greeting = "As Salamu Alaykum"
        }
    }

    /// Calculate daily statistics from existing services
    func calculateDailyStats(from quranVM: QuranViewModel, prayerVM: PrayerViewModel) -> DailyStats {
        guard let progress = quranVM.readingProgress else {
            return DailyStats()
        }

        // Get today's prayer completion count
        let todayCompletedPrayers = PrayerCompletionService.shared.getTodayCompletionCount()

        // Calculate current Juz and progress
        let currentJuz = calculateCurrentJuz(from: progress)
        let juzProgress = calculateJuzProgress(progress: progress, juz: currentJuz)

        let stats = DailyStats(
            streakDays: progress.streakDays,
            versesReadToday: calculateVersesReadToday(progress: progress),
            prayersCompleted: todayCompletedPrayers,
            readingTimeMinutes: calculateReadingTime(progress: progress),
            lastReadSurahName: getSurahName(for: progress.lastReadSurah, from: quranVM),
            lastReadVerseNumber: progress.lastReadVerse,
            juzProgress: juzProgress,
            currentJuz: currentJuz,
            totalVersesRead: progress.totalVersesRead,
            overallCompletion: progress.completionPercentage
        )

        #if DEBUG
        print("📊 [HomeViewModel] calculateDailyStats:")
        print("   - ReadingProgress.totalVersesRead: \(progress.totalVersesRead)")
        print("   - ReadingProgress.completionPercentage: \(progress.completionPercentage)")
        print("   - DailyStats.overallCompletion: \(stats.overallCompletion)")
        print("   - DailyStats.progressPercentage: \(stats.progressPercentage)")
        #endif

        return stats
    }

    // MARK: - Private Methods

    private func loadCachedData() {
        // Load cached Hijri date
        if let cachedHijri = hijriService.getCachedHijriDate() {
            currentHijriDate = cachedHijri
        }

        // Load cached daily stats from UserDefaults
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(CachedHomeData.self, from: data),
           !cached.isExpired {
            dailyStats = cached.stats

            #if DEBUG
            print("📦 [HomeViewModel] Loaded cached stats:")
            print("   - Cached completion: \(cached.stats.overallCompletion)")
            print("   - Cached verses: \(cached.stats.totalVersesRead)")
            print("   - Cache age: \(Date().timeIntervalSince(cached.timestamp))s")
            #endif
        } else {
            #if DEBUG
            print("📦 [HomeViewModel] No valid cached stats found or cache expired")
            #endif
        }
    }

    /// Clear cached data (useful when data seems incorrect)
    func clearCachedData() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        #if DEBUG
        print("🗑️ [HomeViewModel] Cleared cached data")
        #endif
    }

    private func loadFreshData() async {
        // Load data in parallel for performance
        async let hijriTask = loadHijriDate()
        async let verseTask = loadVerseOfDay()
        async let hadithTask = loadHadithOfDay()

        // Await all tasks
        let (hijri, verse, hadith) = await (hijriTask, verseTask, hadithTask)

        // Update state
        currentHijriDate = hijri
        verseOfDay = verse
        hadithOfDay = hadith

        // Cache the data
        cacheHomeData()
    }

    private func loadHijriDate() async -> AppHijriDate? {
        do {
            return try await hijriService.getCurrentHijriDate()
        } catch {
            print("Failed to load Hijri date: \(error)")
            return hijriService.getCachedHijriDate()
        }
    }

    private func loadVerseOfDay() async -> IslamicQuote? {
        do {
            // Get random verse reference
            let verseRef = islamicContentService.getRandomVerseReference()

            // Fetch verse text from API (using English translation)
            let url = "https://api.alquran.cloud/v1/ayah/\(verseRef.surah):\(verseRef.verse)/en.sahih"

            struct VerseResponse: Codable {
                let data: VerseData

                struct VerseData: Codable {
                    let text: String
                    let surah: SurahInfo
                    let numberInSurah: Int

                    struct SurahInfo: Codable {
                        let number: Int
                        let name: String
                        let englishName: String
                    }
                }
            }

            let response: VerseResponse = try await apiClient.fetchDirect(
                url: url,
                cacheKey: "verse_of_day_\(verseRef.surah)_\(verseRef.verse)"
            )

            return IslamicQuote(
                text: response.data.text,
                source: "Quran \(response.data.surah.englishName) \(response.data.numberInSurah)",
                category: .wisdom,
                relatedPrayer: verseRef.relatedPrayer
            )
        } catch {
            print("Failed to load verse of the day: \(error)")
            return nil
        }
    }

    private func loadHadithOfDay() async -> IslamicQuote? {
        // Use Islamic content service to get random hadith
        return islamicContentService.getRandomHadith()
    }

    func cacheHomeData() {
        guard let stats = dailyStats else { return }

        let cached = CachedHomeData(stats: stats, timestamp: Date())
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }

        #if DEBUG
        print("💾 [HomeViewModel] Cached stats: \(stats.progressPercentage), \(stats.totalVersesRead) verses")
        #endif
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("HomeViewModel error: \(error)")
    }

    // MARK: - Helper Methods

    private func calculateVersesReadToday(progress: ReadingProgress) -> Int {
        // Check if last read was today
        if Calendar.current.isDateInToday(progress.lastReadDate) {
            // Count verses read today from readVerses dictionary
            let todayVerses = progress.readVerses.filter { _, data in
                Calendar.current.isDateInToday(data.timestamp)
            }
            return todayVerses.count
        }
        return 0
    }

    private func calculateReadingTime(progress: ReadingProgress) -> Int {
        // Estimate: 1 verse = ~1 minute of reading
        // This could be enhanced with actual time tracking
        return progress.totalVersesRead > 0 ? min(progress.totalVersesRead, 120) : 0
    }

    private func calculateCurrentJuz(from progress: ReadingProgress) -> Int {
        // Simplified: Calculate based on total verses read
        // More accurate calculation would need verse-to-juz mapping
        let versesPerJuz = 6236 / 30 // ~208 verses per juz
        return min(30, max(1, (progress.totalVersesRead / versesPerJuz) + 1))
    }

    private func calculateJuzProgress(progress: ReadingProgress, juz: Int) -> Double {
        let versesPerJuz = 6236 / 30
        let juzStartVerse = (juz - 1) * versesPerJuz
        let versesInCurrentJuz = max(0, progress.totalVersesRead - juzStartVerse)
        return min(1.0, Double(versesInCurrentJuz) / Double(versesPerJuz))
    }

    private func getSurahName(for surahNumber: Int, from quranVM: QuranViewModel) -> String? {
        return quranVM.surahs.first { $0.id == surahNumber }?.englishName
    }
}

// MARK: - Cached Data Model

private struct CachedHomeData: Codable {
    let stats: DailyStats
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour expiry
    }
}

