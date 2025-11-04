//
//  PrayerReminderPopup.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  Modal popup that asks user if they've prayed current prayer on app launch
//

import SwiftUI

/// Prayer reminder modal that appears on app launch
struct PrayerReminderPopup: View {
    // MARK: - Properties

    let prayer: PrayerTime
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Card container
            VStack(spacing: 0) {
                // Header with prayer icon
                VStack(spacing: 16) {
                    // Prayer icon in circle
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.green.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: prayer.name.icon)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(AppColors.primary.green)
                    }

                    // Prayer name
                    Text(prayer.name.displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textColor)

                    // Prayer time
                    Text(prayer.displayTime)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                // Divider
                IslamicDivider(style: .simple)
                    .padding(.vertical, 24)

                // Question text
                VStack(spacing: 12) {
                    Text("Have you prayed?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Text("May Allah accept your prayers")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.primary.gold)
                        .italic()
                }
                .padding(.horizontal, 24)

                // Action buttons
                HStack(spacing: 16) {
                    // Not Yet button
                    Button {
                        // Play back sound + haptic for "Not Yet"
                        // AudioHapticCoordinator.shared.playBack() // Removed: button press sound
                        dismiss()
                    } label: {
                        Text("Not Yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.currentTheme.textColor.opacity(0.2), lineWidth: 1.5)
                            )
                    }

                    // Yes, Alhamdulillah button
                    Button {
                        // Play confirm sound + success haptic for "Yes"
                        // AudioHapticCoordinator.shared.playSuccess() // Removed: button press sound

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            onComplete()
                        }

                        // Dismiss after short delay to show checkmark
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Yes, Alhamdulillah")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary.green)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.currentTheme.cardColor)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Play popup appearance sound + haptic
            AudioHapticCoordinator.shared.playPrayerReminderAppear()

            // Entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayer reminder for \(prayer.name.displayName)")
        .accessibilityHint("Have you prayed \(prayer.name.displayName)?")
    }

    // MARK: - Helper Methods

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Prayer Reminder") {
    ZStack {
        // Background view
        Color(hex: "#1A2332")
            .ignoresSafeArea()

        PrayerReminderPopup(
            prayer: PrayerTime(name: .fajr, time: Date()),
            onComplete: {
                print("Prayer marked as complete")
            },
            onDismiss: {
                print("Popup dismissed")
            }
        )
        .environmentObject(ThemeManager())
    }
}

#Preview("Multiple Prayers") {
    ScrollView {
        VStack(spacing: 40) {
            // Fajr
            PrayerReminderPopup(
                prayer: PrayerTime(name: .fajr, time: Date()),
                onComplete: {},
                onDismiss: {}
            )

            // Dhuhr
            PrayerReminderPopup(
                prayer: PrayerTime(name: .dhuhr, time: Date()),
                onComplete: {},
                onDismiss: {}
            )

            // Asr
            PrayerReminderPopup(
                prayer: PrayerTime(name: .asr, time: Date()),
                onComplete: {},
                onDismiss: {}
            )
        }
        .padding()
    }
    .background(Color(hex: "#1A2332"))
    .environmentObject(ThemeManager())
}
