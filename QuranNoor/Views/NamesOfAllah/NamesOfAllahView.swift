//
//  NamesOfAllahView.swift
//  QuranNoor
//
//  Main view for the 99 Names of Allah (Asma ul Husna)
//

import SwiftUI

struct NamesOfAllahView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var namesService = NamesOfAllahService()
    @State private var searchText = ""
    @State private var selectedName: NameOfAllah?
    @State private var showFavoritesOnly = false
    @State private var selectedCategory: NamesCategory = .all

    private var filteredNames: [NameOfAllah] {
        var names: [NameOfAllah]

        if showFavoritesOnly {
            names = searchText.isEmpty ? namesService.getFavoriteNames() :
                namesService.getFavoriteNames().filter { name in
                    name.transliteration.lowercased().contains(searchText.lowercased()) ||
                    name.translation.lowercased().contains(searchText.lowercased())
                }
        } else {
            names = searchText.isEmpty ? namesService.getAllNames() :
                namesService.searchNames(query: searchText)
        }

        if selectedCategory != .all {
            names = names.filter { $0.category == selectedCategory }
        }

        return names
    }

    private var nameOfTheDay: NameOfAllah? {
        let dayIndex = Calendar.current.component(.dayOfYear, from: Date()) % 99
        let nameNumber = dayIndex + 1
        return namesService.allNames.first { $0.number == nameNumber }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: themeManager.currentTheme.featureGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Progress
                    headerSection

                    // Category Filter Chips
                    categoryChipsSection

                    // Names List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Name of the Day
                            if selectedCategory == .all && searchText.isEmpty && !showFavoritesOnly {
                                nameOfTheDayCard
                            }

                            ForEach(filteredNames) { name in
                                NameCard(
                                    name: name,
                                    isFavorite: namesService.isFavorite(number: name.number),
                                    isLearned: namesService.isLearned(number: name.number),
                                    onFavorite: {
                                        withAnimation {
                                            namesService.toggleFavorite(number: name.number)
                                        }
                                    }
                                )
                                .onTapGesture {
                                    selectedName = name
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("99 Names of Allah")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search names...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showFavoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(showFavoritesOnly ? .red : .primary)
                    }
                }
            }
            .sheet(item: $selectedName) { name in
                NameDetailView(name: name, namesService: namesService)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Text("99")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Asma ul Husna")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("The Beautiful Names of Allah")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Progress Card
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(namesService.progress.totalLearned)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentTheme.featureAccent)

                    Text("Learned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(namesService.progress.totalFavorites)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)

                    Text("Favorites")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Progress Grid (10x10)
                progressGrid
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding()
    }

    // MARK: - Progress Grid

    private var progressGrid: some View {
        VStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { col in
                        let number = row * 10 + col + 1
                        if number <= 99 {
                            Circle()
                                .fill(namesService.isLearned(number: number) ? themeManager.currentTheme.featureAccent : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        } else {
                            Color.clear
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Chips

    private var categoryChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NamesCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ?
                                      AnyShapeStyle(themeManager.currentTheme.featureAccent) :
                                      AnyShapeStyle(.ultraThinMaterial))
                        )
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Name of the Day

    @ViewBuilder
    private var nameOfTheDayCard: some View {
        if let name = nameOfTheDay {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Name of the Day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                Text(name.arabicName)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)

                Text(name.transliteration)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(name.translation)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        .linearGradient(
                            colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .onTapGesture {
                selectedName = name
            }
        }
    }
}

// MARK: - Name Card

struct NameCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let name: NameOfAllah
    let isFavorite: Bool
    let isLearned: Bool
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(
                        .linearGradient(
                            colors: [themeManager.currentTheme.featureAccent.opacity(0.3), themeManager.currentTheme.featureAccentSecondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text("\(name.number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.currentTheme.featureAccent)
            }

            // Name Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name.transliteration)
                        .font(.headline)

                    if isLearned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(themeManager.currentTheme.featureAccent)
                            .font(.caption)
                    }
                }

                Text(name.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(name.arabicName)
                    .font(.title3)
                    .foregroundStyle(themeManager.currentTheme.featureAccent)
            }

            Spacer()

            // Favorite Button
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    NamesOfAllahView()
        .environment(ThemeManager())
}
