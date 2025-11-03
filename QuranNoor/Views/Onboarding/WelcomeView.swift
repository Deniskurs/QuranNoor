//
//  WelcomeView.swift
//  QuranNoor
//
//  Welcome screen for onboarding
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    let coordinator: OnboardingCoordinator

    // MARK: - Body
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.green, AppColors.primary.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: AppColors.primary.green.opacity(0.3), radius: 20)

                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            // Welcome text
            VStack(spacing: 16) {
                ThemedText.title("Qur'an Noor", italic: false)
                    .foregroundColor(AppColors.primary.green)

                ThemedText("Light of the Quran", style: .heading)
                    .foregroundColor(AppColors.primary.gold)

                ThemedText.body("Your comprehensive Islamic companion for spiritual growth, prayer times, Quran reading, and more")
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Features highlights
            VStack(spacing: 20) {
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
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppColors.primary.teal)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                ThemedText(title, style: .body)
                    .fontWeight(.semibold)

                ThemedText.caption(description)
                    .opacity(0.7)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(coordinator: OnboardingCoordinator())
        .environmentObject(ThemeManager())
}
