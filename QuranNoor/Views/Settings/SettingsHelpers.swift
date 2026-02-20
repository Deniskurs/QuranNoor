//
//  SettingsHelpers.swift
//  QuranNoor
//
//  Shared helper views used across settings sections
//

import SwiftUI

/// Reusable section header used in Settings sections
struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.accent)

            ThemedText(title, style: .heading)

            Spacer()
        }
    }
}

/// Reusable setting row used in Settings sections
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)

            ThemedText.body(title)

            Spacer()

            ThemedText.body(value)
                .foregroundColor(color)
                .opacity(themeManager.currentTheme.secondaryOpacity)

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .opacity(themeManager.currentTheme.tertiaryOpacity)
        }
    }
}
