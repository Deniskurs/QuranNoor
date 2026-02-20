//
//  PrayerHeroSection.swift
//  QuranNoor
//
//  Immersive hero section combining sky gradient, countdown, and status
//  Central visual element of the redesigned prayer tab
//

import SwiftUI

/// Immersive hero section for the Prayer tab
struct PrayerHeroSection: View {
    // MARK: - Properties

    let period: PrayerPeriod
    let location: String
    let isLoadingLocation: Bool

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Fixed hero height (responsive via verticalSizeClass if needed)
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// Track view visibility to pause countdown updates when off-screen
    @State private var isViewVisible = true

    // MARK: - Body

    var body: some View {
        ZStack {
            // Time-of-day sky gradient background
            TimeOfDaySkyView()

            // Content overlay
            VStack(spacing: Spacing.sm) {
                // Location header
                locationHeader
                    .padding(.top, Spacing.md)

                Spacer()

                // Current prayer name (large, centered)
                currentPrayerDisplay

                // Countdown timer - narrow TimelineView so only this text rebuilds per-second
                TimelineView(.periodic(from: .now, by: isViewVisible ? 1.0 : 60.0)) { context in
                    let deadline = period.state.nextEventTime
                    let remaining = max(deadline.timeIntervalSince(context.date), 0)
                    let hours = Int(remaining) / 3600
                    let minutes = (Int(remaining) % 3600) / 60
                    let seconds = Int(remaining) % 60
                    let countdown = hours > 0
                        ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                        : String(format: "%02d:%02d", minutes, seconds)
                    let isUrgent = remaining > 0 && remaining <= 30 * 60
                    let urgency = UrgencyLevel.from(secondsRemaining: remaining)

                    HeroCountdownDisplay(
                        countdownString: countdown,
                        isUrgent: isUrgent,
                        urgencyLevel: urgency
                    )
                }

                // Status pill
                PrayerStatusPill(
                    state: period.state,
                    prayerTime: currentPrayerTime,
                    isUrgent: period.isUrgent
                )
                .padding(.top, Spacing.xxs)

                Spacer()
                    .frame(height: Spacing.sm)
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
        .frame(height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xxl + 4, style: .continuous))
        .shadow(color: heroShadowColor, radius: 20, x: 0, y: 10)
        .onAppear { isViewVisible = true }
        .onDisappear { isViewVisible = false }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.uppercased())
                    .font(.system(size: FontSizes.xs - 1, weight: .bold, design: .rounded))
                    .foregroundColor(headerTextColor.opacity(0.7))
                    .tracking(1.5)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(formattedDate)
                    .font(.system(size: FontSizes.sm - 1, weight: .medium))
                    .foregroundColor(headerTextColor.opacity(0.9))
            }

            Spacer()

            if isLoadingLocation {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: headerTextColor))
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Current Prayer Display

    private var currentPrayerDisplay: some View {
        VStack(spacing: Spacing.xxxs + 2) {
            // Prayer icon
            Image(systemName: currentPrayerIcon)
                .font(.system(size: FontSizes.xl + 4, weight: .medium))
                .foregroundColor(prayerAccentColor)
                .shadow(color: prayerAccentColor.opacity(0.5), radius: 8)

            // Prayer name
            Text(currentPrayerName)
                .font(.system(size: FontSizes.xxl, weight: .bold))
                .foregroundColor(heroTextColor)

            // Arabic name
            Text(currentPrayerArabic)
                .font(.custom("KFGQPCHAFSUthmanicScript-Regular", size: 22, relativeTo: .title2))
                .foregroundColor(heroTextColor.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentPrayerName) prayer")
    }

    // MARK: - Computed Properties

    private var heroHeight: CGFloat {
        // Dynamic height based on vertical size class (iOS 26 compatible)
        verticalSizeClass == .regular ? 380 : 320
    }

    private var heroTextColor: Color {
        switch themeManager.currentTheme {
        case .light:
            // Adapt based on time of day
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 6 && hour < 18) ? themeManager.currentTheme.textPrimary : .white
        case .dark, .night:
            return .white
        case .sepia:
            return themeManager.currentTheme.textPrimary
        }
    }

    private var headerTextColor: Color {
        heroTextColor
    }

    private var prayerAccentColor: Color {
        if period.isUrgent {
            return themeManager.currentTheme.accentMuted
        }

        switch themeManager.currentTheme {
        case .light:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 6 && hour < 18) ? themeManager.currentTheme.accent : themeManager.currentTheme.accentMuted
        case .dark:
            return themeManager.currentTheme.accentMuted
        case .night:
            return themeManager.currentTheme.accentMuted
        case .sepia:
            return themeManager.currentTheme.accent
        }
    }

    private var heroShadowColor: Color {
        switch themeManager.currentTheme {
        case .light, .sepia:
            return Color.black.opacity(0.15)
        case .dark:
            return Color.black.opacity(0.4)
        case .night:
            return Color.black.opacity(0.6)
        }
    }

    private var currentPrayerName: String {
        switch period.state {
        case .beforeFajr:
            return "Fajr"
        case .inProgress(let prayer, _):
            return prayer.displayName
        case .betweenPrayers(_, let next, _):
            return next.displayName
        case .afterIsha:
            return "Rest"
        }
    }

    private var currentPrayerArabic: String {
        switch period.state {
        case .beforeFajr:
            return "الفجر"
        case .inProgress(let prayer, _):
            return prayer.arabicName
        case .betweenPrayers(_, let next, _):
            return next.arabicName
        case .afterIsha:
            return "الراحة"
        }
    }

    private var currentPrayerIcon: String {
        switch period.state {
        case .beforeFajr:
            return "moon.stars.fill"
        case .inProgress(let prayer, _):
            return prayer.icon
        case .betweenPrayers(_, let next, _):
            return next.icon
        case .afterIsha:
            return "moon.fill"
        }
    }

    private var currentPrayerTime: Date? {
        switch period.state {
        case .beforeFajr(let fajr):
            return fajr
        case .inProgress(let prayer, _):
            return period.todayPrayers.prayerTimes.first { $0.name == prayer }?.time
        case .betweenPrayers(_, _, let nextStart):
            return nextStart
        case .afterIsha:
            return nil
        }
    }

    private var formattedDate: String {
        Self.dayDateFormatter.string(from: Date())
    }

    // Cached DateFormatter for performance
    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private var accessibilityLabel: String {
        var label = "\(currentPrayerName) prayer. "
        label += "Time remaining: \(period.formattedTimeRemaining). "
        if period.isUrgent {
            label += "Urgent, less than 30 minutes remaining. "
        }
        label += "Location: \(location)."
        return label
    }
}

// MARK: - Prayer Arabic Names Extension

private extension PrayerName {
    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }
}

// MARK: - Preview

#Preview("In Progress - Light") {
    let now = Date()
    let times = DailyPrayerTimes(
        date: now,
        fajr: Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: now)!,
        sunrise: Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: now)!,
        dhuhr: Calendar.current.date(bySettingHour: 12, minute: 15, second: 0, of: now)!,
        asr: Calendar.current.date(bySettingHour: 15, minute: 45, second: 0, of: now)!,
        maghrib: Calendar.current.date(bySettingHour: 18, minute: 20, second: 0, of: now)!,
        isha: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: now)!,
        imsak: nil,
        sunset: Calendar.current.date(bySettingHour: 18, minute: 15, second: 0, of: now)!,
        midnight: Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: now)!,
        firstThird: nil,
        lastThird: nil
    )

    let period = PrayerPeriod(
        state: .inProgress(
            prayer: .asr,
            deadline: Calendar.current.date(bySettingHour: 18, minute: 20, second: 0, of: now)!
        ),
        todayPrayers: times,
        tomorrowPrayers: nil,
        calculatedAt: now
    )

    PrayerHeroSection(
        period: period,
        location: "San Francisco",
        isLoadingLocation: false
    )
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environment(ThemeManager())
}

#Preview("Urgent State - Dark") {
    let now = Date()
    let urgentDeadline = now.addingTimeInterval(600) // 10 minutes

    let times = DailyPrayerTimes(
        date: now,
        fajr: now.addingTimeInterval(-3600 * 10),
        sunrise: now.addingTimeInterval(-3600 * 9),
        dhuhr: now.addingTimeInterval(-3600 * 5),
        asr: now.addingTimeInterval(-1800),
        maghrib: urgentDeadline,
        isha: now.addingTimeInterval(3600 * 2),
        imsak: nil,
        sunset: now.addingTimeInterval(-300),
        midnight: now.addingTimeInterval(3600 * 6),
        firstThird: nil,
        lastThird: nil
    )

    let period = PrayerPeriod(
        state: .inProgress(prayer: .asr, deadline: urgentDeadline),
        todayPrayers: times,
        tomorrowPrayers: nil,
        calculatedAt: now
    )

    PrayerHeroSection(
        period: period,
        location: "San Francisco",
        isLoadingLocation: false
    )
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}

#Preview("Night Theme (OLED)") {
    let now = Date()
    let times = DailyPrayerTimes(
        date: now,
        fajr: now.addingTimeInterval(3600 * 6),
        sunrise: now.addingTimeInterval(3600 * 7),
        dhuhr: now.addingTimeInterval(3600 * 12),
        asr: now.addingTimeInterval(3600 * 15),
        maghrib: now.addingTimeInterval(-3600),
        isha: now.addingTimeInterval(-1800),
        imsak: nil,
        sunset: now.addingTimeInterval(-3700),
        midnight: now.addingTimeInterval(3600 * 4),
        firstThird: nil,
        lastThird: nil
    )

    let period = PrayerPeriod(
        state: .afterIsha(tomorrowFajr: now.addingTimeInterval(3600 * 6)),
        todayPrayers: times,
        tomorrowPrayers: nil,
        calculatedAt: now
    )

    PrayerHeroSection(
        period: period,
        location: "San Francisco",
        isLoadingLocation: false
    )
    .padding()
    .background(Color.black)
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.night)
        return manager
    }())
}
