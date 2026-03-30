//
//  QuranProgressWidget.swift
//  QuranNoorWidgets
//
//  Quran reading progress widget + lock screen streak widget.
//
//  Home screen:
//    systemSmall  — completion ring + streak + current juz
//    systemMedium — ring + streak + last read + verses today
//
//  Lock screen:
//    accessoryCircular — flame + streak count OR progress ring
//

import SwiftUI
import WidgetKit

// MARK: - Widget Definition

struct QuranProgressWidget: Widget {
    let kind: String = "QuranProgressWidget"

    static var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium]
        #if os(iOS)
        families.append(.accessoryCircular)
        #endif
        return families
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProgressProvider()) { entry in
            QuranProgressWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    QuranWidgetBackground()
                }
        }
        .configurationDisplayName("Quran Progress")
        .description("Track your Quran reading streak, progress, and daily goals.")
        .supportedFamilies(QuranProgressWidget.supportedFamilies)
    }
}

// MARK: - Entry View Router

struct QuranProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ReadingTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuranWidget(entry: entry)
        case .systemMedium:
            MediumQuranWidget(entry: entry)
        case .accessoryCircular:
            CircularStreakWidget(entry: entry)
        default:
            SmallQuranWidget(entry: entry)
        }
    }
}

// MARK: - Background

struct QuranWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.12, blue: 0.18),
                Color(red: 0.08, green: 0.18, blue: 0.22),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared Constants

private let progressTeal = Color(red: 0.08, green: 1.0, blue: 0.93)   // #14FFEC
private let goldAccent = Color(red: 0.78, green: 0.65, blue: 0.40)     // #C7A566
private let streakOrange = Color(red: 1.0, green: 0.60, blue: 0.20)

// MARK: - Small Widget (Progress Ring + Streak)

struct SmallQuranWidget: View {
    let entry: ReadingTimelineEntry
    private let data: WidgetReadingEntry

    init(entry: ReadingTimelineEntry) {
        self.entry = entry
        self.data = entry.readingData
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 64, height: 64)

                // Progress ring
                Circle()
                    .trim(from: 0, to: data.completionFraction)
                    .stroke(
                        progressTeal,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 0) {
                    Text("\(Int(data.overallCompletion))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(progressTeal)
                    Text("Quran")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Stats row
            HStack(spacing: 12) {
                // Streak
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(data.streakDays > 0 ? streakOrange : .white.opacity(0.3))
                    Text("\(data.streakDays)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Juz
                HStack(spacing: 3) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(goldAccent)
                    Text("Juz \(data.currentJuz)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .widgetURL(URL(string: "qurannoor://quran"))
    }
}

// MARK: - Medium Widget (Detailed Progress)

struct MediumQuranWidget: View {
    let entry: ReadingTimelineEntry
    private let data: WidgetReadingEntry

    init(entry: ReadingTimelineEntry) {
        self.entry = entry
        self.data = entry.readingData
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 7)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: data.completionFraction)
                    .stroke(
                        AngularGradient(
                            colors: [progressTeal, goldAccent, progressTeal],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(data.overallCompletion))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(progressTeal)
                    Text("Complete")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Right: Stats
            VStack(alignment: .leading, spacing: 8) {
                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(data.streakDays > 0 ? streakOrange : .white.opacity(0.3))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(data.streakDays) day streak")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        if data.versesReadToday > 0 {
                            Text("\(data.versesReadToday) verses today")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                // Current Juz with mini progress
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(goldAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Juz \(data.currentJuz) of 30")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        // Juz progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(goldAccent)
                                    .frame(width: geo.size.width * data.juzProgress, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }

                // Last read location
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(progressTeal.opacity(0.7))
                    Text(data.lastReadLocation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                // Total verses
                Text("\(data.totalVersesRead) of 6,236 verses read")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(2)
        .widgetURL(URL(string: "qurannoor://quran"))
    }
}

// MARK: - Lock Screen: Circular (Streak)

struct CircularStreakWidget: View {
    let entry: ReadingTimelineEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .widgetAccentable()
                Text("\(entry.readingData.streakDays)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("days")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    QuranProgressWidget()
} timeline: {
    ReadingTimelineEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    QuranProgressWidget()
} timeline: {
    ReadingTimelineEntry.placeholder
}

#if os(iOS)
#Preview("Streak Lock Screen", as: .accessoryCircular) {
    QuranProgressWidget()
} timeline: {
    ReadingTimelineEntry.placeholder
}
#endif
