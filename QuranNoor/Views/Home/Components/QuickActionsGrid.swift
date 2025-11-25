//
//
//  QuickActionsGrid.swift
//  QuranNoor
//
//  Created by Claude Code
//  Quick action buttons for common features
//

import SwiftUI

struct QuickActionsGrid: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var selectedTab: Int
    let lastReadLocation: String?

    var body: some View {
        // Grid of individual action cards
        LazyVGrid(columns: gridColumns, spacing: Spacing.gridSpacing) {
            // Continue Reading
            QuickActionButton(
                icon: "book.fill",
                title: "Continue Reading",
                subtitle: lastReadLocation ?? "Start reading",
                gradient: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                action: {
                    selectedTab = 1 // Quran tab
                }
            )

            // Find Qibla
            QuickActionButton(
                icon: "location.north.fill",
                title: "Find Qibla",
                subtitle: "Prayer direction",
                gradient: [themeManager.currentTheme.featureAccentSecondary, themeManager.currentTheme.featureAccent],
                action: {
                    selectedTab = 3 // Qibla tab
                }
            )

            // Prayer Times
            QuickActionButton(
                icon: "clock.fill",
                title: "Prayer Times",
                subtitle: "View all prayers",
                gradient: [AppColors.primary.gold, themeManager.currentTheme.featureAccent],
                action: {
                    selectedTab = 2 // Prayer tab
                }
            )

            // Settings
            QuickActionButton(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Customize app",
                gradient: [AppColors.primary.midnight, AppColors.primary.green],
                action: {
                    selectedTab = 4 // Settings tab
                }
            )
        }
    }

    // MARK: - Grid Configuration

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.gridSpacing),
            GridItem(.flexible(), spacing: Spacing.gridSpacing)
        ]
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            action()
        }) {
            LiquidGlassCardView(intensity: .moderate) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(gradient.first ?? .white)
                    }

                    Spacer()

                    // Text with semantic fonts for accessibility
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold)) // Semantic font for Dynamic Type
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .lineLimit(2)

                        Text(subtitle)
                            .font(.caption) // Semantic font for Dynamic Type
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(ScaleButtonStyle()) // Uses shared ScaleButtonStyle from WelcomeMomentView
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Quick Actions") {
    @Previewable @State var selectedTab = 0

    QuickActionsGrid(
        selectedTab: $selectedTab,
        lastReadLocation: "Al-Baqarah, Verse 255"
    )
    .environment(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("No Last Read") {
    @Previewable @State var selectedTab = 0

    QuickActionsGrid(
        selectedTab: $selectedTab,
        lastReadLocation: nil
    )
    .environment(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    @Previewable @State var selectedTab = 0

    QuickActionsGrid(
        selectedTab: $selectedTab,
        lastReadLocation: "Al-Kahf, Verse 10"
    )
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .background(Color(hex: "#1A2332"))
}
