//
//  WelcomeMomentView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Post-onboarding welcome moment to guide first-time users
//

import SwiftUI

/// Welcome moment overlay shown after onboarding completion
struct WelcomeMomentView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Binding var selectedTab: Int
    let onDismiss: () -> Void

    @State private var animationPhase = 0

    var body: some View {
        ZStack {
            // Blur background
            themeManager.currentTheme.backgroundColor.opacity(0.98)
                .ignoresSafeArea()
                .overlay(
                    Color.black.opacity(0.3)
                )

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Animated crescent moon icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 72))
                    .foregroundColor(themeManager.currentTheme.featureAccent)
                    .scaleEffect(animationPhase == 0 ? 0.5 : 1.0)
                    .opacity(animationPhase == 0 ? 0 : 1)

                // Welcome message
                VStack(spacing: 12) {
                    Text("As Salamu Alaykum! 🌙")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .opacity(animationPhase < 1 ? 0 : 1)

                    Text("Your spiritual companion is ready")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(animationPhase < 2 ? 0 : 1)
                }
                .padding(.horizontal, 32)

                // Suggested actions card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let's start your journey:")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    // Action options
                    VStack(spacing: 16) {
                        suggestionRow(
                            icon: "book.pages",
                            iconColor: themeManager.currentTheme.featureAccent,
                            title: "Read Today's Verse",
                            subtitle: "Inspire yourself with a beautiful Quranic message",
                            isPrimary: true
                        ) {
                            // Stay on home tab, scroll to spiritual content
                            HapticManager.shared.trigger(.light)
                            onDismiss()
                        }

                        suggestionRow(
                            icon: "clock",
                            iconColor: AppColors.primary.green,
                            title: "View Prayer Times",
                            subtitle: "Never miss a prayer with accurate times",
                            isPrimary: false
                        ) {
                            HapticManager.shared.trigger(.light)
                            selectedTab = 2 // Navigate to Prayer tab
                            onDismiss()
                        }

                        suggestionRow(
                            icon: "text.book.closed",
                            iconColor: AppColors.primary.gold,
                            title: "Browse Quran",
                            subtitle: "Explore all 114 surahs",
                            isPrimary: false
                        ) {
                            HapticManager.shared.trigger(.light)
                            selectedTab = 1 // Navigate to Quran tab
                            onDismiss()
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.currentTheme.cardColor)
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                )
                .padding(.horizontal, 24)
                .opacity(animationPhase < 3 ? 0 : 1)

                Spacer()

                // Begin button
                Button(action: {
                    HapticManager.shared.trigger(.medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onDismiss()
                    }
                }) {
                    Text("Begin Journey")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.featureAccent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .opacity(animationPhase < 4 ? 0 : 1)

                // Skip button
                Button(action: {
                    HapticManager.shared.trigger(.light)
                    onDismiss()
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .padding(.bottom, 32)
                .opacity(animationPhase < 4 ? 0 : 1)
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Helper Views

    private func suggestionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                if isPrimary {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.primary.gold)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPrimary ? iconColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? iconColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Animation

    private func animateEntrance() {
        guard !reduceMotion else {
            // Skip to final state if reduced motion enabled
            animationPhase = 4
            return
        }

        // Staggered animation sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animationPhase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = 3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animationPhase = 4
            }
        }
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Welcome Moment") {
    @Previewable @State var selectedTab = 0

    WelcomeMomentView(selectedTab: $selectedTab) {
        print("Dismissed")
    }
    .environment(ThemeManager())
}

#Preview("Dark Mode") {
    @Previewable @State var selectedTab = 0

    WelcomeMomentView(selectedTab: $selectedTab) {
        print("Dismissed")
    }
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}
