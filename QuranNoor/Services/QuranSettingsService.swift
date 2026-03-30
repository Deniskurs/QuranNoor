//
//  QuranSettingsService.swift
//  QuranNoor
//
//  Manages Quran reader preferences (font size, theme, etc.)
//

import Foundation
import SwiftUI
import os

// MARK: - Font Size Options
enum QuranFontSize: String, CaseIterable, Identifiable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    case extraExtraLarge = "extraExtraLarge"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        case .extraLarge:
            return "Extra Large"
        case .extraExtraLarge:
            return "XXL"
        }
    }

    var arabicSize: CGFloat {
        switch self {
        case .small:
            return 20
        case .medium:
            return 24
        case .large:
            return 32
        case .extraLarge:
            return 40
        case .extraExtraLarge:
            return 48
        }
    }

    var translationSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 18
        case .extraLarge:
            return 20
        case .extraExtraLarge:
            return 22
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        case .extraLarge:
            return 12
        case .extraExtraLarge:
            return 14
        }
    }
}

// MARK: - Quran Settings Service
@Observable
@MainActor
final class QuranSettingsService {
    // MARK: - Singleton
    static let shared = QuranSettingsService()

    // MARK: - Published Properties
    private(set) var fontSize: QuranFontSize
    private(set) var showTransliteration: Bool
    private(set) var showTranslation: Bool
    private(set) var mushafType: MushafType
    private(set) var showTajweed: Bool
    private(set) var showWordByWord: Bool

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let fontSize = "quran_font_size"
        static let showTransliteration = "quran_show_transliteration"
        static let showTranslation = "quran_show_translation"
        static let mushafType = "quran_mushaf_type"
        static let showTajweed = "quran_show_tajweed"
        static let showWordByWord = "quran_show_word_by_word"
    }

    // MARK: - Initialization
    private init() {
        // Load saved preferences
        if let savedFontSizeRaw = UserDefaults.standard.string(forKey: Keys.fontSize),
           let savedFontSize = QuranFontSize(rawValue: savedFontSizeRaw) {
            self.fontSize = savedFontSize
        } else {
            self.fontSize = .medium // Default
        }

        self.showTransliteration = UserDefaults.standard.object(forKey: Keys.showTransliteration) as? Bool ?? false
        self.showTranslation = UserDefaults.standard.object(forKey: Keys.showTranslation) as? Bool ?? true

        if let savedMushafRaw = UserDefaults.standard.string(forKey: Keys.mushafType),
           let savedMushaf = MushafType(rawValue: savedMushafRaw) {
            self.mushafType = savedMushaf
        } else {
            self.mushafType = .uthmani
        }

        self.showTajweed = UserDefaults.standard.object(forKey: Keys.showTajweed) as? Bool ?? false
        self.showWordByWord = UserDefaults.standard.object(forKey: Keys.showWordByWord) as? Bool ?? false

        AppLogger.settings.debug("QuranSettingsService initialized: fontSize=\(self.fontSize.displayName, privacy: .public), mushaf=\(self.mushafType.displayName, privacy: .public)")
    }

    // MARK: - Public Methods

    /// Set font size for Quran text
    func setFontSize(_ size: QuranFontSize) {
        fontSize = size
        UserDefaults.standard.set(size.rawValue, forKey: Keys.fontSize)
        AppLogger.settings.debug("Quran font size set to: \(size.displayName, privacy: .public)")
    }

    /// Set mushaf type (Arabic script style)
    func setMushafType(_ type: MushafType) {
        mushafType = type
        UserDefaults.standard.set(type.rawValue, forKey: Keys.mushafType)
        AppLogger.settings.debug("Mushaf type set to: \(type.displayName, privacy: .public)")
    }

    /// Toggle transliteration visibility
    func toggleTransliteration() {
        showTransliteration.toggle()
        UserDefaults.standard.set(showTransliteration, forKey: Keys.showTransliteration)
        AppLogger.settings.debug("Transliteration \(self.showTransliteration ? "enabled" : "disabled", privacy: .public)")
    }

    /// Toggle translation visibility
    func toggleTranslation() {
        showTranslation.toggle()
        UserDefaults.standard.set(showTranslation, forKey: Keys.showTranslation)
        AppLogger.settings.debug("Translation \(self.showTranslation ? "enabled" : "disabled", privacy: .public)")
    }

    /// Toggle tajweed color coding
    func toggleTajweed() {
        showTajweed.toggle()
        UserDefaults.standard.set(showTajweed, forKey: Keys.showTajweed)
        AppLogger.settings.debug("Tajweed \(self.showTajweed ? "enabled" : "disabled", privacy: .public)")
    }

    /// Toggle word-by-word display
    func toggleWordByWord() {
        showWordByWord.toggle()
        UserDefaults.standard.set(showWordByWord, forKey: Keys.showWordByWord)
        AppLogger.settings.debug("Word-by-word \(self.showWordByWord ? "enabled" : "disabled", privacy: .public)")
    }

    /// Reset to defaults
    func resetToDefaults() {
        setFontSize(.medium)
        setMushafType(.uthmani)
        showTransliteration = false
        showTranslation = true
        showTajweed = false
        showWordByWord = false
        UserDefaults.standard.set(showTransliteration, forKey: Keys.showTransliteration)
        UserDefaults.standard.set(showTranslation, forKey: Keys.showTranslation)
        UserDefaults.standard.set(showTajweed, forKey: Keys.showTajweed)
        UserDefaults.standard.set(showWordByWord, forKey: Keys.showWordByWord)
        AppLogger.settings.debug("Quran settings reset to defaults")
    }
}
