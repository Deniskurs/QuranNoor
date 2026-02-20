//
//  SpiritualBookmark.swift
//  QuranNoor
//
//  Data model for bookmarked Daily Inspiration content (verses, hadiths, duas)
//  Separate from Quran verse bookmarks
//

import Foundation

/// Bookmarked spiritual content from Daily Inspiration carousel
struct SpiritualBookmark: Identifiable, Codable, Hashable, Sendable {
    // MARK: - Properties

    let id: UUID
    let text: String
    let source: String
    let category: String // "Verse of the Day", "Hadith of the Day", etc.
    let contentType: ContentType
    let timestamp: Date

    // MARK: - Content Type

    enum ContentType: String, Codable {
        case verse = "verse"
        case hadith = "hadith"
        case wisdom = "wisdom"
        case dua = "dua"
    }

    // MARK: - Initializer

    init(
        text: String,
        source: String,
        category: String,
        contentType: ContentType,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.source = source
        self.category = category
        self.contentType = contentType
        self.timestamp = timestamp
    }

    // MARK: - Convenience Init from IslamicQuote

    init(from quote: IslamicQuote, category: String) {
        self.id = UUID()
        self.text = quote.text
        self.source = quote.source
        self.category = category
        self.contentType = Self.mapQuoteCategory(quote.category)
        self.timestamp = Date()
    }

    // MARK: - Helper Methods

    private static func mapQuoteCategory(_ category: IslamicQuote.QuoteCategory) -> ContentType {
        switch category {
        case .hadith:
            return .hadith
        case .dua:
            return .dua
        case .wisdom:
            return .wisdom
        }
    }

    /// Returns user-friendly display text for the content type
    var typeDisplayName: String {
        switch contentType {
        case .verse:
            return "Qur'an Verse"
        case .hadith:
            return "Hadith"
        case .wisdom:
            return "Islamic Wisdom"
        case .dua:
            return "Du'a"
        }
    }

    /// Returns icon name for the content type
    var iconName: String {
        switch contentType {
        case .verse:
            return "book.fill"
        case .hadith:
            return "text.quote"
        case .wisdom:
            return "lightbulb.fill"
        case .dua:
            return "hands.sparkles.fill"
        }
    }

}

// MARK: - Preview Helpers

#if DEBUG
extension SpiritualBookmark {
    static let sampleVerse = SpiritualBookmark(
        text: "And seek help through patience and prayer. Indeed, it is difficult except for the humble.",
        source: "Qur'an 2:45",
        category: "Verse of the Day",
        contentType: .verse
    )

    static let sampleHadith = SpiritualBookmark(
        text: "The best of you are those who learn the Qur'an and teach it.",
        source: "Sahih Bukhari",
        category: "Hadith of the Day",
        contentType: .hadith
    )

    static let sampleDua = SpiritualBookmark(
        text: "O Allah, I seek refuge in You from anxiety and sorrow, weakness and laziness.",
        source: "Fortress of the Muslim",
        category: "Du'a",
        contentType: .dua
    )
}
#endif
