//
//  BookmarkCardView.swift
//  QuranNoor
//
//  Card component for displaying bookmarked content in list
//  Supports both Quran verse and Daily Inspiration bookmarks
//

import SwiftUI

// MARK: - Spiritual Bookmark Card

struct SpiritualBookmarkCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let bookmark: SpiritualBookmark
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header with category badge
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: bookmark.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)

                    Text(bookmark.category.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .tracking(0.5)

                    Spacer()

                    // Timestamp
                    Text(timeAgo(from: bookmark.timestamp))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                // Content text preview
                Text(bookmark.text)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(4)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // Source reference
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)

                    Text(bookmark.source)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)

                    Spacer()

                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primary.gold)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.currentTheme.cardColor)
            .cornerRadius(BorderRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .strokeBorder(accentColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private var accentColor: Color {
        switch bookmark.contentType {
        case .verse:
            return AppColors.primary.teal
        case .hadith:
            return AppColors.primary.gold
        case .wisdom:
            return AppColors.primary.green
        case .dua:
            return AppColors.primary.teal
        }
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Quran Bookmark Card

struct QuranBookmarkCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let bookmark: Bookmark
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primary.teal)

                    Text("QUR'AN VERSE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .tracking(0.5)

                    Spacer()

                    // Timestamp
                    Text(timeAgo(from: bookmark.timestamp))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                // Verse reference
                Text("Surah \(bookmark.surahNumber), Verse \(bookmark.verseNumber)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // Note if available
                if let note = bookmark.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14, weight: .regular))
                        .lineLimit(2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                // Footer
                HStack {
                    Text("Tap to read verse")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    Spacer()

                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primary.gold)
                }
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.currentTheme.cardColor)
            .cornerRadius(BorderRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .strokeBorder(AppColors.primary.teal.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Spiritual Bookmark") {
    VStack(spacing: 16) {
        SpiritualBookmarkCard(
            bookmark: SpiritualBookmark.sampleVerse,
            onTap: {}
        )

        SpiritualBookmarkCard(
            bookmark: SpiritualBookmark.sampleHadith,
            onTap: {}
        )
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environmentObject(ThemeManager())
}

#Preview("Quran Bookmark") {
    QuranBookmarkCard(
        bookmark: Bookmark(surahNumber: 2, verseNumber: 255, note: "Ayat al-Kursi - for protection"),
        onTap: {}
    )
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environmentObject(ThemeManager())
}
