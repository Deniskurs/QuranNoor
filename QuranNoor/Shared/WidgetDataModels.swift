//
//  WidgetDataModels.swift
//  QuranNoor
//
//  Lightweight Codable models shared between the main app and widget extension.
//  These must NOT use @Observable, SwiftData, or any UIKit/AVFoundation APIs.
//

import Foundation

// MARK: - Widget Prayer Day

/// Minimal set of prayer times for a single day, used to pre-stage future
/// days (e.g. tomorrow) inside a `WidgetPrayerEntry` so the widget extension
/// can roll over at midnight without the main app pushing fresh data.
struct WidgetPrayerDay: Codable {
    let date: Date
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let imsak: Date?
    let midnight: Date?
    let lastThird: Date?
}

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

    /// Tomorrow's prayer times, pushed alongside today so the widget can
    /// transition at midnight even while the main app is suspended. Optional
    /// for backward-compat with entries encoded by older app builds.
    let tomorrow: WidgetPrayerDay?

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

    // MARK: - Day Rollover

    /// Returns the entry that should drive the widget at `referenceDate`.
    ///
    /// - If `referenceDate` falls on the same calendar day as `self.date`,
    ///   returns `self` (today's entry, with completions preserved).
    /// - Otherwise, if `tomorrow` exists and `referenceDate` falls on
    ///   `tomorrow.date`, returns a fresh entry built from the tomorrow data
    ///   with **empty completions** (new day, nothing prayed yet).
    /// - Otherwise (data is more than one day stale), returns `self` as a
    ///   best-effort fallback so the widget still renders something.
    func entry(validFor referenceDate: Date) -> WidgetPrayerEntry {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: referenceDate) {
            return self
        }
        if let tomorrow, calendar.isDate(tomorrow.date, inSameDayAs: referenceDate) {
            return WidgetPrayerEntry(
                date: tomorrow.date,
                location: location,
                fajr: tomorrow.fajr,
                sunrise: tomorrow.sunrise,
                dhuhr: tomorrow.dhuhr,
                asr: tomorrow.asr,
                maghrib: tomorrow.maghrib,
                isha: tomorrow.isha,
                imsak: tomorrow.imsak,
                midnight: tomorrow.midnight,
                lastThird: tomorrow.lastThird,
                completions: [:],
                hijriDateString: nil,
                tomorrow: nil
            )
        }
        return self
    }

    /// True when `referenceDate` is at least one calendar day past this entry
    /// and there is no pre-staged `tomorrow` covering that date. Used by the
    /// widget provider to decide whether to pin a short refresh interval.
    func isStale(at referenceDate: Date) -> Bool {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: referenceDate) { return false }
        if let tomorrow, calendar.isDate(tomorrow.date, inSameDayAs: referenceDate) { return false }
        return true
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
            hijriDateString: nil,
            tomorrow: nil
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
