//
//  FirstTimeUserView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Welcome view for first-time users
//

import SwiftUI

struct FirstTimeUserView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var selectedTab: Int
    var onDismiss: () -> Void

    var body: some View {
        LiquidGlassCardView(showPattern: true, intensity: .prominent) {
            VStack(spacing: 24) {
                // Welcome icon
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary.gold)
                    .symbolEffect(.bounce)

                // Welcome message
                VStack(spacing: 12) {
                    Text("Welcome to Qur'an Noor")
                        .font(.title2.bold())
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Your spiritual companion for prayer times, Quran reading, and Islamic guidance")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Quick start actions
                VStack(spacing: 12) {
                    PrimaryButton(
                        "Start Reading Quran",
                        icon: "book.fill",
                        action: {
                            onDismiss()
                            selectedTab = 1 // Navigate to Quran tab
                        }
                    )
                    .frame(height: 50)

                    SecondaryButton(
                        "View Prayer Times",
                        icon: "clock.fill",
                        action: {
                            onDismiss()
                            selectedTab = 2 // Navigate to Prayer tab
                        }
                    )
                    .frame(height: 50)
                }
                .padding(.top, 8)
            }
            .padding(32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to Qur'an Noor. Your spiritual companion. Start reading Quran or view prayer times.")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedTab = 0

    FirstTimeUserView(
        selectedTab: $selectedTab,
        onDismiss: { print("Dismissed") }
    )
    .environment(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}
