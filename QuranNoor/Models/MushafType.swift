//
//  MushafType.swift
//  QuranNoor
//
//  Represents available Quran script/mushaf types for Arabic text display
//

import Foundation

/// API source for fetching Quran Arabic text
enum MushafAPISource {
    case alquranCloud
    case fawazahmed0
}

/// Available mushaf types (Arabic script styles) for Quran reading
enum MushafType: String, CaseIterable, Identifiable, Codable {
    case uthmani = "quran-uthmani"
    case simpleEnhanced = "quran-simple-enhanced"
    case simpleClean = "quran-simple-clean"
    case indopak = "ara-quranindopak"

    var id: String { rawValue }

    /// Display name shown in the UI
    var displayName: String {
        switch self {
        case .uthmani:
            return "Uthmani"
        case .simpleEnhanced:
            return "Simple Enhanced"
        case .simpleClean:
            return "Simple Clean"
        case .indopak:
            return "IndoPak"
        }
    }

    /// Short name for compact UI (e.g. floating pill)
    var shortName: String {
        switch self {
        case .uthmani:
            return "Uthmani"
        case .simpleEnhanced:
            return "Simple"
        case .simpleClean:
            return "Clean"
        case .indopak:
            return "IndoPak"
        }
    }

    /// Description of the script style
    var description: String {
        switch self {
        case .uthmani:
            return "Traditional Uthmanic script used in Madinah Mushaf. Includes tajweed marks and classical calligraphy."
        case .simpleEnhanced:
            return "Simplified Arabic with diacritics. Easier to read for non-native speakers."
        case .simpleClean:
            return "Minimal Arabic script without diacritical marks. Clean and distraction-free."
        case .indopak:
            return "Nastaleeq-style script popular in South Asia (Pakistan, India, Bangladesh)."
        }
    }

    /// Font name to use for this mushaf type
    var fontName: String {
        switch self {
        case .uthmani:
            return "KFGQPCUthmanicScriptHAFS"
        case .simpleEnhanced, .simpleClean:
            return "" // Uses system Arabic font
        case .indopak:
            return "NotoNastaliqUrdu-Regular"
        }
    }

    /// Whether this mushaf type uses the system Arabic font
    var usesSystemFont: Bool {
        switch self {
        case .uthmani, .indopak:
            return false
        case .simpleEnhanced, .simpleClean:
            return true
        }
    }

    /// Which API to use for fetching Arabic text
    var apiSource: MushafAPISource {
        switch self {
        case .uthmani, .simpleEnhanced, .simpleClean:
            return .alquranCloud
        case .indopak:
            return .fawazahmed0
        }
    }

    /// Edition identifier for API calls
    var editionIdentifier: String {
        return rawValue
    }

    /// Whether this is the recommended default
    var isRecommended: Bool {
        self == .uthmani
    }

    /// Region/tradition this script is associated with
    var region: String {
        switch self {
        case .uthmani:
            return "Middle East & North Africa"
        case .simpleEnhanced:
            return "Universal"
        case .simpleClean:
            return "Universal"
        case .indopak:
            return "South Asia"
        }
    }
}
