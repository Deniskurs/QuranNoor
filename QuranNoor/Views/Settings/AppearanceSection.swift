//
//  AppearanceSection.swift
//  QuranNoor
//
//  Theme selection section for Settings
//

import SwiftUI

struct AppearanceSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Appearance", icon: "paintbrush.fill")

            CardView {
                VStack(spacing: 16) {
                    ForEach(ThemeMode.allCases) { mode in
                        Button {
                            // Haptic feedback for better UX
                            #if canImport(UIKit)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif

                            withAnimation {
                                themeManager.currentTheme = mode
                            }
                            toastMessage = "Theme: \(mode.rawValue)"
                            showToast = true
                        } label: {
                            HStack {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(mode.accent)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    ThemedText.body(mode.rawValue)
                                    ThemedText.caption(mode.description)
                                }

                                Spacer()

                                if themeManager.currentTheme == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.semanticSuccess)
                                        .font(.system(size: 24))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if mode != ThemeMode.allCases.last {
                            IslamicDivider(style: .simple)
                        }
                    }
                }
            }
        }
        .toast(message: toastMessage, style: .info, isPresented: $showToast)
    }
}
