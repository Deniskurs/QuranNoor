//
//  Colors.swift
//  QuraanNoor
//
//  Color palette for Islamic design system
//

import SwiftUI

// MARK: - App Colors
struct AppColors {
    static let primary = PrimaryColors()
    static let neutral = NeutralColors()

    struct PrimaryColors {
        let green = Color(hex: "#0D7377")      // Emerald
        let teal = Color(hex: "#14FFEC")       // Bright teal
        let gold = Color(hex: "#C7A566")       // Gold accent
        let midnight = Color(hex: "#1A2332")   // Midnight blue
    }

    struct NeutralColors {
        let cream = Color(hex: "#F8F4EA")
        let white = Color.white
        let gray = Color(hex: "#E5E5E5")
    }
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case night = "Night"
    case sepia = "Sepia"

    var id: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .light: return Color(hex: "#F8F4EA")
        case .dark: return Color(hex: "#1A2332")
        case .night: return Color.black
        case .sepia: return Color(hex: "#F4E8D0")
        }
    }

    var textColor: Color {
        switch self {
        case .light: return Color(hex: "#1A2332")
        case .dark: return Color(hex: "#F8F4EA")
        case .night: return Color(hex: "#E5E5E5")
        case .sepia: return Color(hex: "#5D4E37")
        }
    }

    var cardColor: Color {
        switch self {
        case .light: return Color.white
        case .dark: return Color(hex: "#2A3342")
        case .night: return Color(hex: "#1A1A1A")
        case .sepia: return Color(hex: "#FFF8E7")
        }
    }

    var borderColor: Color {
        switch self {
        case .light: return Color(hex: "#E5E5E5")
        case .dark: return Color(hex: "#3A4352")
        case .night: return Color(hex: "#2A2A2A")
        case .sepia: return Color(hex: "#D4C8B0")
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .night: return "moon.stars.fill"
        case .sepia: return "book.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .light: return Color(hex: "#0D7377")
        case .dark: return Color(hex: "#14FFEC")
        case .night: return Color(hex: "#C7A566")
        case .sepia: return Color(hex: "#5D4E37")
        }
    }

    var description: String {
        switch self {
        case .light: return "Bright and clear"
        case .dark: return "Easy on the eyes"
        case .night: return "Pure black for OLED"
        case .sepia: return "Classic reading experience"
        }
    }
}
