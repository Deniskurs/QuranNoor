//
//  PrayerSettingsSection.swift
//  QuranNoor
//
//  Prayer calculation method, madhab, adhan, and adjustment settings
//

import SwiftUI

struct PrayerSettingsSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    var prayerVM: PrayerViewModel
    @Binding var showMethodSheet: Bool
    @Binding var showMadhabSheet: Bool
    @Binding var showPrayerCalcInfo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Prayer Settings", icon: "clock.fill")

            CardView {
                VStack(spacing: 12) {
                    // Calculation Method row
                    Button {
                        showMethodSheet = true
                    } label: {
                        SettingsRow(
                            icon: "function",
                            title: "Calculation Method",
                            value: prayerVM.selectedCalculationMethod.rawValue,
                            color: themeManager.currentTheme.accent
                        )
                    }

                    // Subtitle for Calculation Method
                    ThemedText.caption("Determines Fajr/Isha angles and other parameters used to compute daily prayer times.")
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Madhab row
                    Button {
                        showMadhabSheet = true
                    } label: {
                        SettingsRow(
                            icon: "globe",
                            title: "Madhab",
                            value: prayerVM.selectedMadhab.rawValue,
                            color: themeManager.currentTheme.accent
                        )
                    }

                    // Subtitle for Madhab
                    ThemedText.caption("Affects Asr time: Shafi/Standard uses shadow length = 1x; Hanafi uses 2x.")
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Adhan Settings row
                    NavigationLink {
                        AdhanSettingsView()
                            .environment(themeManager)
                    } label: {
                        SettingsRow(
                            icon: "speaker.wave.3.fill",
                            title: "Adhan Audio",
                            value: AdhanAudioService.shared.isEnabled ? "Enabled" : "Disabled",
                            color: themeManager.currentTheme.accentMuted
                        )
                    }

                    // Subtitle for Adhan
                    ThemedText.caption("Configure beautiful call to prayer audio at prayer times.")
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Prayer Time Adjustments row
                    NavigationLink {
                        PrayerTimeAdjustmentView()
                            .environment(themeManager)
                    } label: {
                        SettingsRow(
                            icon: "clock.badge.checkmark",
                            title: "Adjust Prayer Times",
                            value: PrayerTimeAdjustmentService.shared.hasAdjustments
                                ? "\(PrayerTimeAdjustmentService.shared.adjustedPrayerCount) custom"
                                : "Not adjusted",
                            color: themeManager.currentTheme.textPrimary
                        )
                    }

                    // Subtitle for Adjustments
                    ThemedText.caption("Manually adjust times to sync with your local mosque schedule.")
                        .padding(.leading, 44)

                    // Learn more link
                    HStack {
                        Spacer()
                        TertiaryButton("Learn more", icon: "book") {
                            showPrayerCalcInfo = true
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
