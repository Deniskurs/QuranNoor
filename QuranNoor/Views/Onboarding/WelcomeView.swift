//
//  WelcomeView.swift
//  QuranNoor
//
//  Welcome screen for onboarding
//  Design: Sacred restraint — bismillah as visual centerpiece,
//  warm typography, Islamic geometric divider, no flashy gradients.
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let coordinator: OnboardingCoordinator

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 0) {
            Spacer()

            // MARK: - Bismillah (Visual Centerpiece)
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 28))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            // MARK: - App Identity
            VStack(spacing: Spacing.xxs) {
                ThemedText.title("Qur'an Noor", italic: false)
                    .foregroundColor(theme.accent)

                Text("Light of the Qur'an")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.top, Spacing.md)

            // MARK: - Islamic Geometric Divider
            IslamicDivider(style: .ornamental, color: theme.accent)
                .padding(.vertical, Spacing.lg)
                .padding(.horizontal, Spacing.xl)

            // MARK: - Feature Highlights
            VStack(spacing: Spacing.md) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "Accurate Prayer Times",
                    description: "Never miss a prayer with precise timings"
                )

                FeatureRow(
                    icon: "book.fill",
                    title: "Complete Quran",
                    description: "Read with translations and audio recitations"
                )

                FeatureRow(
                    icon: "location.north.fill",
                    title: "Qibla Direction",
                    description: "Find the direction to Mecca anywhere"
                )
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()
            Spacer()
        }
        .padding(.vertical, Spacing.screenVertical)
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme

        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(theme.accent)
                .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(coordinator: OnboardingCoordinator())
        .environment(ThemeManager())
}
