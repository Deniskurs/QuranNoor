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
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)

            // Action grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
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
            .padding(.horizontal, 20)
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
            VStack(alignment: .leading, spacing: 12) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.2) }),
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

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.cardColor)
                    .shadow(
                        color: Color.black.opacity(themeManager.currentTheme == .light ? 0.08 : 0.2),
                        radius: 8,
                        x: 0,
                        y: 4
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
