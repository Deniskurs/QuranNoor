//
//  NamesOfAllah.swift
//  QuranNoor
//
//  Data model for the 99 Names of Allah (Asma ul Husna)
//

import Foundation

// MARK: - Name of Allah

/// Individual name of Allah from Asma ul Husna
struct NameOfAllah: Identifiable, Codable, Hashable {
    let id: UUID
    let number: Int  // 1-99
    let arabicName: String
    let transliteration: String
    let translation: String
    let meaning: String
    let benefit: String?
    let reference: String?

    init(
        id: UUID = UUID(),
        number: Int,
        arabicName: String,
        transliteration: String,
        translation: String,
        meaning: String,
        benefit: String? = nil,
        reference: String? = nil
    ) {
        self.id = id
        self.number = number
        self.arabicName = arabicName
        self.transliteration = transliteration
        self.translation = translation
        self.meaning = meaning
        self.benefit = benefit
        self.reference = reference
    }

    /// Full display title with number
    var fullTitle: String {
        "\(number). \(transliteration)"
    }

    /// Short display without number
    var shortTitle: String {
        transliteration
    }
}

// MARK: - Names Category

/// Categories for grouping Names of Allah
enum NamesCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case mercy = "mercy"
    case power = "power"
    case knowledge = "knowledge"
    case perfection = "perfection"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "All Names"
        case .mercy:
            return "Mercy & Compassion"
        case .power:
            return "Power & Might"
        case .knowledge:
            return "Knowledge & Wisdom"
        case .perfection:
            return "Perfection & Beauty"
        }
    }

    var icon: String {
        switch self {
        case .all:
            return "list.bullet"
        case .mercy:
            return "heart.fill"
        case .power:
            return "bolt.fill"
        case .knowledge:
            return "brain.head.profile"
        case .perfection:
            return "star.fill"
        }
    }
}

// MARK: - Names Progress

/// User's progress with Names of Allah
struct NamesProgress: Codable {
    var learnedNames: Set<Int>  // Numbers of learned names
    var favoriteNames: Set<Int>  // Numbers of favorite names
    var lastAccessDate: Date?

    init() {
        self.learnedNames = []
        self.favoriteNames = []
        self.lastAccessDate = nil
    }

    mutating func markAsLearned(number: Int) {
        learnedNames.insert(number)
        lastAccessDate = Date()
    }

    mutating func toggleFavorite(number: Int) {
        if favoriteNames.contains(number) {
            favoriteNames.remove(number)
        } else {
            favoriteNames.insert(number)
        }
        lastAccessDate = Date()
    }

    func isLearned(number: Int) -> Bool {
        learnedNames.contains(number)
    }

    func isFavorite(number: Int) -> Bool {
        favoriteNames.contains(number)
    }

    var totalLearned: Int {
        learnedNames.count
    }

    var totalFavorites: Int {
        favoriteNames.count
    }

    var progressPercentage: Double {
        Double(learnedNames.count) / 99.0 * 100.0
    }
}
