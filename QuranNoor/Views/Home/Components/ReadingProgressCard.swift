//
//  ReadingProgressCard.swift
//  QuranNoor
//
//  Created by Claude Code
//  Quran reading progress card with chart
//

import SwiftUI

struct ReadingProgressCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let stats: DailyStats

    var body: some View {
        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary.teal)

                    Text("Quran Progress")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Spacer()

                    // Overall completion percentage
                    Text(stats.progressPercentage)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.primary.teal)
                }

                // Progress ring
                HStack(spacing: 20) {
                    // Large progress ring
                    QuranProgressRing(
                        versesRead: stats.totalVersesRead,
                        totalVerses: 6236,
                        size: 100
                    )

                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        statRow(
                            icon: "text.alignleft",
                            label: "Verses Read",
                            value: "\(stats.totalVersesRead) / 6236"
                        )

                        statRow(
                            icon: "book.closed",
                            label: "Current Juz",
                            value: "Juz \(stats.currentJuz)"
                        )

                        statRow(
                            icon: "flame.fill",
                            label: "Streak",
                            value: stats.streakText
                        )
                    }
                }

                // Last read location
                if stats.lastReadSurahName != nil {
                    Divider()
                        .background(themeManager.currentTheme.textTertiary.opacity(0.3))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Read")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)

                            Text(stats.lastReadLocation)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }

                        Spacer()

                        // Continue reading button
                        Button(action: {
                            // Navigate to Quran tab and resume
                        }) {
                            HStack(spacing: 6) {
                                Text("Continue")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.subheadline)
                            }
                            .foregroundColor(AppColors.primary.teal)
                        }
                    }
                }
            }
            .padding(20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Helper Views

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textPrimary)
        }
    }

    // MARK: - Computed Properties

    private var accessibilityText: String {
        var text = "Quran progress: \(stats.progressPercentage) complete. "
        text += "\(stats.totalVersesRead) out of 6,236 verses read. "
        text += "Currently on Juz \(stats.currentJuz). "
        text += "\(stats.streakText). "

        if stats.lastReadSurahName != nil {
            text += "Last read: \(stats.lastReadLocation). "
        }

        return text
    }
}

// MARK: - Preview

#Preview("With Progress") {
    ReadingProgressCard(stats: DailyStats.preview)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Active User") {
    ReadingProgressCard(stats: DailyStats.activeUser)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Empty State") {
    ReadingProgressCard(stats: DailyStats.emptyState)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    ReadingProgressCard(stats: DailyStats.preview)
        .environmentObject({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
        .padding()
        .background(Color(hex: "#1A2332"))
}
