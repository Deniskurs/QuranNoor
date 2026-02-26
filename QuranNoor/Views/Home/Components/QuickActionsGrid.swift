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

    @State private var showQibla = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Section header matching SpiritualNourishmentCarousel pattern
            HStack(spacing: Spacing.xs) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.linearGradient(
                        colors: [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("Quick Actions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }

            // Grid of individual action cards
            LazyVGrid(columns: gridColumns, spacing: Spacing.gridSpacing) {
                // Continue Reading — primary action, teal/green gradient, prominent card
                QuickActionButton(
                    icon: "book.fill",
                    title: "Continue Reading",
                    subtitle: lastReadLocation ?? "Start reading",
                    gradient: [themeManager.currentTheme.accent, Color(hex: "#14FFEC")],
                    isProminent: true,
                    action: {
                        selectedTab = 1 // Quran tab
                    }
                )

                // Find Qibla — gold gradient, opens as sheet
                QuickActionButton(
                    icon: "location.north.fill",
                    title: "Find Qibla",
                    subtitle: "Prayer direction",
                    gradient: [Color(hex: "#C7A566"), Color(hex: "#D4A847")],
                    action: {
                        showQibla = true
                    }
                )

                // Prayer Times — emerald gradient
                QuickActionButton(
                    icon: "clock.fill",
                    title: "Prayer Times",
                    subtitle: "View all prayers",
                    gradient: [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
                    action: {
                        selectedTab = 2 // Prayer tab
                    }
                )

                // More — muted secondary gradient
                QuickActionButton(
                    icon: "ellipsis.circle.fill",
                    title: "More",
                    subtitle: "Adhkar & tools",
                    gradient: [themeManager.currentTheme.textSecondary, themeManager.currentTheme.accentMuted],
                    action: {
                        selectedTab = 3 // More tab
                    }
                )
            }
        }
        .sheet(isPresented: $showQibla) {
            NavigationStack {
                QiblaCompassView()
                    .navigationTitle("Qibla Direction")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showQibla = false }
                        }
                    }
            }
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
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            action()
        }) {
            CardView(intensity: isProminent ? .prominent : .moderate) {
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
                            .font(.title3)
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
