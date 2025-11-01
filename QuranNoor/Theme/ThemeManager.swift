//
//  ThemeManager.swift
//  QuraanNoor
//
//  Manages app theme state
//

import SwiftUI
import Combine

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentTheme: ThemeMode {
        didSet {
            saveTheme()
        }
    }

    // MARK: - Computed Properties
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light, .sepia:
            return .light
        case .dark, .night:
            return .dark
        }
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
        currentTheme = theme
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "themeMode")
    }
}
