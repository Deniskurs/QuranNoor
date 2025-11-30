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

    // MARK: - Initialization

    init(surahNumber: Int, verseNumber: Int, note: String? = nil) {
        self.id = UUID()
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.createdAt = Date()
        self.note = note
    }

    /// Initialize from existing Bookmark during migration
    init(from bookmark: Bookmark) {
        self.id = bookmark.id
        self.surahNumber = bookmark.surahNumber
        self.verseNumber = bookmark.verseNumber
        self.createdAt = bookmark.timestamp
        self.note = bookmark.note
    }

    // MARK: - Conversion

    /// Convert back to legacy Bookmark struct (for API compatibility during migration)
    func toBookmark() -> Bookmark {
        // Use the internal initializer that accepts all parameters
        return Bookmark(
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            note: note
        )
    }
}
