//
//  RamadanHomeCard.swift
//  QuranNoor
//
//  Prominent Ramadan card shown on the Home screen during the blessed month
//

import SwiftUI

struct RamadanHomeCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var calendarService = IslamicCalendarService()
    @State private var showingTracker = false

    /// Optional prayer times for showing Suhoor/Iftar row
    var prayerTimes: DailyPrayerTimes?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = Locale.autoupdatingCurrent
        return f
    }()

    var body: some View {
        if calendarService.isRamadan() {
            let tracker = calendarService.getCurrentRamadanTracker()
            let hijriDate = calendarService.convertToHijri()
            let dayOfRamadan = hijriDate.day
            let progress = Double(dayOfRamadan) / 30.0

            Button {
                showingTracker = true
                HapticManager.shared.trigger(.light)
            } label: {
                CardView(showPattern: true, intensity: .prominent) {
                    VStack(spacing: Spacing.sm) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                Text("RAMADAN MUBARAK")
                                    .font(.system(size: FontSizes.xs - 1, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeManager.currentTheme.accentMuted)
                                    .tracking(1.2)

                                Text("Day \(dayOfRamadan) of 30")
                                    .font(.system(size: FontSizes.xl, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                            }

                            Spacer()

                            // Progress ring
                            ZStack {
                                Circle()
                                    .stroke(themeManager.currentTheme.accentTint, lineWidth: 4)
                                    .frame(width: Spacing.xxl, height: Spacing.xxl)

                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        themeManager.currentTheme.accent,
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                    )
                                    .frame(width: Spacing.xxl, height: Spacing.xxl)
                                    .rotationEffect(.degrees(-90))

                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: FontSizes.sm))
                                    .foregroundStyle(themeManager.currentTheme.accent)
                            }
                        }

                        // Stats row
                        HStack(spacing: Spacing.sm) {
                            miniStat(
                                value: "\(tracker.totalFastingDays)",
                                label: "Fasts",
                                icon: "sun.max.fill"
                            )

                            miniStat(
                                value: "\(tracker.lastTenNightsCount)",
                                label: "Qiyam",
                                icon: "moon.fill"
                            )

                            Spacer()

                            // CTA
                            HStack(spacing: Spacing.xxxs) {
                                Text("Track")
                                    .font(.system(size: FontSizes.sm, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: FontSizes.xs, weight: .semibold))
                            }
                            .foregroundStyle(themeManager.currentTheme.accent)
                        }

                        // Suhoor/Iftar times row (when prayer times available)
                        if let times = prayerTimes {
                            HStack(spacing: Spacing.sm) {
                                // Suhoor
                                HStack(spacing: Spacing.xxxs + 2) {
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: FontSizes.xs))
                                        .foregroundStyle(themeManager.currentTheme.accentMuted)

                                    Text("Suhoor")
                                        .font(.system(size: FontSizes.xs))
                                        .foregroundStyle(themeManager.currentTheme.textTertiary)

                                    Text(Self.timeFormatter.string(from: times.imsak ?? times.fajr))
                                        .font(.system(size: FontSizes.xs, weight: .semibold, design: .rounded))
                                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                                        .monospacedDigit()
                                }

                                Spacer()

                                // Iftar
                                HStack(spacing: Spacing.xxxs + 2) {
                                    Image(systemName: "sunset.fill")
                                        .font(.system(size: FontSizes.xs))
                                        .foregroundStyle(themeManager.currentTheme.accentMuted)

                                    Text("Iftar")
                                        .font(.system(size: FontSizes.xs))
                                        .foregroundStyle(themeManager.currentTheme.textTertiary)

                                    Text(Self.timeFormatter.string(from: times.maghrib))
                                        .font(.system(size: FontSizes.xs, weight: .semibold, design: .rounded))
                                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                                        .monospacedDigit()
                                }
                            }
                            .padding(.top, Spacing.xxxs)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingTracker, onDismiss: {
                // Refresh in case user changed moon sighting offset
                calendarService = IslamicCalendarService()
            }) {
                RamadanTrackerView(calendarService: calendarService)
            }
            .accessibilityLabel("Ramadan tracker, Day \(dayOfRamadan), \(tracker.totalFastingDays) fasts completed. Tap to open tracker.")
        }
    }

    private func miniStat(value: String, label: String, icon: String) -> some View {
        HStack(spacing: Spacing.xxxs + 2) {
            Image(systemName: icon)
                .font(.system(size: FontSizes.xs))
                .foregroundStyle(themeManager.currentTheme.accentMuted)

            Text(value)
                .font(.system(size: FontSizes.base, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textPrimary)

            Text(label)
                .font(.system(size: FontSizes.xs))
                .foregroundStyle(themeManager.currentTheme.textTertiary)
        }
    }
}
