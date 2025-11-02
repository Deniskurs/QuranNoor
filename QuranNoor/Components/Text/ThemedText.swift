//
//  ThemedText.swift
//  QuranNoor
//
//  Premium text component with custom typography and theme support
//

import SwiftUI

// MARK: - Text Style Enum
enum TextStyleType {
    case title           // PP Editorial New Ultralight / SF Pro Display Ultralight - 32pt
    case heading         // SF Pro Display Semibold - 24pt
    case body            // SF Pro Text Regular - 16pt
    case caption         // SF Pro Text Regular - 14pt
    case arabic          // SF Arabic Regular - 20pt
}

// MARK: - ThemedText Component
struct ThemedText: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager

    let text: String
    let style: TextStyleType
    let italic: Bool
    let color: Color?

    // Performance optimization: Cache font availability check
    private static let hasCustomTitleFont: Bool = {
        UIFont(name: "PPEditorialNew-Ultralight", size: 32) != nil
    }()

    // Cache computed fonts to avoid repeated lookups
    private static let cachedFonts: [TextStyleType: Font] = [
        .title: hasCustomTitleFont
            ? .custom("PPEditorialNew-Ultralight", size: 32)
            : .system(size: 32, weight: .ultraLight, design: .default),
        .heading: .system(size: 24, weight: .semibold, design: .default),
        .body: .system(size: 16, weight: .regular, design: .default),
        .caption: .system(size: 14, weight: .regular, design: .default),
        .arabic: .system(size: 20, weight: .regular, design: .default)
    ]

    // MARK: - Initializer
    init(
        _ text: String,
        style: TextStyleType = .body,
        italic: Bool = false,
        color: Color? = nil
    ) {
        self.text = text
        self.style = style
        self.italic = italic
        self.color = color
    }

    // MARK: - Body
    var body: some View {
        Text(text)
            .font(fontForStyle)
            .foregroundColor(color ?? textColorForStyle)
            .italic(italic)
    }

    // MARK: - Font Selection
    private var fontForStyle: Font {
        // Use cached font for performance (avoids repeated UIFont lookups)
        return Self.cachedFonts[style] ?? .body
    }

    // MARK: - Theme-Aware Color
    private var textColorForStyle: Color {
        switch style {
        case .title, .heading:
            return themeManager.currentTheme.textColor

        case .body, .caption:
            return themeManager.currentTheme.textColor.opacity(0.85)

        case .arabic:
            return themeManager.currentTheme.textColor
        }
    }
}

// MARK: - Convenience Initializers
extension ThemedText {
    /// Title text with optional italic emphasis
    static func title(_ text: String, italic: Bool = false) -> ThemedText {
        ThemedText(text, style: .title, italic: italic)
    }

    /// Heading text
    static func heading(_ text: String) -> ThemedText {
        ThemedText(text, style: .heading)
    }

    /// Body text
    static func body(_ text: String) -> ThemedText {
        ThemedText(text, style: .body)
    }

    /// Caption text (smaller, secondary)
    static func caption(_ text: String) -> ThemedText {
        ThemedText(text, style: .caption)
    }

    /// Arabic text with proper RTL support
    static func arabic(_ text: String) -> ThemedText {
        ThemedText(text, style: .arabic)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        ThemedText.title("Qur'an Noor", italic: false)
        ThemedText.title("Beautiful", italic: true)
        ThemedText.heading("Next Prayer: Asr")
        ThemedText.body("Prayer time is approaching in 15 minutes")
        ThemedText.caption("Calculation Method: ISNA")
        ThemedText.arabic("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
    }
    .padding()
    .environmentObject(ThemeManager())
}
