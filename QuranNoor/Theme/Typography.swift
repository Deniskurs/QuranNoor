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

    // MARK: - Arabic Text (Uthmanic Hafs)
    static let arabicVerse = Font.custom("KFGQPC HAFS Uthmanic Script Regular", size: FontSizes.xl)
    static let arabicTitle = Font.custom("KFGQPC HAFS Uthmanic Script Regular", size: FontSizes.xxl)
    static let arabicLarge = Font.custom("KFGQPC HAFS Uthmanic Script Regular", size: FontSizes.xxxl)

    // MARK: - Fallback Arabic (system font)
    static let arabicVerseSystem = Font.system(size: FontSizes.xl, weight: .regular, design: .default)
    static let arabicTitleSystem = Font.system(size: FontSizes.xxl, weight: .medium, design: .default)

    // MARK: - Scalable Arabic fonts for user preferences
    static func arabicScalable(size: CGFloat) -> Font {
        Font.custom("KFGQPC HAFS Uthmanic Script Regular", size: size)
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
}
