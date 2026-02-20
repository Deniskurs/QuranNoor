//
//  ReadingProgressCard.swift
//  QuranNoor
//
//  Created by Claude Code
//  Quran reading progress card with chart
//

import SwiftUI

struct ReadingProgressCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let stats: DailyStats
    let onContinue: () -> Void

    var body: some View {
        CardView(showPattern: true, intensity: .moderate) {
            if stats.totalVersesRead == 0 {
                // Encouraging empty state for new users
                emptyStateView
            } else {
                // Regular progress view
                progressView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Views

    /// Encouraging empty state for new users
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Crescent moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.accentMuted)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Begin Your Journey")
                    .font(.title3.bold())
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("Every journey begins with a single verse")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Start reading button
            Button(action: {
                HapticManager.shared.trigger(.light)
                onContinue()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "book.pages")
                    Text("Read Al-Fatiha")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeManager.currentTheme.accent)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)

            Text("6,236 verses await")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, Spacing.cardPadding)
    }

    /// Regular progress view with stats
    private var progressView: some View {
        VStack(alignment: .leading, spacing: Spacing.cardSpacing) { // Enhanced from 16 to 20
            // Header
            HStack {
                Image(systemName: "book.pages.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.accentMuted)

                Text("Quran Progress")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                // Overall completion percentage
                Text(stats.progressPercentage)
                    .font(.title3.bold())
                    .foregroundColor(themeManager.currentTheme.accentMuted)
            }

            // Progress ring
            HStack(spacing: Spacing.md) { // Enhanced from 20 to 24
                // Large progress ring
                QuranProgressRing(
                    versesRead: stats.totalVersesRead,
                    totalVerses: 6236,
                    size: 110 // Enhanced from 100
                )

                // Stats
                VStack(alignment: .leading, spacing: Spacing.xs) { // Enhanced from 8 to 12
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
                    Button(action: onContinue) {
                        HStack(spacing: 6) {
                            Text("Continue")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.subheadline)
                        }
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                    }
                }
            }
        }
        .padding(Spacing.cardPadding) // Standardized to 24pt (was 20pt)
    }

    // MARK: - Helper Views

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) { // Enhanced from 8
            Image(systemName: icon)
                .font(.system(size: 14)) // Enhanced from caption
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .frame(width: 18) // Enhanced from 16

            Text(label)
                .font(.system(size: 13, weight: .medium)) // Enhanced from caption
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold)) // Enhanced from caption
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
    ReadingProgressCard(stats: DailyStats.preview, onContinue: {
        #if DEBUG
        print("Continue tapped")
        #endif
    })
    .environment(ThemeManager())
    .padding()
    .background(ThemeMode.light.backgroundColor)
}

#Preview("Active User") {
    ReadingProgressCard(stats: DailyStats.activeUser, onContinue: {
        #if DEBUG
        print("Continue tapped")
        #endif
    })
    .environment(ThemeManager())
    .padding()
    .background(ThemeMode.light.backgroundColor)
}

#Preview("Empty State") {
    ReadingProgressCard(stats: DailyStats.emptyState, onContinue: {
        #if DEBUG
        print("Continue tapped")
        #endif
    })
    .environment(ThemeManager())
    .padding()
    .background(ThemeMode.light.backgroundColor)
}

#Preview("Dark Mode") {
    ReadingProgressCard(stats: DailyStats.preview, onContinue: {
        #if DEBUG
        print("Continue tapped")
        #endif
    })
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .padding()
    .background(ThemeMode.dark.backgroundColor)
}
