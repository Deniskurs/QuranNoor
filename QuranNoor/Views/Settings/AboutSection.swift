//
//  AboutSection.swift
//  QuranNoor
//
//  App version, developer info, and rate app section
//

import SwiftUI
import StoreKit

struct AboutSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var showVersionInfo: Bool
    @Binding var showDeveloperInfo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "About", icon: "info.circle.fill")

            CardView {
                VStack(spacing: 16) {
                    Button { showVersionInfo = true } label: {
                        SettingsRow(
                            icon: "app.badge.fill",
                            title: "Version",
                            value: getAppVersion(),
                            color: themeManager.currentTheme.accent
                        )
                    }

                    IslamicDivider(style: .simple)

                    Button { showDeveloperInfo = true } label: {
                        SettingsRow(
                            icon: "person.2.fill",
                            title: "Developer",
                            value: "Qur'an Noor Team",
                            color: themeManager.currentTheme.accentMuted
                        )
                    }

                    IslamicDivider(style: .simple)

                    Button {
                        openPrivacyPolicy()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accent)
                                .frame(width: 32)

                            ThemedText.body("Privacy Policy")

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }
                    }

                    IslamicDivider(style: .simple)

                    Button {
                        rateApp()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accent)
                                .frame(width: 32)

                            ThemedText.body("Rate This App")

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://qurannoor.app/privacy") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    private func rateApp() {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
        #endif
    }
}
