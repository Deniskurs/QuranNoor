//
//  HomeHeaderView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Header view with greeting and Hijri date
//

import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let greeting: String
    let hijriDate: HijriDate?
    let location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting
            HStack {
                Text(greeting)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                // Location indicator
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            // Hijri and Gregorian dates
            HStack(spacing: 12) {
                // Hijri date
                if let hijri = hijriDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(AppColors.primary.gold)

                        Text(hijri.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(AppColors.primary.gold)

                        Text("Loading date...")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }

                // Separator
                Text("•")
                    .foregroundColor(themeManager.currentTheme.textTertiary)

                // Gregorian date
                Text(todayGregorian)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            // Special Islamic occasions/holidays
            if let holidays = hijriDate?.holidays, !holidays.isEmpty {
                ForEach(holidays, id: \.self) { holiday in
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(AppColors.primary.gold)

                        Text(holiday)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primary.gold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        AppColors.primary.gold.opacity(0.15)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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

        text += " Location: \(location)."

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
        greeting: "Good Morning",
        hijriDate: HijriDate(
            date: "15-07-1446",
            format: "DD-MM-YYYY",
            day: "15",
            weekday: Weekday(en: "Monday", ar: "الإثنين"),
            month: HijriMonth(number: 7, en: "Rajab", ar: "رَجَب", days: 30),
            year: "1446",
            designation: Designation(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: ["Laylat al-Mi'raj"],
            adjustedHolidays: nil,
            method: nil
        ),
        location: "New York"
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    HomeHeaderView(
        greeting: "As-salamu alaykum",
        hijriDate: HijriDate(
            date: "01-09-1446",
            format: "DD-MM-YYYY",
            day: "1",
            weekday: Weekday(en: "Saturday", ar: "السبت"),
            month: HijriMonth(number: 9, en: "Ramadan", ar: "رَمَضان", days: 30),
            year: "1446",
            designation: Designation(abbreviated: "AH", expanded: "Anno Hegirae"),
            holidays: ["First Day of Ramadan"],
            adjustedHolidays: nil,
            method: nil
        ),
        location: "Dubai"
    )
    .environmentObject({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .padding()
    .background(Color(hex: "#1A2332"))
}

#Preview("No Hijri Date") {
    HomeHeaderView(
        greeting: "Good Afternoon",
        hijriDate: nil,
        location: "London"
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}
