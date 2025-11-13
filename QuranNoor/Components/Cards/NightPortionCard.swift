//
//  NightPortionCard.swift
//  QuranNoor
//
//  Card showing the divisions of the night (for Tahajjud/Qiyam)
//

import SwiftUI

struct NightPortionCard: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let sunset: Date
    let midnight: Date?
    let lastThird: Date?
    let sunrise: Date

    // MARK: - Body
    var body: some View {
        LiquidGlassCardView(showPattern: true, intensity: .moderate) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary.gold)

                    ThemedText("Night Portions", style: .heading)
                        .foregroundColor(AppColors.primary.gold)

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
                            color: AppColors.primary.teal
                        )
                    }

                    if let lastThird = lastThird {
                        timeRow(
                            icon: "sparkles",
                            label: "Last Third Begins",
                            time: lastThird,
                            color: AppColors.primary.green,
                            highlighted: true
                        )

                        ThemedText.caption("The most virtuous time for Tahajjud prayer")
                            .foregroundColor(AppColors.primary.green)
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
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.textColor.opacity(0.1))
                    .frame(height: 40)

                // Night duration gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.midnight.opacity(0.5),
                                AppColors.primary.teal.opacity(0.3),
                                AppColors.primary.green.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 40)

                // Markers
                HStack(spacing: 0) {
                    // Sunset marker
                    marker(label: "Sunset", position: 0, width: width)

                    Spacer()

                    // Midnight marker (if available)
                    if midnight != nil {
                        marker(label: "Midnight", position: 0.5, width: width)
                        Spacer()
                    }

                    // Last third marker (if available)
                    if lastThird != nil {
                        marker(label: "Last 1/3", position: lastThirdPosition, width: width, highlight: true)
                        Spacer()
                    }

                    // Sunrise marker
                    marker(label: "Sunrise", position: 1, width: width)
                }
            }
        }
        .frame(height: 60)
    }

    private func marker(label: String, position: CGFloat, width: CGFloat, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(highlight ? AppColors.primary.green : themeManager.currentTheme.textColor)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 9, weight: highlight ? .bold : .regular))
                .foregroundColor(highlight ? AppColors.primary.green : themeManager.currentTheme.textColor)
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
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)

            ThemedText.body(label)
                .foregroundColor(highlighted ? color : themeManager.currentTheme.textColor)

            Spacer()

            Text(formatTime(time))
                .font(.system(size: 16, weight: highlighted ? .semibold : .regular))
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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Night Portion Info
struct CompactNightPortionInfo: View {
    let lastThird: Date?

    var body: some View {
        if let lastThird = lastThird {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary.green)

                VStack(alignment: .leading, spacing: 2) {
                    ThemedText.caption("Best time for Tahajjud")
                        .opacity(0.7)

                    Text("Begins at \(formatTime(lastThird))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primary.green)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary.green.opacity(0.1))
            )
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
