//
//  TranslationEdition.swift
//  QuranNoor
//
//  Represents available Quran translation editions
//

import Foundation

/// Available translation editions for Quran
enum TranslationEdition: String, CaseIterable, Identifiable, Codable {
    // English translations
    case sahihInternational = "en.sahih"
    case pickthall = "en.pickthall"
    case yusufAli = "en.yusufali"
    case clearQuran = "en.ahmedali"

    // French translation
    case hamidullah = "fr.hamidullah"

    // Urdu translation
    case jalandhry = "ur.jalandhry"

    // Indonesian translation
    case indonesian = "id.indonesian"

    var id: String { rawValue }

    /// Display name for the translation
    var displayName: String {
        switch self {
        case .sahihInternational:
            return "Sahih International"
        case .pickthall:
            return "Pickthall"
        case .yusufAli:
            return "Yusuf Ali"
        case .clearQuran:
            return "Ahmed Ali"
        case .hamidullah:
            return "Hamidullah"
        case .jalandhry:
            return "Jalandhry"
        case .indonesian:
            return "Indonesian Ministry"
        }
    }

    /// Full name with author details
    var fullName: String {
        switch self {
        case .sahihInternational:
            return "Sahih International (Modern English)"
        case .pickthall:
            return "Marmaduke Pickthall (Classic English)"
        case .yusufAli:
            return "Abdullah Yusuf Ali (Traditional)"
        case .clearQuran:
            return "Ahmed Ali (Clear Quran)"
        case .hamidullah:
            return "Muhammad Hamidullah (French)"
        case .jalandhry:
            return "Fateh Muhammad Jalandhry (Urdu)"
        case .indonesian:
            return "Indonesian Ministry of Religious Affairs"
        }
    }

    /// Description of the translation style
    var description: String {
        switch self {
        case .sahihInternational:
            return "Modern, clear English translation by Saheeh International. Easy to understand and widely accepted."
        case .pickthall:
            return "One of the earliest English translations (1930). Poetic and reverential style."
        case .yusufAli:
            return "Classic translation with commentary. Widely respected and traditional."
        case .clearQuran:
            return "Contemporary translation focused on clarity and modern English."
        case .hamidullah:
            return "Most widely used French translation. Clear and faithful to the original Arabic."
        case .jalandhry:
            return "Popular Urdu translation with beautiful language and literary style."
        case .indonesian:
            return "Official Indonesian translation by the Ministry of Religious Affairs."
        }
    }

    /// Language code
    var language: String {
        switch self {
        case .sahihInternational, .pickthall, .yusufAli, .clearQuran:
            return "English"
        case .hamidullah:
            return "French"
        case .jalandhry:
            return "Urdu"
        case .indonesian:
            return "Indonesian"
        }
    }

    /// Author name
    var author: String {
        switch self {
        case .sahihInternational:
            return "Saheeh International"
        case .pickthall:
            return "Marmaduke Pickthall"
        case .yusufAli:
            return "Abdullah Yusuf Ali"
        case .clearQuran:
            return "Ahmed Ali"
        case .hamidullah:
            return "Muhammad Hamidullah"
        case .jalandhry:
            return "Fateh Muhammad Jalandhry"
        case .indonesian:
            return "Indonesian Ministry"
        }
    }

    /// Recommended for beginners
    var recommendedForBeginners: Bool {
        switch self {
        case .sahihInternational, .clearQuran, .indonesian:
            return true
        case .pickthall, .yusufAli, .hamidullah, .jalandhry:
            return false
        }
    }

    /// Year of publication
    var year: Int {
        switch self {
        case .sahihInternational:
            return 1997
        case .pickthall:
            return 1930
        case .yusufAli:
            return 1934
        case .clearQuran:
            return 2009
        case .hamidullah:
            return 1959
        case .jalandhry:
            return 1955
        case .indonesian:
            return 2002
        }
    }
}

/// User's translation preferences
struct TranslationPreferences: Codable {
    /// Primary translation to display
    var primaryTranslation: TranslationEdition

    /// Secondary translations to show (optional)
    var secondaryTranslations: [TranslationEdition]

    /// Show multiple translations side by side
    var showMultipleTranslations: Bool

    /// Default initializer
    init(
        primaryTranslation: TranslationEdition = .sahihInternational,
        secondaryTranslations: [TranslationEdition] = [],
        showMultipleTranslations: Bool = false
    ) {
        self.primaryTranslation = primaryTranslation
        self.secondaryTranslations = secondaryTranslations
        self.showMultipleTranslations = showMultipleTranslations
    }
}
