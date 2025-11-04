//
//  QuickActionsGrid.swift
//  QuranNoor
//
//  Created by Claude Code
//  Quick action buttons for common features
//

import SwiftUI

struct QuickActionsGrid: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: Int
    let lastReadLocation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) { // Enhanced from 12
            // Section header
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            // Note: Horizontal padding removed - inherited from parent HomeView

            // Action grid
            LazyVGrid(columns: gridColumns, spacing: Spacing.gridSpacing) { // Enhanced from 12 to 16
                // Continue Reading
                QuickActionButton(
                    icon: "book.fill",
                    title: "Continue Reading",
                    subtitle: lastReadLocation ?? "Start reading",
                    gradient: [AppColors.primary.teal, AppColors.primary.green],
                    action: {
                        selectedTab = 1 // Quran tab
                    }
                )

                // Find Qibla
                QuickActionButton(
                    icon: "location.north.fill",
                    title: "Find Qibla",
                    subtitle: "Prayer direction",
                    gradient: [AppColors.primary.green, AppColors.primary.teal],
                    action: {
                        selectedTab = 3 // Qibla tab
                    }
                )

                // Prayer Times
                QuickActionButton(
                    icon: "clock.fill",
                    title: "Prayer Times",
                    subtitle: "View all prayers",
                    gradient: [AppColors.primary.gold, AppColors.primary.teal],
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
            // Note: Horizontal padding removed - inherited from parent HomeView
        }
    }

    // MARK: - Grid Configuration

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            action()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) { // Enhanced from 12 to 16
                // Icon with gradient - enhanced
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }), // Softer from 0.2
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56) // Enhanced from 48

                    Image(systemName: icon)
                        .font(.system(size: 24)) // Enhanced from title3
                        .foregroundColor(gradient.first ?? .white)
                }

                Spacer()

                // Text - better hierarchy
                VStack(alignment: .leading, spacing: 6) { // Enhanced from 4
                    Text(title)
                        .font(.system(size: 15, weight: .semibold)) // Enhanced from subheadline
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular)) // Enhanced from caption
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(Spacing.cardSpacing) // Enhanced from 16 to 20
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140) // Enhanced from 130 for more breathing room
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl) // Use standard radius
                    .fill(themeManager.currentTheme.cardColor)
                    .shadow(
                        color: Color.black.opacity(themeManager.currentTheme == .light ? 0.06 : 0.18), // Softer shadows
                        radius: 10, // Enhanced from 8
                        x: 0,
                        y: 5 // Enhanced from 4
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to navigate")
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
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("No Last Read") {
    @Previewable @State var selectedTab = 0

    QuickActionsGrid(
        selectedTab: $selectedTab,
        lastReadLocation: nil
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    @Previewable @State var selectedTab = 0

    QuickActionsGrid(
        selectedTab: $selectedTab,
        lastReadLocation: "Al-Kahf, Verse 10"
    )
    .environmentObject({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .background(Color(hex: "#1A2332"))
}
