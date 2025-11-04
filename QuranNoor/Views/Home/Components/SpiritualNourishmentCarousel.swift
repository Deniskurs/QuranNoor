//
//  SpiritualNourishmentCarousel.swift
//  QuranNoor
//
//  Created by Claude Code
//  Horizontal carousel showing daily verse and hadith
//

import SwiftUI

struct SpiritualNourishmentCarousel: View {
    @EnvironmentObject var themeManager: ThemeManager
    let verseOfDay: IslamicQuote?
    let hadithOfDay: IslamicQuote?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary.teal)

                Text("Daily Inspiration")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)

            // Scrollable carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Verse of the day
                    if let verse = verseOfDay {
                        SpiritualContentCard(
                            icon: "book.fill",
                            title: "Verse of the Day",
                            content: verse,
                            accentColor: AppColors.primary.teal
                        )
                    }

                    // Hadith of the day
                    if let hadith = hadithOfDay {
                        SpiritualContentCard(
                            icon: "text.quote",
                            title: "Hadith of the Day",
                            content: hadith,
                            accentColor: AppColors.primary.gold
                        )
                    }

                    // Loading placeholders if no content
                    if verseOfDay == nil && hadithOfDay == nil {
                        ForEach(0..<2, id: \.self) { _ in
                            LoadingContentCard()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - Spiritual Content Card

struct SpiritualContentCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let content: IslamicQuote
    let accentColor: Color

    var body: some View {
        CardView(showPattern: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()
                }

                // Content text
                Text(content.text)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Source
                HStack {
                    Text(content.source)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            // Bookmark action
                        }) {
                            Image(systemName: "bookmark")
                                .font(.caption)
                                .foregroundColor(accentColor)
                        }

                        Button(action: {
                            // Share action
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 300, height: 220)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(content.text). Source: \(content.source)")
        .accessibilityHint("Double tap to bookmark or share")
    }
}

// MARK: - Loading State

struct LoadingContentCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        CardView(showPattern: false) {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(AppColors.primary.teal)

                Text("Loading inspiration...")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
        .frame(width: 300, height: 220)
    }
}

// MARK: - Preview

#Preview("With Content") {
    SpiritualNourishmentCarousel(
        verseOfDay: IslamicQuote(
            text: "And seek help through patience and prayer. Indeed, it is difficult except for the humble.",
            source: "Quran 2:45",
            category: .wisdom,
            relatedPrayer: nil
        ),
        hadithOfDay: IslamicQuote(
            text: "The best of you are those who learn the Quran and teach it.",
            source: "Bukhari",
            category: .hadith,
            relatedPrayer: nil
        )
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Loading") {
    SpiritualNourishmentCarousel(
        verseOfDay: nil,
        hadithOfDay: nil
    )
    .environmentObject(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Mode") {
    SpiritualNourishmentCarousel(
        verseOfDay: IslamicQuote(
            text: "And seek help through patience and prayer. Indeed, it is difficult except for the humble.",
            source: "Quran 2:45",
            category: .wisdom,
            relatedPrayer: nil
        ),
        hadithOfDay: IslamicQuote(
            text: "The best of you are those who learn the Quran and teach it.",
            source: "Bukhari",
            category: .hadith,
            relatedPrayer: nil
        )
    )
    .environmentObject({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .background(Color(hex: "#1A2332"))
}
