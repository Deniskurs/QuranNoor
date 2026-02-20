//
//  PrayerTimeCard.swift
//  QuranNoor
//
//  Specialized card for displaying prayer times with countdown and progress ring
//

import SwiftUI

// MARK: - Cached Formatter (Performance: avoid repeated allocation)
private let prayerTimeShortFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

// MARK: - Prayer Time Card Status
enum PrayerTimeStatus {
    case upcoming   // Future prayer
    case current    // Active/next prayer
    case passed     // Past prayer
}

// MARK: - Prayer Time Card Component
struct PrayerTimeCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let prayerName: String
    let time: Date
    let status: PrayerTimeStatus
    let countdown: String?
    let progress: Double?
    let onTap: (() -> Void)?

    // MARK: - Initializer
    init(
        prayerName: String,
        time: Date,
        status: PrayerTimeStatus = .upcoming,
        countdown: String? = nil,
        progress: Double? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.prayerName = prayerName
        self.time = time
        self.status = status
        self.countdown = countdown
        self.progress = progress
        self.onTap = onTap
    }

    // MARK: - Body
    var body: some View {
        Button(action: { onTap?() }) {
            CardView(showPattern: status == .current, intensity: status == .current ? .prominent : .subtle) {
                HStack(spacing: 16) {
                    // Left: Prayer info
                    VStack(alignment: .leading, spacing: 8) {
                        // Status badge
                        if status == .current {
                            Text("NEXT")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.currentTheme.accent)
                                .cornerRadius(6)
                        }

                        // Prayer name
                        ThemedText(
                            prayerName,
                            style: .heading,
                            color: status == .current ? themeManager.currentTheme.accent : nil
                        )

                        // Time
                        Text(formattedTime)
                            .font(.title.weight(.ultraLight))
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        // Countdown (if current)
                        if let countdown = countdown, status == .current {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text(countdown)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(themeManager.currentTheme.accent)
                        }
                    }

                    Spacer()

                    // Right: Progress ring or icon
                    if let progress = progress, status == .current {
                        ProgressRing(
                            progress: progress,
                            lineWidth: 6,
                            size: 80,
                            showPercentage: false,
                            color: themeManager.currentTheme.accent
                        )
                    } else {
                        // Prayer icon
                        Image(systemName: prayerIcon)
                            .font(.largeTitle)
                            .foregroundColor(iconColor)
                            .opacity(status == .passed ? 0.3 : 1.0)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }

    // MARK: - Formatted Time
    private var formattedTime: String {
        prayerTimeShortFormatter.string(from: time)
    }

    // MARK: - Prayer Icons
    private var prayerIcon: String {
        switch prayerName.lowercased() {
        case "fajr":
            return "sunrise.fill"
        case "dhuhr":
            return "sun.max.fill"
        case "asr":
            return "sun.min.fill"
        case "maghrib":
            return "sunset.fill"
        case "isha":
            return "moon.stars.fill"
        default:
            return "moon.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .current:
            return themeManager.currentTheme.accent
        case .upcoming:
            return themeManager.currentTheme.accentMuted.opacity(0.6)
        case .passed:
            return themeManager.currentTheme.textPrimary
        }
    }
}

// MARK: - Compact Prayer Time Card
struct CompactPrayerTimeCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let prayerName: String
    let time: Date
    let isNext: Bool

    // MARK: - Body
    var body: some View {
        HStack {
            // Prayer name
            ThemedText(
                prayerName,
                style: .body,
                color: isNext ? themeManager.currentTheme.accent : nil
            )

            Spacer()

            // Time
            Text(formattedTime)
                .font(.body.weight(isNext ? .semibold : .regular))
                .foregroundColor(isNext ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary)

            // Next indicator
            if isNext {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.accent)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isNext ? themeManager.currentTheme.accent.opacity(0.1) : Color.clear)
        )
    }

    private var formattedTime: String {
        prayerTimeShortFormatter.string(from: time)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Current prayer with countdown
            PrayerTimeCard(
                prayerName: "Asr",
                time: Date().addingTimeInterval(3600),
                status: .current,
                countdown: "in 45 minutes",
                progress: 0.67
            ) {
                print("Asr tapped")
            }

            // Upcoming prayers
            PrayerTimeCard(
                prayerName: "Maghrib",
                time: Date().addingTimeInterval(7200),
                status: .upcoming
            )

            PrayerTimeCard(
                prayerName: "Isha",
                time: Date().addingTimeInterval(10800),
                status: .upcoming
            )

            // Passed prayer
            PrayerTimeCard(
                prayerName: "Dhuhr",
                time: Date().addingTimeInterval(-3600),
                status: .passed
            )

            Divider()
                .padding(.vertical)

            // Compact cards
            VStack(spacing: 8) {
                CompactPrayerTimeCard(
                    prayerName: "Fajr",
                    time: Date().addingTimeInterval(-14400),
                    isNext: false
                )

                CompactPrayerTimeCard(
                    prayerName: "Dhuhr",
                    time: Date().addingTimeInterval(1800),
                    isNext: true
                )

                CompactPrayerTimeCard(
                    prayerName: "Asr",
                    time: Date().addingTimeInterval(5400),
                    isNext: false
                )
            }
        }
        .padding()
    }
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
