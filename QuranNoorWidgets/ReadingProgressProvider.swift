//
//  ReadingProgressProvider.swift
//  QuranNoorWidgets
//
//  TimelineProvider for Quran reading progress widgets.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ReadingTimelineEntry: TimelineEntry {
    let date: Date
    let readingData: WidgetReadingEntry
    let isPlaceholder: Bool

    static let placeholder = ReadingTimelineEntry(
        date: Date(),
        readingData: .placeholder,
        isPlaceholder: true
    )
}

// MARK: - Provider

struct ReadingProgressProvider: TimelineProvider {
    typealias Entry = ReadingTimelineEntry

    func placeholder(in context: Context) -> ReadingTimelineEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingTimelineEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        let entry = makeCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingTimelineEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var entries: [ReadingTimelineEntry] = []

        if let stored = WidgetSharedStore.loadReadingEntry() {
            // "Now" entry — day-scoped counters are zeroed when the stored
            // payload was written on a previous calendar day.
            entries.append(
                ReadingTimelineEntry(
                    date: now,
                    readingData: stored.entry(validFor: now),
                    isPlaceholder: false
                )
            )

            // Midnight-flip entry (mirrors PrayerTimesProvider): shows the
            // reset counters right at the day boundary even if WidgetKit
            // defers the next timeline poll past midnight.
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: now),
               case let midnight = calendar.startOfDay(for: nextDay),
               midnight > now {
                // +1s so the entry date is unambiguously on the new day.
                let flipDate = midnight.addingTimeInterval(1)
                entries.append(
                    ReadingTimelineEntry(
                        date: flipDate,
                        readingData: stored.entry(validFor: flipDate),
                        isPlaceholder: false
                    )
                )
            }
        } else {
            entries.append(.placeholder)
        }

        // Refresh every 30 minutes (reading data changes less frequently)
        let refreshDate = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func makeCurrentEntry() -> ReadingTimelineEntry {
        if let stored = WidgetSharedStore.loadReadingEntry() {
            let now = Date()
            return ReadingTimelineEntry(
                date: now,
                readingData: stored.entry(validFor: now),
                isPlaceholder: false
            )
        }
        return .placeholder
    }
}
