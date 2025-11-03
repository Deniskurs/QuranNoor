//
//  VerseReaderView.swift
//  QuranNoor
//
//  Verse reader with Arabic text, translations, and bookmarks
//

import SwiftUI

struct VerseReaderView: View {
    // MARK: - Properties
    let surah: Surah
    @ObservedObject var viewModel: QuranViewModel

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var verses: [Verse] = []
    @State private var currentVerseIndex: Int = 0
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var translations: [Int: Translation] = [:]  // Verse number → Translation
    @State private var isLoadingTranslations = false
    @State private var trackedVerses: Set<String> = []  // Track verses already marked as read (prevents duplicates)
    @State private var dwellTimers: [String: Task<Void, Never>] = [:]  // Active dwell timers for each verse
    @State private var debounceTimers: [String: Task<Void, Never>] = [:]  // Debounce timers for smooth tracking

    // MARK: - Performance Optimization: Cached Read States
    /// Cached verse read states to prevent querying on every render (120fps = 4,800 queries/sec)
    @State private var verseReadStates: [Int: VerseReadState] = [:]

    struct VerseReadState: Equatable {
        let isRead: Bool
        let timestamp: Date?
    }

    private let quranService = QuranService.shared
    private let dwellTime: TimeInterval = 3.0  // How long verse must be visible before marking as read
    private let debounceDelay: TimeInterval = 0.3  // Wait 300ms before starting dwell timer (reduces jitter)

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                GradientBackground(style: .quran, opacity: 0.2)

                if isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AppColors.primary.teal)

                        ThemedText("Loading verses...", style: .body)
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                    }
                } else if let error = loadError {
                    // Error state
                    VStack(spacing: 20) {
                        CardView {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.primary.gold)

                                ThemedText("Failed to Load Surah", style: .heading)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                ThemedText(error.localizedDescription, style: .body)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.7)

                                Button {
                                    Task {
                                        await loadVerses()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        ThemedText("Retry", style: .body)
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(AppColors.primary.teal)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                        .padding()
                    }
                } else {
                    // Content loaded
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Surah Header
                                surahHeader

                                // Bismillah (except for Surah 9)
                                if surah.id != 9 && surah.id != 1 {
                                    bismillahView
                                }

                                // Verses with native scroll visibility tracking
                                ForEach(Array(verses.enumerated()), id: \.element.id) { index, verse in
                                    verseCard(verse: verse, index: index)
                                        .id(verse.id)
                                        .onScrollVisibilityChange(threshold: 0.8) { isVisible in
                                            handleVerseVisibilityChange(
                                                isVisible: isVisible,
                                                surahNumber: surah.id,
                                                verseNumber: verse.verseNumber
                                            )
                                        }
                                }

                                // End ornament
                                endOrnament
                            }
                            .padding()
                        }
                        .refreshable {
                            await loadVerses()
                        }
                    }
                }
            }
            .navigationTitle(surah.englishName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Share surah
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            // Audio player
                        } label: {
                            Label("Listen", systemImage: "play.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                Task {
                    await loadVerses()
                }
            }
        }
    }

    // MARK: - Components

    private var surahHeader: some View {
        CardView(showPattern: true) {
            VStack(spacing: 12) {
                // Arabic name
                ThemedText.arabic(surah.name)
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.primary.gold)

                // English names
                VStack(spacing: 4) {
                    ThemedText(surah.englishName, style: .heading)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    ThemedText.caption(surah.englishNameTranslation)
                        .opacity(0.7)
                }

                IslamicDivider(style: .ornamental, color: AppColors.primary.gold.opacity(0.3))

                // Surah info
                HStack(spacing: 20) {
                    infoItem(icon: "doc.text", text: "\(surah.numberOfVerses) Verses")
                    infoItem(icon: "mappin.and.ellipse", text: surah.revelationType.rawValue)
                    infoItem(icon: "number", text: "Surah \(surah.id)")
                }
            }
        }
    }

    private func infoItem(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary.teal)
                .font(.system(size: 16))

            ThemedText.caption(text)
                .opacity(0.8)
        }
    }

    private var bismillahView: some View {
        CardView {
            VStack(spacing: 8) {
                ThemedText.arabic("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary.gold)

                ThemedText.caption("In the name of Allah, the Most Gracious, the Most Merciful")
                    .italic()
                    .opacity(0.7)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func verseCard(verse: Verse, index: Int) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Verse header
                HStack {
                    // Verse number badge
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.green.opacity(0.2))
                            .frame(width: 36, height: 36)

                        ThemedText("\(verse.verseNumber)", style: .body)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    // Read status indicator (using cached state for 120fps performance)
                    VerseReadIndicator(
                        isRead: verseReadStates[verse.verseNumber]?.isRead ?? false,
                        readDate: verseReadStates[verse.verseNumber]?.timestamp,
                        onToggle: {
                            // Optimistic update: Update cache immediately for instant UI feedback
                            let currentState = verseReadStates[verse.verseNumber]
                            let newIsRead = !(currentState?.isRead ?? false)
                            verseReadStates[verse.verseNumber] = VerseReadState(
                                isRead: newIsRead,
                                timestamp: newIsRead ? Date() : nil
                            )

                            // Async backend update
                            viewModel.toggleVerseReadStatus(
                                surahNumber: surah.id,
                                verseNumber: verse.verseNumber
                            )
                        }
                    )

                    // Bookmark button
                    Button {
                        toggleBookmark(verse: verse)
                    } label: {
                        Image(systemName: isBookmarked(verse: verse) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(AppColors.primary.gold)
                            .font(.system(size: 20))
                    }
                }

                IslamicDivider(style: .geometric, color: AppColors.primary.gold.opacity(0.2))

                // Arabic text
                ThemedText.arabic(verse.text)
                    .font(.system(size: 28))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)

                IslamicDivider(style: .simple)

                // Translation
                VStack(alignment: .leading, spacing: 8) {
                    if let translation = translations[verse.number] {
                        ThemedText.body(translation.text)
                            .opacity(0.9)
                            .lineSpacing(6)

                        ThemedText.caption("— \(translation.author)")
                            .italic()
                            .foregroundColor(AppColors.primary.teal)
                            .opacity(0.7)
                    } else if isLoadingTranslations {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            ThemedText.caption("Loading translation...")
                                .opacity(0.5)
                        }
                    } else {
                        // Fallback to sample translation
                        let fallback = quranService.getSampleTranslation(forVerse: verse)
                        ThemedText.body(fallback.text)
                            .opacity(0.7)
                            .italic()
                    }
                }
            }
        }
    }

    private var endOrnament: some View {
        VStack(spacing: 12) {
            IslamicDivider(style: .crescent, color: AppColors.primary.gold)

            ThemedText("End of Surah \(surah.englishName)", style: .caption)
                .foregroundColor(AppColors.primary.gold)
                .opacity(0.7)

            IslamicDivider(style: .crescent, color: AppColors.primary.gold)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Private Methods

    /// Handle verse visibility changes from native scroll tracking
    private func handleVerseVisibilityChange(isVisible: Bool, surahNumber: Int, verseNumber: Int) {
        let verseId = "\(surahNumber):\(verseNumber)"

        if isVisible {
            // Verse became visible
            guard !trackedVerses.contains(verseId) else { return }

            // Cancel any existing timers for this verse
            debounceTimers[verseId]?.cancel()
            dwellTimers[verseId]?.cancel()

            // Start debounce timer (wait 300ms before starting dwell timer)
            // This smooths out jittery scroll behavior
            debounceTimers[verseId] = Task {
                try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))

                // Check if debounce wasn't cancelled
                guard !Task.isCancelled else { return }

                #if DEBUG
                await MainActor.run {
                    print("👁️ Verse became visible: \(verseId) - starting \(dwellTime)s dwell timer")
                }
                #endif

                // Now start the actual dwell timer
                await MainActor.run {
                    dwellTimers[verseId] = Task {
                        // Wait for dwell time (realistic reading duration)
                        try? await Task.sleep(nanoseconds: UInt64(dwellTime * 1_000_000_000))

                        // Check if task wasn't cancelled
                        guard !Task.isCancelled else { return }

                        // Mark verse as read
                        await MainActor.run {
                            markVerseAsRead(surahNumber: surahNumber, verseNumber: verseNumber)
                        }
                    }
                }
            }

        } else {
            // Verse is no longer visible - cancel all timers
            debounceTimers[verseId]?.cancel()
            debounceTimers[verseId] = nil
            dwellTimers[verseId]?.cancel()
            dwellTimers[verseId] = nil

            #if DEBUG
            if !trackedVerses.contains(verseId) {
                print("👋 Verse left viewport: \(verseId) - timers cancelled")
            }
            #endif
        }
    }

    /// Mark a verse as read with duplicate prevention
    private func markVerseAsRead(surahNumber: Int, verseNumber: Int) {
        let verseId = "\(surahNumber):\(verseNumber)"

        // Prevent duplicate tracking in this session
        guard !trackedVerses.contains(verseId) else {
            return
        }

        // Mark as tracked in this session
        trackedVerses.insert(verseId)

        // Clean up all timers for this verse
        debounceTimers[verseId]?.cancel()
        debounceTimers[verseId] = nil
        dwellTimers[verseId]?.cancel()
        dwellTimers[verseId] = nil

        // Optimistic update: Update cache immediately for instant UI feedback
        verseReadStates[verseNumber] = VerseReadState(isRead: true, timestamp: Date())

        // Update progress in view model (which calls the service) - async backend update
        viewModel.updateProgress(surahNumber: surahNumber, verseNumber: verseNumber)

        #if DEBUG
        print("📖 Marked verse as read: \(verseId) (80% visible, 3s dwell, 0.3s debounce)")
        #endif
    }

    /// Load all verse read states at once (called once per surah load)
    private func loadVerseReadStates() {
        var states: [Int: VerseReadState] = [:]

        for verse in verses {
            let isRead = viewModel.isVerseRead(
                surahNumber: surah.id,
                verseNumber: verse.verseNumber
            )

            states[verse.verseNumber] = VerseReadState(
                isRead: isRead,
                timestamp: isRead ? viewModel.getVerseReadTimestamp(
                    surahNumber: surah.id,
                    verseNumber: verse.verseNumber
                ) : nil
            )
        }

        verseReadStates = states

        #if DEBUG
        let readCount = states.values.filter { $0.isRead }.count
        print("🔄 Loaded \(verses.count) verse read states (\(readCount) read)")
        #endif
    }

    private func loadVerses() async {
        isLoading = true
        loadError = nil

        do {
            verses = try await quranService.getVerses(forSurah: surah.id)
            isLoading = false

            // Load verse read states immediately after verses load (performance optimization)
            loadVerseReadStates()

            // Load translations after verses are loaded
            await loadTranslations()
        } catch {
            loadError = error
            isLoading = false
            print("Failed to load verses for Surah \(surah.id): \(error)")
            // Fallback to sample data
            verses = quranService.getSampleVerses(forSurah: surah.id)

            // Load read states even for fallback data
            loadVerseReadStates()
        }
    }

    private func loadTranslations() async {
        isLoadingTranslations = true

        // Load translations for all verses concurrently (in batches to avoid overwhelming API)
        // Reduced batch size from 10 to 5 to prevent rate limiting (429 errors)
        let batchSize = 5
        let batches = stride(from: 0, to: verses.count, by: batchSize).map {
            Array(verses[$0..<min($0 + batchSize, verses.count)])
        }

        for (index, batch) in batches.enumerated() {
            await withTaskGroup(of: (Int, Translation?).self) { group in
                for verse in batch {
                    group.addTask {
                        do {
                            let translation = try await self.quranService.getTranslation(forVerse: verse)
                            return (verse.number, translation)
                        } catch {
                            // Silently fail for translations - fallback will be used
                            // Only log non-rate-limit errors
                            if case APIError.serverError(let code) = error, code != 429 {
                                print("Failed to load translation for verse \(verse.number): \(error)")
                            }
                            return (verse.number, nil)
                        }
                    }
                }

                for await (verseNumber, translation) in group {
                    if let translation = translation {
                        translations[verseNumber] = translation
                    }
                }
            }

            // Add 200ms delay between batches to respect API rate limits
            // Skip delay after the last batch
            if index < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 200_000_000)  // 200ms
            }
        }

        isLoadingTranslations = false
    }

    private func isBookmarked(verse: Verse) -> Bool {
        return quranService.isBookmarked(surahNumber: surah.id, verseNumber: verse.verseNumber)
    }

    private func toggleBookmark(verse: Verse) {
        if isBookmarked(verse: verse) {
            // Find and remove bookmark
            if let bookmark = viewModel.bookmarks.first(where: { $0.surahNumber == surah.id && $0.verseNumber == verse.verseNumber }) {
                quranService.removeBookmark(id: bookmark.id)
                HapticManager.shared.triggerPattern(.bookmarkRemoved)
            }
        } else {
            quranService.addBookmark(surahNumber: surah.id, verseNumber: verse.verseNumber)
            HapticManager.shared.triggerPattern(.bookmarkAdded)
        }
        viewModel.loadBookmarks()
    }
}

// MARK: - Preview
#Preview {
    VerseReaderView(
        surah: Surah(
            id: 1,
            name: "الفاتحة",
            englishName: "Al-Fatihah",
            englishNameTranslation: "The Opening",
            numberOfVerses: 7,
            revelationType: .meccan
        ),
        viewModel: QuranViewModel()
    )
    .environmentObject(ThemeManager())
}
