//
//  SmartPrayerRow.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Enhanced prayer row with inline special times and completion tracking
//

import SwiftUI

/// Smart prayer row that shows prayer with inline special times contextually
struct SmartPrayerRow: View {
    // MARK: - Properties

    let prayer: PrayerTime
    let isCurrentPrayer: Bool
    let isNextPrayer: Bool
    let isCompleted: Bool
    let relatedSpecialTimes: [SpecialTime] // e.g., Sunrise for Fajr, Midnight for Isha
    let canCheckOff: Bool // Whether this prayer can be checked off (not future)
    let onCompletionToggle: () -> Void

    @EnvironmentObject var themeManager: ThemeManager

    // Animation state
    @State private var scale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.8

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Main prayer row
            HStack(spacing: 0) {
                // Completion checkbox - Large tap area
                Button {
                    // Play audio + haptic feedback for checkbox tap
                    AudioHapticCoordinator.shared.playPrayerCheckbox()

                    // Scale animation on tap
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        scale = 0.95
                    }

                    // Spring back with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }

                    // Trigger completion with animation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onCompletionToggle()
                    }

                    // Success audio + haptic pattern when completing (not uncompleting)
                    if !isCompleted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            AudioHapticCoordinator.shared.playPrayerComplete()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(checkboxColor, lineWidth: 2.5)
                            .frame(width: 32, height: 32)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(checkmarkScale)
                                .shadow(color: AppColors.primary.green.opacity(0.5), radius: 4)
                                .transition(.scale.combined(with: .opacity))
                                .onAppear {
                                    // Checkmark pop animation
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                        checkmarkScale = 1.0
                                    }
                                }
                                .onDisappear {
                                    checkmarkScale = 0.8
                                }
                        }
                    }
                    .background(
                        Circle()
                            .fill(isCompleted ? checkboxColor : Color.clear)
                            .frame(width: 32, height: 32)
                    )
                    .frame(width: 60, height: 60) // Large tap target
                    .contentShape(Rectangle()) // Make entire area tappable
                }
                .buttonStyle(.plain)
                .disabled(!canCheckOff) // Prevent checking off future prayers

                // Prayer info
                VStack(alignment: .leading, spacing: 8) {
                    // Prayer name and time row
                    HStack(spacing: 12) {
                        // Prayer icon
                        Image(systemName: prayer.name.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(prayerIconColor)
                            .frame(width: 36)

                        // Prayer name
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prayer.name.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(prayerTextColor)

                            // Badge for current/next prayer
                            if isCurrentPrayer || isNextPrayer {
                                Text(isCurrentPrayer ? "IN PROGRESS" : "NEXT")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(isCurrentPrayer ? AppColors.primary.green : Color.purple)
                                    )
                            }
                        }

                        Spacer()

                        // Prayer time
                        Text(prayer.displayTime)
                            .font(.system(size: 20, weight: .light, design: .rounded))
                            .foregroundColor(prayerTextColor)
                    }

                    // Always show special times inline (no expansion)
                    if !relatedSpecialTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(relatedSpecialTimes) { specialTime in
                                HStack(spacing: 8) {
                                    Image(systemName: specialTime.type.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.primary.gold)
                                        .opacity(themeManager.currentTheme.secondaryOpacity)
                                        .frame(width: 20)

                                    Text(specialTime.type.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(themeManager.currentTheme.textSecondary)

                                    Spacer()

                                    Text(specialTime.displayTime)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(AppColors.primary.gold)
                                        .opacity(themeManager.currentTheme.secondaryOpacity)
                                }
                                .padding(.leading, 48) // Indent under icon
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
            .background(rowBackground)
        }
        .scaleEffect(scale)  // Apply scale animation to entire row
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Computed Properties

    private var prayerIconColor: Color {
        if !canCheckOff {
            // Future prayer - dimmed
            return themeManager.currentTheme.textDisabled
        } else if isCompleted {
            return AppColors.primary.green.opacity(themeManager.currentTheme.secondaryOpacity)
        } else if isCurrentPrayer {
            return AppColors.primary.green
        } else if isNextPrayer {
            return AppColors.primary.teal
        } else {
            return themeManager.currentTheme.textSecondary
        }
    }

    private var prayerTextColor: Color {
        if !canCheckOff {
            // Future prayer - dimmed
            return themeManager.currentTheme.textDisabled
        } else if isCompleted {
            return themeManager.currentTheme.textColor.opacity(themeManager.currentTheme.secondaryOpacity)
        } else if isCurrentPrayer || isNextPrayer {
            return themeManager.currentTheme.textColor
        } else {
            return themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.secondaryOpacity)
        }
    }

    private var checkboxColor: Color {
        if !canCheckOff {
            // Future prayer - very dimmed
            return themeManager.currentTheme.textColor.opacity(themeManager.currentTheme.disabledOpacity)
        } else if isCompleted {
            return AppColors.primary.green
        } else if isCurrentPrayer {
            return AppColors.primary.green
        } else {
            return themeManager.currentTheme.textColor.opacity(themeManager.currentTheme.tertiaryOpacity)
        }
    }

    private var rowBackground: some View {
        Group {
            if isCurrentPrayer {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green) * 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green) * 2.5), lineWidth: 2)
                    )
            } else if isNextPrayer {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.cardColor)
            }
        }
    }

    private var accessibilityLabel: String {
        var label = "\(prayer.name.displayName) prayer at \(prayer.displayTime)"
        if isCompleted {
            label += ", completed"
        } else if isCurrentPrayer {
            label += ", in progress"
        } else if isNextPrayer {
            label += ", next prayer"
        }
        if !relatedSpecialTimes.isEmpty {
            label += ", with \(relatedSpecialTimes.count) special times"
        }
        return label
    }
}

// MARK: - Preview

#Preview("Prayer Rows") {
    let now = Date()
    let sunrise = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
    let midnight = Calendar.current.date(byAdding: .hour, value: 8, to: now)!

    ScrollView {
        VStack(spacing: 12) {
            // Fajr - Current prayer with sunrise (can check off)
            SmartPrayerRow(
                prayer: PrayerTime(name: .fajr, time: now),
                isCurrentPrayer: true,
                isNextPrayer: false,
                isCompleted: false,
                relatedSpecialTimes: [
                    SpecialTime(type: .sunrise, time: sunrise)
                ],
                canCheckOff: true,
                onCompletionToggle: {}
            )

            // Dhuhr - Next prayer (future, cannot check off)
            SmartPrayerRow(
                prayer: PrayerTime(name: .dhuhr, time: Calendar.current.date(byAdding: .hour, value: 6, to: now)!),
                isCurrentPrayer: false,
                isNextPrayer: true,
                isCompleted: false,
                relatedSpecialTimes: [],
                canCheckOff: false,
                onCompletionToggle: {}
            )

            // Asr - Completed (past, was checkable)
            SmartPrayerRow(
                prayer: PrayerTime(name: .asr, time: Calendar.current.date(byAdding: .hour, value: -2, to: now)!),
                isCurrentPrayer: false,
                isNextPrayer: false,
                isCompleted: true,
                relatedSpecialTimes: [],
                canCheckOff: true,
                onCompletionToggle: {}
            )

            // Isha - Future with midnight (cannot check off)
            SmartPrayerRow(
                prayer: PrayerTime(name: .isha, time: Calendar.current.date(byAdding: .hour, value: 16, to: now)!),
                isCurrentPrayer: false,
                isNextPrayer: false,
                isCompleted: false,
                relatedSpecialTimes: [
                    SpecialTime(type: .midnight, time: midnight),
                    SpecialTime(type: .lastThird, time: Calendar.current.date(byAdding: .hour, value: 10, to: now)!)
                ],
                canCheckOff: false,
                onCompletionToggle: {}
            )
        }
        .padding()
    }
    .background(Color(hex: "#1A2332"))
    .environmentObject(ThemeManager())
}
