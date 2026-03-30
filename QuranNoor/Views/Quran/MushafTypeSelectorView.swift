//
//  MushafTypeSelectorView.swift
//  QuranNoor
//
//  Sheet for selecting the Arabic script (mushaf) type for Quran reading.
//

import SwiftUI

struct MushafTypeSelectorView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var settings = QuranSettingsService.shared

    let onSelect: (MushafType) -> Void

    var body: some View {
        let theme = themeManager.currentTheme

        NavigationStack {
            List {
                Section {
                    ForEach(MushafType.allCases) { mushafType in
                        MushafTypeRow(
                            mushafType: mushafType,
                            isSelected: settings.mushafType == mushafType,
                            theme: theme
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.setMushafType(mushafType)
                            onSelect(mushafType)
                            HapticManager.shared.trigger(.selection)
                            dismiss()
                        }
                    }
                } header: {
                    Text("Arabic Script")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                } footer: {
                    Text("Choose the Arabic script style for Quran text. Different scripts are used in different regions.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                            .font(AppTypography.arabicFont(for: settings.mushafType, size: settings.fontSize.arabicSize))
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(settings.fontSize.lineSpacing)
                            .environment(\.layoutDirection, .rightToLeft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .navigationTitle("Script Type")
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

// MARK: - Mushaf Type Row

private struct MushafTypeRow: View {
    let mushafType: MushafType
    let isSelected: Bool
    let theme: ThemeMode

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? theme.accent : theme.textSecondary.opacity(0.3))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(mushafType.displayName)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(theme.textPrimary)

                    if mushafType.isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(theme.accent)
                            )
                    }
                }

                Text(mushafType.region)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.accent.opacity(0.8))

                Text(mushafType.description)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}
