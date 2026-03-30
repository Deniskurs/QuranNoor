//
//  AdhkarView.swift
//  QuranNoor
//
//  Main view for adhkar (Islamic remembrances)
//

import SwiftUI

struct AdhkarView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var adhkarService = AdhkarService()
    @State private var selectedCategory: AdhkarCategory?

    private var todayCompletedCount: Int {
        AdhkarCategory.allCases.reduce(0) { total, category in
            total + adhkarService.getStatistics(for: category).completedToday
        }
    }

    private var todayTotalCount: Int {
        AdhkarCategory.allCases.reduce(0) { total, category in
            total + adhkarService.getStatistics(for: category).totalDhikr
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Today's progress summary
                    progressSummary

                    // Statistics Card
                    statisticsCard

                    // Categories
                    categoriesSection
                }
                .padding()
            }
            .navigationTitle("Adhkar")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AdhkarCategory.self) { category in
                AdhkarCategoryView(category: category, adhkarService: adhkarService)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.green, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Daily Remembrances")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Daily remembrances for specific times of the day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                Text("Today's Progress: \(todayCompletedCount)/\(todayTotalCount) completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Streak: \(adhkarService.progress.streak) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Current Streak",
                    value: "\(adhkarService.progress.streak)",
                    icon: "flame.fill",
                    color: .orange
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Total Completions",
                    value: "\(adhkarService.progress.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AdhkarCategory.allCases) { category in
                    NavigationLink(value: category) {
                        AdhkarCategoryCard(
                            category: category,
                            count: adhkarService.getAdhkar(for: category).count,
                            statistics: adhkarService.getStatistics(for: category)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AdhkarCategoryCard: View {
    @Environment(ThemeManager.self) var themeManager
    let category: AdhkarCategory
    let count: Int
    let statistics: AdhkarStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(category.recommendedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Progress Bar
            ProgressView(value: statistics.completionPercentage, total: 100)
                .tint(progressColor)

            HStack {
                Text("\(statistics.completedToday)/\(statistics.totalDhikr)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if statistics.isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statistics.isFullyCompleted ? .green : .clear, lineWidth: 2)
        )
    }

    private var iconColor: Color {
        switch category {
        case .morning:
            return .orange
        case .evening:
            return .purple
        case .afterPrayer:
            return .green
        case .beforeSleep:
            return themeManager.currentTheme.featureAccent
        }
    }

    private var progressColor: Color {
        statistics.completionPercentage >= 100 ? .green : iconColor
    }
}

#Preview {
    AdhkarView()
}
