//
//  TasbihSettingsView.swift
//  QuranNoor
//
//  Settings view for tasbih counter
//

import SwiftUI

struct TasbihSettingsView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var tasbihService = TasbihService.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Haptic Feedback Section
                Section {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { tasbihService.hapticEnabled },
                        set: { tasbihService.updateSettings(haptic: $0) }
                    ))

                    Toggle("Vibrate on Target", isOn: Binding(
                        get: { tasbihService.vibrateOnTarget },
                        set: { tasbihService.updateSettings(vibrate: $0) }
                    ))
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("Haptic feedback provides tactile response while counting. Vibrate on target creates a special pattern when reaching your goal.")
                }

                // Display Options Section
                Section {
                    Toggle("Show Arabic Text", isOn: Binding(
                        get: { tasbihService.showArabic },
                        set: { tasbihService.updateSettings(arabic: $0) }
                    ))

                    Toggle("Show Transliteration", isOn: Binding(
                        get: { tasbihService.showTransliteration },
                        set: { tasbihService.updateSettings(transliteration: $0) }
                    ))

                    Toggle("Show Translation", isOn: Binding(
                        get: { tasbihService.showTranslation },
                        set: { tasbihService.updateSettings(translation: $0) }
                    ))
                } header: {
                    Text("Display")
                } footer: {
                    Text("Customize what text is shown while counting.")
                }

                // Statistics Section
                Section {
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(tasbihService.statistics.totalSessions)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Count")
                        Spacer()
                        Text("\(tasbihService.statistics.totalCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Completed Sessions")
                        Spacer()
                        Text("\(tasbihService.statistics.completedSessions)")
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("Completion Rate")
                        Spacer()
                        Text(String(format: "%.1f%%", tasbihService.statistics.completionRate))
                            .foregroundStyle(themeManager.currentTheme.accent)
                    }

                    HStack {
                        Text("Current Streak")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(tasbihService.statistics.currentStreak)")
                                .foregroundStyle(.orange)
                        }
                    }

                    HStack {
                        Text("Longest Streak")
                        Spacer()
                        Text("\(tasbihService.statistics.longestStreak)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Statistics")
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        resetStatistics()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Statistics")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all your tasbih statistics. This action cannot be undone.")
                }
            }
            .navigationTitle("Tasbih Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func resetStatistics() {
        tasbihService.resetStatistics()

        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}

#Preview {
    TasbihSettingsView()
}
