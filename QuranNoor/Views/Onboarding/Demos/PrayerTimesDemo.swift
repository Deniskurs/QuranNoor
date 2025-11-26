//
//  PrayerTimesDemo.swift
//  QuranNoor
//
//  Interactive prayer times demo for onboarding
//  Shows sample prayer schedule with live countdown animation
//

import SwiftUI

struct PrayerTimesDemo: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var currentTime = Date()
    @State private var selectedPrayer = 2 // Asr (upcoming)

    // Sample prayer times - colors will be resolved dynamically based on theme
    private var prayers: [(name: String, time: String, icon: String, color: Color)] {
        [
            ("Fajr", "05:42 AM", "sunrise.fill", themeManager.currentTheme.featureAccent),
            ("Dhuhr", "12:35 PM", "sun.max.fill", themeManager.currentTheme.accentSecondary),
            ("Asr", "03:48 PM", "sun.haze.fill", themeManager.currentTheme.accentInteractive),
            ("Maghrib", "06:22 PM", "sunset.fill", themeManager.currentTheme.accentPrimary),
            ("Isha", "07:45 PM", "moon.stars.fill", themeManager.currentTheme.featureAccent)
        ]
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with location
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                    ThemedText("San Francisco, CA", style: .heading)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                }

                // Hijri date
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    Text("21 Jumada al-Awwal 1446")
                        .font(.caption)
                }
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                themeManager.currentTheme.cardColor
                    .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.05), radius: 2, y: 2)
            )

            Divider()

            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Countdown card
                    countdownCard

                    // Prayer times list
                    VStack(spacing: 12) {
                        ForEach(prayers.indices, id: \.self) { index in
                            prayerRow(prayer: prayers[index], index: index)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Demo hint
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 40)

                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("Never miss a prayer with timely notifications")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.1), radius: 8, y: 4)
        .task {
            // Modern timer pattern - automatically cancels when view disappears
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                currentTime = Date()
            }
        }
    }

    // MARK: - Countdown Card
    private var countdownCard: some View {
        VStack(spacing: 16) {
            // Next prayer indicator
            HStack {
                Text("NEXT PRAYER")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: prayers[selectedPrayer].icon)
                    .foregroundColor(prayers[selectedPrayer].color)
            }

            // Prayer name
            Text(prayers[selectedPrayer].name)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.accentPrimary)

            // Countdown timer
            HStack(spacing: 4) {
                countdownComponent(value: 2, label: "h")
                Text(":")
                    .font(.title.weight(.bold))
                    .foregroundColor(themeManager.currentTheme.featureAccent)
                countdownComponent(value: 34, label: "m")
                Text(":")
                    .font(.title.weight(.bold))
                    .foregroundColor(themeManager.currentTheme.featureAccent)
                countdownComponent(value: Int(currentTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 60)), label: "s")
            }

            // Prayer time
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text("at \(prayers[selectedPrayer].time)")
                    .font(.headline)
            }
            .foregroundColor(prayers[selectedPrayer].color)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: 0.65) // 65% progress
                    .stroke(
                        AngularGradient(
                            colors: [prayers[selectedPrayer].color, prayers[selectedPrayer].color.opacity(0.5)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: currentTime)

                VStack(spacing: 4) {
                    Text("65%")
                        .font(.title2.weight(.bold))
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                    Text("of day passed")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .frame(width: 120, height: 120)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.cardColor)
                .shadow(color: prayers[selectedPrayer].color.opacity(0.2), radius: 12, y: 6)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Countdown Component
    @ViewBuilder
    private func countdownComponent(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.cardColor.opacity(0.5))
        )
    }

    // MARK: - Prayer Row
    @ViewBuilder
    private func prayerRow(prayer: (name: String, time: String, icon: String, color: Color), index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPrayer = index
                HapticManager.shared.trigger(.selection)
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(prayer.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: prayer.icon)
                        .font(.system(size: 20))
                        .foregroundColor(prayer.color)
                }

                // Prayer name
                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.name)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    if index == selectedPrayer {
                        Text("Upcoming")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(prayer.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(prayer.color.opacity(0.2))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prayer.time)
                        .font(.headline.monospacedDigit())
                        .foregroundColor(index == selectedPrayer ? prayer.color : themeManager.currentTheme.textColor)

                    // Checkmark for completed prayers
                    if index < selectedPrayer {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Prayed")
                                .font(.caption2)
                        }
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                    }
                }

                // Selection indicator
                if index == selectedPrayer {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(prayer.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                index == selectedPrayer ? prayer.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    PrayerTimesDemo()
        .environment(ThemeManager())
        .frame(height: 600)
}
