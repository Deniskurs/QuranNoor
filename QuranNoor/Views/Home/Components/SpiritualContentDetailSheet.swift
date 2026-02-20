//
//  SpiritualContentDetailSheet.swift
//  QuranNoor
//
//  Full-screen detail view for Daily Inspiration content
//  Displays complete text without truncation
//

import SwiftUI

struct SpiritualContentDetailSheet: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    var bookmarkService = SpiritualBookmarkService.shared

    let content: IslamicQuote
    let icon: String
    let title: String
    let accentColor: Color

    @State private var isBookmarked = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Category badge
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(accentColor)

                        Text(title.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )

                    // Full content text (no truncation)
                    Text(content.text)
                        .font(.system(size: 22, weight: .regular))
                        .lineSpacing(10)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    // Source/Reference
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)

                        Text(content.source)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, Spacing.xs)

                    // Category information
                    if content.category != .wisdom {
                        Divider()
                            .padding(.vertical, Spacing.xs)

                        HStack {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)

                            Spacer()

                            Text(content.category.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                    }
                }
                .padding(Spacing.cardPadding)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: Spacing.sm) {
                        // Bookmark button
                        Button(action: {
                            toggleBookmark()
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 18))
                                .foregroundColor(isBookmarked ? themeManager.currentTheme.accentMuted : accentColor)
                        }

                        // Share button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
        .presentationBackground(themeManager.currentTheme.backgroundColor)
        .onAppear {
            checkBookmarkStatus()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
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

    private func checkBookmarkStatus() {
        isBookmarked = bookmarkService.isBookmarked(quote: content)
    }

    // MARK: - Computed Properties

    private var shareText: String {
        """
        \(content.text)

        — \(content.source)

        Shared via Qur'an Noor
        """
    }

    private var accessibilityLabel: String {
        "\(title). \(content.text). Source: \(content.source). You can bookmark or share this content."
    }
}

// MARK: - Preview

#Preview("Verse Detail") {
    SpiritualContentDetailSheet(
        content: IslamicQuote(
            text: "And seek help through patience and prayer. Indeed, it is difficult except for the humble to those who are certain that they will meet their Lord and that they will return to Him.",
            source: "Quran 2:45-46",
            category: .wisdom,
            relatedPrayer: nil
        ),
        icon: "book.fill",
        title: "Verse of the Day",
        accentColor: ThemeMode.light.accent  // Theme-aware preview color
    )
    .environment(ThemeManager())
}

#Preview("Hadith Detail Dark") {
    SpiritualContentDetailSheet(
        content: IslamicQuote(
            text: "The best of you are those who learn the Quran and teach it to others.",
            source: "Sahih Bukhari",
            category: .hadith,
            relatedPrayer: nil
        ),
        icon: "text.quote",
        title: "Hadith of the Day",
        accentColor: ThemeMode.dark.accentMuted
    )
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}
