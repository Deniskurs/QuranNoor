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

    /// Push current prayer times + completion state to the widget store.
    ///
    /// Pass `tomorrow` whenever available so the widget can auto-roll over
    /// at midnight without the main app needing to push fresh data. If
    /// `tomorrow` is nil, the widget will fall back to showing today's data
    /// after midnight (until the user opens the app).
    func updatePrayerWidget(
        prayerTimes: DailyPrayerTimes,
        tomorrow: DailyPrayerTimes? = nil,
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
            hijriDateString: hijriDateString,
            tomorrow: tomorrow.map(widgetDay(from:))
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

        // Create updated entry with new completions (preserves tomorrow)
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
            hijriDateString: entry.hijriDateString,
            tomorrow: entry.tomorrow
        )

        WidgetSharedStore.savePrayerEntry(updated)
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimesWidget")
    }

    private func widgetDay(from times: DailyPrayerTimes) -> WidgetPrayerDay {
        WidgetPrayerDay(
            date: times.date,
            fajr: times.fajr,
            sunrise: times.sunrise,
            dhuhr: times.dhuhr,
            asr: times.asr,
            maghrib: times.maghrib,
            isha: times.isha,
            imsak: times.imsak,
            midnight: times.midnight,
            lastThird: times.lastThird
        )
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
