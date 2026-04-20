//
//  PrayerTimesProvider.swift
//  QuranNoorWidgets
//
//  TimelineProvider that builds entries at each prayer boundary.
//  Uses .atEnd policy so WidgetKit auto-refreshes at each prayer time.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PrayerTimelineEntry: TimelineEntry {
    let date: Date
    let prayerData: WidgetPrayerEntry
    let isPlaceholder: Bool

    static let placeholder = PrayerTimelineEntry(
        date: Date(),
        prayerData: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Provider

struct PrayerTimesProvider: TimelineProvider {
    typealias Entry = PrayerTimelineEntry

    func placeholder(in context: Context) -> PrayerTimelineEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimelineEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        let entry = makeCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimelineEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current

        guard let stored = WidgetSharedStore.loadPrayerEntry() else {
            // No data at all — render placeholder, ask for a retry in 15 min.
            let entry = PrayerTimelineEntry(date: now, prayerData: .placeholder, isPlaceholder: true)
            let retryAt = now.addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(retryAt)))
            return
        }

        var entries: [PrayerTimelineEntry] = []

        // Entry for "now" — pick today's or tomorrow's bundle based on calendar day.
        let activeNow = stored.entry(validFor: now)
        entries.append(
            PrayerTimelineEntry(date: now, prayerData: activeNow, isPlaceholder: false)
        )

        // Append one entry at each remaining prayer boundary within `activeNow`
        // so the widget re-renders when the next prayer changes.
        appendPrayerBoundaries(of: activeNow, after: now, into: &entries)

        // If we're still within the stored entry's "today" and we have a
        // pre-staged tomorrow, schedule a midnight flip so the widget rolls
        // over without the main app needing to push fresh data.
        let storedDayIsNow = calendar.isDate(stored.date, inSameDayAs: now)
        if storedDayIsNow, let tomorrow = stored.tomorrow {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: now),
               case let midnight = calendar.startOfDay(for: nextDay),
               midnight > now {

                let tomorrowEntry = stored.entry(validFor: tomorrow.date)

                // One entry right at midnight carrying tomorrow's data. Using
                // +1 second so `nextPrayer(after: entry.date)` correctly
                // returns tomorrow's Fajr instead of possibly matching midnight itself.
                entries.append(
                    PrayerTimelineEntry(
                        date: midnight.addingTimeInterval(1),
                        prayerData: tomorrowEntry,
                        isPlaceholder: false
                    )
                )

                // And entries at each of tomorrow's prayer boundaries.
                appendPrayerBoundaries(of: tomorrowEntry, after: midnight, into: &entries)
            }
        }

        // Reload policy:
        // - If the stored entry is stale at `now` (more than a day old with no
        //   tomorrow covering today), ask WidgetKit to retry in 30 min so we
        //   pick up fresh data as soon as the app runs again.
        // - Otherwise use `.atEnd` — after the last scheduled prayer boundary,
        //   WidgetKit will ask for a new timeline and we'll re-read storage.
        let policy: TimelineReloadPolicy
        if stored.isStale(at: now) {
            policy = .after(now.addingTimeInterval(30 * 60))
        } else {
            policy = .atEnd
        }

        completion(Timeline(entries: entries, policy: policy))
    }

    // MARK: - Helpers

    /// Append one timeline entry at each future prayer boundary of `entry`.
    ///
    /// Each entry is placed at `prayer.time + 1s` so that
    /// `nextPrayer(after: entry.date)` inside the widget view correctly
    /// advances past the prayer that just elapsed.
    private func appendPrayerBoundaries(
        of entry: WidgetPrayerEntry,
        after referenceDate: Date,
        into entries: inout [PrayerTimelineEntry]
    ) {
        for prayer in entry.orderedPrayers where prayer.time > referenceDate {
            entries.append(
                PrayerTimelineEntry(
                    date: prayer.time.addingTimeInterval(1),
                    prayerData: entry,
                    isPlaceholder: false
                )
            )
        }
    }

    private func makeCurrentEntry() -> PrayerTimelineEntry {
        if let stored = WidgetSharedStore.loadPrayerEntry() {
            return PrayerTimelineEntry(
                date: Date(),
                prayerData: stored.entry(validFor: Date()),
                isPlaceholder: false
            )
        }
        return .placeholder
    }
}
