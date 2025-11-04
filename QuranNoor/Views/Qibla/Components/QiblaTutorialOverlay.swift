//
//  QiblaTutorialOverlay.swift
//  QuranNoor
//
//  First-time tutorial overlay explaining how to use the Qibla compass
//

import SwiftUI

struct QiblaTutorialOverlay: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    @EnvironmentObject private var themeManager: ThemeManager

    // MARK: - Body
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissTutorial()
                }

            // Tutorial card
            VStack(spacing: Spacing.lg) {
                // Title with icon
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "safari")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.primary.teal)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: AppColors.primary.teal.opacity(0.3), radius: 8, x: 0, y: 2)

                    Text("How to Find Qibla")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                }
                .padding(.top, Spacing.lg)

                // Instructions
                VStack(spacing: Spacing.md) {
                    instructionRow(
                        icon: "iphone",
                        title: "Hold Phone Flat",
                        description: "Keep your device parallel to the ground for accuracy"
                    )

                    instructionRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Rotate Device",
                        description: "Turn slowly until the golden arrow points to Qibla"
                    )

                    instructionRow(
                        icon: "hand.wave.fill",
                        title: "Feel the Feedback",
                        description: "Your phone will vibrate when aligned with Qibla"
                    )
                }
                .padding(.horizontal, Spacing.md)

                // Buttons
                VStack(spacing: Spacing.sm) {
                    Button {
                        dismissTutorial()
                    } label: {
                        Text("Got it!")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: BorderRadius.lg)
                                    .fill(AppColors.primary.teal)
                            )
                    }

                    Button {
                        dismissTutorial(dontShowAgain: true)
                    } label: {
                        Text("Don't show again")
                            .font(.callout)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .frame(maxWidth: 350)
            .background(
                ZStack {
                    // Frosted glass blur
                    RoundedRectangle(cornerRadius: BorderRadius.xxl)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent color overlay
                    RoundedRectangle(cornerRadius: BorderRadius.xxl)
                        .fill(themeManager.currentTheme.cardColor.opacity(0.9))

                    // Subtle border
                    RoundedRectangle(cornerRadius: BorderRadius.xxl)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 10)
            )
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.8)),
            removal: .opacity
        ))
    }

    // MARK: - Components

    /// Individual instruction row with icon, title, and description
    private func instructionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary.gold)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 40)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Methods

    /// Dismiss tutorial with optional "don't show again" setting
    private func dismissTutorial(dontShowAgain: Bool = false) {
        if dontShowAgain {
            UserDefaults.standard.set(true, forKey: "hasSeenQiblaTutorial")
        }

        HapticManager.shared.trigger(.light)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        QiblaTutorialOverlay(isPresented: .constant(true))
            .environmentObject(ThemeManager())
    }
}
