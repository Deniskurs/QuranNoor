//
//  MadhabPickerView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Extracted from PrayerTimesView for better maintainability
//

import SwiftUI

/// Sheet view for selecting madhab (affects Asr calculation)
struct MadhabPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @Binding var selectedMadhab: Madhab
    let onMadhabChanged: (Madhab) async -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Informational note
                        infoCard

                        // Madhab options
                        ForEach(Madhab.allCases) { madhab in
                            Button {
                                Task {
                                    await onMadhabChanged(madhab)
                                    dismiss()
                                    AudioHapticCoordinator.shared.playButtonPress()
                                }
                            } label: {
                                madhabRow(madhab)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Madhab")
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

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(themeManager.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("About Madhab Options")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)

                Text("Only Asr calculation time is affected. Standard covers Shafi, Maliki, and Hanbali schools (shadow = object). Hanafi uses different calculation (shadow = 2× object).")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.accentColor.opacity(0.15))
        )
    }

    private func madhabRow(_ madhab: Madhab) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(madhab.rawValue)
                        .font(.body)
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text(madhab.technicalNote)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(themeManager.accentColor)
                }

                Spacer()

                if madhab == selectedMadhab {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(themeManager.accentColor)
                }
            }

            // Explanation
            Text(madhab.explanation)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(themeManager.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    madhab == selectedMadhab
                        ? themeManager.accentColor.opacity(0.15)
                        : themeManager.cardBackground
                )
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedMadhab = Madhab.shafi

    MadhabPickerView(
        selectedMadhab: $selectedMadhab,
        onMadhabChanged: { newMadhab in
            print("Madhab changed to: \(newMadhab)")
        }
    )
    .environment(ThemeManager())
}
