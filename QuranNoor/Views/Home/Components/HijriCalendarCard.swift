//
//  HijriCalendarCard.swift
//  QuranNoor
//
//  Created by Claude Code
//  Islamic calendar card with special occasions
//

import SwiftUI

struct HijriCalendarCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let hijriDate: HijriDate?

    var body: some View {
        CardView(showPattern: true, intensity: .moderate) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.accentMuted)

                    Text("Islamic Calendar")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Spacer()

                    // Crescent moon icon
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                }

                if let hijri = hijriDate {
                    // Hijri date display
                    VStack(alignment: .leading, spacing: 8) {
                        // Month and year
                        Text(hijri.month.en)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            // Day
                            Text("\(hijri.day)")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(themeManager.currentTheme.accentMuted)

                            // Year
                            Text("\(hijri.year) AH")
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }

                    // Special occasions
                    if !hijri.holidays.isEmpty {
                        Divider()
                            .background(themeManager.currentTheme.textTertiary.opacity(0.3))

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(hijri.holidays, id: \.self) { holiday in
                                HStack(spacing: 8) {
                                    Image(systemName: "star.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.accentMuted)

                                    Text(holiday)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.currentTheme.textPrimary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Ramadan countdown (if not Ramadan)
                    if hijri.month.number != 9 {
                        ramadanCountdown(from: hijri)
                    }

                } else {
                    // Loading state
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(themeManager.currentTheme.accentMuted)

                        Text("Loading Islamic date...")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(Spacing.cardPadding) // Standardized to 24pt (was 20pt)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func ramadanCountdown(from hijri: HijriDate) -> some View {
        if let daysUntil = calculateDaysUntilRamadan(from: hijri), daysUntil > 0 {
            Divider()
                .background(themeManager.currentTheme.textTertiary.opacity(0.3))

            HStack(spacing: 12) {
                Image(systemName: "moon.circle.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ramadan in \(daysUntil) days")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("Start preparing spiritually")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func calculateDaysUntilRamadan(from hijri: HijriDate) -> Int? {
        // Simple approximation: Ramadan is month 9
        let currentMonth = hijri.month.number
        let ramadanMonth = 9

        if currentMonth < ramadanMonth {
            // Approximate days (29.5 days per month average)
            let monthsUntil = ramadanMonth - currentMonth
            return monthsUntil * 30 - hijri.day
        } else if currentMonth > ramadanMonth {
            // Next year's Ramadan
            let monthsUntil = (12 - currentMonth) + ramadanMonth
            return monthsUntil * 30
        }

        return nil // Currently Ramadan
    }

    private var accessibilityText: String {
        guard let hijri = hijriDate else {
            return "Loading Islamic date"
        }

        var text = "Islamic date: \(hijri.day) \(hijri.month.en) \(hijri.year) after Hijra."

        if !hijri.holidays.isEmpty {
            text += " Today is \(hijri.holidays.joined(separator: " and "))."
        }

        if hijri.month.number != 9, let daysUntil = calculateDaysUntilRamadan(from: hijri) {
            text += " Ramadan begins in approximately \(daysUntil) days."
        }

        return text
    }
}

// MARK: - Preview

#Preview("With Holiday") {
    HijriCalendarCard(
        hijriDate: HijriDate(
            day: 15,
            month: HijriMonthData(number: 7, en: "Rajab", ar: "رَجَب", days: 30),
            year: 1446,
            weekday: WeekdayData(en: "Monday", ar: "الإثنين"),
            date: "15-07-1446",
            format: "DD-MM-YYYY",
            designation: DesignationData(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: ["Laylat al-Mi'raj"],
            adjustedHolidays: [],
            method: nil
        )
    )
    .environment(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Ramadan") {
    HijriCalendarCard(
        hijriDate: HijriDate(
            day: 1,
            month: HijriMonthData(number: 9, en: "Ramadan", ar: "رَمَضان", days: 30),
            year: 1446,
            weekday: WeekdayData(en: "Saturday", ar: "السبت"),
            date: "01-09-1446",
            format: "DD-MM-YYYY",
            designation: DesignationData(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: ["First Day of Ramadan"],
            adjustedHolidays: [],
            method: nil
        )
    )
    .environment(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("No Holiday") {
    HijriCalendarCard(
        hijriDate: HijriDate(
            day: 10,
            month: HijriMonthData(number: 3, en: "Rabi' al-awwal", ar: "رَبيع الأوّل", days: 29),
            year: 1446,
            weekday: WeekdayData(en: "Wednesday", ar: "الأربعاء"),
            date: "10-03-1446",
            format: "DD-MM-YYYY",
            designation: DesignationData(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: [],
            adjustedHolidays: [],
            method: nil
        )
    )
    .environment(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Loading") {
    HijriCalendarCard(hijriDate: nil)
        .environment(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    HijriCalendarCard(
        hijriDate: HijriDate(
            day: 15,
            month: HijriMonthData(number: 7, en: "Rajab", ar: "رَجَب", days: 30),
            year: 1446,
            weekday: WeekdayData(en: "Monday", ar: "الإثنين"),
            date: "15-07-1446",
            format: "DD-MM-YYYY",
            designation: DesignationData(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: ["Laylat al-Mi'raj"],
            adjustedHolidays: [],
            method: nil
        )
    )
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .padding()
    .background(Color(hex: "#1A2332"))
}
