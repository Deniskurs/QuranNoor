//
//  QuranSettingsService.swift
//  QuranNoor
//
//  Manages Quran reader preferences (font size, theme, etc.)
//

import Foundation
import SwiftUI

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

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let fontSize = "quran_font_size"
        static let showTransliteration = "quran_show_transliteration"
        static let showTranslation = "quran_show_translation"
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

        print("✅ QuranSettingsService initialized: fontSize=\(fontSize.displayName)")
    }

    // MARK: - Public Methods

    /// Set font size for Quran text
    func setFontSize(_ size: QuranFontSize) {
        fontSize = size
        UserDefaults.standard.set(size.rawValue, forKey: Keys.fontSize)
        print("✅ Quran font size set to: \(size.displayName)")
    }

    /// Toggle transliteration visibility
    func toggleTransliteration() {
        showTransliteration.toggle()
        UserDefaults.standard.set(showTransliteration, forKey: Keys.showTransliteration)
        print("✅ Transliteration \(showTransliteration ? "enabled" : "disabled")")
    }

    /// Toggle translation visibility
    func toggleTranslation() {
        showTranslation.toggle()
        UserDefaults.standard.set(showTranslation, forKey: Keys.showTranslation)
        print("✅ Translation \(showTranslation ? "enabled" : "disabled")")
    }

    /// Reset to defaults
    func resetToDefaults() {
        setFontSize(.medium)
        showTransliteration = false
        showTranslation = true
        UserDefaults.standard.set(showTransliteration, forKey: Keys.showTransliteration)
        UserDefaults.standard.set(showTranslation, forKey: Keys.showTranslation)
        print("✅ Quran settings reset to defaults")
    }
}
