//
//  EnhancedPrayerRow.swift
//  QuranNoor
//
//  Enhanced prayer row with improved visuals, larger tap targets,
//  and refined styling. Replaces SmartPrayerRow.
//

import SwiftUI

/// Enhanced prayer row with premium styling and improved interactions
struct EnhancedPrayerRow: View {
    // MARK: - Properties

    let prayer: PrayerTime
    let isCurrentPrayer: Bool
    let isNextPrayer: Bool
    let relatedSpecialTimes: [SpecialTime]
    let canCheckOff: Bool
    let isCompleted: Bool  // Passed from parent to avoid @Observable observation
    let onCompletionToggle: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    // Animation states
    @State private var isPressed: Bool = false
    @State private var showSpecialTimes: Bool = false

    // Minimum row height for accessibility
    private let minRowHeight: CGFloat = 72

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Checkbox area
            PrayerCompletionCheckbox(
                prayerName: prayer.name,
                canCheckOff: canCheckOff,
                isCurrentPrayer: isCurrentPrayer,
                isCompleted: isCompleted,
                onCompletionToggle: onCompletionToggle
            )
            .padding(.leading, 16)

            // Main content
            HStack(spacing: 14) {
                // Prayer icon with glow effect for current
                prayerIcon(isCompleted: isCompleted)

                // Prayer info
                VStack(alignment: .leading, spacing: 6) {
                    // Name and badges
                    HStack(spacing: 8) {
                        Text(prayer.name.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor(isCompleted: isCompleted))

                        if isCurrentPrayer {
                            statusBadge(text: "IN PROGRESS", color: themeManager.currentTheme.accentPrimary)
                        } else if isNextPrayer {
                            statusBadge(text: "NEXT", color: themeManager.currentTheme.accentSecondary)
                        }

                        if PrayerTimeAdjustmentService.shared.isAdjusted(prayer.name) {
                            let adjustment = PrayerTimeAdjustmentService.shared.getAdjustment(for: prayer.name)
                            statusBadge(
                                text: "\(adjustment > 0 ? "+" : "")\(adjustment)m",
                                color: .orange
                            )
                        }
                    }

                    // Special times (inline, expandable)
                    if !relatedSpecialTimes.isEmpty {
                        specialTimesSection(isCompleted: isCompleted)
                    }
                }

                Spacer()

                // Time display
                VStack(alignment: .trailing, spacing: 2) {
                    Text(prayer.displayTime)
                        .font(.system(size: 22, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(timeColor(isCompleted: isCompleted))

                    if isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Done")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
        }
        .frame(minHeight: minRowHeight)
        .background(rowBackground(isCompleted: isCompleted))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(isCompleted: isCompleted))
        .accessibilityAddTraits(isCurrentPrayer ? .isSelected : [])
    }

    // MARK: - Prayer Icon

    private func prayerIcon(isCompleted: Bool) -> some View {
        ZStack {
            // Glow for current prayer
            if isCurrentPrayer && !isCompleted {
                Circle()
                    .fill(themeManager.currentTheme.accentPrimary.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .blur(radius: 6)
            }

            // Icon background
            Circle()
                .fill(iconBackgroundColor(isCompleted: isCompleted))
                .frame(width: 40, height: 40)

            // Icon
            Image(systemName: prayer.name.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconForegroundColor(isCompleted: isCompleted))
        }
    }

    // MARK: - Status Badge

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }

    // MARK: - Special Times Section

    private func specialTimesSection(isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(relatedSpecialTimes.prefix(showSpecialTimes ? relatedSpecialTimes.count : 1)) { specialTime in
                HStack(spacing: 6) {
                    Image(systemName: specialTime.type.icon)
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.currentTheme.accentInteractive)
                        .opacity(isCompleted ? 0.5 : 0.8)

                    Text(specialTime.type.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    Text(specialTime.displayTime)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.accentInteractive)
                        .opacity(isCompleted ? 0.5 : 0.7)
                }
            }

            // Show more button if multiple special times
            if relatedSpecialTimes.count > 1 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSpecialTimes.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showSpecialTimes ? "Show less" : "Show \(relatedSpecialTimes.count - 1) more")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: showSpecialTimes ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(themeManager.currentTheme.accentInteractive)
                }
            }
        }
        .padding(.leading, 2)
    }

    // MARK: - Row Background

    private func rowBackground(isCompleted: Bool) -> some View {
        Group {
            if isCurrentPrayer && !isCompleted {
                // Current prayer: highlighted with accent
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentTheme.accentPrimary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(themeManager.currentTheme.accentPrimary.opacity(0.3), lineWidth: 1.5)
                    )
            } else if isNextPrayer && !isCompleted {
                // Next prayer: subtle highlight
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentTheme.accentSecondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(themeManager.currentTheme.accentSecondary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                // Default card
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentTheme.cardColor)
            }
        }
    }

    // MARK: - Colors

    private func iconBackgroundColor(isCompleted: Bool) -> Color {
        if !canCheckOff {
            return themeManager.currentTheme.textTertiary.opacity(0.1)
        } else if isCompleted {
            return themeManager.currentTheme.accentPrimary.opacity(0.15)
        } else if isCurrentPrayer {
            return themeManager.currentTheme.accentPrimary.opacity(0.2)
        } else if isNextPrayer {
            return themeManager.currentTheme.accentSecondary.opacity(0.15)
        } else {
            return themeManager.currentTheme.textTertiary.opacity(0.1)
        }
    }

    private func iconForegroundColor(isCompleted: Bool) -> Color {
        if !canCheckOff {
            return themeManager.currentTheme.textDisabled
        } else if isCompleted {
            return themeManager.currentTheme.accentPrimary
        } else if isCurrentPrayer {
            return themeManager.currentTheme.accentPrimary
        } else if isNextPrayer {
            return themeManager.currentTheme.accentSecondary
        } else {
            return themeManager.currentTheme.textSecondary
        }
    }

    private func textColor(isCompleted: Bool) -> Color {
        if !canCheckOff {
            return themeManager.currentTheme.textDisabled
        } else if isCompleted {
            return themeManager.currentTheme.textPrimary.opacity(0.6)
        } else {
            return themeManager.currentTheme.textPrimary
        }
    }

    private func timeColor(isCompleted: Bool) -> Color {
        if !canCheckOff {
            return themeManager.currentTheme.textDisabled
        } else if isCompleted {
            return themeManager.currentTheme.textSecondary.opacity(0.6)
        } else if isCurrentPrayer {
            return themeManager.currentTheme.accentPrimary
        } else {
            return themeManager.currentTheme.textPrimary
        }
    }

    // MARK: - Accessibility

    private func accessibilityLabel(isCompleted: Bool) -> String {
        var label = "\(prayer.name.displayName) prayer at \(prayer.displayTime)"
        if isCompleted {
            label += ", completed"
        } else if isCurrentPrayer {
            label += ", in progress"
        } else if isNextPrayer {
            label += ", next prayer"
        } else if !canCheckOff {
            label += ", upcoming"
        }
        if !relatedSpecialTimes.isEmpty {
            label += ". Special times: \(relatedSpecialTimes.map { "\($0.type.displayName) at \($0.displayTime)" }.joined(separator: ", "))"
        }
        return label
    }
}

// MARK: - Preview

#Preview("Enhanced Prayer Rows") {
    let now = Date()

    ScrollView {
        VStack(spacing: 12) {
            // Current prayer
            EnhancedPrayerRow(
                prayer: PrayerTime(name: .asr, time: now),
                isCurrentPrayer: true,
                isNextPrayer: false,
                relatedSpecialTimes: [],
                canCheckOff: true,
                isCompleted: false,
                onCompletionToggle: {}
            )

            // Completed prayer
            EnhancedPrayerRow(
                prayer: PrayerTime(name: .dhuhr, time: now.addingTimeInterval(-3600 * 4)),
                isCurrentPrayer: false,
                isNextPrayer: false,
                relatedSpecialTimes: [],
                canCheckOff: true,
                isCompleted: true,
                onCompletionToggle: {}
            )

            // Fajr with special times
            EnhancedPrayerRow(
                prayer: PrayerTime(name: .fajr, time: now.addingTimeInterval(-3600 * 10)),
                isCurrentPrayer: false,
                isNextPrayer: false,
                relatedSpecialTimes: [
                    SpecialTime(type: .sunrise, time: now.addingTimeInterval(-3600 * 9))
                ],
                canCheckOff: true,
                isCompleted: false,
                onCompletionToggle: {}
            )

            // Next prayer
            EnhancedPrayerRow(
                prayer: PrayerTime(name: .maghrib, time: now.addingTimeInterval(3600)),
                isCurrentPrayer: false,
                isNextPrayer: true,
                relatedSpecialTimes: [],
                canCheckOff: false,
                isCompleted: false,
                onCompletionToggle: {}
            )

            // Isha with multiple special times
            EnhancedPrayerRow(
                prayer: PrayerTime(name: .isha, time: now.addingTimeInterval(3600 * 3)),
                isCurrentPrayer: false,
                isNextPrayer: false,
                relatedSpecialTimes: [
                    SpecialTime(type: .midnight, time: now.addingTimeInterval(3600 * 6)),
                    SpecialTime(type: .lastThird, time: now.addingTimeInterval(3600 * 8))
                ],
                canCheckOff: false,
                isCompleted: false,
                onCompletionToggle: {}
            )
        }
        .padding()
    }
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}
