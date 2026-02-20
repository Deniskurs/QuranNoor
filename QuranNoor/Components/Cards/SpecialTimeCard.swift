//
//  SpecialTimeCard.swift
//  QuranNoor
//
//  Component for displaying special Islamic times (sunrise, sunset, midnight, etc.)
//

import SwiftUI

struct SpecialTimeCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let specialTime: SpecialTime
    let highlight: Bool

    // MARK: - Initializer
    init(specialTime: SpecialTime, highlight: Bool = false) {
        self.specialTime = specialTime
        self.highlight = highlight
    }

    // MARK: - Body
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: specialTime.type.icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 44)

            // Time info
            VStack(alignment: .leading, spacing: 4) {
                ThemedText(specialTime.type.displayName, style: .body)
                    .foregroundColor(highlight ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary)

                ThemedText.caption(specialTime.type.description)
                    .opacity(0.7)
            }

            Spacer()

            // Time display
            Text(specialTime.displayTime)
                .font(.title3.weight(highlight ? .semibold : .regular))
                .foregroundColor(highlight ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    highlight
                        ? themeManager.currentTheme.accent.opacity(0.1)
                        : themeManager.currentTheme.cardColor.opacity(0.5)
                )
        )
    }

    // MARK: - Helpers
    private var iconColor: Color {
        switch specialTime.type {
        case .imsak:
            return themeManager.currentTheme.textPrimary
        case .sunrise:
            return Color.orange
        case .sunset:
            return Color.orange.opacity(0.8)
        case .midnight:
            return themeManager.currentTheme.accent
        case .firstThird:
            return themeManager.currentTheme.accentMuted
        case .lastThird:
            return themeManager.currentTheme.accent
        }
    }
}

// MARK: - Compact Special Time Card
struct CompactSpecialTimeCard: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let time: String
    let color: Color

    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 28)

            ThemedText.body(title)

            Spacer()

            Text(time)
                .font(.body.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SpecialTimeCard(
                specialTime: SpecialTime(
                    type: .sunrise,
                    time: Date().addingTimeInterval(3600)
                )
            )

            SpecialTimeCard(
                specialTime: SpecialTime(
                    type: .sunset,
                    time: Date().addingTimeInterval(7200)
                )
            )

            SpecialTimeCard(
                specialTime: SpecialTime(
                    type: .midnight,
                    time: Date().addingTimeInterval(10800)
                ),
                highlight: true
            )

            SpecialTimeCard(
                specialTime: SpecialTime(
                    type: .lastThird,
                    time: Date().addingTimeInterval(14400)
                )
            )

            Divider().padding()

            // Compact versions
            VStack(spacing: 8) {
                CompactSpecialTimeCard(
                    icon: "sunrise",
                    title: "Sunrise",
                    time: "6:30 AM",
                    color: .orange
                )

                CompactSpecialTimeCard(
                    icon: "sunset",
                    title: "Sunset",
                    time: "6:45 PM",
                    color: .orange.opacity(0.8)
                )

                CompactSpecialTimeCard(
                    icon: "moon.stars",
                    title: "Midnight",
                    time: "12:37 AM",
                    color: ThemeMode.light.accent  // Theme-aware preview color
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeManager().currentTheme.cardColor)
            )
        }
        .padding()
    }
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
