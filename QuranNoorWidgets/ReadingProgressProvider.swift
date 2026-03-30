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
        let entry = makeCurrentEntry()

        // Refresh every 30 minutes (reading data changes less frequently)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func makeCurrentEntry() -> ReadingTimelineEntry {
        if let stored = WidgetSharedStore.loadReadingEntry() {
            return ReadingTimelineEntry(
                date: Date(),
                readingData: stored,
                isPlaceholder: false
            )
        }
        return .placeholder
    }
}
