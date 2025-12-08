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
    let currentTime: Date  // Live time from TimelineView for real-time countdown
    let location: String
    let isLoadingLocation: Bool

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Fixed hero height (responsive via verticalSizeClass if needed)
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: - Body

    var body: some View {
        ZStack {
            // Time-of-day sky gradient background
            TimeOfDaySkyView()

            // Content overlay
            VStack(spacing: 16) {
                // Location header
                locationHeader
                    .padding(.top, 24)  // Increased from 8 to prevent clipping at top

                Spacer()

                // Current prayer name (large, centered)
                currentPrayerDisplay

                // Countdown timer - uses live currentTime for real-time updates
                HeroCountdownDisplay(
                    countdownString: liveCountdownString,
                    isUrgent: liveIsUrgent,
                    urgencyLevel: liveUrgencyLevel
                )

                // Status pill
                PrayerStatusPill(
                    state: period.state,
                    prayerTime: currentPrayerTime,
                    isUrgent: period.isUrgent
                )
                .padding(.top, 8)

                Spacer()
                    .frame(height: 16)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: heroShadowColor, radius: 20, x: 0, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(headerTextColor.opacity(0.7))
                    .tracking(1.5)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(formattedDate)
                    .font(.system(size: 13, weight: .medium))
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
        VStack(spacing: 6) {
            // Prayer icon
            Image(systemName: currentPrayerIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(prayerAccentColor)
                .shadow(color: prayerAccentColor.opacity(0.5), radius: 8)

            // Prayer name
            Text(currentPrayerName)
                .font(.system(size: 32, weight: .bold))
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

    // MARK: - Live Countdown (Real-time Updates)

    /// Compute countdown using live currentTime from TimelineView
    private var liveCountdownString: String {
        let deadline = period.state.nextEventTime
        let interval = max(deadline.timeIntervalSince(currentTime), 0)

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Live urgency check based on currentTime
    private var liveIsUrgent: Bool {
        let deadline = period.state.nextEventTime
        let remaining = deadline.timeIntervalSince(currentTime)
        return remaining > 0 && remaining <= 30 * 60  // 30 minutes
    }

    /// Live urgency level based on currentTime
    private var liveUrgencyLevel: UrgencyLevel {
        let deadline = period.state.nextEventTime
        let remaining = deadline.timeIntervalSince(currentTime)

        if remaining <= 0 {
            return .normal
        } else if remaining <= 5 * 60 {
            return .critical  // < 5 minutes
        } else if remaining <= 10 * 60 {
            return .urgent    // 5-10 minutes
        } else if remaining <= 30 * 60 {
            return .elevated  // 10-30 minutes
        } else {
            return .normal
        }
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
            return .orange
        }

        switch themeManager.currentTheme {
        case .light:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 6 && hour < 18) ? themeManager.currentTheme.accentPrimary : AppColors.primary.gold
        case .dark:
            return themeManager.currentTheme.accentSecondary
        case .night:
            return AppColors.primary.gold
        case .sepia:
            return themeManager.currentTheme.featureAccent
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
        currentTime: Date(),
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
        currentTime: Date(),
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
        currentTime: Date(),
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
