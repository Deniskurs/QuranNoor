//
//  AdhkarQuickAccessCard.swift
//  QuranNoor
//
//  Created by Claude Code
//  Quick access to Adhkar from the Home screen
//

import SwiftUI

struct AdhkarQuickAccessCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var adhkarService = AdhkarService()

    // Sheet states
    @State private var showTasbih = false
    @State private var showNamesOfAllah = false

    // Categories to display
    private let displayCategories: [AdhkarCategory] = [.morning, .evening, .afterPrayer]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.cardSpacing) {
            // Header
            headerSection

            // Stats Row
            statsSection

            // Quick Action Buttons
            quickActionsSection

            // Category Cards
            categoriesSection
        }
        .sheet(isPresented: $showTasbih) {
            TasbihCounterView()
        }
        .sheet(isPresented: $showNamesOfAllah) {
            NamesOfAllahView()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Adhkar quick access")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.linearGradient(
                    colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Daily Adhkar")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            // View All NavigationLink
            NavigationLink {
                AdhkarView()
            } label: {
                HStack(spacing: 4) {
                    Text("View All")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(themeManager.currentTheme.accentSecondary)
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: Spacing.md) {
            // Streak
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(adhkarService.progress.streak)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )

            // Total Completions
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(adhkarService.progress.totalCompletions)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("completed")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Tasbih Button
            Button {
                showTasbih = true
                HapticManager.shared.trigger(.light)
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                .linearGradient(
                                    colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }

                    Text("Tasbih")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)

            // 99 Names Button
            Button {
                showNamesOfAllah = true
                HapticManager.shared.trigger(.light)
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                .linearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Text("99")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("Names")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(spacing: 10) {
            ForEach(displayCategories) { category in
                NavigationLink {
                    AdhkarCategoryView(category: category, adhkarService: adhkarService)
                } label: {
                    CategoryRowView(
                        category: category,
                        statistics: adhkarService.getStatistics(for: category),
                        themeManager: themeManager
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Category Row View

private struct CategoryRowView: View {
    let category: AdhkarCategory
    let statistics: AdhkarStatistics
    let themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(categoryColor)
            }

            // Title and progress text
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("\(statistics.completedToday)/\(statistics.totalDhikr) completed")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Progress bar
            ProgressCapsule(
                progress: statistics.completionPercentage / 100,
                color: statistics.isFullyCompleted ? .green : categoryColor
            )
            .frame(width: 60)

            // Completion check or chevron
            if statistics.isFullyCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.body)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statistics.isFullyCompleted ? .green.opacity(0.3) : .clear, lineWidth: 1)
        )
    }

    private var categoryColor: Color {
        switch category {
        case .morning:
            return .orange
        case .evening:
            return .purple
        case .afterPrayer:
            return .green
        case .beforeSleep:
            return themeManager.currentTheme.featureAccent
        case .waking:
            return .yellow
        case .general:
            return .teal
        }
    }
}

// MARK: - Progress Capsule

private struct ProgressCapsule: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(color.opacity(0.2))

                // Fill
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * min(1, progress)))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Preview

#Preview("With Data") {
    NavigationStack {
        ScrollView {
            AdhkarQuickAccessCard()
                .padding()
        }
    }
    .environment(ThemeManager())
}

#Preview("Dark Mode") {
    NavigationStack {
        ScrollView {
            AdhkarQuickAccessCard()
                .padding()
        }
        .background(Color(hex: "#1A2332"))
    }
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}
