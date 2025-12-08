//
//  SpiritualBookmarkService.swift
//  QuranNoor
//
//  Service for managing Daily Inspiration bookmarks (verses, hadiths, duas)
//  Handles storage, retrieval, and synchronization
//

import Foundation
import Combine

/// Service for managing spiritual content bookmarks
@MainActor
final class SpiritualBookmarkService: ObservableObject {
    // MARK: - Singleton

    static let shared = SpiritualBookmarkService()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Published Properties

    @Published private(set) var bookmarks: [SpiritualBookmark] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "spiritual_bookmarks"

    // MARK: - Initialization

    private init() {
        loadBookmarks()
    }

    // MARK: - Public Methods

    /// Load all bookmarks from storage
    func loadBookmarks() {
        guard let data = userDefaults.data(forKey: bookmarksKey) else {
            bookmarks = []
            return
        }

        do {
            bookmarks = try Self.decoder.decode([SpiritualBookmark].self, from: data)
            bookmarks.sort { $0.timestamp > $1.timestamp } // Most recent first
        } catch {
            print("Error loading spiritual bookmarks: \(error)")
            bookmarks = []
        }
    }

    /// Save bookmarks to storage
    private func saveBookmarks() {
        do {
            let data = try Self.encoder.encode(bookmarks)

            // Save to UserDefaults asynchronously
            Task.detached(priority: .background) { [data, userDefaults, bookmarksKey] in
                userDefaults.set(data, forKey: bookmarksKey)
            }
        } catch {
            print("Error saving spiritual bookmarks: \(error)")
        }
    }

    /// Add a new bookmark
    func addBookmark(from quote: IslamicQuote, category: String) {
        // Check if already bookmarked (avoid duplicates)
        guard !isBookmarked(quote: quote) else {
            print("Already bookmarked: \(quote.text)")
            return
        }

        let bookmark = SpiritualBookmark(from: quote, category: category)
        bookmarks.insert(bookmark, at: 0) // Add at beginning (most recent)
        saveBookmarks()

        print("✅ Bookmarked: \(bookmark.text.prefix(50))...")
    }

    /// Add a bookmark directly
    func addBookmark(_ bookmark: SpiritualBookmark) {
        // Check for duplicates
        guard !bookmarks.contains(where: { $0.text == bookmark.text && $0.source == bookmark.source }) else {
            print("Already bookmarked")
            return
        }

        bookmarks.insert(bookmark, at: 0)
        saveBookmarks()
    }

    /// Remove a bookmark by ID
    func removeBookmark(id: UUID) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else {
            print("Bookmark not found: \(id)")
            return
        }

        let removed = bookmarks.remove(at: index)
        saveBookmarks()

        print("🗑️ Removed bookmark: \(removed.text.prefix(50))...")
    }

    /// Remove a bookmark matching quote content
    func removeBookmark(matching quote: IslamicQuote) {
        guard let index = bookmarks.firstIndex(where: { $0.text == quote.text && $0.source == quote.source }) else {
            print("Bookmark not found")
            return
        }

        bookmarks.remove(at: index)
        saveBookmarks()
    }

    /// Check if a quote is bookmarked
    func isBookmarked(quote: IslamicQuote) -> Bool {
        bookmarks.contains { $0.text == quote.text && $0.source == quote.source }
    }

    /// Get bookmark ID for a quote (if bookmarked)
    func getBookmarkId(for quote: IslamicQuote) -> UUID? {
        bookmarks.first { $0.text == quote.text && $0.source == quote.source }?.id
    }

    /// Get all bookmarks of a specific type
    func getBookmarks(ofType type: SpiritualBookmark.ContentType) -> [SpiritualBookmark] {
        bookmarks.filter { $0.contentType == type }
    }

    /// Get recent bookmarks (default: 5)
    func getRecentBookmarks(limit: Int = 5) -> [SpiritualBookmark] {
        Array(bookmarks.prefix(limit))
    }

    /// Search bookmarks by text
    func searchBookmarks(query: String) -> [SpiritualBookmark] {
        guard !query.isEmpty else { return bookmarks }

        let lowercaseQuery = query.lowercased()
        return bookmarks.filter {
            $0.text.lowercased().contains(lowercaseQuery) ||
            $0.source.lowercased().contains(lowercaseQuery)
        }
    }

    /// Clear all bookmarks
    func clearAllBookmarks() {
        bookmarks.removeAll()
        saveBookmarks()
        print("🗑️ Cleared all spiritual bookmarks")
    }

    // MARK: - Statistics

    /// Get total count of bookmarks
    var totalCount: Int {
        bookmarks.count
    }

    /// Get count by content type
    func count(ofType type: SpiritualBookmark.ContentType) -> Int {
        bookmarks.filter { $0.contentType == type }.count
    }

    /// Get bookmark statistics
    var statistics: BookmarkStatistics {
        BookmarkStatistics(
            total: totalCount,
            verses: count(ofType: .verse),
            hadiths: count(ofType: .hadith),
            duas: count(ofType: .dua),
            wisdom: count(ofType: .wisdom)
        )
    }
}

// MARK: - Supporting Types

struct BookmarkStatistics {
    let total: Int
    let verses: Int
    let hadiths: Int
    let duas: Int
    let wisdom: Int

    var hasBookmarks: Bool {
        total > 0
    }
}
