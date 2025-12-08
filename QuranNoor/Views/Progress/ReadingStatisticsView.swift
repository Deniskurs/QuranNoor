//
//  ReadingStatisticsView.swift
//  QuranNoor
//
//  Comprehensive analytics and statistics for reading progress
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
    @ObservedObject var viewModel: ProgressManagementViewModel
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
                GradientBackground(style: .quran, opacity: 0.2)

                ScrollView {
                    VStack(spacing: 20) {
                        // Overview Stats
                        overviewStatsSection

                        // Streak Calendar
                        streakCalendarSection

                        // Reading Patterns
                        readingPatternsSection

                        // Completion Projections
                        projectionsSection

                        // Most Read Surahs
                        mostReadSurahsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
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
                        HStack {
                            Text(selectedTimeRange.rawValue)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Overview Stats

    private var overviewStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Overview", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "book.fill",
                    title: "Total Verses",
                    value: "\(viewModel.totalVersesRead)",
                    subtitle: "of 6,236",
                    color: themeManager.currentTheme.accentPrimary
                )

                StatCard(
                    icon: "checkmark.seal.fill",
                    title: "Surahs Done",
                    value: "\(viewModel.completedSurahsCount)",
                    subtitle: "of 114",
                    color: themeManager.currentTheme.accentSecondary
                )

                StatCard(
                    icon: "flame.fill",
                    title: "Current Streak",
                    value: "\(viewModel.currentStreak)",
                    subtitle: "day\(viewModel.currentStreak == 1 ? "" : "s")",
                    color: themeManager.currentTheme.accentInteractive
                )

                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Avg Per Day",
                    value: String(format: "%.1f", viewModel.averageVersesPerDay),
                    subtitle: "verses",
                    color: themeManager.currentTheme.accentPrimary
                )
            }
        }
    }

    // MARK: - Streak Calendar

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Reading Streak", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                VStack(spacing: 16) {
                    // Heatmap
                    streakHeatmap

                    IslamicDivider(style: .simple)

                    // Legend
                    HStack {
                        Text("Less")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(0..<5) { index in
                            Rectangle()
                                .fill(heatmapColor(for: index))
                                .frame(width: 16, height: 16)
                                .cornerRadius(2)
                        }

                        Text("More")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        ThemedText.caption("Last \(daysToShow) days")
                            .opacity(0.7)
                    }
                }
            }
        }
    }

    private var streakHeatmap: some View {
        let calendar = viewModel.getReadingStreakCalendar(days: daysToShow)
        let maxVerses = calendar.values.max() ?? 1

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
            spacing: 4
        ) {
            ForEach(getDaysArray(), id: \.self) { date in
                let versesRead = calendar[date] ?? 0
                let intensity = Double(versesRead) / Double(maxVerses)

                Rectangle()
                    .fill(heatmapColor(forIntensity: intensity))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(
                                themeManager.currentTheme.borderColor.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
                    .help(tooltipText(for: date, verses: versesRead))
            }
        }
    }

    private var daysToShow: Int {
        switch selectedTimeRange {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return 365  // Cap at 365 for display
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
            return themeManager.currentTheme.textColor.opacity(0.05)
        } else if intensity < 0.25 {
            return themeManager.currentTheme.accentPrimary.opacity(0.2)
        } else if intensity < 0.5 {
            return themeManager.currentTheme.accentPrimary.opacity(0.4)
        } else if intensity < 0.75 {
            return themeManager.currentTheme.accentPrimary.opacity(0.6)
        } else {
            return themeManager.currentTheme.accentPrimary
        }
    }

    private func heatmapColor(for index: Int) -> Color {
        switch index {
        case 0: return themeManager.currentTheme.textColor.opacity(0.05)
        case 1: return themeManager.currentTheme.accentPrimary.opacity(0.2)
        case 2: return themeManager.currentTheme.accentPrimary.opacity(0.4)
        case 3: return themeManager.currentTheme.accentPrimary.opacity(0.6)
        case 4: return themeManager.currentTheme.accentPrimary
        default: return themeManager.currentTheme.accentPrimary
        }
    }

    private func tooltipText(for date: Date, verses: Int) -> String {
        return "\(statisticsMediumFormatter.string(from: date)): \(verses) verse\(verses == 1 ? "" : "s")"
    }

    // MARK: - Reading Patterns

    private var readingPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Reading Patterns", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                VStack(spacing: 16) {
                    // Reading Velocity
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText.caption("READING VELOCITY")
                            ThemedText(viewModel.readingVelocity, style: .body)
                                .foregroundColor(themeManager.currentTheme.accentPrimary)
                        }

                        Spacer()

                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.currentTheme.accentPrimary.opacity(0.3))
                    }

                    IslamicDivider(style: .simple)

                    // Consistency Score
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText.caption("CONSISTENCY")
                            ThemedText("\(consistencyPercentage)%", style: .body)
                                .foregroundColor(themeManager.currentTheme.accentSecondary)
                        }

                        Spacer()

                        ProgressRing(
                            progress: Double(consistencyPercentage) / 100,
                            lineWidth: 4,
                            size: 40,
                            showPercentage: false,
                            color: themeManager.currentTheme.accentSecondary
                        )
                    }

                    IslamicDivider(style: .simple)

                    // Most Productive Day
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText.caption("MOST PRODUCTIVE DAY")
                            ThemedText(mostProductiveDay, style: .body)
                                .foregroundColor(themeManager.currentTheme.accentInteractive)
                        }

                        Spacer()

                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.currentTheme.accentInteractive.opacity(0.3))
                    }
                }
            }
        }
    }

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

    // MARK: - Projections

    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Completion Projection", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                VStack(spacing: 16) {
                    if viewModel.estimatedDaysToComplete > 0 {
                        // Days to completion
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(themeManager.currentTheme.accentSecondary.opacity(0.3))

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                ThemedText("\(viewModel.estimatedDaysToComplete)", style: .title)
                                    .foregroundColor(themeManager.currentTheme.accentSecondary)

                                ThemedText.caption("days to completion")
                                    .opacity(0.7)
                            }
                        }

                        IslamicDivider(style: .simple)

                        // Estimated completion date
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                ThemedText.caption("ESTIMATED COMPLETION")
                                ThemedText(estimatedCompletionDate, style: .body)
                                    .foregroundColor(themeManager.currentTheme.accentPrimary)
                            }

                            Spacer()

                            Image(systemName: "flag.checkered")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.currentTheme.accentPrimary.opacity(0.3))
                        }

                        IslamicDivider(style: .simple)

                        // Verses remaining
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                ThemedText.caption("VERSES REMAINING")
                                ThemedText("\(versesRemaining)", style: .body)
                                    .foregroundColor(themeManager.currentTheme.accentInteractive)
                            }

                            Spacer()

                            ProgressRing(
                                progress: viewModel.overallCompletionPercentage / 100,
                                lineWidth: 4,
                                size: 40,
                                showPercentage: false,
                                color: themeManager.currentTheme.accentPrimary
                            )
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .opacity(0.5)

                            ThemedText.caption("Not enough data to project completion")
                                .multilineTextAlignment(.center)
                                .opacity(0.7)

                            ThemedText.caption("Keep reading to see your progress!")
                                .multilineTextAlignment(.center)
                                .foregroundColor(themeManager.currentTheme.accentSecondary)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
        }
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
        return viewModel.totalVersesInQuran - viewModel.totalVersesRead
    }

    // MARK: - Most Read Surahs

    private var mostReadSurahsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Most Read Surahs", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                VStack(spacing: 0) {
                    let topSurahs = getTopSurahs(limit: 5)

                    if topSurahs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .opacity(0.5)

                            ThemedText.caption("No reading data yet")
                                .opacity(0.5)
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(Array(topSurahs.enumerated()), id: \.offset) { index, stat in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 12)
                            }

                            HStack(spacing: 12) {
                                // Rank badge
                                ZStack {
                                    Circle()
                                        .fill(rankColor(index).opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(rankColor(index))
                                }

                                // Surah info
                                if let surah = viewModel.getSurah(forNumber: stat.surahNumber) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ThemedText.body(surah.englishName)

                                        ThemedText.caption("\(stat.readVerses) verses read")
                                            .foregroundColor(themeManager.currentTheme.accentSecondary)
                                            .opacity(0.7)
                                    }
                                }

                                Spacer()

                                // Progress indicator
                                Text("\(Int(stat.completionPercentage))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.accentPrimary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                    }
                }
            }
        }
    }

    private func getTopSurahs(limit: Int) -> [SurahProgressStats] {
        return viewModel.surahStats
            .filter { $0.readVerses > 0 }
            .sorted { $0.readVerses > $1.readVerses }
            .prefix(limit)
            .map { $0 }
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return themeManager.currentTheme.accentInteractive
        case 1: return Color(hex: "#C0C0C0")  // Silver
        case 2: return Color(hex: "#CD7F32")  // Bronze
        default: return themeManager.currentTheme.accentSecondary
        }
    }
}

// MARK: - Supporting Components
// Note: StatCard moved to Components/Cards/StatCard.swift

// MARK: - Helper Extensions

extension View {
    func help(_ text: String) -> some View {
        // Tooltip helper (iOS doesn't have native tooltips, but this can be used for accessibility)
        self.accessibilityHint(text)
    }
}

// MARK: - Preview

#Preview {
    ReadingStatisticsView(viewModel: ProgressManagementViewModel())
        .environment(ThemeManager())
}
