//
//  NotificationSettingsView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Advanced notification settings with per-prayer customization
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var preferencesService = NotificationPreferencesService.shared
    @State private var showResetConfirmation = false
    @State private var expandedPrayers: Set<PrayerName> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    summaryCard

                    // Quick Actions
                    quickActionsCard

                    // Individual Prayer Settings
                    VStack(spacing: 16) {
                        ForEach(PrayerName.allCases, id: \.self) { prayer in
                            PrayerNotificationRow(
                                prayer: prayer,
                                isExpanded: expandedPrayers.contains(prayer),
                                onToggleExpand: {
                                    toggleExpansion(for: prayer)
                                }
                            )
                        }
                    }

                    // Information Card
                    infoCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            preferencesService.enableAllNotifications()
                        } label: {
                            Label("Enable All", systemImage: "bell.fill")
                        }

                        Button {
                            preferencesService.disableAllNotifications()
                        } label: {
                            Label("Disable All", systemImage: "bell.slash.fill")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    preferencesService.resetToDefaults()
                    AudioHapticCoordinator.shared.playSuccess()
                }
            } message: {
                Text("This will enable all prayer notifications and clear all reminder settings.")
            }
        }
    }

    // MARK: - Components

    private var summaryCard: some View {
        LiquidGlassCardView {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Notifications")
                            .font(.headline)
                            .foregroundStyle(themeManager.primaryTextColor)

                        Text("\(preferencesService.getEnabledNotificationCount()) of 5 prayers")
                            .font(.subheadline)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }

                    Spacer()
                }

                if preferencesService.getEnabledReminderCount() > 0 {
                    Divider()

                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.title3)
                            .foregroundStyle(Color.orange)

                        Text("\(preferencesService.getEnabledReminderCount()) reminder\(preferencesService.getEnabledReminderCount() != 1 ? "s" : "") active")
                            .font(.subheadline)
                            .foregroundStyle(themeManager.secondaryTextColor)

                        Spacer()
                    }
                }
            }
            .padding(16)
        }
    }

    private var quickActionsCard: some View {
        HStack(spacing: 12) {
            Button {
                preferencesService.enableAllNotifications()
                AudioHapticCoordinator.shared.playButtonPress()
            } label: {
                Label("Enable All", systemImage: "bell.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                preferencesService.disableAllNotifications()
                AudioHapticCoordinator.shared.playButtonPress()
            } label: {
                Label("Disable All", systemImage: "bell.slash")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.cardBackground)
                    .foregroundStyle(themeManager.primaryTextColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var infoCard: some View {
        LiquidGlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("About Notifications", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint(icon: "bell.fill", text: "Main notification at prayer time")
                    bulletPoint(icon: "exclamationmark.triangle.fill", text: "Urgent notification 30 min before end")
                    bulletPoint(icon: "clock.fill", text: "Optional reminder before prayer time")
                }

                Divider()
                    .padding(.vertical, 4)

                Text("Customize each prayer independently to match your schedule and preferences.")
                    .font(.caption)
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func bulletPoint(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(themeManager.accentColor)
                .frame(width: 20)

            Text(text)
                .font(.caption2)
                .foregroundStyle(themeManager.secondaryTextColor)
        }
    }

    // MARK: - Helper Methods

    private func toggleExpansion(for prayer: PrayerName) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if expandedPrayers.contains(prayer) {
                expandedPrayers.remove(prayer)
            } else {
                expandedPrayers.insert(prayer)
            }
        }
        AudioHapticCoordinator.shared.playButtonPress()
    }
}

// MARK: - PrayerNotificationRow

struct PrayerNotificationRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var preferencesService = NotificationPreferencesService.shared

    let prayer: PrayerName
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    @State private var isNotificationEnabled: Bool = true
    @State private var isUrgentEnabled: Bool = true
    @State private var reminderMinutes: Int = 0

    var body: some View {
        LiquidGlassCardView {
            VStack(spacing: 0) {
                // Main Row
                Button {
                    onToggleExpand()
                } label: {
                    HStack(spacing: 12) {
                        // Prayer Icon
                        Image(systemName: prayer.icon)
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 32)

                        // Prayer Name and Status
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prayer.displayName)
                                .font(.headline)
                                .foregroundStyle(themeManager.primaryTextColor)

                            HStack(spacing: 6) {
                                if !isNotificationEnabled {
                                    Text("Disabled")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else {
                                    if reminderMinutes > 0 {
                                        Text("Reminder: \(reminderMinutes)m before")
                                            .font(.caption)
                                            .foregroundStyle(Color.orange)
                                    }
                                }
                            }
                        }

                        Spacer()

                        // Expand/Collapse Icon
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                // Expanded Settings
                if isExpanded {
                    Divider()

                    VStack(spacing: 16) {
                        // Main Notification Toggle
                        Toggle(isOn: $isNotificationEnabled) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(themeManager.accentColor)
                                Text("Prayer Time Notification")
                                    .font(.subheadline)
                            }
                        }
                        .tint(themeManager.accentColor)
                        .onChange(of: isNotificationEnabled) { _, newValue in
                            preferencesService.setNotificationEnabled(for: prayer, enabled: newValue)
                            AudioHapticCoordinator.shared.playButtonPress()
                        }

                        // Urgent Notification Toggle
                        Toggle(isOn: $isUrgentEnabled) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.orange)
                                Text("Urgent Notification (30m before)")
                                    .font(.subheadline)
                            }
                        }
                        .tint(Color.orange)
                        .disabled(!isNotificationEnabled)
                        .opacity(isNotificationEnabled ? 1.0 : 0.5)
                        .onChange(of: isUrgentEnabled) { _, newValue in
                            preferencesService.setUrgentNotificationEnabled(for: prayer, enabled: newValue)
                            AudioHapticCoordinator.shared.playButtonPress()
                        }

                        // Reminder Picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(themeManager.accentColor)
                                Text("Reminder Before Prayer")
                                    .font(.subheadline)
                            }

                            Picker("Reminder", selection: $reminderMinutes) {
                                Text("None").tag(0)
                                ForEach(NotificationPreferencesService.availableReminderTimes.filter { $0 > 0 }, id: \.self) { minutes in
                                    Text("\(minutes) minutes").tag(minutes)
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(!isNotificationEnabled)
                            .opacity(isNotificationEnabled ? 1.0 : 0.5)
                            .onChange(of: reminderMinutes) { _, newValue in
                                preferencesService.setReminderMinutes(for: prayer, minutes: newValue)
                                AudioHapticCoordinator.shared.playButtonPress()
                            }
                        }
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
        }
        .onAppear {
            // Initialize state from service
            isNotificationEnabled = preferencesService.isNotificationEnabled(for: prayer)
            isUrgentEnabled = preferencesService.isUrgentNotificationEnabled(for: prayer)
            reminderMinutes = preferencesService.getReminderMinutes(for: prayer)
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environment(ThemeManager())
}
