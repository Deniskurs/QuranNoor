//
//  ThemeManager.swift
//  QuraanNoor
//
//  Manages app theme state
//

import SwiftUI
import Combine

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentTheme: ThemeMode {
        didSet {
            saveTheme()
            // Clear gradient cache when theme changes
            GradientCache.shared.clearCache()
        }
    }

    // MARK: - Computed Properties
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }

    var backgroundColor: Color {
        currentTheme.backgroundColor
    }

    var textColor: Color {
        currentTheme.textColor
    }

    var cardColor: Color {
        currentTheme.cardColor
    }

    var borderColor: Color {
        currentTheme.borderColor
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
        let theme = currentTheme.rawValue
        // Perform UserDefaults write on background queue to avoid blocking UI
        Task.detached(priority: .utility) {
            UserDefaults.standard.set(theme, forKey: "themeMode")
        }
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
    @EnvironmentObject var themeManager: ThemeManager

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
