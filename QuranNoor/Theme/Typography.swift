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
//
// `Font.system(size:)` returns a fixed-size font that ignores the user's
// Dynamic Type setting. SwiftUI has no `relativeTo:` overload for system
// fonts, so each token scales its base size through UIFontMetrics along the
// curve of an appropriate text style — the same effect `relativeTo:` gives
// the custom Arabic fonts below. Tokens are computed (not cached `let`s) so
// a text-size change is picked up on the next view update.
struct AppTypography {
    /// Scales `size` with the Dynamic Type curve of `style` (system font).
    private static func scaled(
        _ size: CGFloat,
        relativeTo style: UIFont.TextStyle,
        weight: Font.Weight,
        design: Font.Design = .default
    ) -> Font {
        Font.system(
            size: UIFontMetrics(forTextStyle: style).scaledValue(for: size),
            weight: weight,
            design: design
        )
    }

    // MARK: - Headings
    static var h1: Font { scaled(FontSizes.xxxl, relativeTo: .largeTitle, weight: .bold) }
    static var h2: Font { scaled(FontSizes.xxl, relativeTo: .title2, weight: .bold) }
    static var h3: Font { scaled(FontSizes.xl, relativeTo: .title3, weight: .semibold) }

    // MARK: - Body Text
    static var body: Font { scaled(FontSizes.base, relativeTo: .body, weight: .regular) }
    static var bodyLarge: Font { scaled(FontSizes.lg, relativeTo: .body, weight: .regular) }
    static var caption: Font { scaled(FontSizes.sm, relativeTo: .caption1, weight: .regular) }

    // MARK: - Interactive
    static var button: Font { scaled(FontSizes.base, relativeTo: .body, weight: .semibold) }

    // MARK: - Semantic Styles (missing from original design system)
    static var sectionHeader: Font { scaled(FontSizes.sm, relativeTo: .footnote, weight: .semibold) }
    static var statValue: Font { scaled(FontSizes.xxl, relativeTo: .title2, weight: .bold, design: .rounded) }
    static var tabLabel: Font { scaled(FontSizes.xs, relativeTo: .caption1, weight: .medium) }
    static var badge: Font { scaled(11, relativeTo: .caption2, weight: .bold) }
    static var countdown: Font { scaled(FontSizes.xxl, relativeTo: .title2, weight: .ultraLight) }

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
