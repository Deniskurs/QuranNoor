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

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var dismissTask: Task<Void, Never>?

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
                            .fill(themeManager.currentTheme.accent.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: prayer.name.icon)
                            .font(.largeTitle.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.accent)
                    }

                    // Prayer name
                    Text(prayer.name.displayName)
                        .font(.title.weight(.bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    // Prayer time
                    Text(prayer.displayTime)
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                // Divider
                IslamicDivider(style: .simple)
                    .padding(.vertical, 24)

                // Question text
                VStack(spacing: 12) {
                    Text("Have you prayed?")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("May Allah accept your prayers")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.accent)
                        .italic()
                }
                .padding(.horizontal, 24)

                // Action buttons
                HStack(spacing: 16) {
                    // Not Yet button
                    Button {
                        dismiss()
                    } label: {
                        Text("Not Yet")
                            .font(.body.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    // Secondary action: plain glass capsule-rect
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: BorderRadius.lg, style: .continuous))

                    // Yes, Alhamdulillah button
                    Button {
                        // Play confirm sound + success haptic for "Yes"
                        // AudioHapticCoordinator.shared.playSuccess() // Removed: button press sound

                        withAnimation(AppAnimation.standard) {
                            onComplete()
                        }

                        // Dismiss after short delay to show checkmark using structured concurrency
                        dismissTask = Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            guard !Task.isCancelled else { return }
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                            Text("Yes, Alhamdulillah")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(themeManager.currentTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    // Primary action: accent-tinted interactive glass
                    .glassEffect(
                        .regular.tint(themeManager.currentTheme.accent).interactive(),
                        in: .rect(cornerRadius: BorderRadius.lg, style: .continuous)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 380)
            // Liquid Glass card floating over the dimmed backdrop
            .glassEffect(in: .rect(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Play popup appearance sound + haptic
            AudioHapticCoordinator.shared.playPrayerReminderAppear()

            // Entrance animation
            withAnimation(AppAnimation.expressive) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prayer reminder for \(prayer.name.displayName)")
        .accessibilityHint("Have you prayed \(prayer.name.displayName)?")
        .onDisappear {
            dismissTask?.cancel()
        }
    }

    // MARK: - Helper Methods

    private func dismiss() {
        withAnimation(AppAnimation.fast) {
            scale = 0.8
            opacity = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
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
        .environment(ThemeManager())
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
    .environment(ThemeManager())
}
