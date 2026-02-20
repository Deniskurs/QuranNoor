//
//  ThemeManager.swift
//  QuraanNoor
//
//  Manages app theme state and provides convenience accessors
//  for the simplified color system.
//

import SwiftUI
import Observation

// TODO: L13 - Create reusable components: SectionHeader, Badge/Chip, PressableButtonStyle.
// These patterns are repeated across multiple views and should be extracted into Components/.

// MARK: - Theme Manager
@Observable
@MainActor
class ThemeManager {
    // MARK: - Singleton
    static let shared = ThemeManager()

    // MARK: - Properties
    var currentTheme: ThemeMode {
        didSet {
            saveTheme()
            // Clear gradient cache when theme changes
            GradientCache.shared.clearCache()
        }
    }

    // =========================================================================
    // MARK: - Core Convenience Accessors (New Color System)
    // =========================================================================

    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }

    // -- Accent Colors --

    /// Primary brand accent for the current theme
    var accent: Color {
        currentTheme.accent
    }

    /// Muted accent for secondary/decorative elements
    var accentMuted: Color {
        currentTheme.accentMuted
    }

    /// Subtle accent tint for background washes
    var accentTint: Color {
        currentTheme.accentTint
    }

    // -- Surface Colors --

    var backgroundColor: Color {
        currentTheme.backgroundColor
    }

    var cardColor: Color {
        currentTheme.cardColor
    }

    var elevatedCardColor: Color {
        currentTheme.elevatedCardColor
    }

    var borderColor: Color {
        currentTheme.borderColor
    }

    // -- Text Colors --

    var textPrimary: Color {
        currentTheme.textPrimary
    }

    var textSecondary: Color {
        currentTheme.textSecondary
    }

    var textTertiary: Color {
        currentTheme.textTertiary
    }

    var textDisabled: Color {
        currentTheme.textDisabled
    }

    // -- Semantic Colors --

    var semanticSuccess: Color {
        currentTheme.semanticSuccess
    }

    var semanticWarning: Color {
        currentTheme.semanticWarning
    }

    var semanticError: Color {
        currentTheme.semanticError
    }

    var semanticInfo: Color {
        currentTheme.semanticInfo
    }

    // =========================================================================
    // MARK: - Deprecated Convenience Accessors (Backward Compatibility)
    // =========================================================================

    /// Use `textPrimary` instead.
    @available(*, deprecated, renamed: "textPrimary",
               message: "Use 'textPrimary' instead of 'textColor'.")
    var textColor: Color {
        currentTheme.textPrimary
    }

    /// Use `textPrimary` instead.
    @available(*, deprecated, renamed: "textPrimary",
               message: "Use 'textPrimary' instead of 'primaryTextColor'.")
    var primaryTextColor: Color {
        currentTheme.textPrimary
    }

    /// Use `textSecondary` instead.
    @available(*, deprecated, renamed: "textSecondary",
               message: "Use 'textSecondary' instead of 'secondaryTextColor'.")
    var secondaryTextColor: Color {
        currentTheme.textSecondary
    }

    /// Use `accent` instead.
    @available(*, deprecated, renamed: "accent",
               message: "Use 'accent' instead of 'accentColor'.")
    var accentColor: Color {
        currentTheme.accent
    }

    /// Use `cardColor` instead.
    @available(*, deprecated, renamed: "cardColor",
               message: "Use 'cardColor' instead of 'cardBackground'.")
    var cardBackground: Color {
        currentTheme.cardColor
    }

    /// Use `accent` instead.
    @available(*, deprecated, renamed: "accent",
               message: "Use 'accent' instead of 'featureAccent'.")
    var featureAccent: Color {
        currentTheme.accent
    }

    /// Use `accentMuted` instead.
    @available(*, deprecated, renamed: "accentMuted",
               message: "Use 'accentMuted' instead of 'featureAccentSecondary'.")
    var featureAccentSecondary: Color {
        currentTheme.accentMuted
    }

    /// Use `accentTint` instead.
    @available(*, deprecated, renamed: "accentTint",
               message: "Use 'accentTint' instead of 'featureBackgroundTint'.")
    var featureBackgroundTint: Color {
        currentTheme.accentTint
    }

    /// Deprecated. Define gradients in individual views instead.
    @available(*, deprecated,
               message: "Define gradients in individual views. This returns a basic fallback.")
    var featureGradient: [Color] {
        [currentTheme.accent.opacity(0.12), currentTheme.accentMuted.opacity(0.08)]
    }

    // MARK: - Initialization
    init() {
        // Load saved theme or default to light
        if let savedTheme = UserDefaults.standard.string(forKey: "themeMode"),
           let theme = ThemeMode(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .light
        }
    }

    // MARK: - Methods
    func setTheme(_ theme: ThemeMode) {
        // Animate theme changes for smooth transitions
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "themeMode")
    }
}

// MARK: - Environment Key (Performance Optimization)
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeMode = .light
}

extension EnvironmentValues {
    /// Access theme directly from Environment for better performance
    /// Use this instead of @EnvironmentObject when you only need to read the theme
    var theme: ThemeMode {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Themed View Modifier
struct ThemedViewModifier: ViewModifier {
    @Environment(ThemeManager.self) var themeManager

    func body(content: Content) -> some View {
        content
            .environment(\.theme, themeManager.currentTheme)
            .environment(\.colorScheme, themeManager.currentTheme.colorScheme)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

extension View {
    /// Apply theme environment to view hierarchy
    /// Use this at the root level to inject theme into Environment
    func themedEnvironment() -> some View {
        modifier(ThemedViewModifier())
    }
}
