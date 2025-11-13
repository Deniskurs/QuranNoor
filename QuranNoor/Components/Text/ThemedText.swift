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

    /// Maps text style to semantic color level
    var colorLevel: ColorLevel {
        switch self {
        case .title, .heading, .arabic:
            return .primary      // Always full contrast
        case .body:
            return .secondary    // Medium contrast
        case .caption:
            return .tertiary     // Lower contrast (for metadata)
        }
    }
}

// MARK: - Color Level
enum ColorLevel {
    case primary    // Main content, headings, Arabic text - full contrast
    case secondary  // Body text, labels - medium contrast
    case tertiary   // Captions, timestamps - lower contrast
    case disabled   // Inactive elements
}

// MARK: - ThemedText Component
struct ThemedText: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    // Accessibility support
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.colorSchemeContrast) var contrast

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
            .foregroundColor(color ?? effectiveTextColor)
            .italic(italic)
            .minimumScaleFactor(0.8)  // Graceful text scaling for accessibility
            .lineLimit(nil)  // Support multi-line for Dynamic Type
            .dynamicTypeSize(.xSmall ... .accessibility5)  // Support all accessibility sizes
    }

    // MARK: - Font Selection
    private var fontForStyle: Font {
        // Use cached font for performance (avoids repeated UIFont lookups)
        return Self.cachedFonts[style] ?? .body
    }

    // MARK: - Theme-Aware Color with Accessibility Support
    private var effectiveTextColor: Color {
        let theme = themeManager.currentTheme

        // High contrast mode: always use primary color for maximum readability
        if contrast == .increased {
            return theme.textPrimary
        }

        // Use semantic color hierarchy based on style
        switch style.colorLevel {
        case .primary:
            return theme.textPrimary      // Full contrast: title, heading, Arabic
        case .secondary:
            return theme.textSecondary    // Medium contrast: body text
        case .tertiary:
            return theme.textTertiary     // Lower contrast: captions, metadata
        case .disabled:
            return theme.textDisabled     // Very low contrast: inactive elements
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
    .environment(ThemeManager())
}
