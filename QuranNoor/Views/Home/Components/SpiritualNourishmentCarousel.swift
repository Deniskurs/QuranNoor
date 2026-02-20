//
//  SpiritualNourishmentCarousel.swift
//  QuranNoor
//
//  Created by Claude Code
//  Horizontal carousel showing daily verse and hadith
//

import SwiftUI

struct SpiritualNourishmentCarousel: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let verseOfDay: IslamicQuote?
    let hadithOfDay: IslamicQuote?

    @State private var currentPage: Int? = 0

    private var totalPages: Int {
        var count = 0
        if verseOfDay != nil { count += 1 }
        if hadithOfDay != nil { count += 1 }
        return max(count, 2) // Show 2 dots for loading state
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) { // Enhanced from 12
            // Section header
            HStack(spacing: Spacing.xs) { // Add spacing
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18)) // More consistent sizing
                    .foregroundColor(themeManager.currentTheme.accent)

                Text("Daily Inspiration")
                    .font(.system(size: 20, weight: .bold)) // Enhanced from headline
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            // Note: Horizontal padding removed - inherited from parent HomeView

            // Scrollable carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) { // 16pt spacing between cards
                    // Verse of the day
                    if let verse = verseOfDay {
                        SpiritualContentCard(
                            icon: "book.fill",
                            title: "Verse of the Day",
                            content: verse,
                            accentColor: themeManager.currentTheme.accent
                        )
                    }

                    // Hadith of the day
                    if let hadith = hadithOfDay {
                        SpiritualContentCard(
                            icon: "text.quote",
                            title: "Hadith of the Day",
                            content: hadith,
                            accentColor: themeManager.currentTheme.accentMuted
                        )
                    }

                    // Loading placeholders if no content
                    if verseOfDay == nil && hadithOfDay == nil {
                        ForEach(0..<2, id: \.self) { _ in
                            LoadingContentCard()
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 20) // Give space for card shadows (radius 12 + offset 6 = 18pt needed)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)

            // Page indicator
            if totalPages > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Spiritual Content Card

struct SpiritualContentCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    var bookmarkService = SpiritualBookmarkService.shared
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let icon: String
    let title: String
    let content: IslamicQuote
    let accentColor: Color

    @State private var showDetailSheet = false
    @State private var showShareSheet = false
    @State private var isBookmarked = false
    @State private var isTapped = false

    // Dynamic Type support with @ScaledMetric
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 310
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 380
    @ScaledMetric(relativeTo: .body) private var contentAreaHeight: CGFloat = 220

    var body: some View {
        CardView(intensity: .moderate) {
            VStack(alignment: .leading, spacing: 14) {
                // Header - refined with reduced emphasis
                HStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 16)) // Reduced from title3 (~20pt) to 16pt
                        .foregroundColor(accentColor.opacity(0.8))

                    Text(title)
                        .font(.system(size: 11, weight: .semibold)) // Reduced from 12pt
                        .foregroundColor(themeManager.currentTheme.textTertiary) // Reduced prominence
                        .textCase(.uppercase)
                        .tracking(0.6) // Increased letter spacing

                    Spacer()
                }
                .frame(height: 28) // Reduced from 32pt for tighter layout

                // Content text area with better spacing
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Content text - enhanced readability with Dynamic Type support
                    Text(content.text)
                        .font(.body) // Dynamic Type support
                        .lineSpacing(9)
                        .lineLimit(maxLines) // Dynamic line limit based on text size
                        .multilineTextAlignment(.leading)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Cap at xxxLarge

                    Spacer(minLength: 0)

                    // Source reference
                    Text(content.source)
                        .font(.subheadline) // Dynamic Type support
                        .italic()
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: min(contentAreaHeight, 280)) // Dynamic height with cap
                .overlay(alignment: .bottom) {
                    // Fade gradient overlay when text is truncated
                    if isTextTruncated {
                        VStack(spacing: 0) {
                            // Smart gradient with delayed fade start
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .clear, location: 0.5),
                                    .init(color: themeManager.currentTheme.cardColor.opacity(0.7), location: 0.85),
                                    .init(color: themeManager.currentTheme.cardColor, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 80) // Increased from 60pt for smoother transition
                            .allowsHitTesting(false) // Don't interfere with taps

                            // "Read More" badge positioned outside gradient flow
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 13))
                                Text("Read Full Content")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(accentColor.opacity(0.35), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(accentColor)
                            .shadow(color: accentColor.opacity(0.15), radius: 4, y: 2)
                            .offset(y: -12) // Lift into gradient area
                        }
                    }
                }

                Divider()
                    .opacity(0.3)

                // Action buttons row with improved tap targets
                HStack(spacing: 24) {
                    // Bookmark button
                    Button(action: {
                        toggleBookmark()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20)) // Increased from 18pt
                                .foregroundColor(isBookmarked ? themeManager.currentTheme.accentMuted : accentColor)
                                .symbolEffect(.bounce, value: isBookmarked) // iOS 17+ bounce effect
                            Text("Save")
                                .font(.system(size: 11, weight: .medium)) // Increased from 10pt
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(width: 68, height: 52) // Increased tap target
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
                    .accessibilityHint("Saves this \(title.lowercased()) to your bookmarks")

                    Spacer()

                    // Share button
                    Button(action: {
                        shareContent()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20)) // Increased from 18pt
                                .foregroundColor(accentColor)
                            Text("Share")
                                .font(.system(size: 11, weight: .medium)) // Increased from 10pt
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(width: 68, height: 52) // Increased tap target
                    .accessibilityLabel("Share")
                    .accessibilityHint("Share this \(title.lowercased()) with others")
                }
                .frame(height: 52) // Increased from 44pt
            }
        }
        .frame(
            width: min(cardWidth, 400),
            height: min(adaptiveCardHeight, 600)
        ) // Base: 310×380pt with Dynamic Type support and caps
        .scaleEffect(isTapped ? 0.98 : 1.0)
        .contentShape(Rectangle()) // Make entire card tappable
        .onTapGesture {
            // Tap animation with haptic feedback
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isTapped = true
            }
            HapticManager.shared.trigger(.light)

            // Reset after brief delay and show sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isTapped = false
                }
                showDetailSheet = true
            }
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
        .accessibilityLabel(title)
        .accessibilityValue(content.text)
        .accessibilityHint("Source: \(content.source). Double tap to read full content and access bookmark or share options")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Computed Properties

    private var isTextTruncated: Bool {
        // Simple heuristic: if text is longer than ~200 characters, likely truncated at 7 lines
        content.text.count > 200
    }

    private var maxLines: Int {
        // Adjust line limit based on Dynamic Type size
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return 7
        case .xxLarge:
            return 6
        case .xxxLarge:
            return 5
        default:
            return 7
        }
    }

    private var adaptiveCardHeight: CGFloat {
        // Adjust card height based on Dynamic Type size
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return 380
        case .xxLarge:
            return 440
        case .xxxLarge:
            return 500
        default:
            return 380
        }
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
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var animateGradient = false
    @State private var isViewVisible = false

    var body: some View {
        CardView(intensity: .moderate) {
            VStack(alignment: .leading, spacing: 16) {
                // Header skeleton
                RoundedRectangle(cornerRadius: 6)
                    .fill(skeletonGradient)
                    .frame(width: 120, height: 16)

                // Content lines skeleton
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(skeletonGradient)
                            .frame(height: 18)
                            .frame(maxWidth: index == 5 ? 200 : nil, alignment: .leading)
                    }
                }

                Spacer()

                // Source skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 100, height: 14)

                // Divider
                Rectangle()
                    .fill(skeletonGradient.opacity(0.3))
                    .frame(height: 1)

                // Action buttons skeleton
                HStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(skeletonGradient)
                        .frame(width: 60, height: 48)

                    Spacer()

                    RoundedRectangle(cornerRadius: 8)
                        .fill(skeletonGradient)
                        .frame(width: 60, height: 48)
                }
            }
        }
        .frame(width: 310, height: 380)
        .onAppear {
            isViewVisible = true
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animateGradient = true
            }
        }
        .onDisappear {
            isViewVisible = false
            animateGradient = false
        }
    }

    private var skeletonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                themeManager.currentTheme.textTertiary.opacity(0.1),
                themeManager.currentTheme.textTertiary.opacity(0.2),
                themeManager.currentTheme.textTertiary.opacity(0.1)
            ]),
            startPoint: animateGradient ? .leading : .trailing,
            endPoint: animateGradient ? .trailing : .leading
        )
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
    .environment(ThemeManager())
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Loading") {
    SpiritualNourishmentCarousel(
        verseOfDay: nil,
        hadithOfDay: nil
    )
    .environment(ThemeManager())
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
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
    .background(Color(hex: "#1A2332"))
}
