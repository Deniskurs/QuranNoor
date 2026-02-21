//
//  RamadanTimesCard.swift
//  QuranNoor
//
//  Suhoor/Iftar countdown card shown on the Home screen during Ramadan
//

import SwiftUI

struct RamadanTimesCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let prayerTimes: DailyPrayerTimes?

    @State private var calendarService = IslamicCalendarService()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = Locale.autoupdatingCurrent
        return f
    }()

    var body: some View {
        if calendarService.isRamadan(), let times = prayerTimes {
            CardView(showPattern: true, intensity: .moderate) {
                VStack(spacing: Spacing.sm) {
                    // Header
                    HStack(spacing: Spacing.xxxs + 2) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: FontSizes.sm))
                            .foregroundStyle(themeManager.currentTheme.accentMuted)

                        Text("RAMADAN TIMES")
                            .font(.system(size: FontSizes.xs - 1, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.currentTheme.accentMuted)
                            .tracking(1.2)

                        Spacer()
                    }

                    // Suhoor & Iftar columns
                    HStack(spacing: Spacing.md) {
                        // Suhoor (Imsak or Fajr fallback)
                        timeColumn(
                            label: "Suhoor",
                            icon: "moon.fill",
                            time: times.imsak ?? times.fajr,
                            sublabel: times.imsak != nil ? "Imsak" : "Fajr"
                        )

                        // Vertical divider
                        Rectangle()
                            .fill(themeManager.currentTheme.textTertiary.opacity(0.2))
                            .frame(width: 1, height: 50)

                        // Iftar (Maghrib)
                        timeColumn(
                            label: "Iftar",
                            icon: "sunset.fill",
                            time: times.maghrib,
                            sublabel: "Maghrib"
                        )
                    }

                    // Live countdown
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let now = context.date
                        let suhoorTime = times.imsak ?? times.fajr
                        let iftarTime = times.maghrib

                        let countdownInfo = countdownTarget(
                            now: now,
                            suhoor: suhoorTime,
                            iftar: iftarTime
                        )

                        HStack(spacing: Spacing.xxxs + 2) {
                            Image(systemName: "timer")
                                .font(.system(size: FontSizes.xs))
                                .foregroundStyle(themeManager.currentTheme.accent)

                            Text(countdownInfo.text)
                                .font(.system(size: FontSizes.sm, weight: .semibold, design: .rounded))
                                .foregroundStyle(themeManager.currentTheme.textPrimary)
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.linear(duration: 0.3), value: countdownInfo.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxxs + 2)
                        .background(
                            RoundedRectangle(cornerRadius: BorderRadius.md)
                                .fill(themeManager.currentTheme.accent.opacity(0.08))
                        )
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: prayerTimes))
        }
    }

    // MARK: - Time Column

    private func timeColumn(label: String, icon: String, time: Date, sublabel: String) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Text(label)
                .font(.system(size: FontSizes.xs, weight: .medium))
                .foregroundStyle(themeManager.currentTheme.textSecondary)

            HStack(spacing: Spacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: FontSizes.base))
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text(Self.timeFormatter.string(from: time))
                    .font(.system(size: FontSizes.lg, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .monospacedDigit()
            }

            Text(sublabel)
                .font(.system(size: FontSizes.xs - 1))
                .foregroundStyle(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Countdown Logic

    private struct CountdownInfo {
        let text: String
    }

    private func countdownTarget(now: Date, suhoor: Date, iftar: Date) -> CountdownInfo {
        // Before Suhoor (early morning): countdown to Suhoor end
        if now < suhoor {
            let interval = suhoor.timeIntervalSince(now)
            return CountdownInfo(text: "\(formatInterval(interval)) until Suhoor ends")
        }

        // Between Suhoor and Iftar: countdown to Iftar
        if now < iftar {
            let interval = iftar.timeIntervalSince(now)
            return CountdownInfo(text: "\(formatInterval(interval)) until Iftar")
        }

        // After Iftar
        return CountdownInfo(text: "Alhamdulillah — Iftar time!")
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func accessibilityLabel(for times: DailyPrayerTimes?) -> String {
        guard let times else { return "Ramadan times" }
        let suhoor = Self.timeFormatter.string(from: times.imsak ?? times.fajr)
        let iftar = Self.timeFormatter.string(from: times.maghrib)
        return "Ramadan times. Suhoor ends at \(suhoor). Iftar at \(iftar)."
    }
}
