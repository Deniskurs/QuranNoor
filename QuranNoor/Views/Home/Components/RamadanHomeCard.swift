//
//  RamadanHomeCard.swift
//  QuranNoor
//
//  Prominent Ramadan card shown on the Home screen during the blessed month
//

import SwiftUI

struct RamadanHomeCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var calendarService = IslamicCalendarService()
    @State private var showingTracker = false

    var body: some View {
        if calendarService.isRamadan() {
            let tracker = calendarService.getCurrentRamadanTracker()
            let hijriDate = calendarService.convertToHijri()
            let dayOfRamadan = hijriDate.day

            Button {
                showingTracker = true
            } label: {
                VStack(spacing: Spacing.sm) {
                    // Header row
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ramadan Mubarak")
                                .font(.headline)
                                .foregroundStyle(themeManager.currentTheme.textPrimary)

                            Text("Day \(dayOfRamadan) of 30")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()

                        // Fasting progress circle
                        ZStack {
                            Circle()
                                .stroke(Color.purple.opacity(0.2), lineWidth: 4)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: tracker.completionPercentage / 100)
                                .stroke(Color.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))

                            Text("\(tracker.totalFastingDays)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(themeManager.currentTheme.textPrimary)
                        }
                    }

                    // Progress bar
                    VStack(spacing: 4) {
                        ProgressView(value: Double(dayOfRamadan), total: 30)
                            .tint(.purple)

                        HStack {
                            Text("\(tracker.totalFastingDays) fasts completed")
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.textSecondary)

                            Spacer()

                            Text("Tap to track")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .fill(
                            .linearGradient(
                                colors: [.purple.opacity(0.08), .indigo.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .stroke(.purple.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingTracker) {
                RamadanTrackerView(calendarService: calendarService)
            }
        }
    }
}
