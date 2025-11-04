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
        VStack(alignment: .leading, spacing: Spacing.xs) { // Enhanced from 12
            // Section header
            HStack(spacing: Spacing.xs) { // Add spacing
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18)) // More consistent sizing
                    .foregroundColor(AppColors.primary.teal)

                Text("Daily Inspiration")
                    .font(.system(size: 20, weight: .bold)) // Enhanced from headline
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            // Note: Horizontal padding removed - inherited from parent HomeView

            // Scrollable carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) { // Enhanced from 16
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
                // Note: Horizontal padding removed - inherited from parent HomeView
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - Spiritual Content Card

struct SpiritualContentCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var bookmarkService = SpiritualBookmarkService.shared

    let icon: String
    let title: String
    let content: IslamicQuote
    let accentColor: Color

    @State private var showDetailSheet = false
    @State private var showShareSheet = false
    @State private var isBookmarked = false

    var body: some View {
        CardView(showPattern: false) {
            VStack(alignment: .leading, spacing: Spacing.cardSpacing) {
                // Header - refined
                HStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()
                }
                .frame(height: 32) // Fixed header height

                // Content text area with better spacing
                ZStack(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Content text - enhanced readability
                        Text(content.text)
                            .font(.system(size: 18, weight: .regular)) // Enhanced from 17 to 18pt
                            .lineSpacing(8) // Enhanced from 6 to 8pt
                            .lineLimit(7) // Enhanced from 5 to 7 lines
                            .multilineTextAlignment(.leading)
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        Spacer(minLength: 0)

                        // Source reference
                        Text(content.source)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 220) // Fixed content area height

                    // Fade gradient overlay when text is truncated
                    if isTextTruncated {
                        VStack(spacing: 4) {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.currentTheme.cardColor.opacity(0),
                                    themeManager.currentTheme.cardColor.opacity(0.8),
                                    themeManager.currentTheme.cardColor
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 60)

                            // "Tap to read more" hint
                            HStack {
                                Spacer()
                                Text("Tap to read more")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(accentColor.opacity(0.15))
                                    )
                                Spacer()
                            }
                        }
                    }
                }

                Divider()
                    .opacity(0.3)

                // Action buttons row
                HStack(spacing: Spacing.sm) {
                    // Bookmark button
                    Button(action: {
                        toggleBookmark()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 18))
                                .foregroundColor(isBookmarked ? AppColors.primary.gold : accentColor)
                            Text("Save")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(width: 60, height: Spacing.tapTarget)

                    Spacer()

                    // Share button
                    Button(action: {
                        shareContent()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                            Text("Share")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(width: 60, height: Spacing.tapTarget)
                }
                .frame(height: 44)
            }
            .padding(Spacing.cardPadding)
        }
        .frame(width: 320, height: 360) // Enhanced from 280 to 360 for better breathing room
        .contentShape(Rectangle()) // Make entire card tappable
        .onTapGesture {
            showDetailSheet = true
        }
        .sheet(isPresented: $showDetailSheet) {
            SpiritualContentDetailSheet(
                content: content,
                icon: icon,
                title: title,
                accentColor: accentColor
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .onAppear {
            checkBookmarkStatus()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(content.text). Source: \(content.source)")
        .accessibilityHint("Double tap to read full content and bookmark or share")
    }

    // MARK: - Computed Properties

    private var isTextTruncated: Bool {
        // Simple heuristic: if text is longer than ~200 characters, likely truncated at 7 lines
        content.text.count > 200
    }

    // MARK: - Actions

    private func toggleBookmark() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isBookmarked.toggle()
        }

        // Haptic feedback
        HapticManager.shared.trigger(.medium)

        if isBookmarked {
            bookmarkService.addBookmark(from: content, category: title)
        } else {
            bookmarkService.removeBookmark(matching: content)
        }
    }

    private func shareContent() {
        showShareSheet = true
    }

    private func checkBookmarkStatus() {
        isBookmarked = bookmarkService.isBookmarked(quote: content)
    }

    private var shareText: String {
        """
        \(content.text)

        — \(content.source)

        Shared via Qur'an Noor
        """
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
