//
//  VerseProgressDetailView.swift
//  QuranNoor
//
//  Verse-level progress with Arabic hero header, elegant grid, and toggle actions
//

import SwiftUI

struct VerseProgressDetailView: View {
    let surah: Surah
    var viewModel: ProgressManagementViewModel

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var verseStates: [Int: Bool] = [:]
    @State private var showingMarkAllConfirmation = false
    @State private var markAllAsRead = true
    @State private var selectedVerseToScroll: Int?

    private let quranService = QuranService.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.sectionSpacing) {
                        heroHeader

                        progressBar

                        verseGrid
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.screenVertical)
                }
            }
            .navigationTitle(surah.englishName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            goToFirstUnread()
                        } label: {
                            Label("Go to First Unread", systemImage: "arrow.forward.to.line")
                        }
                        .disabled(allVersesRead)

                        Divider()

                        Button {
                            markAllAsRead = true
                            showingMarkAllConfirmation = true
                        } label: {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                        }

                        Button {
                            markAllAsRead = false
                            showingMarkAllConfirmation = true
                        } label: {
                            Label("Mark All Unread", systemImage: "circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear { loadVerseStates() }
            .confirmationDialog(
                markAllAsRead ? "Mark All Read" : "Mark All Unread",
                isPresented: $showingMarkAllConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    markAllAsRead ? "Mark All Read" : "Mark All Unread",
                    role: markAllAsRead ? .none : .destructive
                ) {
                    confirmMarkAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(markAllAsRead
                    ? "Mark all \(surah.numberOfVerses) verses as read?"
                    : "Mark all \(surah.numberOfVerses) verses as unread?")
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: Spacing.sm) {
            // Arabic name as hero
            Text(surah.name)
                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 36))
                .foregroundColor(themeManager.currentTheme.accent)

            // English names
            Text(surah.englishName)
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text(surah.englishNameTranslation)
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.textTertiary)

            IslamicDivider(style: .ornamental, color: themeManager.currentTheme.accent.opacity(0.3))

            // Surah metadata
            HStack(spacing: Spacing.md) {
                metadataItem(text: "\(surah.numberOfVerses) Verses")
                metadataItem(text: surah.revelationType.rawValue)
                metadataItem(text: "Surah \(surah.id)")
            }
        }
        .padding(Spacing.md)
        .background(themeManager.currentTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    private func metadataItem(text: String) -> some View {
        Text(text)
            .font(.system(size: FontSizes.xs))
            .foregroundColor(themeManager.currentTheme.textTertiary)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let stats = getSurahStats()

        return VStack(spacing: Spacing.xs) {
            HStack {
                Text("\(stats.readVerses) / \(stats.totalVerses) verses")
                    .font(.system(size: FontSizes.sm, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Text("\(Int(stats.completionPercentage))%")
                    .font(.system(size: FontSizes.sm, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.accent)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.currentTheme.textPrimary.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.currentTheme.accent)
                        .frame(
                            width: geometry.size.width * (stats.completionPercentage / 100),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            // Date info
            HStack(spacing: Spacing.sm) {
                if let firstRead = stats.firstReadDate {
                    dateLabel(prefix: "Started", date: firstRead)
                }
                if let lastRead = stats.lastReadDate {
                    dateLabel(prefix: "Last read", date: lastRead)
                }
                Spacer()
            }
        }
        .padding(Spacing.sm)
        .background(themeManager.currentTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.lg)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    private func dateLabel(prefix: String, date: Date) -> some View {
        Text("\(prefix): \(formatDate(date))")
            .font(.system(size: 11))
            .foregroundColor(themeManager.currentTheme.textTertiary)
    }

    // MARK: - Verse Grid

    private var verseGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Verses")
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            ScrollViewReader { proxy in
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(1...surah.numberOfVerses, id: \.self) { verseNumber in
                        verseCell(verseNumber)
                            .id(verseNumber)
                    }
                }
                .padding(Spacing.sm)
                .background(themeManager.currentTheme.cardColor)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                )
                .onChange(of: selectedVerseToScroll) { _, newValue in
                    if let verse = newValue {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(verse, anchor: .center)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedVerseToScroll = nil
                        }
                    }
                }
            }
        }
    }

    private func verseCell(_ verseNumber: Int) -> some View {
        let isRead = verseStates[verseNumber] ?? false

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                toggleVerse(verseNumber)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: BorderRadius.md)
                    .fill(
                        isRead
                            ? themeManager.currentTheme.accent
                            : themeManager.currentTheme.textPrimary.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BorderRadius.md)
                            .stroke(
                                isRead
                                    ? themeManager.currentTheme.accent.opacity(0.6)
                                    : themeManager.currentTheme.borderColor,
                                lineWidth: 0.5
                            )
                    )

                VStack(spacing: 2) {
                    Text("\(verseNumber)")
                        .font(.system(size: FontSizes.base, weight: .medium))
                        .foregroundColor(
                            isRead
                                ? .white
                                : themeManager.currentTheme.textPrimary
                        )

                    if isRead {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func loadVerseStates() {
        var states: [Int: Bool] = [:]
        for verseNumber in 1...surah.numberOfVerses {
            states[verseNumber] = quranService.isVerseRead(
                surahNumber: surah.id,
                verseNumber: verseNumber
            )
        }
        verseStates = states
    }

    private func toggleVerse(_ verseNumber: Int) {
        verseStates[verseNumber]?.toggle()
        quranService.toggleVerseReadStatus(
            surahNumber: surah.id,
            verseNumber: verseNumber
        )
        viewModel.loadProgress()
    }

    private func confirmMarkAll() {
        for verseNumber in 1...surah.numberOfVerses {
            if markAllAsRead {
                verseStates[verseNumber] = true
                quranService.markVerseAsRead(
                    surahNumber: surah.id,
                    verseNumber: verseNumber,
                    manual: true
                )
            } else {
                verseStates[verseNumber] = false
                quranService.markVerseAsUnread(
                    surahNumber: surah.id,
                    verseNumber: verseNumber
                )
            }
        }
        viewModel.loadProgress()
    }

    private func goToFirstUnread() {
        for verseNumber in 1...surah.numberOfVerses {
            if !(verseStates[verseNumber] ?? false) {
                selectedVerseToScroll = verseNumber
                return
            }
        }
    }

    private var allVersesRead: Bool {
        verseStates.values.filter({ !$0 }).isEmpty && !verseStates.isEmpty
    }

    private func getSurahStats() -> SurahProgressStats {
        quranService.getSurahStatistics(
            surahNumber: surah.id,
            totalVerses: surah.numberOfVerses
        )
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Preview

#Preview {
    VerseProgressDetailView(
        surah: Surah(
            id: 1,
            name: "\u{0627}\u{0644}\u{0641}\u{0627}\u{062A}\u{062D}\u{0629}",
            englishName: "Al-Fatihah",
            englishNameTranslation: "The Opening",
            numberOfVerses: 7,
            revelationType: .meccan
        ),
        viewModel: ProgressManagementViewModel()
    )
    .environment(ThemeManager())
}
