//
//  TajweedText.swift
//  QuranNoor
//
//  Renders tajweed-colored Arabic text using AttributedString.
//  Each TajweedSegment is given its rule-specific foreground color,
//  while plain segments use the current theme's primary text color.
//

import SwiftUI
import os

// MARK: - TajweedText

/// A SwiftUI view that renders a single Quran verse as color-coded
/// tajweed text using `AttributedString`.
///
/// Usage:
/// ```swift
/// TajweedText(segments: verseSegments, fontSize: 26, mushafType: .uthmani)
/// ```
struct TajweedText: View {

    // MARK: - Properties

    let segments: [TajweedSegment]
    let fontSize: CGFloat
    let mushafType: MushafType

    // MARK: - Environment

    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        let theme = themeManager.currentTheme
        let attributed = buildAttributedString(for: theme)
        let plainText = segments.map(\.text).joined()

        Text(attributed)
            .multilineTextAlignment(.trailing)
            .lineSpacing(lineSpacing)
            .environment(\.layoutDirection, .rightToLeft)
            .accessibilityLabel(plainText)
            .accessibilityHint("Quran verse text")
    }

    // MARK: - AttributedString Construction

    private func buildAttributedString(for theme: ThemeMode) -> AttributedString {
        var result = AttributedString()

        // Resolve the SwiftUI Font → UIFont for AttributedString use
        let uiFont = resolvedUIFont()

        for segment in segments {
            var run = AttributedString(segment.text)

            // Foreground color: rule color or default primary text
            let color: Color
            if let rule = segment.rule {
                color = rule.color(for: theme)
            } else {
                color = theme.textPrimary
            }
            run.foregroundColor = color

            // Apply font via UIFont so AttributedString renders it correctly
            run.font = Font(uiFont)

            result.append(run)
        }

        return result
    }

    // MARK: - Font Resolution

    /// Converts the SwiftUI font for the current mushaf type to a UIFont
    /// so it can be embedded inside an AttributedString.
    private func resolvedUIFont() -> UIFont {
        if mushafType.usesSystemFont {
            return UIFont.systemFont(ofSize: fontSize, weight: .regular)
        }
        // Attempt to load the custom font; fall back to system Arabic if unavailable
        if let customFont = UIFont(name: mushafType.fontName, size: fontSize) {
            return customFont
        }
        AppLogger.quran.warning("TajweedText: font '\(mushafType.fontName)' not found, using system Arabic")
        return UIFont.systemFont(ofSize: fontSize, weight: .regular)
    }

    // MARK: - Line Spacing

    /// Scales line spacing with font size so large Arabic text stays legible.
    private var lineSpacing: CGFloat {
        fontSize * 0.45
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Light Theme") {
    let sampleSegments: [TajweedSegment] = [
        TajweedSegment(text: "بِسۡمِ ", rule: nil),
        TajweedSegment(text: "ٱ", rule: .hamWasl),
        TajweedSegment(text: "للَّهِ ", rule: nil),
        TajweedSegment(text: "ٱلرَّحۡمَٰنِ ", rule: .laamShamsiyah),
        TajweedSegment(text: "ٱلرَّحِيمِ", rule: .maddaNormal)
    ]
    TajweedText(segments: sampleSegments, fontSize: 28, mushafType: .uthmani)
        .environment(ThemeManager.shared)
        .padding()
}
#endif
