//
//  IslamicCalendar.swift
//  QuranNoor
//
//  Data models for Islamic (Hijri) calendar and important dates
//

import Foundation

// MARK: - Hijri Date

/// Supporting structures for HijriDate
struct HijriMonthData: Codable, Hashable {
    let number: Int
    let en: String
    let ar: String
    let days: Int?
}

struct WeekdayData: Codable, Hashable {
    let en: String
    let ar: String
}

struct DesignationData: Codable, Hashable {
    let abbreviated: String
    let expanded: String
}

/// Represents a date in the Islamic (Hijri) calendar
struct HijriDate: Codable, Hashable {
    let day: Int
    let month: HijriMonthData
    let year: Int
    let weekday: WeekdayData
    let date: String
    let format: String
    let designation: DesignationData
    let holidays: [String]
    let adjustedHolidays: [String]
    let method: String?

    var monthName: String {
        month.en
    }

    var monthNameArabic: String {
        month.ar
    }

    var formatted: String {
        "\(day) \(monthName) \(year) AH"
    }

    var formattedArabic: String {
        "\(day) \(monthNameArabic) \(year) هـ"
    }
}

// MARK: - Hijri Months

/// The 12 months of the Islamic calendar
enum HijriMonth: Int, CaseIterable, Identifiable, Codable, Hashable {
    case muharram = 1
    case safar = 2
    case rabiAlAwwal = 3
    case rabiAlThani = 4
    case jumadaAlAwwal = 5
    case jumadaAlThani = 6
    case rajab = 7
    case shaban = 8
    case ramadan = 9
    case shawwal = 10
    case dhulQadah = 11
    case dhulHijjah = 12

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .muharram: return "Muharram"
        case .safar: return "Safar"
        case .rabiAlAwwal: return "Rabi' al-Awwal"
        case .rabiAlThani: return "Rabi' al-Thani"
        case .jumadaAlAwwal: return "Jumada al-Awwal"
        case .jumadaAlThani: return "Jumada al-Thani"
        case .rajab: return "Rajab"
        case .shaban: return "Sha'ban"
        case .ramadan: return "Ramadan"
        case .shawwal: return "Shawwal"
        case .dhulQadah: return "Dhul-Qa'dah"
        case .dhulHijjah: return "Dhul-Hijjah"
        }
    }

    var arabicName: String {
        switch self {
        case .muharram: return "مُحَرَّم"
        case .safar: return "صَفَر"
        case .rabiAlAwwal: return "رَبِيع ٱلْأَوَّل"
        case .rabiAlThani: return "رَبِيع ٱلثَّانِي"
        case .jumadaAlAwwal: return "جُمَادَىٰ ٱلْأُولَىٰ"
        case .jumadaAlThani: return "جُمَادَىٰ ٱلثَّانِيَة"
        case .rajab: return "رَجَب"
        case .shaban: return "شَعْبَان"
        case .ramadan: return "رَمَضَان"
        case .shawwal: return "شَوَّال"
        case .dhulQadah: return "ذُو ٱلْقَعْدَة"
        case .dhulHijjah: return "ذُو ٱلْحِجَّة"
        }
    }

    var significance: String {
        switch self {
        case .muharram:
            return "Sacred month. First month of Islamic year. Contains Day of Ashura."
        case .safar:
            return "Second month. Battles of Abwa and Khaybar occurred."
        case .rabiAlAwwal:
            return "The Prophet ﷺ was born on 12th Rabi' al-Awwal."
        case .rabiAlThani:
            return "Fourth month of the Islamic calendar."
        case .jumadaAlAwwal:
            return "Fifth month. Battle of Muta occurred."
        case .jumadaAlThani:
            return "Sixth month of the Islamic calendar."
        case .rajab:
            return "Sacred month. Isra and Mi'raj (27th Rajab)."
        case .shaban:
            return "Month before Ramadan. Laylat al-Bara'ah (15th Sha'ban)."
        case .ramadan:
            return "Sacred month of fasting. Laylat al-Qadr in last 10 nights."
        case .shawwal:
            return "Eid al-Fitr (1st Shawwal). Six days of fasting recommended."
        case .dhulQadah:
            return "Sacred month. Preparation for Hajj begins."
        case .dhulHijjah:
            return "Sacred month. Hajj (8-13th). Eid al-Adha (10th). Day of Arafah (9th)."
        }
    }

    var isSacred: Bool {
        switch self {
        case .muharram, .rajab, .dhulQadah, .dhulHijjah:
            return true
        default:
            return false
        }
    }
}

// MARK: - Islamic Event

/// Important dates and events in the Islamic calendar
struct IslamicEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let nameArabic: String
    let day: Int
    let month: HijriMonth
    let category: EventCategory
    let description: String
    let significance: String
    let actions: [String]  // Recommended actions (e.g., "Fast", "Pray", "Give charity")
    let isAnnual: Bool

    init(
        id: UUID = UUID(),
        name: String,
        nameArabic: String,
        day: Int,
        month: HijriMonth,
        category: EventCategory,
        description: String,
        significance: String,
        actions: [String],
        isAnnual: Bool = true
    ) {
        self.id = id
        self.name = name
        self.nameArabic = nameArabic
        self.day = day
        self.month = month
        self.category = category
        self.description = description
        self.significance = significance
        self.actions = actions
        self.isAnnual = isAnnual
    }

    var dateString: String {
        "\(day) \(month.name)"
    }

    var dateStringArabic: String {
        "\(day) \(month.arabicName)"
    }
}

// MARK: - Event Categories

/// Categories of Islamic events
enum EventCategory: String, CaseIterable, Identifiable, Codable {
    case eid = "eid"
    case ramadan = "ramadan"
    case hajj = "hajj"
    case sacredDay = "sacred_day"
    case historical = "historical"
    case recommended = "recommended"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eid: return "Eid Celebrations"
        case .ramadan: return "Ramadan Special"
        case .hajj: return "Hajj & Dhul-Hijjah"
        case .sacredDay: return "Sacred Days"
        case .historical: return "Historical Events"
        case .recommended: return "Recommended Days"
        }
    }

    var icon: String {
        switch self {
        case .eid: return "star.circle.fill"
        case .ramadan: return "moon.stars.fill"
        case .hajj: return "building.columns.fill"
        case .sacredDay: return "sparkles"
        case .historical: return "calendar"
        case .recommended: return "heart.fill"
        }
    }

    var color: String {
        switch self {
        case .eid: return "yellow"
        case .ramadan: return "purple"
        case .hajj: return "green"
        case .sacredDay: return "blue"
        case .historical: return "brown"
        case .recommended: return "pink"
        }
    }
}

// MARK: - Calendar Progress

/// User's interaction with the Islamic calendar
struct CalendarProgress: Codable {
    var notifiedEvents: Set<String>  // Stable event keys (e.g., "1-10-Day of Ashura")
    var favoriteEvents: Set<String>  // Stable event keys marked as favorite
    var lastViewedDate: Date?
    var enableNotifications: Bool

    init() {
        self.notifiedEvents = []
        self.favoriteEvents = []
        self.lastViewedDate = nil
        self.enableNotifications = true
    }

    /// Derive a stable string key from an IslamicEvent
    static func stableKey(for event: IslamicEvent) -> String {
        "\(event.month.rawValue)-\(event.day)-\(event.name)"
    }

    mutating func toggleFavorite(eventKey: String) {
        if favoriteEvents.contains(eventKey) {
            favoriteEvents.remove(eventKey)
        } else {
            favoriteEvents.insert(eventKey)
        }
    }

    func isFavorite(eventKey: String) -> Bool {
        favoriteEvents.contains(eventKey)
    }

    mutating func markAsNotified(eventKey: String) {
        notifiedEvents.insert(eventKey)
    }

    func hasBeenNotified(eventKey: String) -> Bool {
        notifiedEvents.contains(eventKey)
    }
}

// MARK: - Ramadan Tracker

/// Special tracker for Ramadan month
struct RamadanTracker: Codable {
    var year: Int  // Hijri year
    var fastingDays: Set<Int>  // Days 1-30 that were completed
    var lastTenNightsQiyam: Set<Int>  // Nights 21-30 with qiyam
    var quranCompleted: Bool
    var zakahPaid: Bool

    init(year: Int) {
        self.year = year
        self.fastingDays = []
        self.lastTenNightsQiyam = []
        self.quranCompleted = false
        self.zakahPaid = false
    }

    var totalFastingDays: Int {
        fastingDays.count
    }

    var lastTenNightsCount: Int {
        lastTenNightsQiyam.count
    }

    var completionPercentage: Double {
        Double(fastingDays.count) / 30.0 * 100.0
    }

    mutating func toggleFasting(day: Int) {
        if fastingDays.contains(day) {
            fastingDays.remove(day)
        } else {
            fastingDays.insert(day)
        }
    }

    mutating func toggleQiyam(night: Int) {
        if lastTenNightsQiyam.contains(night) {
            lastTenNightsQiyam.remove(night)
        } else {
            lastTenNightsQiyam.insert(night)
        }
    }

    func isFastingCompleted(day: Int) -> Bool {
        fastingDays.contains(day)
    }

    func isQiyamCompleted(night: Int) -> Bool {
        lastTenNightsQiyam.contains(night)
    }
}
