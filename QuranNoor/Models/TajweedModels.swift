//
//  TajweedModels.swift
//  QuranNoor
//
//  Tajweed rule definitions and data structures.
//  Colors map to the traditional tajweed color-coding system used in
//  color-coded Quran prints (e.g. Tajweed Quran by Dar Al-Maarifah).
//

import SwiftUI

// MARK: - TajweedRule

/// Represents a single tajweed rule with its associated CSS class name,
/// display name, Arabic example, and color per theme.
enum TajweedRule: String, CaseIterable, Codable, Sendable {
    case hamWasl            = "ham_wasl"
    case laamShamsiyah      = "laam_shamsiyah"
    case silent             = "slnt"
    case maddaNormal        = "madda_normal"
    case maddaPermissible   = "madda_permissible"
    case maddaObligatory    = "madda_obligatory"
    case qalqalah           = "qlq"
    case ikhfa              = "ikhf"
    case ikhfaShafawi       = "ikhf_shfw"
    case idghamGhunnah      = "idgh_ghn"
    case idghamWithoutGhunnah = "idgh_w_ghn"
    case iqlab              = "iqlb"
    case ghunnah            = "ghn"

    // MARK: - CSS Class Name

    /// The HTML/CSS class name used in the Quran.com tajweed API response.
    var cssClass: String { rawValue }

    // MARK: - Factory

    /// Creates a TajweedRule from a CSS class name string.
    /// Returns nil if the class name is not recognised.
    static func from(cssClass: String) -> TajweedRule? {
        TajweedRule(rawValue: cssClass)
    }

    // MARK: - Display Name

    /// Human-readable English name for this rule.
    var displayName: String {
        switch self {
        case .hamWasl:              return "Hamzat Al-Wasl"
        case .laamShamsiyah:        return "Laam Shamsiyah"
        case .silent:               return "Silent Letter"
        case .maddaNormal:          return "Madd Normal (2 counts)"
        case .maddaPermissible:     return "Madd Permissible (2-6 counts)"
        case .maddaObligatory:      return "Madd Obligatory (6 counts)"
        case .qalqalah:             return "Qalqalah"
        case .ikhfa:                return "Ikhfa"
        case .ikhfaShafawi:         return "Ikhfa Shafawi"
        case .idghamGhunnah:        return "Idgham with Ghunnah"
        case .idghamWithoutGhunnah: return "Idgham without Ghunnah"
        case .iqlab:                return "Iqlab"
        case .ghunnah:              return "Ghunnah"
        }
    }

    // MARK: - Arabic Example

    /// A brief Arabic character or short example illustrating this rule.
    var arabicExample: String {
        switch self {
        case .hamWasl:              return "ٱ"
        case .laamShamsiyah:        return "ال"
        case .silent:               return "ء"
        case .maddaNormal:          return "ا"
        case .maddaPermissible:     return "آ"
        case .maddaObligatory:      return "ّ"
        case .qalqalah:             return "ق"
        case .ikhfa:                return "ن"
        case .ikhfaShafawi:         return "م"
        case .idghamGhunnah:        return "ن"
        case .idghamWithoutGhunnah: return "ن"
        case .iqlab:                return "ب"
        case .ghunnah:              return "ن"
        }
    }

    // MARK: - Color per Theme

    /// Returns the appropriate tajweed highlight color for the given theme.
    /// Colors follow the widely-used Dar Al-Maarifah color convention with
    /// adjustments for legibility in dark and sepia themes.
    func color(for theme: ThemeMode) -> Color {
        switch self {

        // Silent / Reduced – rendered as muted gray
        case .hamWasl, .laamShamsiyah, .silent:
            switch theme {
            case .light:        return Color(hex: "#AAAAAA")
            case .dark, .night: return Color(hex: "#888888")
            case .sepia:        return Color(hex: "#999988")
            }

        // Elongation – blue family
        case .maddaNormal:
            switch theme {
            case .light:        return Color(hex: "#537FFF")
            case .dark, .night: return Color(hex: "#6B93FF")
            case .sepia:        return Color(hex: "#4A6FCC")
            }

        case .maddaPermissible:
            switch theme {
            case .light:        return Color(hex: "#4050FF")
            case .dark, .night: return Color(hex: "#5A6AFF")
            case .sepia:        return Color(hex: "#3845CC")
            }

        case .maddaObligatory:
            switch theme {
            case .light:        return Color(hex: "#000EBC")
            case .dark, .night: return Color(hex: "#4455DD")
            case .sepia:        return Color(hex: "#1020AA")
            }

        // Emphasis – red
        case .qalqalah:
            switch theme {
            case .light:        return Color(hex: "#DD0008")
            case .dark, .night: return Color(hex: "#FF4444")
            case .sepia:        return Color(hex: "#CC1111")
            }

        // Nasalisation – purple / magenta family
        case .ikhfa:
            switch theme {
            case .light:        return Color(hex: "#9400A8")
            case .dark, .night: return Color(hex: "#BB44CC")
            case .sepia:        return Color(hex: "#8800AA")
            }

        case .ikhfaShafawi:
            switch theme {
            case .light:        return Color(hex: "#D500B7")
            case .dark, .night: return Color(hex: "#E855CC")
            case .sepia:        return Color(hex: "#BB0099")
            }

        case .idghamGhunnah, .idghamWithoutGhunnah:
            switch theme {
            case .light:        return Color(hex: "#169200")
            case .dark, .night: return Color(hex: "#44BB33")
            case .sepia:        return Color(hex: "#228800")
            }

        case .iqlab:
            switch theme {
            case .light:        return Color(hex: "#26BFFD")
            case .dark, .night: return Color(hex: "#55D4FF")
            case .sepia:        return Color(hex: "#2299CC")
            }

        case .ghunnah:
            switch theme {
            case .light:        return Color(hex: "#FF7E1E")
            case .dark, .night: return Color(hex: "#FF9944")
            case .sepia:        return Color(hex: "#DD6611")
            }
        }
    }
}

// MARK: - TajweedSegment

/// A run of Arabic text with an optional tajweed rule applied.
/// A nil rule indicates plain text that should use the default text color.
struct TajweedSegment: Codable, Sendable {
    /// The Arabic text for this segment (may span multiple characters).
    let text: String
    /// The tajweed rule governing this segment's color, or nil for plain text.
    let rule: TajweedRule?
}
