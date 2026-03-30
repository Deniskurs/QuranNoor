//
//  Typography.swift
//  QuraanNoor
//
//  Typography system for consistent text styling
//

import SwiftUI

// MARK: - Font Sizes
struct FontSizes {
    static let xs: CGFloat = 12
    static let sm: CGFloat = 14
    static let base: CGFloat = 16
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - App Typography
struct AppTypography {
    // MARK: - Headings
    static let h1 = Font.system(size: FontSizes.xxxl, weight: .bold, design: .default)
    static let h2 = Font.system(size: FontSizes.xxl, weight: .bold, design: .default)
    static let h3 = Font.system(size: FontSizes.xl, weight: .semibold, design: .default)

    // MARK: - Body Text
    static let body = Font.system(size: FontSizes.base, weight: .regular, design: .default)
    static let bodyLarge = Font.system(size: FontSizes.lg, weight: .regular, design: .default)
    static let caption = Font.system(size: FontSizes.sm, weight: .regular, design: .default)

    // MARK: - Interactive
    static let button = Font.system(size: FontSizes.base, weight: .semibold, design: .default)

    // MARK: - Semantic Styles (missing from original design system)
    static let sectionHeader = Font.system(size: FontSizes.sm, weight: .semibold, design: .default)
    static let statValue = Font.system(size: FontSizes.xxl, weight: .bold, design: .rounded)
    static let tabLabel = Font.system(size: FontSizes.xs, weight: .medium, design: .default)
    static let badge = Font.system(size: 11, weight: .bold, design: .default)
    static let countdown = Font.system(size: FontSizes.xxl, weight: .ultraLight, design: .default)

    // MARK: - Arabic Text (Uthmanic Hafs) — Dynamic Type scaling via relativeTo:
    //
    // Font file: "UthmanicHafs.ttf" in Resources/Fonts/
    // PostScript name: "KFGQPCUthmanicScriptHAFS"
    // Registration: Must be listed under "Fonts provided by application" (UIAppFonts)
    //   in Info.plist as "Fonts/UthmanicHafs.ttf" (or the correct bundle-relative path).
    //   If the font fails to load, SwiftUI silently falls back to the system font.
    //
    static let arabicVerse = Font.custom("KFGQPCUthmanicScriptHAFS", size: FontSizes.xl, relativeTo: .title)
    static let arabicTitle = Font.custom("KFGQPCUthmanicScriptHAFS", size: FontSizes.xxl, relativeTo: .title)
    static let arabicLarge = Font.custom("KFGQPCUthmanicScriptHAFS", size: FontSizes.xxxl, relativeTo: .largeTitle)

    // MARK: - Fallback Arabic (system font)
    static let arabicVerseSystem = Font.system(size: FontSizes.xl, weight: .regular, design: .default)
    static let arabicTitleSystem = Font.system(size: FontSizes.xxl, weight: .medium, design: .default)

    // MARK: - Scalable Arabic fonts for user preferences
    static func arabicScalable(size: CGFloat) -> Font {
        Font.custom("KFGQPCUthmanicScriptHAFS", size: size, relativeTo: .body)
    }

    // MARK: - Dynamic Arabic font based on mushaf type
    /// Returns the appropriate font for the given mushaf type and size.
    /// Use this for Quran verse text that should change with the user's script preference.
    /// For static Arabic text (prayer names, app titles), continue using `arabicScalable(size:)`.
    static func arabicFont(for mushafType: MushafType, size: CGFloat) -> Font {
        if mushafType.usesSystemFont {
            return Font.system(size: size, weight: .regular)
        }
        return Font.custom(mushafType.fontName, size: size, relativeTo: .body)
    }
}

// MARK: - Text Styles
extension Text {
    func h1Style() -> some View {
        self.font(AppTypography.h1)
    }

    func h2Style() -> some View {
        self.font(AppTypography.h2)
    }

    func h3Style() -> some View {
        self.font(AppTypography.h3)
    }

    func bodyStyle() -> some View {
        self.font(AppTypography.body)
    }

    func captionStyle() -> some View {
        self.font(AppTypography.caption)
    }

    func buttonStyle() -> some View {
        self.font(AppTypography.button)
    }

    func arabicVerseStyle() -> some View {
        self.font(AppTypography.arabicVerse) // Using Uthmanic Hafs font
            .lineSpacing(8)
    }

    func arabicTitleStyle() -> some View {
        self.font(AppTypography.arabicTitle)
            .lineSpacing(6)
    }

    func sectionHeaderStyle() -> some View {
        self.font(AppTypography.sectionHeader)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    func statValueStyle() -> some View {
        self.font(AppTypography.statValue)
    }

    func tabLabelStyle() -> some View {
        self.font(AppTypography.tabLabel)
    }
}
