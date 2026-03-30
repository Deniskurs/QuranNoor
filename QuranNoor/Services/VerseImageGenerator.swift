//
//  VerseImageGenerator.swift
//  QuranNoor
//
//  Generates shareable verse images using ImageRenderer (iOS 16+)
//

import SwiftUI

// MARK: - Share Image Style

enum ShareImageStyle: String, CaseIterable, Identifiable {
    case emerald
    case midnight
    case parchment
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emerald:   return "Emerald"
        case .midnight:  return "Midnight"
        case .parchment: return "Parchment"
        case .minimal:   return "Minimal"
        }
    }

    /// Whether this style uses a gradient background (vs. a solid color)
    var usesGradient: Bool {
        switch self {
        case .emerald, .midnight: return true
        case .parchment, .minimal: return false
        }
    }

    var backgroundColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#0D4F3C")
        case .midnight:  return Color(hex: "#0A1628")
        case .parchment: return Color(hex: "#F4E8D0")
        case .minimal:   return Color.white
        }
    }

    /// Gradient start → end colors. For non-gradient styles, both entries are `backgroundColor`.
    var gradientColors: [Color] {
        switch self {
        case .emerald:
            return [Color(hex: "#0D4F3C"), Color(hex: "#0D7377")]
        case .midnight:
            return [Color(hex: "#0A1628"), Color(hex: "#1A2332")]
        case .parchment:
            return [Color(hex: "#F4E8D0"), Color(hex: "#F4E8D0")]
        case .minimal:
            return [Color.white, Color.white]
        }
    }

    var arabicTextColor: Color {
        switch self {
        case .emerald:   return Color.white
        case .midnight:  return Color.white
        case .parchment: return Color(hex: "#3D2F1F")
        case .minimal:   return Color(hex: "#1A2332")
        }
    }

    var translationTextColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#F8F4EA")   // Cream
        case .midnight:  return Color(hex: "#88AACC")   // Soft blue
        case .parchment: return Color(hex: "#5D4E37")   // Dark brown
        case .minimal:   return Color(hex: "#5A6372")   // Gray
        }
    }

    var referenceTextColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#C7A566").opacity(0.85)  // Gold muted
        case .midnight:  return Color(hex: "#8899AA").opacity(0.85)  // Silver muted
        case .parchment: return Color(hex: "#8A7A60")
        case .minimal:   return Color(hex: "#5A6372").opacity(0.75)
        }
    }

    var borderColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#C7A566")   // Gold
        case .midnight:  return Color(hex: "#8899AA")   // Silver
        case .parchment: return Color(hex: "#C7A566")   // Warm gold
        case .minimal:   return Color(hex: "#E5E5E5")   // Light gray
        }
    }

    var brandingColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#C7A566").opacity(0.65)
        case .midnight:  return Color(hex: "#8899AA").opacity(0.65)
        case .parchment: return Color(hex: "#8A7A60").opacity(0.65)
        case .minimal:   return Color(hex: "#5A6372").opacity(0.55)
        }
    }

    var dividerColor: Color {
        switch self {
        case .emerald:   return Color(hex: "#C7A566").opacity(0.50)
        case .midnight:  return Color(hex: "#8899AA").opacity(0.50)
        case .parchment: return Color(hex: "#C7A566").opacity(0.50)
        case .minimal:   return Color(hex: "#E5E5E5")
        }
    }
}

// MARK: - Share Image Size

enum ShareImageSize: String, CaseIterable, Identifiable {
    case portrait  // 1080 x 1350  (4:5 — Instagram portrait)
    case square    // 1080 x 1080  (1:1 — Instagram square)

    var id: String { rawValue }

    var width: CGFloat { 1080 }

    var height: CGFloat {
        switch self {
        case .portrait: return 1350
        case .square:   return 1080
        }
    }

    var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .square:   return "Square"
        }
    }

    /// Arabic font size appropriate for canvas dimensions
    var arabicFontSize: CGFloat {
        switch self {
        case .portrait: return 42
        case .square:   return 38
        }
    }
}

// MARK: - Verse Image Generator

@MainActor
struct VerseImageGenerator {
    /// Renders a `VerseShareImageView` to a `UIImage` at 2× scale (2160 × 2700 / 2160 × 2160 px).
    /// Returns `nil` if `ImageRenderer` fails to produce an image.
    static func generateImage(
        arabicText: String,
        translationText: String?,
        surahName: String,
        verseReference: String,
        style: ShareImageStyle,
        size: ShareImageSize
    ) -> UIImage? {
        let view = VerseShareImageView(
            arabicText: arabicText,
            translationText: translationText,
            surahName: surahName,
            verseReference: verseReference,
            style: style,
            size: size
        )
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
