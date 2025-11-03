//
//  Colors.swift
//  QuraanNoor
//
//  Color palette for Islamic design system
//

import SwiftUI

// MARK: - App Colors
struct AppColors {
    static let primary = PrimaryColors()
    static let neutral = NeutralColors()

    struct PrimaryColors {
        let green = Color(hex: "#0D7377")      // Emerald
        let teal = Color(hex: "#14FFEC")       // Bright teal
        let gold = Color(hex: "#C7A566")       // Gold accent
        let midnight = Color(hex: "#1A2332")   // Midnight blue
    }

    struct NeutralColors {
        let cream = Color(hex: "#F8F4EA")
        let white = Color.white
        let gray = Color(hex: "#E5E5E5")
    }
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case night = "Night"
    case sepia = "Sepia"

    var id: String { rawValue }

    // MARK: - Background Colors (Hierarchy)

    /// Primary background - main app background
    var backgroundColor: Color {
        switch self {
        case .light: return Color(hex: "#F8F4EA")
        case .dark: return Color(hex: "#1A2332")
        case .night: return Color.black
        case .sepia: return Color(hex: "#F4E8D0")
        }
    }

    /// Secondary background - cards, panels
    var cardColor: Color {
        switch self {
        case .light: return Color.white
        case .dark: return Color(hex: "#2A3342")
        case .night: return Color(hex: "#1A1A1A")
        case .sepia: return Color(hex: "#FFFBF0")  // Slightly lighter for better contrast
        }
    }

    /// Tertiary background - elevated cards, modals
    var elevatedCardColor: Color {
        switch self {
        case .light: return Color.white
        case .dark: return Color(hex: "#323D4D")
        case .night: return Color(hex: "#252525")
        case .sepia: return Color(hex: "#FFFBF0")
        }
    }

    // MARK: - Text Colors (Semantic Hierarchy)

    /// Primary text - Body content, headings, Arabic Quran text
    /// Target: 7:1 contrast ratio (WCAG AAA)
    var textPrimary: Color {
        switch self {
        case .light: return Color(hex: "#1A2332")      // 13.4:1 contrast ✅
        case .dark: return Color(hex: "#F8F4EA")       // 13.4:1 contrast ✅
        case .night: return Color.white                // 21:1 contrast ✅ (OLED optimized)
        case .sepia: return Color(hex: "#3D2F1F")      // 9.2:1 contrast ✅ (improved from 5.8:1)
        }
    }

    /// Secondary text - Subheadings, labels, prayer names
    /// Target: 4.5:1 contrast ratio (WCAG AA)
    var textSecondary: Color {
        switch self {
        case .light: return Color(hex: "#3A4352")      // Direct color, ~10:1 contrast
        case .dark: return Color(hex: "#D4C8B0")       // Direct color, ~9:1 contrast
        case .night: return Color(white: 0.85)         // Solid gray for OLED (no opacity)
        case .sepia: return Color(hex: "#6B5D47")      // Darker sepia, ~6:1 contrast
        }
    }

    /// Tertiary text - Captions, timestamps, metadata
    /// Target: 3:1 contrast ratio (WCAG AA Large)
    var textTertiary: Color {
        switch self {
        case .light: return Color(hex: "#5A6372")      // Direct color, ~6:1 contrast
        case .dark: return Color(hex: "#A0A0A0")       // Direct color, ~5:1 contrast
        case .night: return Color(white: 0.65)         // Solid gray for OLED
        case .sepia: return Color(hex: "#8A7A60")      // Warm gray, ~4:1 contrast
        }
    }

    /// Disabled text - Inactive UI elements
    var textDisabled: Color {
        switch self {
        case .light: return textPrimary.opacity(0.50)
        case .dark: return textPrimary.opacity(0.40)
        case .night: return Color(white: 0.40)
        case .sepia: return Color(hex: "#A89878")
        }
    }

    // MARK: - Legacy Support (for gradual migration)

    /// Legacy textColor property - maps to textPrimary
    /// @deprecated Use textPrimary instead
    var textColor: Color {
        textPrimary
    }

    var borderColor: Color {
        switch self {
        case .light: return Color(hex: "#E5E5E5")
        case .dark: return Color(hex: "#3A4352")
        case .night: return Color(hex: "#2A2A2A")
        case .sepia: return Color(hex: "#D4C8B0")
        }
    }

    // MARK: - Functional Colors

    /// Divider lines
    var divider: Color {
        textPrimary.opacity(0.15)
    }

    /// Subtle borders
    var border: Color {
        textPrimary.opacity(0.20)
    }

    // MARK: - Accent Colors (Theme-Adaptive)

    var accentPrimary: Color {
        AppColors.primary.green
    }

    var accentSecondary: Color {
        switch self {
        case .light, .sepia: return AppColors.primary.gold
        case .dark, .night: return AppColors.primary.teal
        }
    }

    /// Active prayer card background (solid gold with high contrast text)
    var prayerActiveBackground: Color {
        AppColors.primary.gold  // #C7A566
    }

    /// Active prayer card text color (ensures contrast with gold)
    var prayerActiveText: Color {
        switch self {
        case .light, .sepia:
            return Color(hex: "#1A2332")  // Midnight on gold: ~5.2:1 ✅
        case .dark, .night:
            return Color(hex: "#1A2332")  // Midnight on gold works best
        }
    }

    // MARK: - Gradient Support

    /// Whether this theme supports decorative gradients
    var supportsGradients: Bool {
        self != .sepia  // No gradients in sepia mode for reading comfort
    }

    /// Theme-appropriate gradient colors
    var gradientColors: [Color] {
        switch self {
        case .light:
            return [
                AppColors.primary.teal.opacity(0.15),
                AppColors.primary.green.opacity(0.20)
            ]
        case .dark:
            return [
                AppColors.primary.green.opacity(0.30),
                AppColors.primary.midnight.opacity(0.80)
            ]
        case .night:
            return [Color.black, Color.black]  // Pure black for OLED
        case .sepia:
            return [
                Color(hex: "#E8DCC8"),  // Warm beige
                Color(hex: "#C8B59A")   // Warm tan (good contrast)
            ]
        }
    }

    /// Maximum safe gradient opacity for accent colors
    func gradientOpacity(for color: Color) -> Double {
        let isLight = self == .light || self == .sepia

        // Sepia mode: no gradients
        if self == .sepia { return 0.0 }

        // Theme-specific opacity limits
        if color == AppColors.primary.gold {
            return isLight ? 0.08 : 0.20
        } else if color == AppColors.primary.green {
            return isLight ? 0.06 : 0.18
        } else if color == AppColors.primary.teal {
            return isLight ? 0.04 : 0.12
        }
        return 0.0
    }

    // MARK: - Theme-Specific Opacity Values

    /// Opacity for secondary text elements
    var secondaryOpacity: Double {
        switch self {
        case .light, .sepia: return 0.85  // Higher opacity on light backgrounds
        case .dark, .night: return 0.75   // Lower opacity works on dark
        }
    }

    /// Opacity for tertiary text elements
    var tertiaryOpacity: Double {
        switch self {
        case .light, .sepia: return 0.70
        case .dark, .night: return 0.60
        }
    }

    /// Opacity for disabled text elements
    var disabledOpacity: Double {
        switch self {
        case .light, .sepia: return 0.50
        case .dark, .night: return 0.40
        }
    }

    // MARK: - SwiftUI ColorScheme

    var colorScheme: ColorScheme {
        switch self {
        case .light, .sepia: return .light
        case .dark, .night: return .dark
        }
    }
}
