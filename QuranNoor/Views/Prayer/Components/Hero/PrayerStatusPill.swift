//
//  PrayerStatusPill.swift
//  QuranNoor
//
//  Glassmorphic status badge showing prayer state and time
//  Uses liquid glass effect with edge highlights
//

import SwiftUI

/// Prayer status displayed in a glassmorphic pill
struct PrayerStatusPill: View {
    // MARK: - Properties

    let state: PrayerPeriodState
    let prayerTime: Date?
    let isUrgent: Bool

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Status label
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .scaleEffect(isUrgent ? 1.8 : 1.0)
                            .opacity(isUrgent ? 0.6 : 0)
                    )

                Text(statusText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            // Divider
            if let time = prayerTime {
                Capsule()
                    .fill(themeManager.currentTheme.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 16)

                // Time
                Text(timeFormatter.string(from: time))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(pillBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Background

    private var pillBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .background(
                Capsule()
                    .fill(glassBackgroundTint)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                glassEdgeHighlight.opacity(0.6),
                                glassEdgeHighlight.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: glassShadowColor, radius: 8, x: 0, y: 4)
    }

    // MARK: - Glass Colors

    private var glassBackgroundTint: Color {
        switch themeManager.currentTheme {
        case .light:
            return Color.white.opacity(0.3)
        case .dark:
            return themeManager.currentTheme.accentPrimary.opacity(0.1)
        case .night:
            return Color.white.opacity(0.05)
        case .sepia:
            return AppColors.primary.gold.opacity(0.1)
        }
    }

    private var glassEdgeHighlight: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.white
        case .dark:
            return Color.white.opacity(0.3)
        case .night:
            return Color.white.opacity(0.15)
        }
    }

    private var glassShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        case .night:
            return Color.black.opacity(0.5)
        }
    }

    // MARK: - Status Properties

    private var statusText: String {
        switch state {
        case .beforeFajr:
            return "Before Fajr"
        case .inProgress(let prayer, _):
            return "\(prayer.displayName) Time"
        case .betweenPrayers(_, let next, _):
            return "\(next.displayName) Next"
        case .afterIsha:
            return "After Isha"
        }
    }

    private var statusColor: Color {
        if isUrgent {
            return .orange
        }

        switch state {
        case .beforeFajr:
            return themeManager.currentTheme.accentPrimary
        case .inProgress:
            return themeManager.currentTheme.accentSecondary
        case .betweenPrayers:
            return themeManager.currentTheme.accentInteractive
        case .afterIsha:
            return themeManager.currentTheme.accentPrimary
        }
    }

    private var accessibilityDescription: String {
        var description = statusText
        if let time = prayerTime {
            description += " at \(timeFormatter.string(from: time))"
        }
        if isUrgent {
            description += ", urgent"
        }
        return description
    }

    // MARK: - Formatter

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Preview

#Preview("All States") {
    let now = Date()

    VStack(spacing: 20) {
        PrayerStatusPill(
            state: .beforeFajr(nextFajr: now),
            prayerTime: now,
            isUrgent: false
        )

        PrayerStatusPill(
            state: .inProgress(prayer: .asr, deadline: now),
            prayerTime: Calendar.current.date(bySettingHour: 15, minute: 45, second: 0, of: now)!,
            isUrgent: false
        )

        PrayerStatusPill(
            state: .inProgress(prayer: .maghrib, deadline: now),
            prayerTime: Calendar.current.date(bySettingHour: 18, minute: 20, second: 0, of: now)!,
            isUrgent: true
        )

        PrayerStatusPill(
            state: .betweenPrayers(previous: .dhuhr, next: .asr, nextStartTime: now),
            prayerTime: Calendar.current.date(bySettingHour: 15, minute: 45, second: 0, of: now)!,
            isUrgent: false
        )

        PrayerStatusPill(
            state: .afterIsha(tomorrowFajr: now),
            prayerTime: nil,
            isUrgent: false
        )
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}

#Preview("Light Theme") {
    VStack(spacing: 20) {
        PrayerStatusPill(
            state: .inProgress(prayer: .dhuhr, deadline: Date()),
            prayerTime: Date(),
            isUrgent: false
        )

        PrayerStatusPill(
            state: .betweenPrayers(previous: .dhuhr, next: .asr, nextStartTime: Date()),
            prayerTime: Date(),
            isUrgent: true
        )
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environment(ThemeManager())
}
