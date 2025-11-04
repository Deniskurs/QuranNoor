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
    @State var prayerVM: PrayerViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            CardView(showPattern: false) {
                VStack(spacing: 16) {
                    if let period = prayerVM.currentPrayerPeriod {
                        content(for: period)
                    } else {
                        loadingContent
                    }
                }
                .padding(20)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
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
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary.teal)

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
                        color: AppColors.primary.teal,
                        backgroundColor: Color.gray.opacity(0.2),
                        showPercentage: false
                    )
                }
            }

            // Prayer name and countdown
            if let nextPrayer = period.nextPrayer {
                VStack(spacing: 8) {
                    Text(nextPrayer.name.displayName)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text(period.countdownString)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(AppColors.primary.teal)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                }

                // Prayer time
                Text("at \(nextPrayer.time, formatter: timeFormatter)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            // Prayer completion row
            if let times = prayerVM.todayPrayerTimes {
                prayerCompletionRow(times: times.prayerTimes)
            }

            // Quick action button
            PrimaryButton(
                "View All Prayer Times",
                icon: "list.bullet",
                action: {
                    // Navigate to prayer tab
                }
            )
            .frame(height: 44)
        }
    }

    // Urgent state (< 30min to prayer)
    private func urgentContent(period: PrayerPeriod) -> some View {
        VStack(spacing: 16) {
            // Urgent header with pulsing icon
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primary.gold)
                    .symbolEffect(.bounce.byLayer, options: .repeating)

                Text("PRAYER TIME APPROACHING")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary.gold)

                Spacer()
            }

            // Large countdown with pulsing ring
            ZStack {
                // Pulsing background
                Circle()
                    .fill(AppColors.primary.gold.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(AppColors.primary.gold, lineWidth: 3)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                    )

                VStack(spacing: 4) {
                    if let nextPrayer = period.nextPrayer {
                        Text(nextPrayer.name.displayName)
                            .font(.title3.bold())
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        Text("in \(period.formattedTimeRemaining)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primary.gold)
                            .contentTransition(.numericText())
                    }
                }
            }
            .task {
                startPulsing()
            }

            // Action buttons
            HStack(spacing: 12) {
                SecondaryButton(
                    "Snooze 5min",
                    icon: "clock.arrow.circlepath",
                    action: {
                        // Snooze notification
                    }
                )

                PrimaryButton(
                    "View Details",
                    icon: "info.circle",
                    action: {
                        // Navigate to prayer details
                    }
                )
            }
            .frame(height: 44)
        }
    }

    // Prayer window active (time to pray now)
    private func prayerWindowContent(prayer: PrayerName, period: PrayerPeriod) -> some View {
        VStack(spacing: 16) {
            // Active prayer header
            HStack {
                Text("🕌")
                    .font(.title2)
                    .foregroundColor(AppColors.primary.green)

                Text("TIME FOR \(prayer.displayName.uppercased())")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary.green)

                Spacer()
            }

            // Inspirational quote
            Text("Prayer is better than sleep")
                .font(.title3)
                .italic()
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)

            // Action buttons
            VStack(spacing: 12) {
                PrimaryButton(
                    "I've Prayed",
                    icon: "checkmark.circle.fill",
                    action: {
                        // Mark prayer as completed
                    }
                )
                .frame(height: 50)

                SecondaryButton(
                    "Remind me in 10 minutes",
                    icon: "clock.arrow.circlepath",
                    action: {
                        // Schedule reminder
                    }
                )
                .frame(height: 44)
            }

            // Window duration
            if let nextPrayer = period.nextPrayer {
                Text("Window closes at \(nextPrayer.time, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
    }

    // Loading state
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppColors.primary.teal)

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
                        .foregroundColor(isCompleted ? AppColors.primary.green : themeManager.currentTheme.textTertiary)

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

    NextPrayerCardView(prayerVM: prayerVM)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
        .task {
            await prayerVM.initialize()
        }
}

#Preview("Dark Mode") {
    @Previewable @State var prayerVM = PrayerViewModel()

    NextPrayerCardView(prayerVM: prayerVM)
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
