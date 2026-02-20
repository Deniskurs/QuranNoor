//
//  IslamicCalendarService.swift
//  QuranNoor
//
//  Service for Islamic calendar, Hijri date conversion, and important Islamic dates
//

import Foundation
import UserNotifications

@Observable
final class IslamicCalendarService {
    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    private(set) var allEvents: [IslamicEvent] = []
    private(set) var progress: CalendarProgress
    private(set) var ramadanTrackers: [Int: RamadanTracker] = [:]  // Year -> Tracker

    /// Moon sighting day offset: adjusts the calculated Hijri date.
    /// Positive = the calculated date is ahead (shift back), negative = behind (shift forward).
    /// e.g. if Apple says "3 Ramadan" but your local sighting says "2 Ramadan", set offset to -1.
    private(set) var hijriDayOffset: Int

    private static let progressKey = "islamicCalendarProgress"
    private static let ramadanTrackersKey = "ramadanTrackers"
    private static let hijriOffsetKey = "hijriDayOffset"

    private let islamicCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamic)
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    init() {
        self.hijriDayOffset = UserDefaults.standard.integer(forKey: Self.hijriOffsetKey)
        self.progress = Self.loadProgress()
        self.ramadanTrackers = Self.loadRamadanTrackers()
        self.allEvents = Self.createEventsDatabase()
    }

    /// Update the moon sighting offset (range: -3 to +3 days).
    /// Automatically clears any fasting/qiyam entries that become "future" under the new offset.
    func setHijriDayOffset(_ offset: Int) {
        let clamped = max(-3, min(3, offset))
        hijriDayOffset = clamped
        UserDefaults.standard.set(clamped, forKey: Self.hijriOffsetKey)

        // Strip entries that are now in the future under the new offset
        let newCurrentDay = convertToHijri().day
        let currentYear = convertToHijri().year
        if var tracker = ramadanTrackers[currentYear] {
            tracker.clearFutureEntries(currentDay: newCurrentDay)
            ramadanTrackers[currentYear] = tracker
            saveRamadanTrackers()
        }
    }

    // MARK: - Date Conversion

    /// Convert Gregorian date to Hijri date (applies moon sighting offset)
    func convertToHijri(from gregorianDate: Date = Date()) -> HijriDate {
        // Apply moon sighting offset: shifting the Gregorian input date shifts
        // the resulting Hijri date by the same number of days.
        let adjustedDate = hijriDayOffset == 0
            ? gregorianDate
            : (Calendar.current.date(byAdding: .day, value: hijriDayOffset, to: gregorianDate) ?? gregorianDate)

        let components = islamicCalendar.dateComponents([.year, .month, .day, .weekday], from: adjustedDate)

        let monthNumber = components.month ?? 1
        let monthEnum = HijriMonth.allCases[safe: monthNumber - 1] ?? .muharram
        let weekdayNumber = components.weekday ?? 1
        let weekdayName = Calendar.current.weekdaySymbols[weekdayNumber - 1]
        let day = components.day ?? 1
        let year = components.year ?? 1446

        return HijriDate(
            day: day,
            month: HijriMonthData(
                number: monthNumber,
                en: monthEnum.name,
                ar: monthEnum.arabicName,
                days: nil
            ),
            year: year,
            weekday: WeekdayData(
                en: weekdayName,
                ar: ""
            ),
            date: "\(day)-\(monthNumber)-\(year)",
            format: "DD-MM-YYYY",
            designation: DesignationData(
                abbreviated: "AH",
                expanded: "Anno Hegirae"
            ),
            holidays: [],
            adjustedHolidays: [],
            method: "Apple Islamic Calendar"
        )
    }

    /// Convert Hijri date to approximate Gregorian date
    func convertToGregorian(hijriDate: HijriDate) -> Date? {
        var components = DateComponents()
        components.calendar = islamicCalendar
        components.year = hijriDate.year
        components.month = hijriDate.month.number
        components.day = hijriDate.day

        return islamicCalendar.date(from: components)
    }

    /// Get current Hijri month
    func getCurrentHijriMonth() -> HijriMonth {
        let hijriDate = convertToHijri()
        return HijriMonth(rawValue: hijriDate.month.number) ?? .muharram
    }

    /// Check if currently in Ramadan
    func isRamadan() -> Bool {
        getCurrentHijriMonth() == .ramadan
    }

    /// Get Ramadan tracker for current year
    func getCurrentRamadanTracker() -> RamadanTracker {
        let currentYear = convertToHijri().year
        if let tracker = ramadanTrackers[currentYear] {
            return tracker
        } else {
            let newTracker = RamadanTracker(year: currentYear)
            ramadanTrackers[currentYear] = newTracker
            saveRamadanTrackers()
            return newTracker
        }
    }

    // MARK: - Events Management

    /// Get all events
    func getAllEvents() -> [IslamicEvent] {
        return allEvents.sorted { event1, event2 in
            if event1.month.rawValue != event2.month.rawValue {
                return event1.month.rawValue < event2.month.rawValue
            }
            return event1.day < event2.day
        }
    }

    /// Get events by category
    func getEvents(for category: EventCategory) -> [IslamicEvent] {
        return allEvents.filter { $0.category == category }
            .sorted { $0.day < $1.day }
    }

    /// Get events for specific month
    func getEvents(for month: HijriMonth) -> [IslamicEvent] {
        return allEvents.filter { $0.month == month }
            .sorted { $0.day < $1.day }
    }

    /// Get upcoming events (next 30 days)
    func getUpcomingEvents(limit: Int = 10) -> [IslamicEvent] {
        let today = Date()
        let hijriToday = convertToHijri(from: today)

        var upcomingEvents: [(event: IslamicEvent, daysUntil: Int)] = []

        for event in allEvents {
            // Calculate days until event
            let monthNumber = event.month.rawValue
            let eventHijriDate = HijriDate(
                day: event.day,
                month: HijriMonthData(
                    number: monthNumber,
                    en: event.month.name,
                    ar: event.month.arabicName,
                    days: nil
                ),
                year: hijriToday.year,
                weekday: WeekdayData(en: "", ar: ""),
                date: "\(event.day)-\(monthNumber)-\(hijriToday.year)",
                format: "DD-MM-YYYY",
                designation: DesignationData(abbreviated: "AH", expanded: "Anno Hegirae"),
                holidays: [],
                adjustedHolidays: [],
                method: nil
            )

            if let eventDate = convertToGregorian(hijriDate: eventHijriDate) {
                let daysUntil = Calendar.current.dateComponents([.day], from: today, to: eventDate).day ?? 0

                if daysUntil >= 0 && daysUntil <= 30 {
                    upcomingEvents.append((event, daysUntil))
                }
            }
        }

        // Sort by days until
        upcomingEvents.sort { $0.daysUntil < $1.daysUntil }

        return upcomingEvents.prefix(limit).map { $0.event }
    }

    /// Get favorite events
    func getFavoriteEvents() -> [IslamicEvent] {
        return allEvents.filter { progress.isFavorite(eventKey: CalendarProgress.stableKey(for: $0)) }
    }

    /// Search events
    func searchEvents(query: String) -> [IslamicEvent] {
        let lowercased = query.lowercased()
        return allEvents.filter { event in
            event.name.lowercased().contains(lowercased) ||
            event.nameArabic.contains(lowercased) ||
            event.description.lowercased().contains(lowercased) ||
            event.month.name.lowercased().contains(lowercased)
        }
    }

    // MARK: - Progress Management

    func toggleFavorite(event: IslamicEvent) {
        progress.toggleFavorite(eventKey: CalendarProgress.stableKey(for: event))
        saveProgress()
    }

    func isFavorite(event: IslamicEvent) -> Bool {
        progress.isFavorite(eventKey: CalendarProgress.stableKey(for: event))
    }

    // MARK: - Ramadan Tracking

    func updateRamadanTracker(_ tracker: RamadanTracker) {
        ramadanTrackers[tracker.year] = tracker
        saveRamadanTrackers()
    }

    func toggleFasting(day: Int, year: Int) {
        var tracker = ramadanTrackers[year] ?? RamadanTracker(year: year)
        tracker.toggleFasting(day: day)
        ramadanTrackers[year] = tracker
        saveRamadanTrackers()
    }

    func toggleQiyam(night: Int, year: Int) {
        var tracker = ramadanTrackers[night] ?? RamadanTracker(year: year)
        tracker.toggleQiyam(night: night)
        ramadanTrackers[year] = tracker
        saveRamadanTrackers()
    }

    // MARK: - Persistence

    private static func loadProgress() -> CalendarProgress {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? decoder.decode(CalendarProgress.self, from: data) {
            return progress
        }
        return CalendarProgress()
    }

    private func saveProgress() {
        if let data = try? Self.encoder.encode(progress) {
            UserDefaults.standard.set(data, forKey: Self.progressKey)
        }
    }

    private static func loadRamadanTrackers() -> [Int: RamadanTracker] {
        if let data = UserDefaults.standard.data(forKey: ramadanTrackersKey),
           let trackers = try? decoder.decode([Int: RamadanTracker].self, from: data) {
            return trackers
        }
        return [:]
    }

    private func saveRamadanTrackers() {
        if let data = try? Self.encoder.encode(ramadanTrackers) {
            UserDefaults.standard.set(data, forKey: Self.ramadanTrackersKey)
        }
    }

    // MARK: - Events Database

    private static func createEventsDatabase() -> [IslamicEvent] {
        return [
            // Muharram
            IslamicEvent(
                name: "Islamic New Year",
                nameArabic: "رَأْس ٱلسَّنَة ٱلْهِجْرِيَّة",
                day: 1,
                month: .muharram,
                category: .historical,
                description: "First day of the Islamic calendar year",
                significance: "Marks the Hijrah (migration) of Prophet Muhammad ﷺ from Makkah to Madinah in 622 CE. This event established the first Muslim community.",
                actions: ["Reflect on Hijrah", "Make new intentions", "Seek Allah's guidance"]
            ),

            IslamicEvent(
                name: "Day of Ashura",
                nameArabic: "يَوْم عَاشُورَاء",
                day: 10,
                month: .muharram,
                category: .sacredDay,
                description: "The 10th day of Muharram, a day of great significance",
                significance: "The day Allah saved Prophet Musa (Moses) and the Israelites from Pharaoh. Prophet Muhammad ﷺ fasted this day and recommended fasting.",
                actions: ["Fast on 9th & 10th", "Increase charity", "Remember Allah's mercy"]
            ),

            // Rabi' al-Awwal
            IslamicEvent(
                name: "Mawlid an-Nabi",
                nameArabic: "مَوْلِد ٱلنَّبِي",
                day: 12,
                month: .rabiAlAwwal,
                category: .historical,
                description: "Birth of Prophet Muhammad ﷺ",
                significance: "The Prophet ﷺ was born on this day in Makkah. Some Muslims commemorate this day with gatherings, while scholarly opinions differ on celebrations.",
                actions: ["Send blessings on the Prophet", "Study his biography", "Follow his Sunnah"]
            ),

            // Rajab
            IslamicEvent(
                name: "Isra and Mi'raj",
                nameArabic: "ٱلْإِسْرَاء وَٱلْمِعْرَاج",
                day: 27,
                month: .rajab,
                category: .historical,
                description: "The Night Journey and Ascension of Prophet Muhammad ﷺ",
                significance: "The Prophet ﷺ was taken from Makkah to Jerusalem and then ascended through the heavens. During this journey, the five daily prayers were prescribed.",
                actions: ["Pray Tahajjud", "Reflect on the journey", "Be punctual with prayers"]
            ),

            // Sha'ban
            IslamicEvent(
                name: "Laylat al-Bara'ah",
                nameArabic: "لَيْلَة ٱلْبَرَاءَة",
                day: 15,
                month: .shaban,
                category: .recommended,
                description: "The Night of Forgiveness (Mid-Sha'ban)",
                significance: "A blessed night when Allah's mercy and forgiveness are abundant. Many Muslims spend this night in prayer and seeking forgiveness.",
                actions: ["Pray at night", "Seek forgiveness", "Fast the next day"]
            ),

            // Ramadan
            IslamicEvent(
                name: "First Day of Ramadan",
                nameArabic: "أَوَّل يَوْم رَمَضَان",
                day: 1,
                month: .ramadan,
                category: .ramadan,
                description: "Beginning of the blessed month of fasting",
                significance: "The month in which the Quran was revealed. Fasting is obligatory for all adult Muslims. Gates of Paradise are opened and gates of Hell are closed.",
                actions: ["Fast from dawn to sunset", "Increase Quran recitation", "Give charity"]
            ),

            IslamicEvent(
                name: "Laylat al-Qadr",
                nameArabic: "لَيْلَة ٱلْقَدْر",
                day: 27,
                month: .ramadan,
                category: .ramadan,
                description: "The Night of Power (likely 27th Ramadan)",
                significance: "The night when the Quran was first revealed. Better than 1000 months. Usually sought in the last 10 nights of Ramadan, especially odd nights.",
                actions: ["Pray Qiyam all night", "Seek Laylat al-Qadr", "Make abundant dua"]
            ),

            // Shawwal
            IslamicEvent(
                name: "Eid al-Fitr",
                nameArabic: "عِيد ٱلْفِطْر",
                day: 1,
                month: .shawwal,
                category: .eid,
                description: "Festival of Breaking the Fast",
                significance: "Celebrates the completion of Ramadan fasting. Muslims pray Eid prayer, give Zakat al-Fitr, and celebrate with family and community.",
                actions: ["Pray Eid prayer", "Give Zakat al-Fitr", "Visit family and friends", "Wear best clothes"]
            ),

            IslamicEvent(
                name: "Six Days of Shawwal",
                nameArabic: "سِتَّة أَيَّام مِن شَوَّال",
                day: 2,
                month: .shawwal,
                category: .recommended,
                description: "Recommended fasting after Eid",
                significance: "Fasting six days of Shawwal after Eid is equivalent to fasting the entire year. Can be done consecutively or separately.",
                actions: ["Fast 6 days", "Can be non-consecutive", "Great reward promised"]
            ),

            // Dhul-Hijjah
            IslamicEvent(
                name: "First Ten Days",
                nameArabic: "عَشْر ذِي ٱلْحِجَّة",
                day: 1,
                month: .dhulHijjah,
                category: .hajj,
                description: "The blessed first ten days of Dhul-Hijjah",
                significance: "The most blessed days of the year. Good deeds are more beloved to Allah in these days than any other days.",
                actions: ["Fast (especially 9th)", "Increase dhikr", "Give charity", "Good deeds"]
            ),

            IslamicEvent(
                name: "Day of Arafah",
                nameArabic: "يَوْم عَرَفَة",
                day: 9,
                month: .dhulHijjah,
                category: .hajj,
                description: "The day of standing at Arafah (for Hajj pilgrims)",
                significance: "The most important day of Hajj. For non-pilgrims, fasting this day expiates sins of the past and coming year.",
                actions: ["Fast (if not pilgrim)", "Make abundant dua", "Seek forgiveness"]
            ),

            IslamicEvent(
                name: "Eid al-Adha",
                nameArabic: "عِيد ٱلْأَضْحَىٰ",
                day: 10,
                month: .dhulHijjah,
                category: .eid,
                description: "Festival of Sacrifice",
                significance: "Commemorates Prophet Ibrahim's willingness to sacrifice his son. Pilgrims complete Hajj. Muslims sacrifice animals and distribute meat to the poor.",
                actions: ["Pray Eid prayer", "Sacrifice animal (if able)", "Distribute meat to needy", "Visit family"]
            ),

            IslamicEvent(
                name: "Days of Tashriq",
                nameArabic: "أَيَّام ٱلتَّشْرِيق",
                day: 11,
                month: .dhulHijjah,
                category: .hajj,
                description: "The three days following Eid al-Adha",
                significance: "Days of celebration, eating, and remembering Allah. Fasting is prohibited. Pilgrims complete final Hajj rituals.",
                actions: ["Make takbir after prayers", "Eat and celebrate", "Remember Allah"]
            ),

            // Additional Sacred Days

            IslamicEvent(
                name: "Day of Arafah Eve",
                nameArabic: "لَيْلَة عَرَفَة",
                day: 8,
                month: .dhulHijjah,
                category: .recommended,
                description: "Night before the Day of Arafah",
                significance: "A blessed night of worship before the greatest day of the year.",
                actions: ["Pray at night", "Prepare for fasting", "Make intention"]
            ),

            IslamicEvent(
                name: "Last Friday of Ramadan",
                nameArabic: "آخِر جُمُعَة مِن رَمَضَان",
                day: 25,
                month: .ramadan,
                category: .ramadan,
                description: "Final Friday of the blessed month",
                significance: "The last Jumu'ah of Ramadan, a particularly blessed day combining Friday and Ramadan blessings.",
                actions: ["Attend Jumu'ah", "Make abundant dua", "Seek Laylat al-Qadr"]
            )
        ]
    }
}

// MARK: - Array Extension
private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
