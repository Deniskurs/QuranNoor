//
//  DuaCategoryView.swift
//  QuranNoor
//
//  View displaying all duas within a specific category
//

import SwiftUI

struct DuaCategoryView: View {
    @Environment(ThemeManager.self) var themeManager
    let category: DuaCategory
    @Bindable var duaService: FortressDuaService

    @State private var selectedDua: FortressDua?
    @State private var showingDetail = false

    private var duas: [FortressDua] {
        duaService.getDuas(for: category)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category Header
                categoryHeader

                // Duas List
                LazyVStack(spacing: 12) {
                    ForEach(duas) { dua in
                        FortressDuaDetailCard(
                            dua: dua,
                            duaService: duaService,
                            onTap: {
                                selectedDua = dua
                                showingDetail = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingDetail) {
            if let dua = selectedDua {
                DuaDetailView(dua: dua, duaService: duaService)
            }
        }
    }

    // MARK: - Category Header

    private var categoryHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        .linearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: category.icon)
                    .font(.system(size: 35))
                    .foregroundStyle(.white)
            }

            Text(category.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Label("\(duas.count) duas", systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: category.color)
    }
}

// MARK: - Fortress Dua Detail Card

struct FortressDuaDetailCard: View {
    let dua: FortressDua
    @Bindable var duaService: FortressDuaService
    let onTap: () -> Void

    private var isFavorite: Bool {
        duaService.isFavorite(dua: dua)
    }

    private var usageCount: Int {
        duaService.progress.getUsageCount(duaKey: DuaProgress.stableKey(for: dua))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with title and favorite button
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
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Arabic Text
                Text(dua.arabicText)
                    .font(.title3)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)

                // Transliteration
                Text(dua.transliteration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()

                // Translation
                Text(dua.translation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Divider()

                // Footer with reference and usage
                HStack {
                    Label(dua.reference, systemImage: "text.book.closed")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if usageCount > 0 {
                        Label("\(usageCount)x", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFavorite ? .red.opacity(0.3) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DuaCategoryView(
            category: .waking,
            duaService: FortressDuaService()
        )
    }
}
