//
//  HijriCalendarService.swift
//  QuranNoor
//
//  Manages Hijri calendar conversions using Aladhan API
//

import Foundation

// MARK: - API Response Models

/// Response data from Aladhan Hijri calendar API (already unwrapped by APIClient)
struct HijriCalendarResponse: Codable {
    let gregorian: GregorianDate
    let hijri: HijriDate
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: Month
    let year: String
    let designation: Designation?
    let lunarSighting: Bool?
}

struct HijriDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: HijriMonth
    let year: String
    let designation: Designation
    let holidays: [String]?
    let adjustedHolidays: [String]?
    let method: String?
}

struct Weekday: Codable {
    let en: String
    let ar: String?
}

struct Month: Codable {
    let number: Int
    let en: String
}

struct HijriMonth: Codable {
    let number: Int
    let en: String
    let ar: String
    let days: Int?
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}

// MARK: - Hijri Calendar Service
class HijriCalendarService {
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let userDefaults = UserDefaults.standard

    // Cache keys
    private let currentHijriDateCacheKey = "current_hijri_date"
    private func hijriDateCacheKey(for date: String) -> String {
        return "hijri_date_\(date)"
    }

    // MARK: - Public Methods

    /// Get current Hijri date
    func getCurrentHijriDate() async throws -> HijriDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let todayString = dateFormatter.string(from: Date())

        return try await convertGregorianToHijri(date: todayString)
    }

    /// Get cached Hijri date (synchronous version using cached data only)
    func getCachedHijriDate() -> HijriDate? {
        // Try to get from cache first
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let todayString = dateFormatter.string(from: Date())

        let cacheKey = "cache_\(hijriDateCacheKey(for: todayString))"
        if let entryData = userDefaults.data(forKey: cacheKey) {
            let decoder = JSONDecoder()
            if let cachedEntry = try? decoder.decode(CachedEntry.self, from: entryData) {
                // Check expiration
                if Date() <= cachedEntry.expirationDate {
                    if let cachedResponse = try? decoder.decode(HijriCalendarResponse.self, from: cachedEntry.data) {
                        return cachedResponse.hijri
                    }
                } else {
                    // Expired, remove it
                    userDefaults.removeObject(forKey: cacheKey)
                }
            }
        }

        return nil
    }

    /// Convert Gregorian date to Hijri
    func convertGregorianToHijri(date: String) async throws -> HijriDate {
        let response: HijriCalendarResponse = try await apiClient.fetch(
            endpoint: .hijriCalendar(date),
            cacheKey: hijriDateCacheKey(for: date)
        )
        return response.hijri
    }

    /// Convert Hijri date to Gregorian
    func convertHijriToGregorian(date: String) async throws -> GregorianDate {
        let response: HijriCalendarResponse = try await apiClient.fetch(
            endpoint: .hijriToGregorian(date)
        )
        return response.gregorian
    }

    /// Get formatted Hijri date string
    func getFormattedHijriDate(hijriDate: HijriDate) -> String {
        return "\(hijriDate.day) \(hijriDate.month.en) \(hijriDate.year) \(hijriDate.designation.abbreviated)"
    }

    /// Get formatted Hijri date string in Arabic
    func getFormattedHijriDateArabic(hijriDate: HijriDate) -> String {
        return "\(hijriDate.day) \(hijriDate.month.ar) \(hijriDate.year) \(hijriDate.designation.abbreviated)"
    }

    /// Check if today is an Islamic holiday
    func getTodayHolidays() async throws -> [String] {
        let hijriDate = try await getCurrentHijriDate()
        return hijriDate.holidays ?? []
    }

    /// Get Hijri month name (English)
    func getHijriMonthName(monthNumber: Int) -> String {
        let months = [
            "Muharram", "Safar", "Rabi' al-awwal", "Rabi' al-thani",
            "Jumada al-awwal", "Jumada al-thani", "Rajab", "Sha'ban",
            "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
        ]
        return months[safe: monthNumber - 1] ?? "Unknown"
    }

    /// Get Hijri month name (Arabic)
    func getHijriMonthNameArabic(monthNumber: Int) -> String {
        let months = [
            "مُحَرَّم", "صَفَر", "رَبِيع ٱلْأَوَّل", "رَبِيع ٱلثَّانِي",
            "جُمَادَىٰ ٱلْأُولَىٰ", "جُمَادَىٰ ٱلثَّانِيَة", "رَجَب", "شَعْبَان",
            "رَمَضَان", "شَوَّال", "ذُو ٱلْقَعْدَة", "ذُو ٱلْحِجَّة"
        ]
        return months[safe: monthNumber - 1] ?? "Unknown"
    }

    /// Check if current month is Ramadan
    func isRamadan() async throws -> Bool {
        let hijriDate = try await getCurrentHijriDate()
        return hijriDate.month.number == 9
    }

    /// Get days until Ramadan
    func getDaysUntilRamadan() async throws -> Int {
        let hijriDate = try await getCurrentHijriDate()
        let currentMonth = hijriDate.month.number
        let currentDay = Int(hijriDate.day) ?? 1

        if currentMonth == 9 {
            // Already in Ramadan
            return 0
        } else if currentMonth < 9 {
            // Ramadan is later this year
            let monthsUntilRamadan = 9 - currentMonth
            // Approximate calculation (each month ~29-30 days)
            return (monthsUntilRamadan * 30) - currentDay
        } else {
            // Ramadan is next year
            let monthsUntilNextYear = 12 - currentMonth
            let monthsUntilRamadan = monthsUntilNextYear + 9
            return (monthsUntilRamadan * 30) - currentDay
        }
    }

    /// Get Islamic holidays for a specific Hijri month
    func getIslamicHolidaysForMonth(monthNumber: Int) -> [String] {
        switch monthNumber {
        case 1: // Muharram
            return ["1 Muharram - Islamic New Year", "10 Muharram - Day of Ashura"]
        case 3: // Rabi' al-awwal
            return ["12 Rabi' al-awwal - Mawlid (Prophet's Birthday)"]
        case 7: // Rajab
            return ["27 Rajab - Isra and Mi'raj"]
        case 8: // Sha'ban
            return ["15 Sha'ban - Mid-Sha'ban"]
        case 9: // Ramadan
            return ["1 Ramadan - Start of Ramadan", "27 Ramadan - Laylat al-Qadr (Night of Power)"]
        case 10: // Shawwal
            return ["1 Shawwal - Eid al-Fitr"]
        case 12: // Dhu al-Hijjah
            return ["8-10 Dhu al-Hijjah - Hajj", "9 Dhu al-Hijjah - Day of Arafah", "10 Dhu al-Hijjah - Eid al-Adha"]
        default:
            return []
        }
    }

    /// Clear Hijri date cache
    func clearCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix("cache_hijri_date_") }.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }
}

private struct CachedEntry: Codable {
    let data: Data
    let expirationDate: Date
}

// MARK: - Array Extension (Safe Subscript)
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
