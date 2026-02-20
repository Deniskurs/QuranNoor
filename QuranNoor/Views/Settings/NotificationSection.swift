//
//  NotificationSection.swift
//  QuranNoor
//
//  Notification toggle and advanced notification settings
//

import SwiftUI

struct NotificationSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var notificationsEnabled: Bool
    @Binding var soundEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Notifications", icon: "bell.fill")

            CardView {
                VStack(spacing: 16) {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accentMuted)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Prayer Reminders")
                                ThemedText.caption("Get notified before prayer times")
                            }
                        }
                    }
                    .tint(themeManager.currentTheme.accent)

                    IslamicDivider(style: .simple)

                    Toggle(isOn: $soundEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Sound Alerts")
                                ThemedText.caption("Play adhan when prayer time arrives")
                            }
                        }
                    }
                    .tint(themeManager.currentTheme.accent)
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1.0 : themeManager.currentTheme.disabledOpacity)

                    IslamicDivider(style: .simple)

                    // Advanced Notification Settings Link
                    NavigationLink {
                        NotificationSettingsView()
                            .environment(themeManager)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Advanced Settings")
                                ThemedText.caption("Per-prayer notifications & reminders")
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.tertiaryOpacity)
                        }
                    }
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1.0 : themeManager.currentTheme.disabledOpacity)
                }
            }
        }
    }
}
