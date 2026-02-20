//
//  FontSizePickerView.swift
//  QuranNoor
//
//  Font size picker for Quran reader customization
//

import SwiftUI

struct FontSizePickerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var settings = QuranSettingsService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Font size options
                    ForEach(QuranFontSize.allCases) { fontSize in
                        FontSizeRow(
                            fontSize: fontSize,
                            isSelected: settings.fontSize == fontSize
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.setFontSize(fontSize)
                            }
                        }
                    }
                } header: {
                    Text("Font Size")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                } footer: {
                    Text("Choose your preferred Quran text size for comfortable reading.")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Section {
                    // Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        // Arabic preview
                        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                            .font(AppTypography.arabicScalable(size: settings.fontSize.arabicSize))
                            .lineSpacing(settings.fontSize.lineSpacing)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()

                        // Translation preview
                        Text("In the name of Allah, the Most Gracious, the Most Merciful")
                            .font(.system(size: settings.fontSize.translationSize))
                            .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Section {
                    // Display options
                    Toggle("Show Translation", isOn: Binding(
                        get: { settings.showTranslation },
                        set: { _ in settings.toggleTranslation() }
                    ))

                    Toggle("Show Transliteration", isOn: Binding(
                        get: { settings.showTransliteration },
                        set: { _ in settings.toggleTransliteration() }
                    ))
                } header: {
                    Text("Display Options")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Section {
                    Button {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Reading Preferences")
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

// MARK: - Font Size Row
struct FontSizeRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let fontSize: QuranFontSize
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary.opacity(0.3))
                .frame(width: 24, height: 24)

            // Font size info
            VStack(alignment: .leading, spacing: 4) {
                Text(fontSize.displayName)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Text("Arabic: \(Int(fontSize.arabicSize))pt | Translation: \(Int(fontSize.translationSize))pt")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Preview icon size
            Text("أ")
                .font(AppTypography.arabicScalable(size: fontSize.arabicSize * 0.7))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview("Font Size Picker") {
    struct PreviewWrapper: View {
        @State private var themeManager = ThemeManager()

        var body: some View {
            FontSizePickerView()
                .environment(themeManager)
        }
    }

    return PreviewWrapper()
}
