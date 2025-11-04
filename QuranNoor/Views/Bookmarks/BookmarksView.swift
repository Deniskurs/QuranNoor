//
//  BookmarksView.swift
//  QuranNoor
//
//  View for displaying and managing all bookmarked content
//  Includes tabs for Quran verses and Daily Inspiration bookmarks
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var viewModel = BookmarksViewModel()
    @State private var selectedBookmark: SpiritualBookmark?
    @State private var showDetailSheet = false

    var body: some View {
        NavigationStack {
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
                                // TODO: Add confirmation alert
                            }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.primary.teal)
                    }
                }
            }
            .onAppear {
                viewModel.loadBookmarks()
            }
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
                                .tint(AppColors.primary.teal)
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
            if viewModel.filteredQuranBookmarks.isEmpty {
                noResultsView
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.filteredQuranBookmarks) { bookmark in
                            QuranBookmarkCard(bookmark: bookmark) {
                                // TODO: Navigate to verse reader
                                print("Navigate to Surah \(bookmark.surahNumber):\(bookmark.verseNumber)")
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

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.teal.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "bookmark")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primary.teal)
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
                .tint(AppColors.primary.teal)
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
            return AppColors.primary.teal
        case .hadith:
            return AppColors.primary.gold
        case .wisdom:
            return AppColors.primary.green
        case .dua:
            return AppColors.primary.teal
        }
    }
}

// MARK: - Tab Button Component

private struct TabButton: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                                .fill(isSelected ? AppColors.primary.teal : themeManager.currentTheme.textTertiary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? AppColors.primary.teal : themeManager.currentTheme.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.md)
                    .fill(isSelected ? AppColors.primary.teal.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.md)
                    .strokeBorder(
                        isSelected ? AppColors.primary.teal : themeManager.currentTheme.textTertiary.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("With Bookmarks") {
    BookmarksView()
        .environmentObject(ThemeManager())
}

#Preview("Empty State") {
    BookmarksView()
        .environmentObject(ThemeManager())
}

#Preview("Dark Mode") {
    BookmarksView()
        .environmentObject({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
}
