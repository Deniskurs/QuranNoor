//
//  RecentActivityFeed.swift
//  QuranNoor
//
//  Created by Claude Code
//  Recent activity timeline
//

import SwiftUI

struct RecentActivityFeed: View {
    @EnvironmentObject var themeManager: ThemeManager
    let bookmarks: [Bookmark]
    let lastReadSurah: String?
    let lastReadVerse: Int?
    let prayersCompleted: Int

    var body: some View {
        LiquidGlassCardView(intensity: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.cardSpacing) { // Enhanced from 16 to 20
                // Header
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.accentSecondary)

                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Spacer()

                    // View all button
                    Button(action: {
                        // Navigate to full activity view
                    }) {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentSecondary)
                    }
                }

                // Activity items
                if hasActivity {
                    VStack(alignment: .leading, spacing: Spacing.sm) { // Enhanced from 12 to 16
                        // Last read
                        if let surah = lastReadSurah, let verse = lastReadVerse {
                            ActivityRow(
                                icon: "book.fill",
                                iconColor: themeManager.currentTheme.accentSecondary,
                                title: "Read \(surah)",
                                subtitle: "Verse \(verse)",
                                timestamp: "Today"
                            )
                        }

                        // Recent bookmarks (show last 2)
                        ForEach(bookmarks.prefix(2)) { bookmark in
                            ActivityRow(
                                icon: "bookmark.fill",
                                iconColor: themeManager.currentTheme.accentInteractive,
                                title: "Bookmarked verse",
                                subtitle: "Surah \(bookmark.surahNumber):\(bookmark.verseNumber)",
                                timestamp: timeAgo(from: bookmark.timestamp)
                            )
                        }

                        // Prayers completed today
                        if prayersCompleted > 0 {
                            ActivityRow(
                                icon: "checkmark.circle.fill",
                                iconColor: themeManager.currentTheme.accentPrimary,
                                title: "Completed prayers",
                                subtitle: "\(prayersCompleted)/5 today",
                                timestamp: "Today"
                            )
                        }
                    }
                } else {
                    // Encouraging empty state
                    VStack(spacing: 16) {
                        Image(systemName: "book.circle")
                            .font(.system(size: 44))
                            .foregroundColor(themeManager.currentTheme.accentSecondary)

                        VStack(spacing: 6) {
                            Text("Your Story Starts Here")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimary)

                            Text("Complete your first prayer or read a verse to begin tracking your spiritual journey")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Encouraging call-to-action
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("Get Started")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(themeManager.currentTheme.accentSecondary)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
            .padding(Spacing.cardPadding) // Standardized to 24pt (was 20pt)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recent activity feed")
    }

    // MARK: - Computed Properties

    private var hasActivity: Bool {
        lastReadSurah != nil || !bookmarks.isEmpty || prayersCompleted > 0
    }

    // MARK: - Helper Methods

    private func timeAgo(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: Date())

        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let timestamp: String

    var body: some View {
        HStack(spacing: Spacing.sm) { // Enhanced from 12 to 16
            // Icon - larger and more refined
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12)) // Softer from 0.15
                    .frame(width: 48, height: 48) // Enhanced from 40

                Image(systemName: icon)
                    .font(.system(size: 18)) // Enhanced from 16
                    .foregroundColor(iconColor)
            }

            // Content - better hierarchy
            VStack(alignment: .leading, spacing: Spacing.xxxs) { // Enhanced from 2 to 4
                Text(title)
                    .font(.system(size: 15, weight: .semibold)) // Enhanced from subheadline
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular)) // Enhanced from caption
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Timestamp - refined
            Text(timestamp)
                .font(.system(size: 11, weight: .medium)) // Enhanced from caption2
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(.vertical, Spacing.xxxs) // Add vertical breathing room
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle). \(timestamp)")
    }
}

// MARK: - Preview

#Preview("With Activity") {
    RecentActivityFeed(
        bookmarks: [
            Bookmark(
                surahNumber: 2,
                verseNumber: 255,
                note: nil
            ),
            Bookmark(
                surahNumber: 18,
                verseNumber: 10,
                note: nil
            )
        ],
        lastReadSurah: "Al-Baqarah",
        lastReadVerse: 286,
        prayersCompleted: 4
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Empty State") {
    RecentActivityFeed(
        bookmarks: [],
        lastReadSurah: nil,
        lastReadVerse: nil,
        prayersCompleted: 0
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    RecentActivityFeed(
        bookmarks: [
            Bookmark(
                surahNumber: 2,
                verseNumber: 255,
                note: nil
            )
        ],
        lastReadSurah: "Al-Kahf",
        lastReadVerse: 110,
        prayersCompleted: 5
    )
    .environmentObject({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .padding()
    .background(Color(hex: "#1A2332"))
}
