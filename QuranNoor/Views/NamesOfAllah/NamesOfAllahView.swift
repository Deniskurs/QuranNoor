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

    private var filteredNames: [NameOfAllah] {
        if showFavoritesOnly {
            return searchText.isEmpty ? namesService.getFavoriteNames() :
                namesService.getFavoriteNames().filter { name in
                    name.transliteration.lowercased().contains(searchText.lowercased()) ||
                    name.translation.lowercased().contains(searchText.lowercased())
                }
        } else {
            return searchText.isEmpty ? namesService.getAllNames() :
                namesService.searchNames(query: searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [themeManager.currentTheme.accent.opacity(0.12), themeManager.currentTheme.accentMuted.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Progress
                    headerSection

                    // Names List
                    ScrollView {
                        LazyVStack(spacing: 12) {
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
                                colors: [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
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
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(namesService.progress.totalLearned)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentTheme.accent)

                    Text("Learned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(namesService.progress.totalFavorites)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)

                    Text("Favorites")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", namesService.progress.progressPercentage))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.currentTheme.accent)

                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding()
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
                            colors: [themeManager.currentTheme.accent.opacity(0.3), themeManager.currentTheme.accentMuted.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text("\(name.number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.currentTheme.accent)
            }

            // Name Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name.transliteration)
                        .font(.headline)

                    if isLearned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(themeManager.currentTheme.accent)
                            .font(.caption)
                    }
                }

                Text(name.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(name.arabicName)
                    .font(.title3)
                    .foregroundStyle(themeManager.currentTheme.accent)
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
