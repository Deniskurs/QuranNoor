//
//  BookmarksViewModel.swift
//  QuranNoor
//
//  ViewModel for managing and displaying bookmarked content
//  Handles both Quran verse bookmarks and Daily Inspiration bookmarks
//

import SwiftUI
import Combine

@MainActor
@Observable
final class BookmarksViewModel {
    // MARK: - Properties

    var quranBookmarks: [Bookmark] = []
    var spiritualBookmarks: [SpiritualBookmark] = []
    var searchQuery: String = ""
    var selectedTab: BookmarkTab = .spiritual
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
        isLoading = true

        // Reload from services
        loadBookmarks()

        // Simulate brief loading state for smooth UI
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            isLoading = false
        }
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
        guard !searchQuery.isEmpty else { return quranBookmarks }

        let lowercaseQuery = searchQuery.lowercased()
        return quranBookmarks.filter {
            // Note: Would need to load verse text to search by content
            // For now, search by surah/verse numbers
            "\($0.surahNumber):\($0.verseNumber)".contains(lowercaseQuery)
        }
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
