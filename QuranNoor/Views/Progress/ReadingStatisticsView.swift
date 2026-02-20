//
//  ReadingStatisticsView.swift
//  QuranNoor
//
//  Elegant reading statistics — key metrics, streak heatmap, and insights
//

import SwiftUI

// MARK: - Cached Formatters (Performance: avoid repeated allocation)
private let statisticsMediumFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f
}()

private let statisticsLongFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .long
    return f
}()

struct ReadingStatisticsView: View {
    var viewModel: ProgressManagementViewModel
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTimeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case year = "365 Days"
        case all = "All Time"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.sectionSpacing) {
                        keyMetricsSection

                        streakHeatmapSection

                        insightsSection
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.screenVertical)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                selectedTimeRange = range
                            } label: {
                                HStack {
                                    Text(range.rawValue)
                                    if selectedTimeRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.xxxs) {
                            Text(selectedTimeRange.rawValue)
                                .font(.system(size: FontSizes.xs))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                    }
                }
            }
        }
    }

    // MARK: - Key Metrics

    private var keyMetricsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Primary stat: verses read with progress ring
            HStack(spacing: Spacing.md) {
                ProgressRing(
                    progress: viewModel.overallCompletionPercentage / 100,
                    lineWidth: 6,
                    size: 64,
                    showPercentage: true,
                    color: themeManager.currentTheme.accent
                )

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("\(viewModel.totalVersesRead)")
                        .font(.system(size: FontSizes.xl, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Text("of 6,236 verses read")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()
            }
            .padding(Spacing.md)
            .background(themeManager.currentTheme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
            )

            // Secondary stats row
            HStack(spacing: Spacing.xs) {
                metricCard(
                    value: "\(viewModel.currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill"
                )

                metricCard(
                    value: "\(viewModel.completedSurahsCount)",
                    label: "Surahs Done",
                    icon: "checkmark.seal.fill"
                )

                metricCard(
                    value: String(format: "%.1f", viewModel.averageVersesPerDay),
                    label: "Per Day",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }

    private func metricCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.accent)

            Text(value)
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(themeManager.currentTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Streak Heatmap

    private var streakHeatmapSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Reading Streak")
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            VStack(spacing: Spacing.sm) {
                streakHeatmap

                IslamicDivider(style: .simple)

                // Legend
                HStack {
                    Text("Less")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    ForEach(0..<5) { index in
                        Rectangle()
                            .fill(heatmapColor(for: index))
                            .frame(width: 14, height: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }

                    Text("More")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    Spacer()

                    Text("Last \(daysToShow) days")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
            }
            .padding(Spacing.md)
            .background(themeManager.currentTheme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
            )
        }
    }

    private var streakHeatmap: some View {
        let calendar = viewModel.getReadingStreakCalendar(days: daysToShow)
        let maxVerses = calendar.values.max() ?? 1

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7),
            spacing: 3
        ) {
            ForEach(getDaysArray(), id: \.self) { date in
                let versesRead = calendar[date] ?? 0
                let intensity = Double(versesRead) / Double(maxVerses)

                Rectangle()
                    .fill(heatmapColor(forIntensity: intensity))
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .accessibilityHint(tooltipText(for: date, verses: versesRead))
            }
        }
    }

    private var daysToShow: Int {
        switch selectedTimeRange {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return 365
        }
    }

    private func getDaysArray() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<daysToShow).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }

    private func heatmapColor(forIntensity intensity: Double) -> Color {
        if intensity == 0 {
            return themeManager.currentTheme.textPrimary.opacity(0.05)
        } else if intensity < 0.25 {
            return themeManager.currentTheme.accent.opacity(0.2)
        } else if intensity < 0.5 {
            return themeManager.currentTheme.accent.opacity(0.4)
        } else if intensity < 0.75 {
            return themeManager.currentTheme.accent.opacity(0.6)
        } else {
            return themeManager.currentTheme.accent
        }
    }

    private func heatmapColor(for index: Int) -> Color {
        switch index {
        case 0: return themeManager.currentTheme.textPrimary.opacity(0.05)
        case 1: return themeManager.currentTheme.accent.opacity(0.2)
        case 2: return themeManager.currentTheme.accent.opacity(0.4)
        case 3: return themeManager.currentTheme.accent.opacity(0.6)
        case 4: return themeManager.currentTheme.accent
        default: return themeManager.currentTheme.accent
        }
    }

    private func tooltipText(for date: Date, verses: Int) -> String {
        "\(statisticsMediumFormatter.string(from: date)): \(verses) verse\(verses == 1 ? "" : "s")"
    }

    // MARK: - Insights Section (compact summary)

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Insights")
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            VStack(spacing: 0) {
                // Reading velocity
                insightRow(
                    label: "Reading Pace",
                    value: viewModel.readingVelocity,
                    icon: "gauge.with.dots.needle.67percent"
                )

                IslamicDivider(style: .simple)
                    .padding(.horizontal, Spacing.sm)

                // Consistency
                insightRow(
                    label: "30-Day Consistency",
                    value: "\(consistencyPercentage)%",
                    icon: "calendar.badge.checkmark"
                )

                IslamicDivider(style: .simple)
                    .padding(.horizontal, Spacing.sm)

                // Most productive day
                insightRow(
                    label: "Best Day",
                    value: mostProductiveDay,
                    icon: "star.fill"
                )

                if viewModel.estimatedDaysToComplete > 0 {
                    IslamicDivider(style: .simple)
                        .padding(.horizontal, Spacing.sm)

                    // Estimated completion
                    insightRow(
                        label: "Est. Completion",
                        value: estimatedCompletionDate,
                        icon: "flag.checkered"
                    )

                    IslamicDivider(style: .simple)
                        .padding(.horizontal, Spacing.sm)

                    // Verses remaining
                    insightRow(
                        label: "Verses Remaining",
                        value: "\(versesRemaining)",
                        icon: "book.closed"
                    )
                }
            }
            .padding(.vertical, Spacing.xs)
            .background(themeManager.currentTheme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
            )
        }
    }

    private func insightRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.accent)
                .frame(width: 24)

            Text(label)
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Computed Values

    private var consistencyPercentage: Int {
        let calendar = viewModel.getReadingStreakCalendar(days: 30)
        let daysWithReading = calendar.filter { $0.value > 0 }.count
        return Int((Double(daysWithReading) / 30.0) * 100)
    }

    private var mostProductiveDay: String {
        let calendar = viewModel.getReadingStreakCalendar(days: 365)
        guard let (date, _) = calendar.max(by: { $0.value < $1.value }) else {
            return "No data"
        }
        return statisticsMediumFormatter.string(from: date)
    }

    private var estimatedCompletionDate: String {
        guard viewModel.estimatedDaysToComplete > 0 else { return "Unknown" }
        let calendar = Calendar.current
        if let completionDate = calendar.date(
            byAdding: .day,
            value: viewModel.estimatedDaysToComplete,
            to: Date()
        ) {
            return statisticsLongFormatter.string(from: completionDate)
        }
        return "Unknown"
    }

    private var versesRemaining: Int {
        viewModel.totalVersesInQuran - viewModel.totalVersesRead
    }
}

// MARK: - Preview

#Preview {
    ReadingStatisticsView(viewModel: ProgressManagementViewModel())
        .environment(ThemeManager())
}
