//
//  TranslationSelectorView.swift
//  QuranNoor
//
//  Translation selector with multiple edition support
//

import SwiftUI

struct TranslationSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var preferences: TranslationPreferences
    private let onSelect: (TranslationEdition) -> Void

    init(
        currentPreferences: TranslationPreferences,
        onSelect: @escaping (TranslationEdition) -> Void
    ) {
        self._preferences = State(initialValue: currentPreferences)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TranslationEdition.allCases) { edition in
                        TranslationRow(
                            edition: edition,
                            isSelected: preferences.primaryTranslation == edition,
                            isRecommended: edition.recommendedForBeginners
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                preferences.primaryTranslation = edition
                                QuranService.shared.setPrimaryTranslation(edition)
                                onSelect(edition)

                                // Auto-dismiss after short delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Translation")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                } footer: {
                    Text("Choose your preferred English translation of the Quran. You can change this anytime in settings.")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .navigationTitle("Translations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Translation Row
struct TranslationRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let edition: TranslationEdition
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary.opacity(0.3))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(edition.displayName)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)

                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.accent)
                            )
                    }

                    Spacer()

                    Text("\(edition.year)")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Text(edition.description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("by \(edition.author)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Translation Picker
struct CompactTranslationPicker: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var selectedTranslation: TranslationEdition
    @State private var showingSelector = false

    var body: some View {
        Button {
            showingSelector = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 14))
                Text(selectedTranslation.displayName)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(themeManager.currentTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(themeManager.currentTheme.accent.opacity(0.1))
            )
        }
        .sheet(isPresented: $showingSelector) {
            TranslationSelectorView(
                currentPreferences: QuranService.shared.getTranslationPreferences()
            ) { edition in
                selectedTranslation = edition
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Preview
#Preview("Translation Selector") {
    TranslationSelectorView(
        currentPreferences: TranslationPreferences()
    ) { edition in
        #if DEBUG
        print("Selected: \(edition.displayName)")
        #endif
    }
}

#Preview("Compact Picker") {
    struct PreviewWrapper: View {
        @State private var selected: TranslationEdition = .sahihInternational

        var body: some View {
            VStack {
                CompactTranslationPicker(selectedTranslation: $selected)
                Text("Selected: \(selected.displayName)")
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}
