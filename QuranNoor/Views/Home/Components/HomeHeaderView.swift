//
//  HomeHeaderView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Header view with greeting and Hijri date
//

import SwiftUI

struct HomeHeaderView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let greeting: String
    let hijriDate: HijriDate?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Greeting - Bold & Modern (iOS 26 style)
            Text(greeting)
                .font(.system(size: 40, weight: .heavy))
                .tracking(-0.5)
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Clean divider separator
            Divider()
                .background(themeManager.currentTheme.textTertiary.opacity(0.3))

            // Dates stacked vertically (Modern Split style)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Hijri date - top
                HStack(spacing: 8) {
                    if let hijri = hijriDate {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.accentSecondary)

                        Text(hijri.formattedDate)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.accentSecondary)

                        Text("Loading...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }

                // Gregorian date - bottom
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Text(todayGregorian)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }

            // Special Islamic occasions/holidays
            if let holidays = hijriDate?.holidays, !holidays.isEmpty {
                ForEach(holidays, id: \.self) { holiday in
                    HStack(spacing: Spacing.xxs) { // Enhanced from 6 to 8
                        Image(systemName: "star.fill")
                            .font(.system(size: 11)) // Enhanced from caption2
                            .foregroundColor(themeManager.currentTheme.accentSecondary)

                        Text(holiday)
                            .font(.system(size: 13, weight: .semibold)) // Enhanced from caption + medium
                            .foregroundColor(themeManager.currentTheme.accentSecondary)
                    }
                    .padding(.horizontal, Spacing.sm) // Enhanced from 12 to 16
                    .padding(.vertical, Spacing.xxs) // Enhanced from 6 to 8
                    .background(
                        Capsule() // Changed from cornerRadius for sleeker look
                            .fill(themeManager.currentTheme.accentSecondary.opacity(0.15))
                    )
                }
                .padding(.top, Spacing.xxs) // Add top spacing
            }
        }
        .padding(.horizontal, Spacing.cardPadding) // Enhanced from 20 to 24
        .padding(.vertical, Spacing.screenVertical) // Enhanced from 16 to 20
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Computed Properties

    private var todayGregorian: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var accessibilityText: String {
        var text = "\(greeting). "

        if let hijri = hijriDate {
            text += "Islamic date: \(hijri.formattedDate). "
        }

        text += "Gregorian date: \(todayGregorian)."

        if let holidays = hijriDate?.holidays, !holidays.isEmpty {
            text += " Today is \(holidays.joined(separator: " and "))."
        }

        return text
    }
}

// MARK: - Hijri Date Extension

private extension HijriDate {
    var formattedDate: String {
        "\(day) \(month.en) \(year)"
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    HomeHeaderView(
        greeting: "As Salamu Alaykum",
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

#Preview("Dark Mode") {
    HomeHeaderView(
        greeting: "As Salamu Alaykum",
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
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .padding()
    .background(Color(hex: "#1A2332"))
}

#Preview("No Hijri Date") {
    HomeHeaderView(
        greeting: "As Salamu Alaykum",
        hijriDate: nil
    )
    .environment(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}
