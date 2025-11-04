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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Greeting - full width
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(greeting)
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.5)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // Subtle subtext
                Text("May peace be upon you")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Centered date layout with separator - dot is fixed at screen center
            ZStack {
                // Center dot - absolutely centered
                Text("•")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textTertiary)

                // Dates on either side
                HStack(spacing: 0) {
                    // Hijri date - left side
                    HStack(spacing: 6) {
                        if let hijri = hijriDate {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundColor(AppColors.primary.gold)

                            Text(hijri.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        } else {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(AppColors.primary.gold)

                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Spacing.md) // Space before center dot

                    // Spacer for center dot
                    Spacer()
                        .frame(width: 20) // Fixed width for dot area

                    // Gregorian date - right side
                    Text(todayGregorian)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, Spacing.md) // Space after center dot
                }
            }

            // Special Islamic occasions/holidays
            if let holidays = hijriDate?.holidays, !holidays.isEmpty {
                ForEach(holidays, id: \.self) { holiday in
                    HStack(spacing: Spacing.xxs) { // Enhanced from 6 to 8
                        Image(systemName: "star.fill")
                            .font(.system(size: 11)) // Enhanced from caption2
                            .foregroundColor(AppColors.primary.gold)

                        Text(holiday)
                            .font(.system(size: 13, weight: .semibold)) // Enhanced from caption + medium
                            .foregroundColor(AppColors.primary.gold)
                    }
                    .padding(.horizontal, Spacing.sm) // Enhanced from 12 to 16
                    .padding(.vertical, Spacing.xxs) // Enhanced from 6 to 8
                    .background(
                        Capsule() // Changed from cornerRadius for sleeker look
                            .fill(AppColors.primary.gold.opacity(0.12)) // Softer from 0.15
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
        )
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    HomeHeaderView(
        greeting: "As Salamu Alaykum",
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
        )
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
        greeting: "As Salamu Alaykum",
        hijriDate: nil
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}
