//
//  DailyStatsRow.swift
//  QuranNoor
//
//  Created by Claude Code
//  Horizontal row displaying daily statistics
//

import SwiftUI

struct DailyStatsRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let stats: DailyStats

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: Spacing.gridSpacing) { // Enhanced from 12 to 16
            // Streak stat
            HomeStatCard(
                icon: "flame.fill",
                iconColor: stats.hasStreak ? .orange : themeManager.currentTheme.textTertiary,
                value: "\(stats.streakDays)",
                label: "Day Streak",
                showAnimation: stats.hasStreak
            )

            // Verses read stat
            HomeStatCard(
                icon: "book.fill",
                iconColor: AppColors.primary.teal,
                value: "\(stats.versesReadToday)",
                label: "Verses Today",
                showAnimation: stats.hasReadToday
            )

            // Prayers completed stat
            HomeStatCard(
                icon: "checkmark.circle.fill",
                iconColor: stats.hasCompletedAllPrayers ? AppColors.primary.green : themeManager.currentTheme.textTertiary,
                value: stats.prayersCompletedText,
                label: "Prayers",
                showAnimation: stats.hasCompletedAllPrayers
            )

            // Juz progress stat
            HomeStatCard(
                icon: "chart.bar.fill",
                iconColor: AppColors.primary.gold,
                value: "\(Int(stats.juzProgress * 100))%",
                label: "Juz \(stats.currentJuz)",
                showAnimation: stats.juzProgress > 0
            )
        }
    }

    // MARK: - Grid Configuration

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.gridSpacing), // Enhanced from 12 to 16
            GridItem(.flexible(), spacing: Spacing.gridSpacing)
        ]
    }
}

// MARK: - Home Stat Card Component

struct HomeStatCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    var showAnimation: Bool = false

    @State private var scale: CGFloat = 1.0

    var body: some View {
        CardView(showPattern: false) {
            VStack(spacing: Spacing.sm) { // Enhanced from 12 to 16
                // Icon - keep size, add subtle enhancement
                Image(systemName: icon)
                    .font(.system(size: 36)) // Enhanced from 32 for better visual weight
                    .foregroundColor(iconColor)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: scale)

                // Value - PROMINENT enhancement
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded)) // Enhanced from 24
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .contentTransition(.numericText())

                // Label - refined sizing
                Text(label)
                    .font(.system(size: 11, weight: .medium)) // Enhanced from caption
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.cardPadding) // Standardized to uniform 24pt all around
        }
        .aspectRatio(1.0, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .task {
            if showAnimation {
                // Bounce animation on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scale = 1.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Stats") {
    DailyStatsRow(stats: DailyStats.preview)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Empty State") {
    DailyStatsRow(stats: DailyStats.emptyState)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Active User") {
    DailyStatsRow(stats: DailyStats.activeUser)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    DailyStatsRow(stats: DailyStats.preview)
        .environmentObject({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
        .padding()
        .background(Color(hex: "#1A2332"))
}
