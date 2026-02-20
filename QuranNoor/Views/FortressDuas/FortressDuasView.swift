//
//  FortressDuasView.swift
//  QuranNoor
//
//  Main view for Fortress of the Muslim duas (Hisn al-Muslim)
//

import SwiftUI

struct FortressDuasView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var duaService = FortressDuaService()
    @State private var searchText = ""
    @State private var showingFavorites = false

    private var categoriesWithCount: [(category: DuaCategory, count: Int)] {
        duaService.getCategoriesWithCount()
    }

    private var filteredDuas: [FortressDua] {
        if showingFavorites {
            let favorites = duaService.getFavoriteDuas()
            return searchText.isEmpty ? favorites : favorites.filter { dua in
                dua.title.localizedCaseInsensitiveContains(searchText) ||
                dua.occasion.localizedCaseInsensitiveContains(searchText) ||
                dua.transliteration.localizedCaseInsensitiveContains(searchText)
            }
        } else if !searchText.isEmpty {
            return duaService.searchDuas(query: searchText)
        } else {
            return []
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Statistics Card
                    statisticsCard

                    // Toggle between categories and search results
                    if searchText.isEmpty && !showingFavorites {
                        // Categories Grid
                        categoriesSection
                    } else {
                        // Search Results or Favorites
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Fortress of the Muslim")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search duas...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showingFavorites.toggle()
                            if showingFavorites {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: showingFavorites ? "heart.fill" : "heart")
                            .foregroundStyle(showingFavorites ? .red : .primary)
                    }
                }
            }
            .navigationDestination(for: DuaCategory.self) { category in
                DuaCategoryView(category: category, duaService: duaService)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.green, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Hisn al-Muslim")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Authentic supplications from the Quran and Sunnah")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Total Duas",
                    value: "\(duaService.allDuas.count)",
                    icon: "text.book.closed.fill",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Favorites",
                    value: "\(duaService.progress.totalFavorites)",
                    icon: "heart.fill",
                    color: .red
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Total Usage",
                    value: "\(duaService.progress.totalUsages)",
                    icon: "checkmark.circle.fill",
                    color: themeManager.currentTheme.accent
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(categoriesWithCount, id: \.category) { item in
                    NavigationLink(value: item.category) {
                        DuaCategoryCard(
                            category: item.category,
                            count: item.count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(showingFavorites ? "Favorite Duas" : "Search Results")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            if filteredDuas.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDuas) { dua in
                        NavigationLink(value: dua.category) {
                            FortressDuaCard(dua: dua, duaService: duaService)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: showingFavorites ? "heart.slash" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(showingFavorites ? "No Favorite Duas" : "No Results Found")
                .font(.headline)

            Text(showingFavorites ? "Mark duas as favorites to see them here" : "Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

struct DuaCategoryCard: View {
    @Environment(ThemeManager.self) var themeManager
    let category: DuaCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(categoryColor)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(category.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: category.color)
    }
}

struct FortressDuaCard: View {
    let dua: FortressDua
    @Bindable var duaService: FortressDuaService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dua.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(dua.occasion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation {
                        duaService.toggleFavorite(dua: dua)
                    }
                } label: {
                    Image(systemName: duaService.isFavorite(dua: dua) ? "heart.fill" : "heart")
                        .foregroundStyle(duaService.isFavorite(dua: dua) ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }

            Text(dua.arabicText)
                .font(.title3)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(dua.transliteration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    FortressDuasView()
}
