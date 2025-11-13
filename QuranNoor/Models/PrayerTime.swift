//
//  PrayerTime.swift
//  QuraanNoor
//
//  Prayer time data model
//

import Foundation
import Combine

// MARK: - Prayer Name
enum PrayerName: String, CaseIterable, Identifiable, Codable {
    case fajr = "Fajr"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.min.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

// MARK: - Prayer Time
struct PrayerTime: Identifiable {
    let id = UUID()
    let name: PrayerName
    let time: Date

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Returns true if the prayer time has started (time is now or in the past)
    var hasStarted: Bool {
        time <= Date()
    }
}

// MARK: - Special Time Type
enum SpecialTimeType: String, CaseIterable {
    case imsak = "Imsak"
    case sunrise = "Sunrise"
    case sunset = "Sunset"
    case midnight = "Midnight"
    case firstThird = "First Third"
    case lastThird = "Last Third"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .imsak: return "moon.fill"
        case .sunrise: return "sunrise"
        case .sunset: return "sunset"
        case .midnight: return "moon.stars"
        case .firstThird: return "moon.haze.fill"
        case .lastThird: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .imsak: return "Stop eating for Fajr"
        case .sunrise: return "Sun rises"
        case .sunset: return "Sun sets"
        case .midnight: return "Islamic midnight"
        case .firstThird: return "First third of night"
        case .lastThird: return "Best time for Tahajjud"
        }
    }
}

// MARK: - Special Time
struct SpecialTime: Identifiable {
    let id = UUID()
    let type: SpecialTimeType
    let time: Date

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

// MARK: - Daily Prayer Times
struct DailyPrayerTimes {
    let date: Date
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date

    // Special Islamic times
    let imsak: Date?
    let sunset: Date
    let midnight: Date?
    let firstThird: Date?
    let lastThird: Date?

    var prayerTimes: [PrayerTime] {
        [
            PrayerTime(name: .fajr, time: fajr),
            PrayerTime(name: .dhuhr, time: dhuhr),
            PrayerTime(name: .asr, time: asr),
            PrayerTime(name: .maghrib, time: maghrib),
            PrayerTime(name: .isha, time: isha)
        ]
    }

    var specialTimes: [SpecialTime] {
        var times: [SpecialTime] = [
            SpecialTime(type: .sunrise, time: sunrise),
            SpecialTime(type: .sunset, time: sunset)
        ]

        if let imsak = imsak {
            times.insert(SpecialTime(type: .imsak, time: imsak), at: 0)
        }

        if let midnight = midnight {
            times.append(SpecialTime(type: .midnight, time: midnight))
        }

        if let firstThird = firstThird {
            times.append(SpecialTime(type: .firstThird, time: firstThird))
        }

        if let lastThird = lastThird {
            times.append(SpecialTime(type: .lastThird, time: lastThird))
        }

        return times.sorted { $0.time < $1.time }
    }

    /// Get all times (prayers + special) sorted chronologically
    var allTimesSorted: [(String, Date)] {
        var all: [(String, Date)] = []

        if let imsak = imsak {
            all.append(("Imsak", imsak))
        }
        all.append(("Fajr", fajr))
        all.append(("Sunrise", sunrise))
        all.append(("Dhuhr", dhuhr))
        all.append(("Asr", asr))
        all.append(("Sunset", sunset))
        all.append(("Maghrib", maghrib))
        all.append(("Isha", isha))
        if let midnight = midnight {
            all.append(("Midnight", midnight))
        }
        if let lastThird = lastThird {
            all.append(("Last Third", lastThird))
        }

        return all.sorted { $0.1 < $1.1 }
    }
}

// MARK: - Calculation Method
enum CalculationMethod: String, CaseIterable, Identifiable {
    case muslimWorldLeague = "Muslim World League"
    case isna = "ISNA (North America)"
    case egyptian = "Egyptian General Authority"
    case ummAlQura = "Umm al-Qura (Makkah)"
    case karachi = "University of Islamic Sciences, Karachi"
    case dubai = "Dubai"
    case moonsightingCommittee = "Moonsighting Committee Worldwide"

    var id: String { rawValue }

    // Legacy compatibility
    static var mwl: CalculationMethod { .muslimWorldLeague }

    /// Short name for display
    var shortName: String {
        switch self {
        case .muslimWorldLeague: return "MWL"
        case .isna: return "ISNA"
        case .egyptian: return "Egyptian"
        case .ummAlQura: return "Umm al-Qura"
        case .karachi: return "Karachi"
        case .dubai: return "Dubai"
        case .moonsightingCommittee: return "Moonsighting"
        }
    }

    /// Description of where this method is commonly used
    var regionDescription: String {
        switch self {
        case .muslimWorldLeague:
            return "Europe, Far East, parts of America"
        case .isna:
            return "North America (US & Canada)"
        case .egyptian:
            return "Egypt, Syria, Lebanon, Malaysia"
        case .ummAlQura:
            return "Saudi Arabia (Makkah)"
        case .karachi:
            return "Pakistan, Bangladesh, India, Afghanistan"
        case .dubai:
            return "Dubai, UAE"
        case .moonsightingCommittee:
            return "Worldwide (follows closest sunrise/sunset)"
        }
    }
}

// MARK: - Madhab (Asr calculation school)
enum Madhab: String, CaseIterable, Identifiable {
    case shafi = "Standard (Shafi, Maliki, Hanbali)"
    case hanafi = "Hanafi"

    var id: String { rawValue }

    /// Explanation of the madhab's Asr calculation method
    var explanation: String {
        switch self {
        case .shafi:
            return "Asr when shadow = object length (used by Shafi, Maliki, and Hanbali schools)"
        case .hanafi:
            return "Asr when shadow = 2× object length (used by Hanafi school)"
        }
    }

    /// Short technical description
    var technicalNote: String {
        switch self {
        case .shafi:
            return "Shadow length: 1× object"
        case .hanafi:
            return "Shadow length: 2× object"
        }
    }
}
