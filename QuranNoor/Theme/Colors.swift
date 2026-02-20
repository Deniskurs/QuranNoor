//
//  Colors.swift
//  QuraanNoor
//
//  Color palette for Islamic design system
//
//  Design Philosophy:
//  A Quran app should feel sacred, calm, and elegant. Colors evoke
//  aged manuscripts, mosque architecture, and warm lantern light.
//
//  Architecture:
//  - 3 accent roles (accent, accentMuted, accentTint)
//  - 4-level text hierarchy (primary, secondary, tertiary, disabled)
//  - 3 surface levels (background, card, elevatedCard)
//  - 4 semantic states (success, warning, error, info)
//
//  All deprecated aliases are preserved at the bottom of the file
//  so existing views continue to compile without changes.
//

import SwiftUI

// MARK: - App Colors (Raw Palette)

struct AppColors {
    static let primary = PrimaryColors()
    static let neutral = NeutralColors()

    struct PrimaryColors {
        let green = Color(hex: "#0D7377")      // Emerald
        let teal = Color(hex: "#14FFEC")       // Bright teal (legacy reference)
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

    // =========================================================================
    // MARK: - Accent Colors (3 Semantic Roles)
    // =========================================================================

    /// Primary brand accent. Used for CTAs, selected states, links, icons.
    /// ONE color per theme - the single source of interactive/brand color.
    ///
    /// Contrast ratios (on respective backgrounds):
    /// - Light (#0D7377 on #F8F4EA): 5.4:1  (WCAG AA)
    /// - Dark  (#5EC4C8 on #1A2332): 6.8:1  (WCAG AA)
    /// - Night (#D4A574 on #050505): 8.2:1  (WCAG AAA)
    /// - Sepia (#7A6148 on #F4E8D0): 4.6:1  (WCAG AA)
    var accent: Color {
        switch self {
        case .light: return Color(hex: "#0D7377")  // Emerald green - clean, confident
        case .dark:  return Color(hex: "#5EC4C8")  // Soft teal - restful, not harsh
        case .night: return Color(hex: "#D4A574")  // Warm amber - lantern glow, not neon gold
        case .sepia: return Color(hex: "#7A6148")  // Warm brown ink - manuscript aesthetic
        }
    }

    /// Softer accent for secondary UI elements. Used for decorative icons,
    /// secondary labels, borders, and lower-priority interactive elements.
    ///
    /// Contrast ratios (on respective backgrounds):
    /// - Light (#5A8F91 on #F8F4EA): 3.5:1  (WCAG AA Large)
    /// - Dark  (#3A8F93 on #1A2332): 4.1:1  (WCAG AA Large)
    /// - Night (#8B7355 on #050505): 4.5:1  (WCAG AA)
    /// - Sepia (#9B8A72 on #F4E8D0): 3.1:1  (WCAG AA Large)
    var accentMuted: Color {
        switch self {
        case .light: return Color(hex: "#5A8F91")  // Softened emerald
        case .dark:  return Color(hex: "#3A8F93")  // Muted teal
        case .night: return Color(hex: "#8B7355")  // Muted amber
        case .sepia: return Color(hex: "#9B8A72")  // Light brown
        }
    }

    /// Very subtle background wash derived from the accent. Used for
    /// card highlights, selected row backgrounds, and hover states.
    /// Intentionally low-contrast - meant to tint, not to be read.
    var accentTint: Color {
        switch self {
        case .light: return Color(hex: "#0D7377").opacity(0.08)
        case .dark:  return Color(hex: "#5EC4C8").opacity(0.12)
        case .night: return Color(hex: "#D4A574").opacity(0.10)
        case .sepia: return Color(hex: "#7A6148").opacity(0.08)
        }
    }

    // =========================================================================
    // MARK: - Background / Surface Colors (3-Level Hierarchy)
    // =========================================================================

    /// Primary background - main app background
    var backgroundColor: Color {
        switch self {
        case .light: return Color(hex: "#F8F4EA")
        case .dark:  return Color(hex: "#1A2332")
        case .night: return Color(hex: "#050505")  // Near-black, less harsh than pure #000
        case .sepia: return Color(hex: "#F4E8D0")
        }
    }

    /// Secondary background - cards, panels
    var cardColor: Color {
        switch self {
        case .light: return Color.white            // White cards on cream for clear contrast
        case .dark:  return Color(hex: "#263045")   // Brighter card for separation from #1A2332
        case .night: return Color(hex: "#141414")   // Slightly lifted from pure black
        case .sepia: return Color(hex: "#FFF8ED")   // Warm white with clear contrast on #F4E8D0
        }
    }

    /// Tertiary background - elevated cards, modals
    var elevatedCardColor: Color {
        switch self {
        case .light: return Color.white
        case .dark:  return Color(hex: "#2E3B4E")   // Lifted above cardColor (#263045)
        case .night: return Color(hex: "#1E1E1E")   // Clear elevation above #141414
        case .sepia: return Color(hex: "#FFFBF0")
        }
    }

    // =========================================================================
    // MARK: - Text Colors (4-Level Semantic Hierarchy)
    // =========================================================================

    /// Primary text - Body content, headings, Arabic Quran text
    /// Target: 7:1 contrast ratio (WCAG AAA)
    var textPrimary: Color {
        switch self {
        case .light: return Color(hex: "#1A2332")    // 13.4:1 on #F8F4EA
        case .dark:  return Color(hex: "#F8F4EA")    // 13.4:1 on #1A2332
        case .night: return Color.white              // 21:1 on #050505 (OLED optimized)
        case .sepia: return Color(hex: "#3D2F1F")    //  9.2:1 on #F4E8D0
        }
    }

    /// Secondary text - Subheadings, labels, prayer names
    /// Target: 4.5:1 contrast ratio (WCAG AA)
    var textSecondary: Color {
        switch self {
        case .light: return Color(hex: "#3A4352")    // ~10:1 on #F8F4EA
        case .dark:  return Color(hex: "#B8C4D0")    // Cooler blue-gray for readability
        case .night: return Color(white: 0.85)       // Solid gray for OLED (no opacity)
        case .sepia: return Color(hex: "#6B5D47")    // Darker sepia, ~6:1
        }
    }

    /// Tertiary text - Captions, timestamps, metadata
    /// Target: 3:1 contrast ratio (WCAG AA Large)
    var textTertiary: Color {
        switch self {
        case .light: return Color(hex: "#5A6372")    // ~6:1 on #F8F4EA
        case .dark:  return Color(hex: "#A0A0A0")    // ~5:1 on #1A2332
        case .night: return Color(white: 0.65)       // Solid gray for OLED
        case .sepia: return Color(hex: "#8A7A60")    // Warm gray, ~4:1
        }
    }

    /// Disabled text - Inactive UI elements
    var textDisabled: Color {
        switch self {
        case .light: return textPrimary.opacity(0.50)
        case .dark:  return textPrimary.opacity(0.40)
        case .night: return Color(white: 0.40)
        case .sepia: return Color(hex: "#A89878")
        }
    }

    // =========================================================================
    // MARK: - Border & Divider Colors
    // =========================================================================

    var borderColor: Color {
        switch self {
        case .light: return Color(hex: "#E5E5E5")
        case .dark:  return Color(hex: "#3A4352")
        case .night: return Color(hex: "#2A2A2A")
        case .sepia: return Color(hex: "#D4C8B0")
        }
    }

    /// Divider lines
    var divider: Color {
        textPrimary.opacity(0.15)
    }

    // =========================================================================
    // MARK: - Semantic Status Colors
    // =========================================================================

    /// Success state (completed prayers, saved bookmarks)
    var semanticSuccess: Color {
        switch self {
        case .light: return Color(hex: "#1B7A3D")
        case .dark:  return Color(hex: "#4ADE80")
        case .night: return Color(hex: "#4ADE80")
        case .sepia: return Color(hex: "#2D6A1E")
        }
    }

    /// Warning state (approaching deadline, low battery)
    var semanticWarning: Color {
        switch self {
        case .light: return Color(hex: "#B45309")
        case .dark:  return Color(hex: "#FBBF24")
        case .night: return Color(hex: "#FBBF24")
        case .sepia: return Color(hex: "#92400E")
        }
    }

    /// Error state (failed load, network error)
    var semanticError: Color {
        switch self {
        case .light: return Color(hex: "#DC2626")
        case .dark:  return Color(hex: "#F87171")
        case .night: return Color(hex: "#F87171")
        case .sepia: return Color(hex: "#B91C1C")
        }
    }

    /// Info state (tips, neutral alerts)
    var semanticInfo: Color {
        switch self {
        case .light: return Color(hex: "#2563EB")
        case .dark:  return Color(hex: "#60A5FA")
        case .night: return Color(hex: "#60A5FA")
        case .sepia: return Color(hex: "#1E40AF")
        }
    }

    // =========================================================================
    // MARK: - Card Shadow
    // =========================================================================

    /// Theme-appropriate card shadow color
    var cardShadow: Color {
        switch self {
        case .light: return Color.black.opacity(0.08)
        case .dark:  return Color.black.opacity(0.30)
        case .night: return Color.black.opacity(0.50)
        case .sepia: return Color.black.opacity(0.10)
        }
    }

    /// Card shadow radius
    var cardShadowRadius: CGFloat {
        switch self {
        case .light: return 12
        case .dark:  return 16
        case .night: return 8
        case .sepia: return 10
        }
    }

    // =========================================================================
    // MARK: - Theme-Specific Opacity Values
    // =========================================================================

    /// Opacity for secondary text elements
    var secondaryOpacity: Double {
        switch self {
        case .light, .sepia: return 0.85
        case .dark, .night:  return 0.75
        }
    }

    /// Opacity for tertiary text elements
    var tertiaryOpacity: Double {
        switch self {
        case .light, .sepia: return 0.70
        case .dark, .night:  return 0.60
        }
    }

    /// Opacity for disabled text elements
    var disabledOpacity: Double {
        switch self {
        case .light, .sepia: return 0.50
        case .dark, .night:  return 0.40
        }
    }

    // =========================================================================
    // MARK: - Category Color Mapping
    // =========================================================================

    /// Maps category color strings to theme-appropriate colors.
    /// Views that categorize content by color name use this to get
    /// a theme-consistent result.
    func categoryColor(for colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue":            return accent
        case "purple":          return accentMuted
        case "green":           return accent
        case "yellow", "gold":  return accentMuted
        case "orange":          return semanticWarning
        case "red":             return semanticError
        case "brown":           return accentMuted
        case "pink":            return semanticError.opacity(0.8)
        case "teal":            return accent
        default:                return textTertiary
        }
    }

    // =========================================================================
    // MARK: - Prayer-Specific Colors
    // =========================================================================
    // These remain for backward compatibility. In future, prayer views should
    // define their own highlight colors internally.

    /// Active prayer card background (solid gold with high contrast text)
    var prayerActiveBackground: Color {
        AppColors.primary.gold  // #C7A566
    }

    /// Active prayer card text color (ensures contrast with gold)
    var prayerActiveText: Color {
        switch self {
        case .light, .sepia:
            return Color(hex: "#1A2332")  // Midnight on gold: ~5.2:1
        case .dark, .night:
            return Color(hex: "#1A2332")  // Midnight on gold works best
        }
    }

    // =========================================================================
    // MARK: - SwiftUI ColorScheme
    // =========================================================================

    var colorScheme: ColorScheme {
        switch self {
        case .light, .sepia: return .light
        case .dark, .night:  return .dark
        }
    }

    // =========================================================================
    // MARK: - Deprecated Aliases (Backward Compatibility)
    // =========================================================================
    //
    // These properties map old names to the new simplified color roles.
    // They exist so the rest of the codebase compiles without changes.
    // Migrate call sites to the new names over time.
    //

    /// Use `accent` instead.
    @available(*, deprecated, renamed: "accent",
               message: "Use 'accent' - the single primary brand color per theme.")
    var accentPrimary: Color { accent }

    /// Use `accentMuted` instead.
    @available(*, deprecated, renamed: "accentMuted",
               message: "Use 'accentMuted' for secondary/decorative elements.")
    var accentSecondary: Color { accentMuted }

    /// Use `accent` instead.
    @available(*, deprecated, renamed: "accent",
               message: "Use 'accent' - interactive elements use the same brand color.")
    var accentInteractive: Color { accent }

    /// Use `accentTint` instead.
    @available(*, deprecated, renamed: "accentTint",
               message: "Use 'accentTint' for subtle background washes.")
    var accentSubtle: Color { accentTint }

    /// Use `accent` instead.
    @available(*, deprecated, renamed: "accent",
               message: "Use 'accent' - feature highlights use the same brand color.")
    var featureAccent: Color { accent }

    /// Use `accentMuted` instead.
    @available(*, deprecated, renamed: "accentMuted",
               message: "Use 'accentMuted' for secondary feature elements.")
    var featureAccentSecondary: Color { accentMuted }

    /// Use `accentTint` instead.
    @available(*, deprecated, renamed: "accentTint",
               message: "Use 'accentTint' for background tints.")
    var featureBackgroundTint: Color { accentTint }

    /// Use `textPrimary` instead.
    @available(*, deprecated, renamed: "textPrimary",
               message: "Use 'textPrimary' for primary text color.")
    var textColor: Color { textPrimary }

    /// Deprecated. Define gradients in individual views, not in the theme.
    /// Returns a two-color array derived from `accent` for basic compatibility.
    @available(*, deprecated,
               message: "Define gradients in individual views. This returns a basic fallback.")
    var featureGradient: [Color] {
        [accent.opacity(0.12), accentMuted.opacity(0.08)]
    }

    /// Deprecated. Define gradients in individual views, not in the theme.
    @available(*, deprecated,
               message: "Define gradients in individual views. This returns a basic fallback.")
    var gradientColors: [Color] {
        [accent.opacity(0.10), accentMuted.opacity(0.06)]
    }

    /// Deprecated. Gradient support decisions belong in individual views.
    @available(*, deprecated,
               message: "Gradient support decisions belong in individual views.")
    var supportsGradients: Bool {
        self != .sepia
    }

    /// Deprecated. Gradient opacity decisions belong in individual views.
    @available(*, deprecated,
               message: "Gradient opacity logic belongs in individual views.")
    func gradientOpacity(for color: Color) -> Double {
        let isLight = self == .light || self == .sepia
        if self == .sepia { return 0.0 }
        if color == AppColors.primary.gold {
            return isLight ? 0.08 : 0.20
        } else if color == AppColors.primary.green {
            return isLight ? 0.06 : 0.18
        } else if color == AppColors.primary.teal {
            return isLight ? 0.04 : 0.12
        }
        return 0.0
    }
}
