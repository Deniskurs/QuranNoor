//
//  PrayerTimesWidget.swift
//  QuranNoorWidgets
//
//  Prayer times widget supporting home screen + lock screen families.
//
//  Home screen:
//    systemSmall     — next prayer + live countdown
//    systemMedium    — all 5 prayers grid with current highlighted
//    systemLarge     — full prayer dashboard with special times
//
//  Lock screen:
//    accessoryCircular     — prayer icon + countdown ring
//    accessoryRectangular  — prayer name + time + countdown
//    accessoryInline       — single-line "Maghrib 6:45 PM"
//

import SwiftUI
import WidgetKit

// MARK: - Widget Definition

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    static var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        #if os(iOS)
        families.append(contentsOf: [.accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
        return families
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground(entry: entry)
                }
        }
        .configurationDisplayName("Prayer Times")
        .description("Stay connected with your daily prayer times and countdowns.")
        .supportedFamilies(PrayerTimesWidget.supportedFamilies)
    }
}

// MARK: - Entry View Router

struct PrayerTimesWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PrayerTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPrayerWidget(entry: entry)
        case .systemMedium:
            MediumPrayerWidget(entry: entry)
        case .systemLarge:
            LargePrayerWidget(entry: entry)
        case .accessoryCircular:
            CircularPrayerWidget(entry: entry)
        case .accessoryRectangular:
            RectangularPrayerWidget(entry: entry)
        case .accessoryInline:
            InlinePrayerWidget(entry: entry)
        default:
            SmallPrayerWidget(entry: entry)
        }
    }
}

// MARK: - Widget Background

struct WidgetBackground: View {
    let entry: PrayerTimelineEntry

    var body: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundColors: [Color] {
        let hour = Calendar.current.component(.hour, from: entry.date)
        switch hour {
        case 4..<7:   // Fajr time - deep blue to purple
            return [Color(red: 0.08, green: 0.09, blue: 0.22), Color(red: 0.15, green: 0.10, blue: 0.30)]
        case 7..<12:  // Morning - warm cream
            return [Color(red: 0.97, green: 0.95, blue: 0.90), Color(red: 0.93, green: 0.90, blue: 0.82)]
        case 12..<15: // Afternoon - warm gold
            return [Color(red: 0.96, green: 0.93, blue: 0.85), Color(red: 0.92, green: 0.88, blue: 0.78)]
        case 15..<18: // Late afternoon - amber tones
            return [Color(red: 0.95, green: 0.90, blue: 0.80), Color(red: 0.88, green: 0.82, blue: 0.70)]
        case 18..<20: // Maghrib - sunset orange to deep blue
            return [Color(red: 0.20, green: 0.15, blue: 0.30), Color(red: 0.12, green: 0.10, blue: 0.25)]
        default:      // Night - deep midnight
            return [Color(red: 0.10, green: 0.14, blue: 0.20), Color(red: 0.06, green: 0.08, blue: 0.15)]
        }
    }
}

// MARK: - Adaptive Text Color

private var adaptiveTextPrimary: Color {
    // Widget system handles light/dark automatically via environment
    // Using semantic colors that work well on gradient backgrounds
    .primary
}

private var adaptiveTextSecondary: Color {
    .secondary
}

// MARK: - Shared Constants

private let accentTeal = Color(red: 0.05, green: 0.45, blue: 0.47)     // #0D7377
private let accentGold = Color(red: 0.78, green: 0.65, blue: 0.40)     // #C7A566
private let accentBrightTeal = Color(red: 0.08, green: 1.0, blue: 0.93) // #14FFEC

// MARK: - Small Widget (Next Prayer + Countdown)

struct SmallPrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry
    private let isDark: Bool

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
        let hour = Calendar.current.component(.hour, from: entry.date)
        self.isDark = hour < 7 || hour >= 18
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Location
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 8))
                Text(data.location)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isDark ? .white.opacity(0.7) : .secondary)

            Spacer()

            if let next = data.nextPrayer(after: entry.date) {
                // Prayer icon + name
                HStack(spacing: 6) {
                    Image(systemName: next.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                    Text(next.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isDark ? .white : .primary)
                }

                // Prayer time
                Text(next.time, style: .time)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDark ? .white.opacity(0.8) : .secondary)

                // Live countdown
                Text(next.time, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                    .contentTransition(.numericText(countsDown: true))
            } else {
                // All prayers passed
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                Text("All prayers\ncompleted")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDark ? .white : .primary)
            }

            Spacer()

            // Completion dots
            HStack(spacing: 4) {
                ForEach(data.orderedPrayers, id: \.name) { prayer in
                    Circle()
                        .fill(data.isCompleted(prayer.name)
                              ? (isDark ? accentBrightTeal : accentTeal)
                              : (isDark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)))
                        .frame(width: 6, height: 6)
                }
                Spacer()
                Text("\(data.completedCount)/5")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isDark ? .white.opacity(0.6) : .secondary)
            }
        }
        .padding(2)
        .widgetURL(URL(string: "qurannoor://prayers"))
    }
}

// MARK: - Medium Widget (All Prayer Times Grid)

struct MediumPrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry
    private let isDark: Bool
    private let nextPrayerName: String?

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
        let hour = Calendar.current.component(.hour, from: entry.date)
        self.isDark = hour < 7 || hour >= 18
        self.nextPrayerName = entry.prayerData.nextPrayer(after: entry.date)?.name
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text(data.location)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(isDark ? .white.opacity(0.7) : .secondary)

                Spacer()

                if !data.displayHijriDate.isEmpty {
                    Text(data.displayHijriDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isDark ? accentBrightTeal.opacity(0.8) : accentTeal.opacity(0.8))
                }
            }

            // Next prayer countdown (if available)
            if let next = data.nextPrayer(after: entry.date) {
                HStack(spacing: 6) {
                    Image(systemName: next.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                    Text("Next: \(next.name)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isDark ? .white : .primary)
                    Text(next.time, style: .timer)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                        .contentTransition(.numericText(countsDown: true))
                    Spacer()
                }
            }

            // 5-column prayer grid
            HStack(spacing: 0) {
                ForEach(data.orderedPrayers, id: \.name) { prayer in
                    prayerColumn(prayer: prayer)
                    if prayer.name != "Isha" {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(2)
        .widgetURL(URL(string: "qurannoor://prayers"))
    }

    @ViewBuilder
    private func prayerColumn(prayer: (name: String, icon: String, time: Date)) -> some View {
        let isNext = nextPrayerName == prayer.name
        let isPast = prayer.time <= entry.date
        let isCompleted = data.isCompleted(prayer.name)

        VStack(spacing: 4) {
            // Icon
            Image(systemName: prayer.icon)
                .font(.system(size: 14, weight: isNext ? .bold : .regular))
                .foregroundStyle(
                    isNext ? (isDark ? accentBrightTeal : accentTeal) :
                    isPast ? (isDark ? .white.opacity(0.4) : .gray.opacity(0.5)) :
                    (isDark ? .white.opacity(0.7) : .primary.opacity(0.7))
                )

            // Name
            Text(prayer.name)
                .font(.system(size: 10, weight: isNext ? .bold : .medium))
                .foregroundStyle(
                    isNext ? (isDark ? .white : .primary) :
                    isPast ? (isDark ? .white.opacity(0.4) : .secondary) :
                    (isDark ? .white.opacity(0.8) : .primary.opacity(0.8))
                )

            // Time
            Text(prayer.time, style: .time)
                .font(.system(size: 11, weight: isNext ? .bold : .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    isNext ? (isDark ? accentBrightTeal : accentTeal) :
                    (isDark ? .white.opacity(0.6) : .secondary)
                )

            // Completion dot
            Circle()
                .fill(isCompleted
                      ? (isDark ? accentBrightTeal : accentTeal)
                      : (isDark ? .white.opacity(0.15) : .gray.opacity(0.2)))
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            isNext ?
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDark ? Color.white.opacity(0.08) : accentTeal.opacity(0.08))
            : nil
        )
    }
}

// MARK: - Large Widget (Full Prayer Dashboard)

struct LargePrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry
    private let isDark: Bool
    private let nextPrayerName: String?

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
        let hour = Calendar.current.component(.hour, from: entry.date)
        self.isDark = hour < 7 || hour >= 18
        self.nextPrayerName = entry.prayerData.nextPrayer(after: entry.date)?.name
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header with location and Hijri date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(data.location)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isDark ? .white.opacity(0.8) : .primary)

                    if !data.displayHijriDate.isEmpty {
                        Text(data.displayHijriDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isDark ? accentBrightTeal.opacity(0.7) : accentTeal.opacity(0.8))
                    }
                }

                Spacer()

                // Completion badge
                VStack(spacing: 2) {
                    Text("\(data.completedCount)/5")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                    Text("Prayed")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isDark ? .white.opacity(0.6) : .secondary)
                }
            }

            // Next prayer hero section
            if let next = data.nextPrayer(after: entry.date) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Prayer")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isDark ? .white.opacity(0.6) : .secondary)
                            .textCase(.uppercase)
                        HStack(spacing: 8) {
                            Image(systemName: next.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(next.name)
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundStyle(isDark ? .white : .primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(next.time, style: .time)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isDark ? .white.opacity(0.7) : .secondary)
                        Text(next.time, style: .timer)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(isDark ? accentBrightTeal : accentTeal)
                            .contentTransition(.numericText(countsDown: true))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDark ? Color.white.opacity(0.06) : accentTeal.opacity(0.06))
                )
            }

            // Prayer times list
            VStack(spacing: 6) {
                ForEach(data.orderedPrayers, id: \.name) { prayer in
                    prayerRow(prayer: prayer)
                }
            }

            // Special times
            if data.lastThird != nil || data.midnight != nil {
                Divider()
                    .background(isDark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))

                HStack(spacing: 16) {
                    if let lastThird = data.lastThird {
                        specialTimeItem(name: "Last Third", icon: "sparkles", time: lastThird)
                    }
                    if let midnight = data.midnight {
                        specialTimeItem(name: "Midnight", icon: "moon.stars", time: midnight)
                    }
                    if let imsak = data.imsak {
                        specialTimeItem(name: "Imsak", icon: "moon.fill", time: imsak)
                    }
                    Spacer()
                }
            }
        }
        .padding(2)
        .widgetURL(URL(string: "qurannoor://prayers"))
    }

    @ViewBuilder
    private func prayerRow(prayer: (name: String, icon: String, time: Date)) -> some View {
        let isNext = nextPrayerName == prayer.name
        let isPast = prayer.time <= entry.date
        let isCompleted = data.isCompleted(prayer.name)

        HStack {
            // Completion indicator
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(
                    isCompleted ? (isDark ? accentBrightTeal : accentTeal) :
                    (isDark ? .white.opacity(0.2) : .gray.opacity(0.3))
                )

            Image(systemName: prayer.icon)
                .font(.system(size: 13))
                .foregroundStyle(
                    isNext ? (isDark ? accentBrightTeal : accentTeal) :
                    isPast ? (isDark ? .white.opacity(0.4) : .gray.opacity(0.5)) :
                    (isDark ? .white.opacity(0.7) : .primary.opacity(0.7))
                )
                .frame(width: 20)

            Text(prayer.name)
                .font(.system(size: 14, weight: isNext ? .bold : .medium))
                .foregroundStyle(
                    isNext ? (isDark ? .white : .primary) :
                    isPast ? (isDark ? .white.opacity(0.5) : .secondary) :
                    (isDark ? .white.opacity(0.8) : .primary)
                )

            Spacer()

            Text(prayer.time, style: .time)
                .font(.system(size: 14, weight: isNext ? .bold : .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    isNext ? (isDark ? accentBrightTeal : accentTeal) :
                    (isDark ? .white.opacity(0.6) : .secondary)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isNext ?
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDark ? Color.white.opacity(0.06) : accentTeal.opacity(0.06))
            : nil
        )
    }

    @ViewBuilder
    private func specialTimeItem(name: String, icon: String, time: Date) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 9, weight: .medium))
            Text(time, style: .time)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(isDark ? .white.opacity(0.5) : .secondary)
    }
}

// MARK: - Lock Screen: Circular (Prayer Progress Gauge)

struct CircularPrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
    }

    /// How far through the 5-prayer day: 0.0 (before Fajr) → 1.0 (after Isha)
    private var dayProgress: Double {
        let prayers = data.orderedPrayers
        guard let nextIdx = prayers.firstIndex(where: { $0.time > entry.date }) else {
            return 1.0
        }
        return Double(nextIdx) / Double(prayers.count)
    }

    private func prayerAbbrev(_ name: String) -> String {
        switch name {
        case "Fajr": return "FJR"
        case "Dhuhr": return "DHR"
        case "Asr": return "ASR"
        case "Maghrib": return "MGH"
        case "Isha": return "ISH"
        default: return String(name.prefix(3)).uppercased()
        }
    }

    var body: some View {
        if let next = data.nextPrayer(after: entry.date) {
            // Gauge ring showing prayer day progress + next prayer abbreviation
            Gauge(value: dayProgress) {
                Text(prayerAbbrev(next.name))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            } currentValueLabel: {
                Text(next.time, style: .timer)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
            .widgetURL(URL(string: "qurannoor://prayers"))
        } else {
            // All prayers passed — show completion
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: data.completedCount == 5
                          ? "checkmark.seal.fill"
                          : "moon.stars.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .widgetAccentable()
                    Text("\(data.completedCount)/5")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
            }
            .widgetURL(URL(string: "qurannoor://prayers"))
        }
    }
}

// MARK: - Lock Screen: Rectangular (Hijri + Prayer + Countdown)

struct RectangularPrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
    }

    private var hijriDisplay: String {
        data.displayHijriDate
    }

    var body: some View {
        if let next = data.nextPrayer(after: entry.date) {
            VStack(alignment: .leading, spacing: 2) {
                // Line 1: Hijri date with decorative moon
                if !hijriDisplay.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 9))
                        Text(hijriDisplay)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                // Line 2: Next prayer with icon + time
                HStack(spacing: 4) {
                    Image(systemName: next.icon)
                        .font(.system(size: 11))
                        .widgetAccentable()
                    Text(next.name)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text(next.time, style: .time)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }
                .lineLimit(1)

                // Line 3: Live countdown with prayer completion dots
                HStack(spacing: 0) {
                    Text(next.time, style: .timer)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))

                    Spacer()

                    // Mini prayer completion indicators
                    HStack(spacing: 3) {
                        ForEach(data.orderedPrayers, id: \.name) { prayer in
                            Image(systemName: data.isCompleted(prayer.name)
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .font(.system(size: 7))
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(URL(string: "qurannoor://prayers"))
        } else {
            // All prayers passed — show actual completion status
            VStack(alignment: .leading, spacing: 2) {
                // Line 1: Hijri date
                if !hijriDisplay.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 9))
                        Text(hijriDisplay)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                // Line 2: Actual completion count
                HStack(spacing: 4) {
                    Image(systemName: data.completedCount == 5
                          ? "checkmark.seal.fill"
                          : "circle.dotted")
                        .font(.system(size: 11))
                        .widgetAccentable()
                    Text(data.completedCount == 5
                         ? "All 5 Prayers Done"
                         : "\(data.completedCount) of 5 Prayed")
                        .font(.system(size: 13, weight: .bold))
                }

                // Line 3: Completion dots or motivational text
                HStack(spacing: 0) {
                    if data.completedCount == 5 {
                        Text("ما شاء الله")
                            .font(.system(size: 12, weight: .medium))
                    } else {
                        // Show which prayers are complete
                        HStack(spacing: 4) {
                            ForEach(data.orderedPrayers, id: \.name) { prayer in
                                HStack(spacing: 1) {
                                    Image(systemName: data.isCompleted(prayer.name)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .font(.system(size: 7))
                                    Text(String(prayer.name.prefix(1)))
                                        .font(.system(size: 8, weight: .medium))
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(URL(string: "qurannoor://prayers"))
        }
    }
}

// MARK: - Lock Screen: Inline (Hijri Date)

struct InlinePrayerWidget: View {
    let entry: PrayerTimelineEntry
    private let data: WidgetPrayerEntry

    init(entry: PrayerTimelineEntry) {
        self.entry = entry
        self.data = entry.prayerData
    }

    /// SF Symbol name matching the real lunar phase for the entry date
    private var moonPhaseIcon: String {
        // Known new moon: Jan 6 2000 00:00 UTC
        let knownNewMoon = Date(timeIntervalSince1970: 947_116_800)
        let lunarCycle = 29.53059 // days
        let daysSince = entry.date.timeIntervalSince(knownNewMoon) / 86400
        let phase = daysSince.truncatingRemainder(dividingBy: lunarCycle)
        let normalized = phase < 0 ? phase + lunarCycle : phase
        let segment = lunarCycle / 8

        switch normalized {
        case 0 ..< segment:             return "moonphase.new.moon"
        case segment ..< segment * 2:   return "moonphase.waxing.crescent"
        case segment * 2 ..< segment * 3: return "moonphase.first.quarter"
        case segment * 3 ..< segment * 4: return "moonphase.waxing.gibbous"
        case segment * 4 ..< segment * 5: return "moonphase.full.moon"
        case segment * 5 ..< segment * 6: return "moonphase.waning.gibbous"
        case segment * 6 ..< segment * 7: return "moonphase.last.quarter"
        default:                         return "moonphase.waning.crescent"
        }
    }

    var body: some View {
        Text("\(Image(systemName: moonPhaseIcon)) \(data.displayHijriDate)")
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}

#if os(iOS)
#Preview("Lock Screen Circular", as: .accessoryCircular) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}

#Preview("Lock Screen Inline", as: .accessoryInline) {
    PrayerTimesWidget()
} timeline: {
    PrayerTimelineEntry.placeholder
}
#endif
