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

    @Environment(ThemeManager.self) var themeManager: ThemeManager

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
                        .foregroundColor(isUrgent ? .orange : themeManager.currentTheme.accentSecondary)

                    Text(countdownLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .opacity(themeManager.currentTheme.secondaryOpacity)

                    Spacer()

                    Text(countdownString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(isUrgent ? .orange : themeManager.currentTheme.accentSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isUrgent ? Color.orange : themeManager.currentTheme.accentSecondary).opacity(0.15))
                )
            }

            // Motivational tip (optional, based on state)
            if let tip = motivationalTip {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentSecondary)

                    Text(tip)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
            return themeManager.currentTheme.accentPrimary
        case .inProgress(let prayer, _):
            if isUrgent {
                return .orange
            }
            return prayerColor(prayer)
        case .betweenPrayers(_, let next, _):
            return prayerColor(next).opacity(themeManager.currentTheme.secondaryOpacity)
        case .afterIsha:
            return themeManager.currentTheme.accentPrimary
        }
    }

    private func prayerColor(_ prayer: PrayerName) -> Color {
        switch prayer {
        case .fajr:
            return themeManager.currentTheme.accentPrimary
        case .dhuhr:
            return themeManager.currentTheme.accentSecondary
        case .asr:
            return themeManager.currentTheme.accentInteractive
        case .maghrib:
            return .orange
        case .isha:
            return themeManager.currentTheme.accentPrimary
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
            return getBeforeFajrMessage()
        case .inProgress(let prayer, _):
            if isUrgent {
                return getUrgentMessage(for: prayer)
            }
            return getInProgressMessage(for: prayer)
        case .betweenPrayers(_, let next, _):
            return getBetweenPrayersMessage(for: next)
        case .afterIsha:
            return getAfterIshaMessage()
        }
    }

    // MARK: - Contextual Messages

    private func getBeforeFajrMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Last third of night (special blessed time)
        if hour >= 3 && hour < 5 {
            return "The Last Third of Night"
        }

        return "Preparing for Fajr"
    }

    private func getInProgressMessage(for prayer: PrayerName) -> String {
        let messages: [PrayerName: [String]] = [
            .fajr: [
                "Time for Fajr Prayer",
                "Begin Your Day with Prayer",
                "The Best Start to Your Day"
            ],
            .dhuhr: [
                "Time for Dhuhr Prayer",
                "Midday Break for Prayer",
                "Renew Your Focus with Prayer"
            ],
            .asr: [
                "Time for Asr Prayer",
                "Afternoon Prayer Time",
                "Seek Forgiveness Before Sunset"
            ],
            .maghrib: [
                "Time for Maghrib Prayer",
                "Break Your Fast with Prayer",
                "The Sunset Prayer"
            ],
            .isha: [
                "Time for Isha Prayer",
                "Complete Your Day with Prayer",
                "The Final Prayer of the Day"
            ]
        ]

        // Get day of week to add Friday-specific message for Dhuhr
        if prayer == .dhuhr && Calendar.current.component(.weekday, from: Date()) == 6 {
            return "Time for Jumu'ah Prayer"
        }

        let prayerMessages = messages[prayer] ?? ["Time for \(prayer.displayName) Prayer"]
        return prayerMessages.randomElement() ?? prayerMessages[0]
    }

    private func getUrgentMessage(for prayer: PrayerName) -> String {
        let urgentMessages: [PrayerName: [String]] = [
            .fajr: [
                "Fajr Ending Soon!",
                "Don't Miss Fajr!",
                "Last Moments of Fajr"
            ],
            .dhuhr: [
                "Dhuhr Ending Soon",
                "Time Running Out for Dhuhr",
                "Complete Dhuhr Now"
            ],
            .asr: [
                "Asr Ending Soon",
                "Pray Asr Before Sunset",
                "Final Minutes of Asr"
            ],
            .maghrib: [
                "Maghrib Ending Soon",
                "Don't Delay Maghrib",
                "Time Running Out"
            ],
            .isha: [
                "Isha Ending Soon",
                "Complete Your Day's Prayers",
                "Last Call for Isha"
            ]
        ]

        let prayerMessages = urgentMessages[prayer] ?? ["\(prayer.displayName) Ending Soon"]
        return prayerMessages.randomElement() ?? prayerMessages[0]
    }

    private func getBetweenPrayersMessage(for nextPrayer: PrayerName) -> String {
        let betweenMessages: [PrayerName: [String]] = [
            .fajr: [
                "Fajr Approaching",
                "Night is Ending Soon"
            ],
            .dhuhr: [
                "Dhuhr is Next",
                "Prepare for Midday Prayer"
            ],
            .asr: [
                "Asr Approaching",
                "Afternoon Prayer Soon"
            ],
            .maghrib: [
                "Maghrib is Next",
                "Sunset Prayer Soon"
            ],
            .isha: [
                "Isha Approaching",
                "Final Prayer of the Day Soon"
            ]
        ]

        // Add Friday-specific message
        if nextPrayer == .dhuhr && Calendar.current.component(.weekday, from: Date()) == 6 {
            return "Jumu'ah Prayer Approaching"
        }

        let messages = betweenMessages[nextPrayer] ?? ["\(nextPrayer.displayName) Upcoming"]
        return messages.randomElement() ?? messages[0]
    }

    private func getAfterIshaMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Late night (past midnight)
        if hour >= 0 && hour < 3 {
            return "Night of Reflection"
        }

        // Evening (before midnight)
        return "Rest and Recharge"
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

    private var motivationalTip: String? {
        switch state {
        case .beforeFajr:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 3 && hour < 5 {
                return "The last third of the night is blessed for making dua"
            }
            return "Fajr prayer awakens the soul and brings blessings"

        case .inProgress(let prayer, _):
            if isUrgent {
                return getUrgentTip(for: prayer)
            }
            return getInProgressTip(for: prayer)

        case .betweenPrayers(_, let next, _):
            return getBetweenPrayersTip(for: next)

        case .afterIsha:
            return "Rest is worship when it prepares you for tomorrow's prayers"
        }
    }

    private func getInProgressTip(for prayer: PrayerName) -> String {
        let tips: [PrayerName: [String]] = [
            .fajr: [
                "Pray in congregation for 27x reward",
                "Two rakahs of Fajr are better than the world",
                "Angels witness the Fajr prayer"
            ],
            .dhuhr: [
                "Make dua after prayer - it's more likely to be answered",
                "A break for prayer brings barakah to your work",
                "Pray with focus and presence"
            ],
            .asr: [
                "The afternoon is blessed for seeking forgiveness",
                "Remember Allah during the day for peace of heart",
                "Prayer on time is most beloved to Allah"
            ],
            .maghrib: [
                "Break your fast first, then pray promptly",
                "Dua at Iftar time is readily accepted",
                "The Prophet ﷺ would hasten to pray Maghrib"
            ],
            .isha: [
                "Complete your day with gratitude",
                "Pray Witr before you sleep",
                "The night prayer brings tranquility"
            ]
        ]

        let prayerTips = tips[prayer] ?? []
        return prayerTips.randomElement() ?? ""
    }

    private func getUrgentTip(for prayer: PrayerName) -> String {
        return "Prayer on time is most beloved to Allah - don't delay!"
    }

    private func getBetweenPrayersTip(for nextPrayer: PrayerName) -> String {
        let tips: [PrayerName: [String]] = [
            .fajr: ["Prepare yourself now - Fajr is the most challenging prayer"],
            .dhuhr: ["Use your break time wisely - prioritize prayer"],
            .asr: ["Plan to leave work early for prayer if needed"],
            .maghrib: ["Prepare to break your fast and pray"],
            .isha: ["Wind down your day with the final prayer"]
        ]

        let prayerTips = tips[nextPrayer] ?? []
        return prayerTips.randomElement() ?? ""
    }
}

// MARK: - Preview

#Preview("All States") {
    let sampleFajr = Date()
    let sampleDhuhr = Calendar.current.date(byAdding: .hour, value: 6, to: sampleFajr)!
    let sampleAsr = Calendar.current.date(byAdding: .hour, value: 10, to: sampleFajr)!

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
    .environment(ThemeManager())
}
