//
//  BookmarksViewModel.swift
//  QuranNoor
//
//  ViewModel for managing and displaying bookmarked content
//  Handles both Quran verse bookmarks and Daily Inspiration bookmarks
//

import SwiftUI

@MainActor
@Observable
final class BookmarksViewModel {
    // MARK: - Properties

    var quranBookmarks: [Bookmark] = []
    var spiritualBookmarks: [SpiritualBookmark] = []
    var searchQuery: String = ""
    var selectedTab: BookmarkTab = .spiritual
    var selectedCategory: String = BookmarkCategory.allBookmarks
    var isLoading = false

    // MARK: - Dependencies

    private let quranService: QuranService
    private let spiritualBookmarkService: SpiritualBookmarkService

    // MARK: - Tab Selection

    enum BookmarkTab: String, CaseIterable {
        case spiritual = "Daily Inspiration"
        case quran = "Qur'an Verses"

        var icon: String {
            switch self {
            case .spiritual:
                return "book.closed.fill"
            case .quran:
                return "book.fill"
            }
        }
    }

    // MARK: - Initialization

    init() {
        self.quranService = QuranService.shared
        self.spiritualBookmarkService = SpiritualBookmarkService.shared

        loadBookmarks()
    }

    // MARK: - Data Loading

    func loadBookmarks() {
        quranBookmarks = quranService.getBookmarks()
        spiritualBookmarks = spiritualBookmarkService.bookmarks
    }

    func refresh() {
        // Reload from services synchronously (no artificial delay needed)
        loadBookmarks()
    }

    // MARK: - Category Support

    /// All available bookmark categories for the filter pills
    var availableCategories: [String] {
        quranService.getBookmarkCategories()
    }

    /// Select a category filter
    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    // MARK: - Filtered Data

    var filteredSpiritualBookmarks: [SpiritualBookmark] {
        guard !searchQuery.isEmpty else { return spiritualBookmarks }

        let lowercaseQuery = searchQuery.lowercased()
        return spiritualBookmarks.filter {
            $0.text.lowercased().contains(lowercaseQuery) ||
            $0.source.lowercased().contains(lowercaseQuery) ||
            $0.category.lowercased().contains(lowercaseQuery)
        }
    }

    var filteredQuranBookmarks: [Bookmark] {
        // Apply category filter first
        var result: [Bookmark]
        if selectedCategory == BookmarkCategory.allBookmarks {
            result = quranBookmarks
        } else {
            result = quranBookmarks.filter { $0.category == selectedCategory }
        }

        // Then apply search filter
        if !searchQuery.isEmpty {
            let lowercaseQuery = searchQuery.lowercased()
            result = result.filter {
                "\($0.surahNumber):\($0.verseNumber)".contains(lowercaseQuery) ||
                ($0.note?.lowercased().contains(lowercaseQuery) ?? false) ||
                $0.category.lowercased().contains(lowercaseQuery)
            }
        }

        return result
    }

    // MARK: - Actions

    func deleteSpiritualBookmark(_ bookmark: SpiritualBookmark) {
        spiritualBookmarkService.removeBookmark(id: bookmark.id)
        loadBookmarks()
    }

    func deleteQuranBookmark(_ bookmark: Bookmark) {
        quranService.removeBookmark(id: bookmark.id)
        loadBookmarks()
    }

    func clearSearchQuery() {
        searchQuery = ""
    }

    func clearCurrentTab() {
        switch selectedTab {
        case .spiritual:
            spiritualBookmarkService.clearAllBookmarks()
        case .quran:
            // Clear all Quran bookmarks by removing each one
            for bookmark in quranBookmarks {
                quranService.removeBookmark(id: bookmark.id)
            }
        }
        loadBookmarks()
    }

    // MARK: - Statistics

    var hasBookmarks: Bool {
        !quranBookmarks.isEmpty || !spiritualBookmarks.isEmpty
    }

    var totalBookmarksCount: Int {
        quranBookmarks.count + spiritualBookmarks.count
    }

    var currentTabCount: Int {
        switch selectedTab {
        case .spiritual:
            return spiritualBookmarks.count
        case .quran:
            return quranBookmarks.count
        }
    }
}
