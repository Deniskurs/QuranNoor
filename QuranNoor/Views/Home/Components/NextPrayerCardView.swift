//
//  NextPrayerCardView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Real-time next prayer countdown card with TimelineView
//

import SwiftUI

struct NextPrayerCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var prayerVM: PrayerViewModel
    @Binding var selectedTab: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            LiquidGlassCardView(intensity: .prominent) {
                VStack(spacing: Spacing.md) { // Enhanced from 16 to 24
                    if let period = prayerVM.currentPrayerPeriod {
                        content(for: period)
                    } else {
                        loadingContent
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = 2 // Navigate to Prayer tab
            AudioHapticCoordinator.shared.playToast()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to open Prayer Times")
    }

    // MARK: - Content Views

    @ViewBuilder
    private func content(for period: PrayerPeriod) -> some View {
        if period.isUrgent {
            urgentContent(period: period)
        } else if let currentPrayer = period.currentPrayer {
            prayerWindowContent(prayer: currentPrayer, period: period)
        } else {
            normalContent(period: period)
        }
    }

    // Normal state (> 30min to prayer)
    private func normalContent(period: PrayerPeriod) -> some View {
        VStack(spacing: Spacing.md) { // Enhanced from 16 to 24
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.accentSecondary)

                    Text("NEXT PRAYER")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                // Progress ring
                if period.periodProgress > 0 {
                    OptimizedProgressRing(
                        progress: period.periodProgress,
                        lineWidth: 4,
                        size: 40,
                        color: themeManager.currentTheme.accentSecondary,
                        backgroundColor: Color.gray.opacity(0.2),
                        showPercentage: false
                    )
                }
            }

            // Prayer name and countdown
            if let nextPrayer = period.nextPrayer {
                VStack(spacing: Spacing.xs) { // Enhanced from 8 to 12
                    Text(nextPrayer.name.displayName)
                        .font(.system(size: 40, weight: .bold)) // Enhanced from 36
                        .tracking(-0.5) // Tighter tracking for impact
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text(period.countdownString)
                        .font(.system(size: 72, weight: .ultraLight, design: .rounded)) // HERO enhancement from 48
                        .tracking(2) // Add letter spacing for elegance
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                }
                .padding(.vertical, Spacing.xxs) // Add breathing room

                // Prayer time
                Text("at \(nextPrayer.time, formatter: timeFormatter)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            // Prayer completion row
            if let times = prayerVM.todayPrayerTimes {
                Divider()
                    .padding(.vertical, Spacing.xxs) // Add spacing around divider

                prayerCompletionRow(times: times.prayerTimes)
                    .padding(.vertical, Spacing.xxxs) // Subtle spacing
            }

        }
    }

    // Urgent state (< 30min to prayer)
    private func urgentContent(period: PrayerPeriod) -> some View {
        VStack(spacing: Spacing.md) { // Enhanced from 16 to 24
            // Urgent header with pulsing icon
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accentSecondary)
                    .symbolEffect(.bounce.byLayer, options: .repeating)

                Text("PRAYER TIME APPROACHING")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.accentSecondary)

                Spacer()
            }

            // Large countdown with pulsing ring (respects reduced motion)
            ZStack {
                // Background (pulsing only if motion not reduced)
                Circle()
                    .fill(themeManager.currentTheme.accentSecondary.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(themeManager.currentTheme.accentSecondary, lineWidth: reduceMotion ? 4 : 3)
                            .scaleEffect(reduceMotion ? 1.0 : pulseScale)
                            .opacity(reduceMotion ? 1.0 : pulseOpacity)
                    )

                VStack(spacing: 4) {
                    if let nextPrayer = period.nextPrayer {
                        Text(nextPrayer.name.displayName)
                            .font(.title3.bold())
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        Text("in \(period.formattedTimeRemaining)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.accentSecondary)
                            .contentTransition(.numericText())
                    }
                }
            }
            .task {
                if !reduceMotion {
                    startPulsing()
                }
            }
        }
    }

    // Prayer window active (time to pray now)
    private func prayerWindowContent(prayer: PrayerName, period: PrayerPeriod) -> some View {
        let isCompleted = PrayerCompletionService.shared.isCompleted(prayer)

        return VStack(spacing: Spacing.md) {
            // Active prayer header
            HStack {
                Text("🕌")
                    .font(.title2)

                Text("TIME FOR \(prayer.displayName.uppercased())")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.accentPrimary)

                Spacer()

                // Completion indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                }
            }

            // Large countdown
            if let nextPrayer = period.nextPrayer {
                VStack(spacing: Spacing.xs) {
                    Text(period.countdownString)
                        .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                        .tracking(2)
                        .foregroundColor(themeManager.currentTheme.accentInteractive)
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    Text("until \(nextPrayer.name.displayName)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
    }

    // Loading state
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(themeManager.currentTheme.accentInteractive)

            Text("Calculating prayer times...")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(40)
    }

    // MARK: - Helper Views

    private func prayerCompletionRow(times: [PrayerTime]) -> some View {
        HStack(spacing: 16) {
            ForEach(Array(times.prefix(5)), id: \.name) { time in
                let isCompleted = PrayerCompletionService.shared.isCompleted(time.name)

                VStack(spacing: 4) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? themeManager.currentTheme.accentPrimary : themeManager.currentTheme.textTertiary)
                        .symbolEffect(.bounce, options: .speed(0.5), value: isCompleted) // iOS 26 draw-on animation

                    Text(String(time.name.displayName.prefix(3)))
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Animation State

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
            pulseOpacity = 0.0
        }
    }

    // MARK: - Computed Properties

    private var accessibilityLabel: String {
        guard let period = prayerVM.currentPrayerPeriod else {
            return "Loading prayer times"
        }

        if period.isUrgent {
            return "Prayer time approaching. \(period.nextPrayer?.name.displayName ?? "Prayer") in \(period.formattedTimeRemaining)"
        } else if let currentPrayer = period.currentPrayer {
            return "It's time for \(currentPrayer.displayName) prayer"
        } else {
            return "Next prayer: \(period.nextPrayer?.name.displayName ?? "Unknown") in \(period.formattedTimeRemaining)"
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Preview

#Preview("Normal State") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
        .task {
            await prayerVM.initialize()
        }
}

#Preview("Dark Mode") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environmentObject({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
        .padding()
        .background(Color(hex: "#1A2332"))
        .task {
            await prayerVM.initialize()
        }
}
