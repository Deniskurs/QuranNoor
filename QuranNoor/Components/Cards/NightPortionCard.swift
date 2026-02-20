//
//  NightPortionCard.swift
//  QuranNoor
//
//  Card showing the divisions of the night (for Tahajjud/Qiyam)
//

import SwiftUI

// MARK: - Cached Formatter (Performance: avoid repeated allocation)
private let nightPortionTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

struct NightPortionCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let sunset: Date
    let midnight: Date?
    let lastThird: Date?
    let sunrise: Date

    // MARK: - Body
    var body: some View {
        CardView(showPattern: true, intensity: .moderate) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.accentMuted)

                    ThemedText("Night Portions", style: .heading)
                        .foregroundColor(themeManager.currentTheme.accentMuted)

                    Spacer()
                }

                ThemedText.caption("Best times for voluntary night prayers (Tahajjud/Qiyam)")
                    .opacity(0.7)

                IslamicDivider(style: .geometric)

                // Visual timeline
                nightTimeline

                // Time details
                VStack(spacing: 12) {
                    if let midnight = midnight {
                        timeRow(
                            icon: "moon.stars",
                            label: "Islamic Midnight",
                            time: midnight,
                            color: themeManager.currentTheme.accent
                        )
                    }

                    if let lastThird = lastThird {
                        timeRow(
                            icon: "sparkles",
                            label: "Last Third Begins",
                            time: lastThird,
                            color: themeManager.currentTheme.accent,
                            highlighted: true
                        )

                        ThemedText.caption("The most virtuous time for Tahajjud prayer")
                            .foregroundColor(themeManager.currentTheme.accent)
                            .padding(.leading, 44)
                            .opacity(0.8)
                    }
                }
            }
        }
    }

    // MARK: - Timeline View
    private var nightTimeline: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.textPrimary.opacity(0.1))
                    .frame(height: 40)

                // Night duration gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.textPrimary.opacity(0.5),
                                themeManager.currentTheme.accent.opacity(0.3),
                                themeManager.currentTheme.accent.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 40)

                // Markers
                HStack(spacing: 0) {
                    // Sunset marker
                    marker(label: "Sunset")

                    Spacer()

                    // Midnight marker (if available)
                    if midnight != nil {
                        marker(label: "Midnight")
                        Spacer()
                    }

                    // Last third marker (if available)
                    if lastThird != nil {
                        marker(label: "Last 1/3", highlight: true)
                        Spacer()
                    }

                    // Sunrise marker
                    marker(label: "Sunrise")
                }
            }
        }
        .frame(height: 60)
    }

    private func marker(label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(highlight ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2.weight(highlight ? .bold : .regular))
                .foregroundColor(highlight ? themeManager.currentTheme.accent : themeManager.currentTheme.textPrimary)
                .opacity(highlight ? 1.0 : 0.7)
        }
    }

    private func timeRow(
        icon: String,
        label: String,
        time: Date,
        color: Color,
        highlighted: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 28)

            ThemedText.body(label)
                .foregroundColor(highlighted ? color : themeManager.currentTheme.textPrimary)

            Spacer()

            Text(formatTime(time))
                .font(.body.weight(highlighted ? .semibold : .regular))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(highlighted ? color.opacity(0.1) : Color.clear)
        )
    }

    // MARK: - Helpers
    private var lastThirdPosition: CGFloat {
        // Last third starts at 2/3 of the night
        return 0.67
    }

    private func formatTime(_ date: Date) -> String {
        nightPortionTimeFormatter.string(from: date)
    }
}

// MARK: - Compact Night Portion Info
struct CompactNightPortionInfo: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let lastThird: Date?

    var body: some View {
        if let lastThird = lastThird {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    ThemedText.caption("Best time for Tahajjud")
                        .opacity(0.7)

                    Text("Begins at \(formatTime(lastThird))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.currentTheme.accent)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.accent.opacity(0.1))
            )
        }
    }

    private func formatTime(_ date: Date) -> String {
        nightPortionTimeFormatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            NightPortionCard(
                sunset: Date().addingTimeInterval(-3600),
                midnight: Date().addingTimeInterval(3600),
                lastThird: Date().addingTimeInterval(7200),
                sunrise: Date().addingTimeInterval(14400)
            )

            CompactNightPortionInfo(
                lastThird: Date().addingTimeInterval(7200)
            )
        }
        .padding()
    }
    .background(ThemeManager().currentTheme.backgroundColor)
    .environment(ThemeManager())
}
