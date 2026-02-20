//
//  PrayerTimeService.swift
//  QuranNoor
//
//  Calculate prayer times using Aladhan API with offline fallback
//  Uses Adhan Swift package for offline calculations when API fails
//

import Foundation

import Observation

// MARK: - Calculation Source
enum CalculationSource {
    case api
    case offline
    case cache

    var displayName: String {
        switch self {
        case .api: return "Online"
        case .offline: return "Offline"
        case .cache: return "Cached"
        }
    }
}

// MARK: - Prayer Time Error
enum PrayerTimeError: LocalizedError {
    case calculationFailed
    case networkError
    case invalidResponse
    case offlineFallbackFailed

    var errorDescription: String? {
        switch self {
        case .calculationFailed:
            return "Failed to calculate prayer times. Please try again."
        case .networkError:
            return "Network error. Attempting offline calculation..."
        case .invalidResponse:
            return "Invalid response from prayer time service."
        case .offlineFallbackFailed:
            return "Both online and offline calculations failed. Please check your location settings."
        }
    }
}

// MARK: - Aladhan API Models
private struct AladhanResponse: Codable {
    let data: AladhanData
}

private struct AladhanData: Codable {
    let timings: AladhanTimings
    let date: AladhanDate
}

private struct AladhanTimings: Codable {
    let Imsak: String?
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Sunset: String
    let Maghrib: String
    let Isha: String
    let Midnight: String?
    let Firstthird: String?
    let Lastthird: String?
}

private struct AladhanDate: Codable {
    let hijri: AladhanHijri
    let gregorian: AladhanGregorian
}

private struct AladhanHijri: Codable {
    let date: String
    let day: String
    let month: AladhanMonth
    let year: String
}

private struct AladhanGregorian: Codable {
    let date: String
}

private struct AladhanMonth: Codable {
    let en: String
    let ar: String?
}

// MARK: - Prayer Time Service
@Observable
@MainActor
final class PrayerTimeService {
    // MARK: - Singleton
    static let shared = PrayerTimeService()

    // MARK: - Cached Formatters (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone.current
        return f
    }()

    // MARK: - Published Properties
    private(set) var todayPrayerTimes: DailyPrayerTimes?
    private(set) var isCalculating: Bool = false
    private(set) var isUsingOfflineMode: Bool = false
    private(set) var lastCalculationSource: CalculationSource = .api

    // MARK: - Private Properties
    private let baseURL = "https://api.aladhan.com/v1"
    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "cachedPrayerTimes" // Will append date
    private let cacheVersionKey = "cacheVersion" // Add versioning for cache invalidation
    private let currentCacheVersion = "3.1" // Updated for offline fallback support
    private let cacheSettingsKey = "cachedPrayerSettings" // Store method + madhab used for cache
    private let offlineService = OfflinePrayerCalculationService.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Calculate prayer times for a specific date using coordinates
    /// - Parameters:
    ///   - coordinates: Location coordinates
    ///   - date: The date to calculate prayer times for (default: today)
    ///   - method: Calculation method (default: ISNA)
    ///   - madhab: Madhab (school) for Asr calculation (default: Shafi)
    /// - Returns: Daily prayer times
    func calculatePrayerTimes(
        coordinates: LocationCoordinates,
        date: Date = Date(),
        method: CalculationMethod = .isna,
        madhab: Madhab = .shafi
    ) async throws -> DailyPrayerTimes {
        isCalculating = true
        defer { isCalculating = false }

        // Check if settings have changed
        let currentSettings = "\(method.rawValue)-\(madhab.rawValue)"
        let cachedSettings = userDefaults.string(forKey: cacheSettingsKey)

        // Check date-aware cache first (valid for specified date AND same settings)
        if let cached = loadCachedPrayerTimes(forDate: date),
           Calendar.current.isDate(cached.date, inSameDayAs: date),
           cachedSettings == currentSettings {
            // Update todayPrayerTimes only if this is today
            if Calendar.current.isDateInToday(date) {
                todayPrayerTimes = cached
            }
            lastCalculationSource = .cache
            return cached
        }

        // If settings changed, clear all caches
        if cachedSettings != currentSettings {
            clearAllPrayerTimesCaches()
        }

        // Fetch from API using specified date's timestamp
        let timestamp = Int(date.timeIntervalSince1970)
        let methodCode = mapCalculationMethod(method)

        let urlString = "\(baseURL)/timings/\(timestamp)"
        guard var components = URLComponents(string: urlString) else {
            throw PrayerTimeError.calculationFailed
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
            URLQueryItem(name: "method", value: String(methodCode)),
            URLQueryItem(name: "school", value: mapMadhab(madhab))
        ]

        guard let url = components.url else {
            throw PrayerTimeError.calculationFailed
        }

        // Try API first
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try Self.decoder.decode(AladhanResponse.self, from: data)

            // Parse times for the specified date
            let prayerTimes = try parsePrayerTimes(from: response.data, forDate: date)

            // Cache the result with date-aware key
            cachePrayerTimes(prayerTimes, forDate: date, method: method, madhab: madhab)

            // Update published property only if this is today
            if Calendar.current.isDateInToday(date) {
                todayPrayerTimes = prayerTimes
            }

            // Mark as API source and disable offline mode
            lastCalculationSource = .api
            isUsingOfflineMode = false

            return prayerTimes

        } catch is DecodingError {
            // Fallback to offline calculation
            return try await fallbackToOfflineCalculation(
                coordinates: coordinates,
                date: date,
                method: method,
                madhab: madhab
            )
        } catch {
            // Fallback to offline calculation
            return try await fallbackToOfflineCalculation(
                coordinates: coordinates,
                date: date,
                method: method,
                madhab: madhab
            )
        }
    }

    // MARK: - Offline Fallback

    /// Fallback to offline calculation when API fails
    private func fallbackToOfflineCalculation(
        coordinates: LocationCoordinates,
        date: Date,
        method: CalculationMethod,
        madhab: Madhab
    ) async throws -> DailyPrayerTimes {
        do {
            let prayerTimes = try offlineService.calculateOfflinePrayerTimes(
                coordinates: coordinates,
                date: date,
                method: method,
                madhab: madhab
            )

            // Cache the offline result
            cachePrayerTimes(prayerTimes, forDate: date, method: method, madhab: madhab)

            // Update published property only if this is today
            if Calendar.current.isDateInToday(date) {
                todayPrayerTimes = prayerTimes
            }

            // Mark as offline source and enable offline mode
            lastCalculationSource = .offline
            isUsingOfflineMode = true

            return prayerTimes

        } catch {
            throw PrayerTimeError.offlineFallbackFailed
        }
    }

    /// Force use of offline calculations (for testing or offline mode preference)
    func useOfflineCalculation(
        coordinates: LocationCoordinates,
        date: Date = Date(),
        method: CalculationMethod = .muslimWorldLeague,
        madhab: Madhab = .shafi
    ) async throws -> DailyPrayerTimes {
        isCalculating = true
        defer { isCalculating = false }

        return try await fallbackToOfflineCalculation(
            coordinates: coordinates,
            date: date,
            method: method,
            madhab: madhab
        )
    }

    // MARK: - Private Methods

    private func parsePrayerTimes(from data: AladhanData, forDate date: Date) throws -> DailyPrayerTimes {
        let timings = data.timings
        let calendar = Calendar.current

        // Helper to parse time string and combine with specified date
        func parseTime(_ timeString: String) -> Date? {
            // Remove timezone info (e.g., "(PKT)" at the end)
            let cleanTime = timeString.components(separatedBy: " ").first ?? timeString

            guard let time = Self.timeFormatter.date(from: cleanTime) else {
                return nil
            }

            // Combine specified date with the parsed time
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            components.second = 0

            return calendar.date(from: components)
        }

        guard
            let fajr = parseTime(timings.Fajr),
            let sunrise = parseTime(timings.Sunrise),
            let dhuhr = parseTime(timings.Dhuhr),
            let asr = parseTime(timings.Asr),
            let sunset = parseTime(timings.Sunset),
            let maghrib = parseTime(timings.Maghrib),
            let isha = parseTime(timings.Isha)
        else {
            throw PrayerTimeError.invalidResponse
        }

        // Optional times
        let imsak = timings.Imsak.flatMap { parseTime($0) }
        let midnight = timings.Midnight.flatMap { parseTime($0) }
        let firstThird = timings.Firstthird.flatMap { parseTime($0) }
        let lastThird = timings.Lastthird.flatMap { parseTime($0) }

        return DailyPrayerTimes(
            date: date,
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            imsak: imsak,
            sunset: sunset,
            midnight: midnight,
            firstThird: firstThird,
            lastThird: lastThird
        )
    }

    private func mapCalculationMethod(_ method: CalculationMethod) -> Int {
        switch method {
        case .muslimWorldLeague: return 3
        case .isna: return 2
        case .egyptian: return 5
        case .ummAlQura: return 4
        case .karachi: return 1
        case .dubai: return 13
        case .moonsightingCommittee: return 7
        }
    }

    private func mapMadhab(_ madhab: Madhab) -> String {
        switch madhab {
        case .shafi:
            return "0" // Standard (Shafi, Maliki, Hanbali)
        case .hanafi:
            return "1"
        }
    }

    // MARK: - Caching

    /// Generate cache key for a specific date
    private func cacheKey(for date: Date) -> String {
        let dateString = date.formatted(date: .numeric, time: .omitted)
        return "\(cacheKeyPrefix)_\(dateString)"
    }

    private func cachePrayerTimes(
        _ times: DailyPrayerTimes,
        forDate date: Date,
        method: CalculationMethod,
        madhab: Madhab
    ) {
        let cacheData: [String: Any] = [
            "date": times.date.timeIntervalSince1970,
            "fajr": times.fajr.timeIntervalSince1970,
            "sunrise": times.sunrise.timeIntervalSince1970,
            "dhuhr": times.dhuhr.timeIntervalSince1970,
            "asr": times.asr.timeIntervalSince1970,
            "sunset": times.sunset.timeIntervalSince1970,
            "maghrib": times.maghrib.timeIntervalSince1970,
            "isha": times.isha.timeIntervalSince1970,
            "imsak": times.imsak?.timeIntervalSince1970 as Any,
            "midnight": times.midnight?.timeIntervalSince1970 as Any,
            "firstThird": times.firstThird?.timeIntervalSince1970 as Any,
            "lastThird": times.lastThird?.timeIntervalSince1970 as Any
        ]

        // Use date-aware cache key
        let key = cacheKey(for: date)
        userDefaults.set(cacheData, forKey: key)
        userDefaults.set(currentCacheVersion, forKey: cacheVersionKey)
        userDefaults.set("\(method.rawValue)-\(madhab.rawValue)", forKey: cacheSettingsKey)
    }

    private func loadCachedPrayerTimes(forDate date: Date) -> DailyPrayerTimes? {
        // Check cache version
        let cachedVersion = userDefaults.string(forKey: cacheVersionKey)
        guard cachedVersion == currentCacheVersion else {
            // Cache version mismatch, clear all caches
            clearAllPrayerTimesCaches()
            return nil
        }

        // Use date-aware cache key
        let key = cacheKey(for: date)
        guard let cacheData = userDefaults.dictionary(forKey: key) else {
            return nil
        }

        guard
            let dateTimestamp = cacheData["date"] as? TimeInterval,
            let fajrTimestamp = cacheData["fajr"] as? TimeInterval,
            let sunriseTimestamp = cacheData["sunrise"] as? TimeInterval,
            let dhuhrTimestamp = cacheData["dhuhr"] as? TimeInterval,
            let asrTimestamp = cacheData["asr"] as? TimeInterval,
            let sunsetTimestamp = cacheData["sunset"] as? TimeInterval,
            let maghribTimestamp = cacheData["maghrib"] as? TimeInterval,
            let ishaTimestamp = cacheData["isha"] as? TimeInterval
        else {
            return nil
        }

        let imsakTimestamp = cacheData["imsak"] as? TimeInterval
        let midnightTimestamp = cacheData["midnight"] as? TimeInterval
        let firstThirdTimestamp = cacheData["firstThird"] as? TimeInterval
        let lastThirdTimestamp = cacheData["lastThird"] as? TimeInterval

        return DailyPrayerTimes(
            date: Date(timeIntervalSince1970: dateTimestamp),
            fajr: Date(timeIntervalSince1970: fajrTimestamp),
            sunrise: Date(timeIntervalSince1970: sunriseTimestamp),
            dhuhr: Date(timeIntervalSince1970: dhuhrTimestamp),
            asr: Date(timeIntervalSince1970: asrTimestamp),
            maghrib: Date(timeIntervalSince1970: maghribTimestamp),
            isha: Date(timeIntervalSince1970: ishaTimestamp),
            imsak: imsakTimestamp.map { Date(timeIntervalSince1970: $0) },
            sunset: Date(timeIntervalSince1970: sunsetTimestamp),
            midnight: midnightTimestamp.map { Date(timeIntervalSince1970: $0) },
            firstThird: firstThirdTimestamp.map { Date(timeIntervalSince1970: $0) },
            lastThird: lastThirdTimestamp.map { Date(timeIntervalSince1970: $0) }
        )
    }

    // MARK: - Cache Helpers

    /// Clear all prayer time caches (all dates)
    func clearAllPrayerTimesCaches() {
        // Clear version and settings
        userDefaults.removeObject(forKey: cacheVersionKey)
        userDefaults.removeObject(forKey: cacheSettingsKey)

        // Clear all date-specific caches
        // Get all keys and remove those starting with our prefix
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        for key in allKeys where key.hasPrefix(cacheKeyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

    /// Clear prayer time cache for a specific date
    func clearPrayerTimesCache(forDate date: Date) {
        let key = cacheKey(for: date)
        userDefaults.removeObject(forKey: key)
    }
}
