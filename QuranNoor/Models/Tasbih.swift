//
//  Tasbih.swift
//  QuranNoor
//
//  Data models for digital tasbih counter (prayer beads)
//

import Foundation

// MARK: - Cached Formatter (Performance: avoid repeated allocation)
private let tasbihHistoryFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

// MARK: - Tasbih Preset

/// Common dhikr phrases with recommended counts
enum TasbihPreset: String, CaseIterable, Identifiable, Codable {
    case subhanAllah = "subhan_allah"
    case alhamdulillah = "alhamdulillah"
    case allahuAkbar = "allahu_akbar"
    case laIlahaIllallah = "la_ilaha_illallah"
    case astaghfirullah = "astaghfirullah"
    case allahumma = "allahumma"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .subhanAllah:
            return "SubhanAllah"
        case .alhamdulillah:
            return "Alhamdulillah"
        case .allahuAkbar:
            return "Allahu Akbar"
        case .laIlahaIllallah:
            return "La ilaha illallah"
        case .astaghfirullah:
            return "Astaghfirullah"
        case .allahumma:
            return "Allahumma Salli"
        case .custom:
            return "Custom"
        }
    }

    var arabicText: String {
        switch self {
        case .subhanAllah:
            return "سُبْحَانَ اللَّهِ"
        case .alhamdulillah:
            return "الْحَمْدُ لِلَّهِ"
        case .allahuAkbar:
            return "اللَّهُ أَكْبَرُ"
        case .laIlahaIllallah:
            return "لَا إِلَٰهَ إِلَّا اللَّهُ"
        case .astaghfirullah:
            return "أَسْتَغْفِرُ اللَّهَ"
        case .allahumma:
            return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ"
        case .custom:
            return ""
        }
    }

    var transliteration: String {
        switch self {
        case .subhanAllah:
            return "SubhanAllah"
        case .alhamdulillah:
            return "Alhamdulillah"
        case .allahuAkbar:
            return "Allahu Akbar"
        case .laIlahaIllallah:
            return "La ilaha illallah"
        case .astaghfirullah:
            return "Astaghfirullah"
        case .allahumma:
            return "Allahumma salli 'ala Muhammad"
        case .custom:
            return ""
        }
    }

    var translation: String {
        switch self {
        case .subhanAllah:
            return "Glory be to Allah"
        case .alhamdulillah:
            return "All praise is due to Allah"
        case .allahuAkbar:
            return "Allah is the Greatest"
        case .laIlahaIllallah:
            return "There is no deity except Allah"
        case .astaghfirullah:
            return "I seek forgiveness from Allah"
        case .allahumma:
            return "O Allah, send blessings upon Muhammad"
        case .custom:
            return ""
        }
    }

    var defaultTarget: Int {
        switch self {
        case .subhanAllah, .alhamdulillah, .allahuAkbar:
            return 33  // After prayer
        case .laIlahaIllallah, .astaghfirullah, .allahumma:
            return 100
        case .custom:
            return 99
        }
    }

    var icon: String {
        switch self {
        case .subhanAllah:
            return "star.fill"
        case .alhamdulillah:
            return "heart.fill"
        case .allahuAkbar:
            return "flame.fill"
        case .laIlahaIllallah:
            return "moon.stars.fill"
        case .astaghfirullah:
            return "drop.fill"
        case .allahumma:
            return "sparkle"
        case .custom:
            return "pencil"
        }
    }

    var color: String {
        switch self {
        case .subhanAllah:
            return "blue"
        case .alhamdulillah:
            return "green"
        case .allahuAkbar:
            return "orange"
        case .laIlahaIllallah:
            return "purple"
        case .astaghfirullah:
            return "teal"
        case .allahumma:
            return "pink"
        case .custom:
            return "gray"
        }
    }
}

// MARK: - Tasbih Target

/// Common target counts
enum TasbihTarget: Int, CaseIterable, Identifiable {
    case eleven = 11
    case thirtythree = 33
    case seventyseven = 77
    case ninetynine = 99
    case hundred = 100
    case thousand = 1000
    case custom = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .eleven:
            return "11"
        case .thirtythree:
            return "33"
        case .seventyseven:
            return "77"
        case .ninetynine:
            return "99"
        case .hundred:
            return "100"
        case .thousand:
            return "1,000"
        case .custom:
            return "Custom"
        }
    }

    var description: String {
        switch self {
        case .eleven:
            return "Quick dhikr"
        case .thirtythree:
            return "After prayer"
        case .seventyseven:
            return "Extended dhikr"
        case .ninetynine:
            return "Traditional"
        case .hundred:
            return "Daily goal"
        case .thousand:
            return "Challenge"
        case .custom:
            return "Your choice"
        }
    }
}

// MARK: - Tasbih Session

/// A single tasbih counting session
struct TasbihSession: Identifiable, Codable {
    let id: UUID
    let preset: TasbihPreset
    let targetCount: Int
    var currentCount: Int
    let startDate: Date
    var endDate: Date?
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        preset: TasbihPreset,
        targetCount: Int,
        currentCount: Int = 0,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.preset = preset
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
    }

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Tasbih Statistics

/// Statistics for tasbih usage
struct TasbihStatistics: Codable {
    var totalSessions: Int
    var totalCount: Int
    var completedSessions: Int
    var currentStreak: Int
    var longestStreak: Int
    var todayCount: Int
    var lastSessionDate: Date?

    init() {
        self.totalSessions = 0
        self.totalCount = 0
        self.completedSessions = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.todayCount = 0
        self.lastSessionDate = nil
    }

    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions) * 100.0
    }

    mutating func updateStreak() {
        guard let lastDate = lastSessionDate else {
            currentStreak = 1
            longestStreak = max(longestStreak, currentStreak)
            return
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            // Already counted today
            return
        } else if calendar.isDate(lastDate, inSameDayAs: Date().addingTimeInterval(-86400)) {
            // Was yesterday, increment streak
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Missed a day, reset streak
            currentStreak = 1
        }
    }

    mutating func checkAndResetDaily() {
        guard let lastDate = lastSessionDate else { return }

        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            todayCount = 0
        }
    }
}

// MARK: - Tasbih History Entry

/// Individual history entry
struct TasbihHistoryEntry: Identifiable, Codable {
    let id: UUID
    let session: TasbihSession
    let date: Date

    init(id: UUID = UUID(), session: TasbihSession, date: Date = Date()) {
        self.id = id
        self.session = session
        self.date = date
    }

    var formattedDate: String {
        tasbihHistoryFormatter.string(from: date)
    }
}
