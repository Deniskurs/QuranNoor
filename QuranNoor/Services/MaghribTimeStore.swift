//
//  MaghribTimeStore.swift
//  QuranNoor
//
//  Lightweight singleton storing today's Maghrib time.
//  Acts as a decoupling layer between PrayerViewModel (writer)
//  and Hijri date services (readers) for Maghrib-based day transitions.
//

import Foundation

final class MaghribTimeStore: Sendable {
    static let shared = MaghribTimeStore()

    private let cacheKey = "maghribTimeStore_maghribTime"
    private let cacheDateKey = "maghribTimeStore_cacheDate"

    private init() {}

    /// Today's Maghrib time (nil if not yet loaded or cache is stale)
    var todayMaghribTime: Date? {
        let cachedInterval = UserDefaults.standard.double(forKey: cacheKey)
        let cacheDateInterval = UserDefaults.standard.double(forKey: cacheDateKey)

        guard cachedInterval > 0, cacheDateInterval > 0 else { return nil }

        let cacheDate = Date(timeIntervalSince1970: cacheDateInterval)

        // Only use cached value if it was stored today
        guard Calendar.current.isDateInToday(cacheDate) else { return nil }

        return Date(timeIntervalSince1970: cachedInterval)
    }

    /// Update the stored Maghrib time (called by PrayerViewModel after loading prayer times)
    func update(maghribTime: Date) {
        UserDefaults.standard.set(maghribTime.timeIntervalSince1970, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheDateKey)
    }

    /// Whether the current time is past today's Maghrib
    var isPastMaghrib: Bool {
        guard let maghrib = todayMaghribTime else { return false }
        return Date() >= maghrib
    }

    /// Returns a Maghrib-adjusted date for Hijri conversion.
    /// If the input date is on the same Gregorian day as the stored Maghrib
    /// AND is >= Maghrib, returns the next day so the Islamic calendar advances.
    /// For dates not matching today, returns the input unchanged.
    func maghribAdjustedDate(from date: Date) -> Date {
        guard let maghrib = todayMaghribTime else { return date }

        let calendar = Calendar.current
        // Only adjust if the input date is on the same Gregorian day as the stored Maghrib
        guard calendar.isDate(date, inSameDayAs: maghrib) else { return date }

        // If the input time is >= Maghrib, shift to next day for Hijri conversion
        if date >= maghrib {
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return date
    }
}
