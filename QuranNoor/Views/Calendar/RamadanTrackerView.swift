//
//  RamadanTrackerView.swift
//  QuranNoor
//
//  Special tracker for Ramadan fasting and Qiyam
//

import SwiftUI

struct RamadanTrackerView: View {
    @Environment(ThemeManager.self) var themeManager
    @Bindable var calendarService: IslamicCalendarService

    @Environment(\.dismiss) private var dismiss

    @State private var currentTracker: RamadanTracker
    private let currentYear: Int

    init(calendarService: IslamicCalendarService) {
        self.calendarService = calendarService
        let hijriDate = calendarService.convertToHijri()
        self.currentYear = hijriDate.year
        self._currentTracker = State(initialValue: calendarService.getCurrentRamadanTracker())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Statistics Card
                    statisticsCard

                    // Fasting Tracker
                    fastingTrackerSection

                    // Last 10 Nights Qiyam Tracker
                    qiyamTrackerSection

                    // Quran & Zakah Checklist
                    checklistSection
                }
                .padding()
            }
            .navigationTitle("Ramadan Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [themeManager.currentTheme.accentMuted, themeManager.currentTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Ramadan \(currentYear) AH")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Track your blessed month journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatBox(
                    title: "Fasts",
                    value: "\(currentTracker.totalFastingDays)/30",
                    icon: "sun.max.fill",
                    color: .orange,
                    percentage: currentTracker.completionPercentage
                )

                StatBox(
                    title: "Qiyam",
                    value: "\(currentTracker.lastTenNightsCount)/10",
                    icon: "moon.stars.fill",
                    color: .purple,
                    percentage: Double(currentTracker.lastTenNightsCount) / 10.0 * 100.0
                )
            }

            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(currentTracker.completionPercentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                ProgressView(value: currentTracker.completionPercentage, total: 100)
                    .tint(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Fasting Tracker Section

    private var fastingTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Daily Fasting (1-30)")
                    .font(.headline)
                Spacer()
            }

            // Grid of days 1-30
            let columns = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...30, id: \.self) { day in
                    DayButton(
                        day: day,
                        isCompleted: currentTracker.isFastingCompleted(day: day),
                        color: .orange
                    ) {
                        currentTracker.toggleFasting(day: day)
                        calendarService.updateRamadanTracker(currentTracker)
                    }
                }
            }

            Text("Tap on each day when you complete your fast")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
        )
    }

    // MARK: - Qiyam Tracker Section

    private var qiyamTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.purple)
                Text("Last 10 Nights Qiyam (21-30)")
                    .font(.headline)
                Spacer()
            }

            Text("Track your night prayers during the last 10 blessed nights of Ramadan, when Laylat al-Qadr is most likely to occur.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Grid of nights 21-30
            let columns = Array(repeating: GridItem(.flexible()), count: 5)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(21...30, id: \.self) { night in
                    NightButton(
                        night: night,
                        isCompleted: currentTracker.isQiyamCompleted(night: night),
                        isOdd: night % 2 != 0,
                        color: .purple
                    ) {
                        currentTracker.toggleQiyam(night: night)
                        calendarService.updateRamadanTracker(currentTracker)
                    }
                }
            }

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Odd nights (21, 23, 25, 27, 29) are especially blessed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.purple.opacity(0.1))
        )
    }

    // MARK: - Checklist Section

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.green)
                Text("Ramadan Checklist")
                    .font(.headline)
                Spacer()
            }

            // Quran Completion
            Button {
                currentTracker.quranCompleted.toggle()
                calendarService.updateRamadanTracker(currentTracker)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: currentTracker.quranCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(currentTracker.quranCompleted ? .green : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Complete Quran Recitation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Aim to recite the entire Quran during Ramadan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentTracker.quranCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            // Zakah Payment
            Button {
                currentTracker.zakahPaid.toggle()
                calendarService.updateRamadanTracker(currentTracker)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: currentTracker.zakahPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(currentTracker.zakahPaid ? .green : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pay Zakat al-Fitr")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Obligatory charity before Eid prayer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentTracker.zakahPaid ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
        )
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let percentage: Double

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: percentage, total: 100)
                .tint(color)
                .frame(width: 60)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct DayButton: View {
    let day: Int
    let isCompleted: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                } else {
                    Text("\(day)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct NightButton: View {
    let night: Int
    let isCompleted: Bool
    let isOdd: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(isOdd ? .yellow : .clear, lineWidth: 2)
                    )

                VStack(spacing: 2) {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .font(.caption)
                            .fontWeight(.bold)
                    }

                    Text("\(night)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isCompleted ? .white : .primary)
                }

                // Star indicator for odd nights
                if isOdd && !isCompleted {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                                .offset(x: -4, y: -4)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RamadanTrackerView(calendarService: IslamicCalendarService())
}
