//
//  CurrentPrayerHeader.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Sticky header component showing current prayer period state
//

import SwiftUI

/// Sticky header displaying current prayer period with progress and countdown
struct CurrentPrayerHeader: View {
    // MARK: - Properties

    let state: PrayerPeriodState
    let progress: Double
    let countdownString: String
    let isUrgent: Bool

    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Top section: State icon + description
            HStack(spacing: 12) {
                // Icon
                Image(systemName: stateIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(stateColor)
                    .frame(width: 44, height: 44)

                // State description
                VStack(alignment: .leading, spacing: 4) {
                    Text(stateBadgeText.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(stateColor)

                    Text(stateDescription)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)
                }

                Spacer()

                // Progress ring (only for in-progress state)
                if case .inProgress = state {
                    OptimizedProgressRing(
                        progress: progress,
                        lineWidth: 6,
                        size: 56,
                        color: isUrgent ? .orange : stateColor,
                        showPercentage: false
                    )
                }
            }

            // Countdown section (if applicable)
            if !countdownString.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isUrgent ? .orange : AppColors.primary.teal)

                    Text(countdownLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))

                    Spacer()

                    Text(countdownString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(isUrgent ? .orange : AppColors.primary.teal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isUrgent ? Color.orange : AppColors.primary.teal).opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.cardColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Computed Properties

    private var stateIcon: String {
        switch state {
        case .beforeFajr:
            return "moon.stars.fill"
        case .inProgress(let prayer, _):
            return prayer.icon
        case .betweenPrayers(_, let next, _):
            return next.icon
        case .afterIsha:
            return "moon.fill"
        }
    }

    private var stateColor: Color {
        switch state {
        case .beforeFajr:
            return AppColors.primary.midnight
        case .inProgress(let prayer, _):
            if isUrgent {
                return .orange
            }
            return prayerColor(prayer)
        case .betweenPrayers(_, let next, _):
            return prayerColor(next).opacity(0.7)
        case .afterIsha:
            return AppColors.primary.midnight
        }
    }

    private func prayerColor(_ prayer: PrayerName) -> Color {
        switch prayer {
        case .fajr:
            return AppColors.primary.green
        case .dhuhr:
            return AppColors.primary.teal
        case .asr:
            return AppColors.primary.gold
        case .maghrib:
            return .orange
        case .isha:
            return AppColors.primary.midnight
        }
    }

    private var stateBadgeText: String {
        switch state {
        case .beforeFajr:
            return "Before Fajr"
        case .inProgress(let prayer, _):
            return "\(prayer.displayName) Period"
        case .betweenPrayers(_, _, _):
            return "Between Prayers"
        case .afterIsha:
            return "After Isha"
        }
    }

    private var stateDescription: String {
        switch state {
        case .beforeFajr:
            return "Preparing for Fajr"
        case .inProgress(let prayer, _):
            if isUrgent {
                return "\(prayer.displayName) Ending Soon"
            }
            return "\(prayer.displayName) Time"
        case .betweenPrayers(_, let next, _):
            return "\(next.displayName) Upcoming"
        case .afterIsha:
            return "Night Time"
        }
    }

    private var countdownLabel: String {
        switch state {
        case .inProgress:
            return isUrgent ? "Ends in" : "Time remaining"
        default:
            return "Starts in"
        }
    }

    private var accessibilityLabel: String {
        let stateText = stateDescription
        let timeText = !countdownString.isEmpty ? ", \(countdownLabel) \(countdownString)" : ""
        return "\(stateText)\(timeText)"
    }
}

// MARK: - Preview

#Preview("All States") {
    let sampleFajr = Date()
    let sampleDhuhr = Calendar.current.date(byAdding: .hour, value: 6, to: sampleFajr)!
    let sampleAsr = Calendar.current.date(byAdding: .hour, value: 10, to: sampleFajr)!
    let _ = Calendar.current.date(byAdding: .hour, value: 14, to: sampleFajr)! // sampleMaghrib
    let _ = Calendar.current.date(byAdding: .hour, value: 16, to: sampleFajr)! // sampleIsha
    let _ = Calendar.current.date(byAdding: .hour, value: 22, to: sampleFajr)! // sampleMidnight

    ScrollView {
        VStack(spacing: 20) {
            // Before Fajr
            CurrentPrayerHeader(
                state: .beforeFajr(nextFajr: sampleFajr),
                progress: 0,
                countdownString: "02:30:15",
                isUrgent: false
            )

            // In Progress - Fajr (Not Urgent)
            CurrentPrayerHeader(
                state: .inProgress(prayer: .fajr, deadline: sampleFajr),
                progress: 0.3,
                countdownString: "45:20",
                isUrgent: false
            )

            // In Progress - Dhuhr (Urgent)
            CurrentPrayerHeader(
                state: .inProgress(prayer: .dhuhr, deadline: sampleDhuhr),
                progress: 0.85,
                countdownString: "12:45",
                isUrgent: true
            )

            // Between Prayers
            CurrentPrayerHeader(
                state: .betweenPrayers(
                    previous: .dhuhr,
                    next: .asr,
                    nextStartTime: sampleAsr
                ),
                progress: 0.6,
                countdownString: "01:15:30",
                isUrgent: false
            )

            // After Isha
            CurrentPrayerHeader(
                state: .afterIsha(tomorrowFajr: sampleFajr),
                progress: 0,
                countdownString: "04:20:00",
                isUrgent: false
            )
        }
        .padding()
    }
    .background(Color(hex: "#1A2332"))
    .environmentObject(ThemeManager())
}
