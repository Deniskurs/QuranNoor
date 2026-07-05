//
//  LanguageSection.swift
//  QuranNoor
//
//  App language selection section for Settings
//

import SwiftUI

struct LanguageSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(LocalizationManager.self) var localizationManager: LocalizationManager

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Language", icon: "globe")

            CardView {
                VStack(spacing: 16) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            // Haptic feedback for better UX
                            #if canImport(UIKit)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif

                            withAnimation {
                                localizationManager.setLanguage(language)
                            }
                            toastMessage = "Language: \(language.displayName)"
                            showToast = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    ThemedText.body(language.nativeName)
                                    ThemedText.caption(language.displayName)
                                }

                                Spacer()

                                if localizationManager.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.semanticSuccess)
                                        .font(.system(size: 24))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        IslamicDivider(style: .simple)
                    }

                    // Honest disclosure: switching language flips layout direction,
                    // but most screens are not translated yet.
                    ThemedText.caption("Translation is in progress — most screens currently remain in English.")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .toast(message: toastMessage, style: .info, isPresented: $showToast)
    }
}
