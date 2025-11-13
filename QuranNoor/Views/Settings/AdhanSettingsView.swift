//
//  AdhanSettingsView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Settings view for selecting and configuring Adhan audio
//

import SwiftUI

struct AdhanSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var adhanService = AdhanAudioService.shared
    @State private var volume: Float
    @State private var isEnabled: Bool
    @State private var isPreviewingAdhan: AdhanAudio? = nil

    init() {
        let service = AdhanAudioService.shared
        _volume = State(initialValue: service.volume)
        _isEnabled = State(initialValue: service.isEnabled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Enable/Disable Toggle
                    enableToggleCard

                    // Volume Control
                    if isEnabled {
                        volumeControlCard
                    }

                    // Adhan Selection
                    if isEnabled {
                        adhanSelectionSection
                    }

                    // Information Card
                    infoCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Adhan Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var enableToggleCard: some View {
        LiquidGlassCardView {
            Toggle(isOn: $isEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Enable Adhan", systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text("Play beautiful call to prayer at prayer times")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .tint(themeManager.accentColor)
            .padding(16)
            .onChange(of: isEnabled) { _, newValue in
                adhanService.setEnabled(newValue)
                AudioHapticCoordinator.shared.playButtonPress()
            }
        }
    }

    private var volumeControlCard: some View {
        LiquidGlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Volume", systemImage: "speaker.wave.2.fill")
                        .font(.headline)
                        .foregroundStyle(themeManager.primaryTextColor)

                    Spacer()

                    Text("\(Int(volume * 100))%")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.secondaryTextColor)
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)

                    Slider(value: $volume, in: 0...1, step: 0.1)
                        .tint(themeManager.accentColor)
                        .onChange(of: volume) { _, newValue in
                            adhanService.setVolume(newValue)
                        }

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .padding(16)
        }
    }

    private var adhanSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Adhan Audio")
                .font(.headline)
                .foregroundStyle(themeManager.primaryTextColor)
                .padding(.horizontal, 4)

            ForEach(AdhanAudio.allCases) { adhan in
                AdhanOptionRow(
                    adhan: adhan,
                    isSelected: adhanService.selectedAdhan == adhan,
                    isPlaying: adhanService.isPlaying && isPreviewingAdhan == adhan,
                    onSelect: {
                        selectAdhan(adhan)
                    },
                    onPreview: {
                        previewAdhan(adhan)
                    },
                    onStopPreview: {
                        stopPreview()
                    }
                )
            }
        }
    }

    private var infoCard: some View {
        LiquidGlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("About Adhan", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.accentColor)

                Text("The Adhan will play at each prayer time if notifications are enabled. You can stop it at any time by opening the app.")
                    .font(.caption)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    infoRow(icon: "checkmark.circle.fill", text: "Works even when app is closed")
                    infoRow(icon: "speaker.fill", text: "Respects silent mode and volume settings")
                    infoRow(icon: "play.circle.fill", text: "Tap to preview before selecting")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
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

    private func selectAdhan(_ adhan: AdhanAudio) {
        AudioHapticCoordinator.shared.playButtonPress()
        adhanService.selectAdhan(adhan)
    }

    private func previewAdhan(_ adhan: AdhanAudio) {
        isPreviewingAdhan = adhan
        Task {
            await adhanService.previewAdhan(adhan)
        }
    }

    private func stopPreview() {
        adhanService.stopAdhan()
        isPreviewingAdhan = nil
    }
}

// MARK: - AdhanOptionRow

struct AdhanOptionRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let adhan: AdhanAudio
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    let onStopPreview: () -> Void

    var body: some View {
        LiquidGlassCardView {
            VStack(spacing: 0) {
                // Main content
                Button {
                    onSelect()
                } label: {
                    HStack(spacing: 12) {
                        // Selection indicator
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)

                        // Adhan info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(adhan.displayName)
                                .font(.headline)
                                .foregroundStyle(themeManager.primaryTextColor)

                            Text(adhan.description)
                                .font(.caption)
                                .foregroundStyle(themeManager.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(16)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Preview button
                Button {
                    if isPlaying {
                        onStopPreview()
                    } else {
                        onPreview()
                    }
                } label: {
                    HStack {
                        Spacer()

                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title3)

                        Text(isPlaying ? "Stop Preview" : "Preview")
                            .font(.subheadline.weight(.medium))

                        Spacer()
                    }
                    .foregroundStyle(themeManager.accentColor)
                    .padding(.vertical, 12)
                }
            }
        }
    }
}

#Preview {
    AdhanSettingsView()
        .environment(ThemeManager())
}
