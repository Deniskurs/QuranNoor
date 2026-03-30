//
//  WidgetDataModels.swift
//  QuranNoor
//
//  Lightweight Codable models shared between the main app and widget extension.
//  These must NOT use @Observable, SwiftData, or any UIKit/AVFoundation APIs.
//

import Foundation

// MARK: - Widget Prayer Entry

/// Snapshot of today's prayer times for the widget timeline
struct WidgetPrayerEntry: Codable {
    let date: Date
    let location: String
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let imsak: Date?
    let midnight: Date?
    let lastThird: Date?

    /// Prayer completion status (keyed by PrayerName.rawValue)
    let completions: [String: Bool]

    /// Hijri date string (pre-formatted)
    let hijriDateString: String?

    // MARK: - Helpers

    /// All five prayers in chronological order
    var orderedPrayers: [(name: String, icon: String, time: Date)] {
        [
            ("Fajr", "sunrise.fill", fajr),
            ("Dhuhr", "sun.max.fill", dhuhr),
            ("Asr", "sun.min.fill", asr),
            ("Maghrib", "sunset.fill", maghrib),
            ("Isha", "moon.stars.fill", isha),
        ]
    }

    /// The current active prayer (most recent prayer that has started)
    var currentPrayer: (name: String, icon: String, time: Date)? {
        let now = Date()
        return orderedPrayers.last { $0.time <= now }
    }

    /// The next upcoming prayer (uses live Date() — for main app only)
    var nextPrayer: (name: String, icon: String, time: Date)? {
        let now = Date()
        return orderedPrayers.first { $0.time > now }
    }

    /// The next upcoming prayer after a given reference date (for widgets — avoids stale Date())
    func nextPrayer(after referenceDate: Date) -> (name: String, icon: String, time: Date)? {
        orderedPrayers.first { $0.time > referenceDate }
    }

    /// The current active prayer at a given reference date
    func currentPrayer(at referenceDate: Date) -> (name: String, icon: String, time: Date)? {
        orderedPrayers.last { $0.time <= referenceDate }
    }

    /// Time remaining until the next prayer
    var timeUntilNextPrayer: TimeInterval? {
        guard let next = nextPrayer else { return nil }
        return next.time.timeIntervalSince(Date())
    }

    /// Is the given prayer completed?
    func isCompleted(_ prayerName: String) -> Bool {
        completions[prayerName] ?? false
    }

    /// Number of prayers completed today
    var completedCount: Int {
        completions.values.filter { $0 }.count
    }

    // MARK: - Hijri Date (local fallback)

    private static let hijriMonthNames = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Shaban",
        "Ramadan", "Shawwal", "Dhul Qadah", "Dhul Hijjah"
    ]

    /// Hijri date string — uses API value if available, otherwise computes locally
    var displayHijriDate: String {
        if let hijri = hijriDateString, !hijri.isEmpty {
            return hijri.replacingOccurrences(of: " AH", with: "")
        }
        let islamic = Calendar(identifier: .islamicUmmAlQura)
        let components = islamic.dateComponents([.day, .month, .year], from: date)
        guard let day = components.day,
              let month = components.month, month >= 1, month <= 12,
              let year = components.year else { return "" }
        return "\(day) \(Self.hijriMonthNames[month - 1]) \(year)"
    }
}

// MARK: - Widget Reading Entry

/// Snapshot of Quran reading progress for the widget
struct WidgetReadingEntry: Codable {
    let streakDays: Int
    let versesReadToday: Int
    let totalVersesRead: Int
    let overallCompletion: Double // 0-100
    let currentJuz: Int
    let juzProgress: Double // 0.0-1.0
    let lastReadSurahName: String?
    let lastReadVerseNumber: Int?
    let prayersCompleted: Int
    let lastUpdated: Date

    // MARK: - Computed

    var completionFraction: Double {
        overallCompletion / 100.0
    }

    var lastReadLocation: String {
        guard let surah = lastReadSurahName, let verse = lastReadVerseNumber else {
            return "Start reading"
        }
        return "\(surah) \(verse)"
    }
}

// MARK: - Placeholder Data

extension WidgetPrayerEntry {
    static let placeholder: WidgetPrayerEntry = {
        let now = Date()
        let cal = Calendar.current
        func time(_ hour: Int, _ minute: Int) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }
        return WidgetPrayerEntry(
            date: now,
            location: "Loading...",
            fajr: time(5, 15),
            sunrise: time(6, 45),
            dhuhr: time(12, 30),
            asr: time(15, 45),
            maghrib: time(18, 20),
            isha: time(19, 50),
            imsak: time(5, 5),
            midnight: time(0, 15),
            lastThird: time(2, 30),
            completions: [:],
            hijriDateString: nil
        )
    }()
}

extension WidgetReadingEntry {
    static let placeholder = WidgetReadingEntry(
        streakDays: 0,
        versesReadToday: 0,
        totalVersesRead: 0,
        overallCompletion: 0,
        currentJuz: 1,
        juzProgress: 0,
        lastReadSurahName: nil,
        lastReadVerseNumber: nil,
        prayersCompleted: 0,
        lastUpdated: Date()
    )
}
