//
//  BookmarksView.swift
//  QuranNoor
//
//  View for displaying and managing all bookmarked content
//  Includes tabs for Quran verses and Daily Inspiration bookmarks
//

import SwiftUI

struct BookmarksView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var viewModel = BookmarksViewModel()
    @State private var selectedBookmark: SpiritualBookmark?
    @State private var showDetailSheet = false

    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.xs)

                // Tab selector
                tabSelector
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.xxs)

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasBookmarks {
                    emptyStateView
                } else {
                    tabContent
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        viewModel.refresh()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }

                    if viewModel.currentTabCount > 0 {
                        Button(role: .destructive, action: {
                            // Clear all bookmarks in current tab - confirmation is handled by destructive role
                            viewModel.clearCurrentTab()
                        }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(themeManager.currentTheme.accent)
                }
            }
        }
        .onAppear {
            viewModel.loadBookmarks()
        }
        .sheet(item: $selectedBookmark) { bookmark in
            SpiritualContentDetailSheet(
                content: IslamicQuote(
                    text: bookmark.text,
                    source: bookmark.source,
                    category: mapContentType(bookmark.contentType),
                    relatedPrayer: nil
                ),
                icon: bookmark.iconName,
                title: bookmark.category,
                accentColor: getAccentColor(for: bookmark.contentType)
            )
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.textTertiary)

            TextField("Search bookmarks...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.clearSearchQuery()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Spacing.xs)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(BorderRadius.md)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(BookmarksViewModel.BookmarkTab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    icon: tab.icon,
                    isSelected: viewModel.selectedTab == tab,
                    count: tab == .spiritual ? viewModel.spiritualBookmarks.count : viewModel.quranBookmarks.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedTab = tab
                    }
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .spiritual:
            spiritualBookmarksList
        case .quran:
            quranBookmarksList
        }
    }

    private var spiritualBookmarksList: some View {
        Group {
            if viewModel.filteredSpiritualBookmarks.isEmpty {
                noResultsView
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.filteredSpiritualBookmarks) { bookmark in
                            SpiritualBookmarkCard(bookmark: bookmark) {
                                selectedBookmark = bookmark
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    // Share bookmark
                                    shareBookmark(bookmark)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(themeManager.currentTheme.accent)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteSpiritualBookmark(bookmark)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    private var quranBookmarksList: some View {
        Group {
            VStack(spacing: 0) {
                // Category filter pills
                categoryFilterBar
                    .padding(.vertical, Spacing.xs)

                if viewModel.filteredQuranBookmarks.isEmpty {
                    noResultsView
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(viewModel.filteredQuranBookmarks) { bookmark in
                                QuranBookmarkCard(bookmark: bookmark) {
                                    // Navigation to QuranReaderView is handled by parent HomeView's NavigationStack
                                    // This would require passing a binding or using an environment object
                                    #if DEBUG
                                    print("Navigate to Surah \(bookmark.surahNumber):\(bookmark.verseNumber)")
                                    #endif
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteQuranBookmark(bookmark)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.vertical, Spacing.md)
                    }
                }
            }
        }
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xxs) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    CategoryPill(
                        label: BookmarkCategory.shortLabel(for: category),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.accent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "bookmark")
                    .font(.system(size: 50))
                    .foregroundColor(themeManager.currentTheme.accent)
            }

            // Text
            VStack(spacing: Spacing.xs) {
                Text("No Bookmarks Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text("Bookmark verses and daily inspiration\nto revisit them anytime")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(themeManager.currentTheme.textTertiary)

            Text("No Results Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Spacer()
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.currentTheme.accent)
            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func shareBookmark(_ bookmark: SpiritualBookmark) {
        let text = """
        \(bookmark.text)

        — \(bookmark.source)

        Shared via Qur'an Noor
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func mapContentType(_ type: SpiritualBookmark.ContentType) -> IslamicQuote.QuoteCategory {
        switch type {
        case .hadith:
            return .hadith
        case .dua:
            return .dua
        case .verse, .wisdom:
            return .wisdom
        }
    }

    private func getAccentColor(for type: SpiritualBookmark.ContentType) -> Color {
        switch type {
        case .verse:
            return themeManager.currentTheme.accent
        case .hadith:
            return themeManager.currentTheme.accentMuted
        case .wisdom:
            return themeManager.currentTheme.accent
        case .dua:
            return themeManager.currentTheme.accent
        }
    }
}

// MARK: - Tab Button Component

private struct TabButton: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : themeManager.currentTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.md)
                    .fill(isSelected ? themeManager.currentTheme.accent.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.md)
                    .strokeBorder(
                        isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Category Pill Component

private struct CategoryPill: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: FontSizes.sm, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.cardColor)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : themeManager.currentTheme.textTertiary.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("With Bookmarks") {
    BookmarksView()
        .environment(ThemeManager())
}

#Preview("Empty State") {
    BookmarksView()
        .environment(ThemeManager())
}

#Preview("Dark Mode") {
    BookmarksView()
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
}
