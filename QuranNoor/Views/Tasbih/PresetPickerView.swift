//
//  PresetPickerView.swift
//  QuranNoor
//
//  Preset selector for tasbih counter
//

import SwiftUI

struct PresetPickerView: View {
    @Binding var selectedPreset: TasbihPreset
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TasbihPreset.allCases.filter { $0 != .custom }) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        )
                        .onTapGesture {
                            selectedPreset = preset
                            onSelect()
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Dhikr")
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
}

struct PresetCard: View {
    @Environment(ThemeManager.self) var themeManager
    let preset: TasbihPreset
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(colorForPreset.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: preset.icon)
                        .foregroundStyle(colorForPreset)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.displayName)
                        .font(.headline)

                    Text(preset.transliteration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }

            Divider()

            // Arabic Text
            Text(preset.arabicText)
                .font(.title2)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Translation
            Text(preset.translation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Default target
            HStack {
                Text("Default target:")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("\(preset.defaultTarget)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? .green : .clear, lineWidth: 2)
        )
    }

    private var colorForPreset: Color {
        themeManager.currentTheme.categoryColor(for: preset.color)
    }
}

#Preview {
    PresetPickerView(selectedPreset: .constant(.subhanAllah)) {
        print("Selected")
    }
}
