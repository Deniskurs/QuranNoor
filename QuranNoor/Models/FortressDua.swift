//
//  FortressDua.swift
//  QuranNoor
//
//  Data models for Fortress of the Muslim duas (Hisn al-Muslim)
//

import Foundation

// MARK: - Dua Category

/// Categories of duas from Fortress of the Muslim
enum DuaCategory: String, CaseIterable, Identifiable, Codable {
    case waking = "waking"
    case dressing = "dressing"
    case entering_leaving_home = "entering_leaving_home"
    case mosque = "mosque"
    case prayer = "prayer"
    case eating_drinking = "eating_drinking"
    case travel = "travel"
    case sleep = "sleep"
    case sickness = "sickness"
    case distress = "distress"
    case gratitude = "gratitude"
    case general = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .waking:
            return "Upon Waking"
        case .dressing:
            return "Wearing Clothes"
        case .entering_leaving_home:
            return "Entering & Leaving Home"
        case .mosque:
            return "Going to Mosque"
        case .prayer:
            return "Prayer Duas"
        case .eating_drinking:
            return "Eating & Drinking"
        case .travel:
            return "Travel"
        case .sleep:
            return "Sleep & Rest"
        case .sickness:
            return "Sickness & Healing"
        case .distress:
            return "Times of Distress"
        case .gratitude:
            return "Gratitude & Thanks"
        case .general:
            return "General Supplications"
        }
    }

    var description: String {
        switch self {
        case .waking:
            return "Duas to recite when waking up"
        case .dressing:
            return "Duas for wearing new or old clothes"
        case .entering_leaving_home:
            return "Duas for entering and leaving your home"
        case .mosque:
            return "Duas for entering and leaving the mosque"
        case .prayer:
            return "Duas related to prayer"
        case .eating_drinking:
            return "Duas before and after eating"
        case .travel:
            return "Duas for journey and travel"
        case .sleep:
            return "Duas before sleeping and upon waking from sleep"
        case .sickness:
            return "Duas for healing and visiting the sick"
        case .distress:
            return "Duas during hardship and anxiety"
        case .gratitude:
            return "Duas for expressing gratitude"
        case .general:
            return "General purpose supplications"
        }
    }

    var icon: String {
        switch self {
        case .waking:
            return "sun.max.fill"
        case .dressing:
            return "tshirt.fill"
        case .entering_leaving_home:
            return "house.fill"
        case .mosque:
            return "building.columns.fill"
        case .prayer:
            return "hands.sparkles.fill"
        case .eating_drinking:
            return "fork.knife"
        case .travel:
            return "car.fill"
        case .sleep:
            return "moon.stars.fill"
        case .sickness:
            return "cross.case.fill"
        case .distress:
            return "heart.text.square.fill"
        case .gratitude:
            return "star.fill"
        case .general:
            return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .waking:
            return "orange"
        case .dressing:
            return "purple"
        case .entering_leaving_home:
            return "blue"
        case .mosque:
            return "green"
        case .prayer:
            return "teal"
        case .eating_drinking:
            return "red"
        case .travel:
            return "indigo"
        case .sleep:
            return "purple"
        case .sickness:
            return "pink"
        case .distress:
            return "brown"
        case .gratitude:
            return "yellow"
        case .general:
            return "gray"
        }
    }
}

// MARK: - Fortress Dua

/// Individual dua from Fortress of the Muslim
struct FortressDua: Identifiable, Codable, Hashable {
    let id: UUID
    let category: DuaCategory
    let title: String
    let arabicText: String
    let transliteration: String
    let translation: String
    let reference: String
    let occasion: String
    let benefits: String?
    let order: Int

    init(
        id: UUID = UUID(),
        category: DuaCategory,
        title: String,
        arabicText: String,
        transliteration: String,
        translation: String,
        reference: String,
        occasion: String,
        benefits: String? = nil,
        order: Int
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.reference = reference
        self.occasion = occasion
        self.benefits = benefits
        self.order = order
    }
}

// MARK: - Dua Progress

/// User's progress with Fortress of the Muslim duas
struct DuaProgress: Codable {
    var favoriteDuas: Set<String>  // Stable dua keys (e.g., "waking:Upon Waking Up")
    var frequentlyUsed: [String: Int]  // Stable dua key -> usage count
    var lastAccessDate: Date?

    init() {
        self.favoriteDuas = []
        self.frequentlyUsed = [:]
        self.lastAccessDate = nil
    }

    /// Derive a stable string key from a FortressDua
    static func stableKey(for dua: FortressDua) -> String {
        "\(dua.category.rawValue):\(dua.title)"
    }

    mutating func toggleFavorite(duaKey: String) {
        if favoriteDuas.contains(duaKey) {
            favoriteDuas.remove(duaKey)
        } else {
            favoriteDuas.insert(duaKey)
        }
        lastAccessDate = Date()
    }

    mutating func incrementUsage(duaKey: String) {
        frequentlyUsed[duaKey, default: 0] += 1
        lastAccessDate = Date()
    }

    func isFavorite(duaKey: String) -> Bool {
        favoriteDuas.contains(duaKey)
    }

    func getUsageCount(duaKey: String) -> Int {
        frequentlyUsed[duaKey] ?? 0
    }

    var totalFavorites: Int {
        favoriteDuas.count
    }

    var totalUsages: Int {
        frequentlyUsed.values.reduce(0, +)
    }

    func getMostUsed(limit: Int = 5) -> [String] {
        frequentlyUsed.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}
