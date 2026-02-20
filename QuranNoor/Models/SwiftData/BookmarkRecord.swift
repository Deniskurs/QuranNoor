//
//  BookmarkRecord.swift
//  QuranNoor
//
//  SwiftData model for storing Quran bookmarks
//

import Foundation
import SwiftData

/// SwiftData model for storing verse bookmarks
/// Replaces the UserDefaults-based [Bookmark] array
///
// MARK: - Usage with @Query
// In SwiftUI views, use @Query for automatic updates:
// @Query(sort: \BookmarkRecord.createdAt, order: .reverse) var bookmarks: [BookmarkRecord]
// @Query(filter: #Predicate<BookmarkRecord> { $0.category == "Favorites" }) var favorites: [BookmarkRecord]
// @Query(filter: #Predicate<BookmarkRecord> { $0.surahNumber == 2 }) var surahBookmarks: [BookmarkRecord]
@Model
final class BookmarkRecord {
    // MARK: - Properties

    /// Unique identifier for the bookmark
    @Attribute(.unique) var id: UUID

    /// Surah number (1-114)
    var surahNumber: Int

    /// Verse number within the surah
    var verseNumber: Int

    /// When the bookmark was created
    var createdAt: Date

    /// Optional user note for the bookmark
    var note: String?

    /// Bookmark category for organization (defaults to "All Bookmarks" for existing records)
    var category: String = "All Bookmarks"

    // MARK: - Indexes
    // Compound indexes for optimized queries:
    // - surahNumber for filtering by surah
    // - createdAt for sorting by date
    // - category for category filtering
    // - compound (surahNumber, verseNumber) for efficient verse lookup
    #Index<BookmarkRecord>([\.surahNumber], [\.createdAt], [\.category], [\.surahNumber, \.verseNumber])

    // MARK: - Initialization

    init(surahNumber: Int, verseNumber: Int, note: String? = nil, category: String = "All Bookmarks") {
        self.id = UUID()
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.createdAt = Date()
        self.note = note
        self.category = category
    }

    /// Initialize from existing Bookmark during migration
    init(from bookmark: Bookmark) {
        self.id = bookmark.id
        self.surahNumber = bookmark.surahNumber
        self.verseNumber = bookmark.verseNumber
        self.createdAt = bookmark.timestamp
        self.note = bookmark.note
        self.category = bookmark.category
    }

    // MARK: - Conversion

    /// Convert back to legacy Bookmark struct (for API compatibility during migration)
    func toBookmark() -> Bookmark {
        return Bookmark(
            id: id,
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            note: note,
            category: category,
            timestamp: createdAt
        )
    }
}
