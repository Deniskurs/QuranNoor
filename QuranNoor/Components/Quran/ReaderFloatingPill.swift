//
//  ReaderFloatingPill.swift
//  QuranNoor
//
//  Floating toggle bar for the Quran reader — controls translation,
//  transliteration, and word-by-word visibility.
//

import SwiftUI

struct ReaderFloatingPill: View {
    let showTranslation: Bool
    let showTransliteration: Bool
    let showWordByWord: Bool
    let onToggleTranslation: () -> Void
    let onToggleTransliteration: () -> Void
    let onToggleWordByWord: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        let theme = themeManager.currentTheme

        HStack(spacing: 0) {
            // Translation toggle
            pillButton(
                icon: "textformat.abc",
                label: "Translation",
                isActive: showTranslation,
                theme: theme,
                action: onToggleTranslation
            )

            pillDivider(theme: theme)

            // Transliteration toggle
            pillButton(
                icon: "character.textbox",
                label: "Transliteration",
                isActive: showTransliteration,
                theme: theme,
                action: onToggleTransliteration
            )

            pillDivider(theme: theme)

            // Word-by-word toggle
            pillButton(
                icon: "text.word.spacing",
                label: "Words",
                isActive: showWordByWord,
                theme: theme,
                action: onToggleWordByWord
            )
        }
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(theme.borderColor.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func pillButton(
        icon: String,
        label: String,
        isActive: Bool,
        theme: ThemeMode,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.shared.trigger(.light)
            withAnimation(AppAnimation.fast) {
                action()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .symbolEffect(.bounce, value: reduceMotion ? false : isActive)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isActive ? theme.accent : theme.textTertiary)
            .padding(.horizontal, 14)
            .frame(minHeight: Spacing.tapTarget)
        }
        .accessibilityLabel("\(label) \(isActive ? "on" : "off")")
    }

    private func pillDivider(theme: ThemeMode) -> some View {
        Rectangle()
            .fill(theme.borderColor.opacity(0.3))
            .frame(width: 0.5, height: 24)
    }
}
