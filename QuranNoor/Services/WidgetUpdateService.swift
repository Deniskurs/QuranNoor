//
//  WidgetUpdateService.swift
//  QuranNoor
//
//  Pushes app data to the shared App Group store and triggers widget refreshes.
//  Call methods on this service whenever prayer times, completions, or reading progress change.
//

import Foundation
import WidgetKit

@MainActor
final class WidgetUpdateService {

    // MARK: - Singleton
    static let shared = WidgetUpdateService()
    private init() {}

    // MARK: - Prayer Times

    /// Push current prayer times + completion state to the widget store
    func updatePrayerWidget(
        prayerTimes: DailyPrayerTimes,
        location: String,
        hijriDateString: String? = nil
    ) {
        let completions = PrayerCompletionService.shared.getTodayCompletions()
        let completionDict = Dictionary(
            uniqueKeysWithValues: completions.map { ($0.key.rawValue, $0.value) }
        )

        let entry = WidgetPrayerEntry(
            date: prayerTimes.date,
            location: location,
            fajr: prayerTimes.fajr,
            sunrise: prayerTimes.sunrise,
            dhuhr: prayerTimes.dhuhr,
            asr: prayerTimes.asr,
            maghrib: prayerTimes.maghrib,
            isha: prayerTimes.isha,
            imsak: prayerTimes.imsak,
            midnight: prayerTimes.midnight,
            lastThird: prayerTimes.lastThird,
            completions: completionDict,
            hijriDateString: hijriDateString
        )

        WidgetSharedStore.savePrayerEntry(entry)
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimesWidget")
    }

    /// Update just the prayer completion state (no prayer times change)
    func updatePrayerCompletions() {
        // Load existing entry, update completions, save back
        guard let entry = WidgetSharedStore.loadPrayerEntry() else { return }

        let completions = PrayerCompletionService.shared.getTodayCompletions()
        let completionDict = Dictionary(
            uniqueKeysWithValues: completions.map { ($0.key.rawValue, $0.value) }
        )

        // Create updated entry with new completions
        let updated = WidgetPrayerEntry(
            date: entry.date,
            location: entry.location,
            fajr: entry.fajr,
            sunrise: entry.sunrise,
            dhuhr: entry.dhuhr,
            asr: entry.asr,
            maghrib: entry.maghrib,
            isha: entry.isha,
            imsak: entry.imsak,
            midnight: entry.midnight,
            lastThird: entry.lastThird,
            completions: completionDict,
            hijriDateString: entry.hijriDateString
        )

        WidgetSharedStore.savePrayerEntry(updated)
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimesWidget")
    }

    // MARK: - Reading Progress

    /// Push reading progress to the widget store
    func updateReadingWidget(stats: DailyStats) {
        let entry = WidgetReadingEntry(
            streakDays: stats.streakDays,
            versesReadToday: stats.versesReadToday,
            totalVersesRead: stats.totalVersesRead,
            overallCompletion: stats.overallCompletion,
            currentJuz: stats.currentJuz,
            juzProgress: stats.juzProgress,
            lastReadSurahName: stats.lastReadSurahName,
            lastReadVerseNumber: stats.lastReadVerseNumber,
            prayersCompleted: stats.prayersCompleted,
            lastUpdated: Date()
        )

        WidgetSharedStore.saveReadingEntry(entry)
        WidgetCenter.shared.reloadTimelines(ofKind: "QuranProgressWidget")
    }

    // MARK: - Reload All

    /// Force reload all widget timelines
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
