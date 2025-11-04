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
        CardView(showPattern: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundColor(AppColors.primary.teal)

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
                            .foregroundColor(AppColors.primary.teal)
                    }
                }

                // Activity items
                if hasActivity {
                    VStack(alignment: .leading, spacing: 12) {
                        // Last read
                        if let surah = lastReadSurah, let verse = lastReadVerse {
                            ActivityRow(
                                icon: "book.fill",
                                iconColor: AppColors.primary.teal,
                                title: "Read \(surah)",
                                subtitle: "Verse \(verse)",
                                timestamp: "Today"
                            )
                        }

                        // Recent bookmarks (show last 2)
                        ForEach(bookmarks.prefix(2)) { bookmark in
                            ActivityRow(
                                icon: "bookmark.fill",
                                iconColor: AppColors.primary.gold,
                                title: "Bookmarked verse",
                                subtitle: "Surah \(bookmark.surahNumber):\(bookmark.verseNumber)",
                                timestamp: timeAgo(from: bookmark.timestamp)
                            )
                        }

                        // Prayers completed today
                        if prayersCompleted > 0 {
                            ActivityRow(
                                icon: "checkmark.circle.fill",
                                iconColor: AppColors.primary.green,
                                title: "Completed prayers",
                                subtitle: "\(prayersCompleted)/5 today",
                                timestamp: "Today"
                            )
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.currentTheme.textTertiary)

                        Text("No recent activity")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        Text("Start reading or mark prayers to see your activity here")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(20)
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
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Timestamp
            Text(timestamp)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
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
