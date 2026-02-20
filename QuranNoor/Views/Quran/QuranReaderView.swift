//
//  QuranReaderView.swift
//  QuranNoor
//
//  Quran reader with surah list and progress tracking
//
//  Redesigned as a clean table of contents — minimal, elegant, orderly.
//

import SwiftUI

// MARK: - Revelation Filter

enum RevelationFilter: String, CaseIterable {
    case all = "All"
    case meccan = "Meccan"
    case medinan = "Medinan"
}

// MARK: - Search Scope

enum SearchScope: String, CaseIterable {
    case surahs = "Surahs"
    case verses = "Verses"
}

// MARK: - QuranReaderView

struct QuranReaderView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Bindable var viewModel: QuranViewModel
    @State private var showingVerseReader = false
    @State private var showProgressManagement = false
    @State private var showingResetConfirmation = false
    @State private var selectedSurahForReset: Surah?
    @State private var activeFilter: RevelationFilter = .all
    @State private var searchScope: SearchScope = .surahs
    @State private var verseSearchTask: Task<Void, Never>?
    @State private var navigateToSurah: Surah?
    @State private var navigateToVerse: Int?
    @AppStorage("hideProgressBanner") private var hideProgressBanner = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                GradientBackground(style: .quran, opacity: 0.3)

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        // Header
                        headerSection
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Progress summary (compact single line)
                        if viewModel.getProgressPercentage() > 0 {
                            progressSummary
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }

                        // Content: verse search results or surah list
                        if !viewModel.searchQuery.isEmpty && searchScope == .verses {
                            verseSearchResultsView
                                .padding(.top, Spacing.xs)
                        } else {
                            // Filter controls
                            filterControls
                                .padding(.horizontal)
                                .padding(.top, Spacing.sm)

                            // Surah list
                            surahList
                                .padding(.top, Spacing.xxs)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Holy Quran")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: searchScope == .surahs ? "Search surahs..." : "Search verses in English..."
            )
            .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                if searchScope == .surahs {
                    viewModel.searchSurahs(newValue)
                } else {
                    triggerVerseSearch(newValue)
                }
            }
            .toolbar {
                // Search scope picker - shows when search is active
                if !viewModel.searchQuery.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Picker("Search Scope", selection: $searchScope) {
                            ForEach(SearchScope.allCases, id: \.self) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .onChange(of: searchScope) { _, newScope in
                            if newScope == .surahs {
                                viewModel.searchSurahs(viewModel.searchQuery)
                            } else {
                                triggerVerseSearch(viewModel.searchQuery)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProgressManagement = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            .foregroundColor(themeManager.currentTheme.accentMuted)
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("View reading progress")
                    .accessibilityHint("Shows your Quran reading statistics and progress management")
                }
            }
            .fullScreenCover(isPresented: $showingVerseReader) {
                if let surah = viewModel.selectedSurah {
                    VerseReaderView(surah: surah, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showProgressManagement) {
                ProgressManagementView()
                    .environment(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Reset Progress",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Progress", role: .destructive) {
                    if let surah = selectedSurahForReset {
                        resetSurahProgress(surah)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let surah = selectedSurahForReset {
                    Text("This will reset your progress for \(surah.englishName). You can track it again by reading.")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func resetSurahProgress(_ surah: Surah) {
        QuranService.shared.resetSurahProgress(surahNumber: surah.id)
        #if DEBUG
        print("Reset progress for \(surah.englishName) from QuranReaderView")
        #endif
    }

    private func applyFilter(_ filter: RevelationFilter) {
        activeFilter = filter
        switch filter {
        case .all:
            viewModel.filterByRevelationType(nil)
        case .meccan:
            viewModel.filterByRevelationType(.meccan)
        case .medinan:
            viewModel.filterByRevelationType(.medinan)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("القرآن الكريم")
                .font(.system(size: 34, weight: .regular, design: .default))
                .foregroundColor(themeManager.currentTheme.accent)

            Text("The Noble Quran")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Progress Summary (compact)

    private var progressSummary: some View {
        Button {
            showProgressManagement = true
        } label: {
            HStack(spacing: 12) {
                ProgressRing(
                    progress: viewModel.getProgressPercentage() / 100,
                    lineWidth: 3,
                    size: 32,
                    showPercentage: false,
                    color: themeManager.currentTheme.accent
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.readingProgress?.totalVersesRead ?? 0) of 6,236 verses read")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("\(viewModel.getStreakText()) streak · Last: \(viewModel.getLastReadSurahName())")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                if !hideProgressBanner {
                    Button {
                        hideProgressBanner = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(themeManager.currentTheme.cardColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Verse Search Helpers

    private func triggerVerseSearch(_ query: String) {
        verseSearchTask?.cancel()
        guard !query.isEmpty else {
            viewModel.verseSearchResults = []
            viewModel.isSearchingVerses = false
            return
        }
        // Debounce: wait 500ms before firing the search
        verseSearchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.searchVerses(query)
        }
    }

    // MARK: - Filter Controls

    private var filterControls: some View {
        HStack(spacing: 0) {
            ForEach(RevelationFilter.allCases, id: \.self) { filter in
                let count: Int = {
                    switch filter {
                    case .all: return viewModel.totalSurahs
                    case .meccan: return viewModel.meccanCount
                    case .medinan: return viewModel.medinanCount
                    }
                }()

                FilterButton(
                    title: "\(filter.rawValue) (\(count))",
                    isSelected: activeFilter == filter
                ) {
                    applyFilter(filter)
                }

                if filter != .medinan {
                    Spacer()
                }
            }
        }
    }

    // MARK: - Surah List

    private var surahList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.filteredSurahs) { surah in
                let progress = viewModel.getSurahProgress(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses
                )

                Button {
                    viewModel.selectSurah(surah)
                    showingVerseReader = true
                } label: {
                    SurahRow(
                        surah: surah,
                        progress: progress
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        viewModel.selectSurah(surah)
                        showProgressManagement = true
                    } label: {
                        Label("View Progress Details", systemImage: "chart.bar")
                    }

                    if progress > 0 {
                        Button(role: .destructive) {
                            selectedSurahForReset = surah
                            showingResetConfirmation = true
                        } label: {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        }
                    }
                }

                // Subtle divider between rows
                if surah.id != viewModel.filteredSurahs.last?.id {
                    Rectangle()
                        .fill(themeManager.currentTheme.borderColor.opacity(0.5))
                        .frame(height: 0.5)
                        .padding(.leading, 60)
                        .padding(.trailing, 16)
                }
            }
        }
    }

    // MARK: - Verse Search Results

    private var verseSearchResultsView: some View {
        let theme = themeManager.currentTheme

        return Group {
            if viewModel.isSearchingVerses {
                // Loading state
                VStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(1.1)
                        .tint(theme.accent)

                    Text("Searching verses...")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xl)
            } else if viewModel.verseSearchResults.isEmpty {
                // Empty state
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(theme.textTertiary.opacity(0.6))

                    Text("No matching verses")
                        .font(.system(size: FontSizes.base, weight: .medium))
                        .foregroundColor(theme.textSecondary)

                    Text("Try different keywords in English")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xl)
            } else {
                // Results list
                LazyVStack(spacing: 0) {
                    // Results count
                    HStack {
                        Text("\(viewModel.verseSearchResults.count) result\(viewModel.verseSearchResults.count == 1 ? "" : "s")")
                            .font(.system(size: FontSizes.xs, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.xxs)

                    ForEach(viewModel.verseSearchResults) { result in
                        Button {
                            navigateToVerseResult(result)
                        } label: {
                            VerseSearchResultRow(
                                result: result,
                                query: viewModel.searchQuery
                            )
                        }
                        .buttonStyle(.plain)

                        // Divider
                        if result.id != viewModel.verseSearchResults.last?.id {
                            Rectangle()
                                .fill(theme.borderColor.opacity(0.5))
                                .frame(height: 0.5)
                                .padding(.leading, Spacing.sm)
                                .padding(.trailing, Spacing.sm)
                        }
                    }
                }
            }
        }
    }

    private func navigateToVerseResult(_ result: VerseSearchResult) {
        if let surah = viewModel.surahs.first(where: { $0.id == result.surahNumber }) {
            viewModel.selectSurah(surah)
            showingVerseReader = true
        }
    }
}

// MARK: - Verse Search Result Row

struct VerseSearchResultRow: View {
    let result: VerseSearchResult
    let query: String
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Surah name and verse number
            HStack(spacing: Spacing.xxs) {
                Text(result.surahName)
                    .font(.system(size: FontSizes.sm, weight: .semibold))
                    .foregroundColor(theme.accent)

                Text("·")
                    .foregroundColor(theme.textTertiary)

                Text("Verse \(result.verseNumber)")
                    .font(.system(size: FontSizes.sm, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: FontSizes.xs))
                    .foregroundColor(theme.textTertiary)
            }

            // Matched translation text with highlighting
            Text(highlightedText)
                .font(.system(size: FontSizes.sm))
                .foregroundColor(theme.textSecondary)
                .lineLimit(3)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }

    /// Build an AttributedString that highlights query words in the matched text
    private var highlightedText: AttributedString {
        let text = result.matchedText
        var attributed = AttributedString(text)

        let queryWords = query.lowercased().split(separator: " ").map(String.init)
        let lowercasedText = text.lowercased()

        for word in queryWords {
            var searchStart = lowercasedText.startIndex
            while searchStart < lowercasedText.endIndex,
                  let range = lowercasedText.range(of: word, range: searchStart..<lowercasedText.endIndex) {
                // Convert String.Index range to AttributedString range
                if let attrRange = Range(range, in: attributed) {
                    attributed[attrRange].foregroundColor = themeManager.currentTheme.accent
                    attributed[attrRange].font = .system(size: FontSizes.sm, weight: .semibold)
                }
                searchStart = range.upperBound
            }
        }

        return attributed
    }
}

// MARK: - Surah Row

struct SurahRow: View {
    let surah: Surah
    let progress: Double // 0-100
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Surah number badge (diamond/octagonal Islamic motif)
            surahNumberBadge
                .frame(width: 42, height: 42)

            // Center: name and metadata
            VStack(alignment: .leading, spacing: 3) {
                // English name (primary text, bold)
                Text(surah.englishName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // Subtitle: translation + verse count + revelation type
                Text("\(surah.englishNameTranslation) · \(surah.numberOfVerses) verses · \(surah.revelationType.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .lineLimit(1)

                // Progress bar — only if progress > 0
                if progress > 0 {
                    progressBar
                }
            }

            Spacer(minLength: 8)

            // Arabic name (right-aligned)
            Text(surah.name)
                .font(.system(size: 22, weight: .regular, design: .default))
                .foregroundColor(themeManager.currentTheme.accent)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Number Badge

    private var surahNumberBadge: some View {
        ZStack {
            // Octagonal shape (Islamic geometric motif)
            OctagonShape()
                .stroke(
                    progress >= 100
                        ? themeManager.currentTheme.accent
                        : themeManager.currentTheme.accentMuted.opacity(0.4),
                    lineWidth: 1.2
                )

            OctagonShape()
                .fill(
                    progress >= 100
                        ? themeManager.currentTheme.accent.opacity(0.12)
                        : Color.clear
                )

            if progress >= 100 {
                // Completed: checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.accent)
            } else {
                // Surah number
                Text("\(surah.id)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(themeManager.currentTheme.borderColor)
                        .frame(height: 3)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accent,
                                    themeManager.currentTheme.accentMuted
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (progress / 100),
                            height: 3
                        )
                }
            }
            .frame(height: 3)

            Text("\(Int(progress))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.currentTheme.accentMuted)
                .monospacedDigit()
        }
        .padding(.top, 2)
    }
}

// MARK: - Octagon Shape

struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Inset factor — controls how "cut" the corners are
        let f: CGFloat = 0.29

        var path = Path()
        path.move(to: CGPoint(x: w * f, y: 0))
        path.addLine(to: CGPoint(x: w * (1 - f), y: 0))
        path.addLine(to: CGPoint(x: w, y: h * f))
        path.addLine(to: CGPoint(x: w, y: h * (1 - f)))
        path.addLine(to: CGPoint(x: w * (1 - f), y: h))
        path.addLine(to: CGPoint(x: w * f, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * (1 - f)))
        path.addLine(to: CGPoint(x: 0, y: h * f))
        path.closeSubpath()
        return path
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accent.opacity(0.12)
                        : Color.clear
                )
                .foregroundColor(
                    isSelected
                        ? themeManager.currentTheme.accent
                        : themeManager.currentTheme.textTertiary
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                                ? themeManager.currentTheme.accent.opacity(0.4)
                                : themeManager.currentTheme.borderColor,
                            lineWidth: 0.5
                        )
                )
        }
    }
}

// MARK: - Preview
#Preview {
    QuranReaderView(viewModel: QuranViewModel())
        .environment(ThemeManager())
}
