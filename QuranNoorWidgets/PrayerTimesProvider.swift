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
        let currentEntry = makeCurrentEntry()
        let prayerData = currentEntry.prayerData

        // Build entries at each future prayer boundary
        var entries: [PrayerTimelineEntry] = [currentEntry]
        let now = Date()

        // Add an entry at each upcoming prayer time so the widget refreshes
        let futureTimes = prayerData.orderedPrayers
            .map(\.time)
            .filter { $0 > now }

        for prayerTime in futureTimes {
            // Offset by 1 second so nextPrayer(after:) correctly advances
            // to the following prayer when this entry renders
            let entry = PrayerTimelineEntry(
                date: prayerTime.addingTimeInterval(1),
                prayerData: prayerData,
                isPlaceholder: false
            )
            entries.append(entry)
        }

        // Add an end-of-day entry to trigger refresh for tomorrow
        // Only if no prayer time extends past 23:55 (e.g. Isha in northern latitudes)
        if let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 55, second: 0, of: now) {
            let lastPrayerTime = futureTimes.last ?? now
            if lastPrayerTime < endOfDay {
                let eodEntry = PrayerTimelineEntry(
                    date: endOfDay,
                    prayerData: prayerData,
                    isPlaceholder: false
                )
                entries.append(eodEntry)
            }
        }

        // Use .atEnd so WidgetKit requests new timeline after last entry
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: - Helpers

    private func makeCurrentEntry() -> PrayerTimelineEntry {
        if let stored = WidgetSharedStore.loadPrayerEntry() {
            return PrayerTimelineEntry(
                date: Date(),
                prayerData: stored,
                isPlaceholder: false
            )
        }
        return .placeholder
    }
}
