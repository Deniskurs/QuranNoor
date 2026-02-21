//
//  VerseReaderView.swift
//  QuranNoor
//
//  Immersive mushaf-quality verse reader with Uthmanic calligraphy,
//  verse markers, and sacred reading experience
//

import SwiftUI

struct VerseReaderView: View {
    // MARK: - Properties
    let initialSurah: Surah
    var viewModel: QuranViewModel

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var surah: Surah
    @State private var verses: [Verse] = []
    @State private var currentVerseIndex: Int = 0
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var translations: [Int: Translation] = [:]  // Verse number -> Translation
    @State private var isLoadingTranslations = false
    @State private var visibleVerses: Set<String> = []  // Currently visible verse IDs
    @State private var dwellTask: Task<Void, Never>?  // Single dwell timer for all visible verses
    @State private var showingTranslationSelector = false
    @State private var selectedTranslation: TranslationEdition = .sahihInternational
    @State private var audioService = QuranAudioService.shared
    @State private var showCategoryPicker = false
    @State private var pendingBookmarkVerse: Verse?
    @State private var showFullPlayer = false

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .success

    // Continue to next surah state
    @State private var isTransitioningToNextSurah = false

    // Share sheet state
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    // MARK: - Performance Optimization: Cached Read States
    @State private var verseReadStates: [Int: VerseReadState] = [:]

    // MARK: - Initializer
    init(surah: Surah, viewModel: QuranViewModel) {
        self.initialSurah = surah
        self.viewModel = viewModel
        self._surah = State(initialValue: surah)
    }

    struct VerseReadState: Equatable {
        let isRead: Bool
        let timestamp: Date?
    }

    private let quranService = QuranService.shared
    private let dwellTime: TimeInterval = 3.0

    // MARK: - Body
    var body: some View {
        let theme = themeManager.currentTheme

        NavigationStack {
            ZStack(alignment: .bottom) {
                // Solid theme background -- no gradient, let the text breathe
                theme.backgroundColor
                    .ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if let error = loadError {
                    errorState(error)
                } else {
                    contentView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(surah.name)
                            .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 18))
                            .foregroundColor(theme.textPrimary)
                        Text(surah.englishName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingTranslationSelector = true
                        } label: {
                            Label("Translation: \(selectedTranslation.displayName)", systemImage: "text.book.closed")
                        }

                        // Reciter submenu
                        Menu {
                            ForEach(Reciter.allCases) { reciter in
                                Button {
                                    audioService.selectedReciter = reciter
                                    toastMessage = "Reciter: \(reciter.shortName)"
                                    toastStyle = .info
                                    showToast = true
                                } label: {
                                    HStack {
                                        Text(reciter.displayName)
                                        if audioService.selectedReciter == reciter {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Reciter: \(audioService.selectedReciter.shortName)", systemImage: "person.wave.2")
                        }

                        Divider()

                        Button {
                            shareSurah()
                        } label: {
                            Label("Share Surah", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.backgroundColor.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                selectedTranslation = quranService.getTranslationPreferences().primaryTranslation
                Task {
                    await loadVerses()
                }
            }
            .sheet(isPresented: $showingTranslationSelector) {
                TranslationSelectorView(
                    currentPreferences: quranService.getTranslationPreferences()
                ) { edition in
                    selectedTranslation = edition
                    Task {
                        await loadTranslations(for: verses)
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCategoryPicker) {
                BookmarkCategoryPickerSheet { category in
                    if let verse = pendingBookmarkVerse {
                        saveBookmark(verse: verse, category: category)
                        pendingBookmarkVerse = nil
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .toast(message: toastMessage, style: toastStyle, isPresented: $showToast)
            .sheet(isPresented: $showFullPlayer) {
                AudioPlayerView {
                    showFullPlayer = false
                }
                .presentationDragIndicator(.visible)
                .presentationBackground(themeManager.currentTheme.backgroundColor)
            }
            .sheet(isPresented: $showShareSheet) {
                if #available(iOS 16.0, *) {
                    ShareSheet(items: shareItems)
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.currentTheme.accent)

            Text("Loading verses...")
                .font(.system(size: 15))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    // MARK: - Error State

    private func errorState(_ error: Error) -> some View {
        let theme = themeManager.currentTheme

        return VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(theme.accent)

            VStack(spacing: 8) {
                Text("Failed to Load Surah")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                Task {
                    await loadVerses()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(theme.accent)
                )
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        let theme = themeManager.currentTheme

        return ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Surah Header
                        surahHeader
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                            .id("surah-header-top")

                        // Bismillah (except for Surah At-Tawbah and Al-Fatihah)
                        if surah.id != 9 && surah.id != 1 {
                            bismillahView
                                .padding(.bottom, 20)
                        }

                        // Prominent play button
                        surahPlayButton

                        // Verses
                        ForEach(Array(verses.enumerated()), id: \.element.id) { index, verse in
                            VStack(spacing: 0) {
                                if index > 0 {
                                    // Subtle divider between verses
                                    Rectangle()
                                        .fill(theme.borderColor.opacity(0.5))
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 24)
                                }

                                verseRow(verse: verse, index: index)
                            }
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

                        // Continue to next surah card
                        nextSurahContinuationCard {
                            navigateToNextSurah(proxy: proxy)
                        }

                        // Bottom padding for audio pill
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 4)
                }
                .refreshable {
                    await loadVerses()
                }
                .onChange(of: audioService.currentVerse) { oldVerse, newVerse in
                    if let playingVerse = newVerse, audioService.playbackState.isPlaying {
                        // Find matching verse in our loaded list (UUIDs differ between loads)
                        if let match = verses.first(where: {
                            $0.surahNumber == playingVerse.surahNumber && $0.verseNumber == playingVerse.verseNumber
                        }) {
                            // Delay scroll slightly so highlight animates first ("light then scroll")
                            Task {
                                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(match.id, anchor: UnitPoint(x: 0.5, y: 0.3))
                                }
                            }
                        }
                    }
                }
            }

            // Now Playing indicator (taps to open full player)
            // No animationNamespace — VerseReaderView uses .sheet() for the full player
            MiniAudioPlayerView(
                showSkipControls: false,
                showCloseButton: false,
                animationNamespace: nil,
                onTap: { showFullPlayer = true }
            )
            .padding(.bottom, Spacing.xxs)
        }
    }

    // MARK: - Surah Header

    private var surahHeader: some View {
        let theme = themeManager.currentTheme

        return VStack(spacing: 16) {
            // Arabic surah name -- large, calligraphic
            Text(surah.name)
                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 40))
                .foregroundColor(theme.accent)

            // English name and translation
            VStack(spacing: 4) {
                Text(surah.englishName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(surah.englishNameTranslation)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textTertiary)
            }

            // Surah metadata
            HStack(spacing: 16) {
                metadataLabel(text: "\(surah.numberOfVerses) Verses")
                Text("·")
                    .foregroundColor(theme.textTertiary)
                metadataLabel(text: surah.revelationType.rawValue)
                Text("·")
                    .foregroundColor(theme.textTertiary)
                metadataLabel(text: "Surah \(surah.id)")
            }

            // Ornamental divider
            IslamicDivider(
                style: .ornamental,
                color: theme.accent.opacity(0.3)
            )
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }

    private func metadataLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeManager.currentTheme.textTertiary)
    }

    // MARK: - Bismillah

    private var bismillahView: some View {
        let theme = themeManager.currentTheme

        return VStack(spacing: 10) {
            Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ")
                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 26))
                .foregroundColor(theme.accent)
                .multilineTextAlignment(.center)

            Text("In the name of Allah, the Most Gracious, the Most Merciful")
                .font(.system(size: 13))
                .italic()
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Surah Play Button

    private var surahPlayButton: some View {
        let theme = themeManager.currentTheme

        return Button {
            audioService.continuousPlaybackEnabled = true
            Task {
                do {
                    try await audioService.playVerses(verses, startingAt: 0)
                } catch {
                    showAudioError(error)
                }
            }
            HapticManager.shared.trigger(.selection)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Listen to Surah")
                        .font(.system(size: 14, weight: .semibold))
                    Text(audioService.selectedReciter.shortName)
                        .font(.system(size: 11))
                        .opacity(0.8)
                }
            }
            .foregroundColor(theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(theme.accent.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(theme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.bottom, 16)
    }

    // MARK: - Verse Row

    private func verseRow(verse: Verse, index: Int) -> some View {
        let theme = themeManager.currentTheme
        let isCurrentlyPlaying = audioService.currentVerse?.surahNumber == verse.surahNumber
            && audioService.currentVerse?.verseNumber == verse.verseNumber
            && audioService.playbackState.isPlaying

        return VStack(alignment: .leading, spacing: 16) {
            // Verse header: number circle + action buttons
            HStack(alignment: .center) {
                // Verse number in elegant circle
                verseNumberBadge(number: verse.verseNumber, isPlaying: isCurrentlyPlaying)

                Spacer()

                // Subtle action buttons
                HStack(spacing: 14) {
                    // Play menu
                    Menu {
                        // Primary: Play from this verse through end of surah
                        Button {
                            audioService.continuousPlaybackEnabled = true
                            Task {
                                do {
                                    try await audioService.playVerses(verses, startingAt: index)
                                } catch {
                                    showAudioError(error)
                                }
                            }
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            Label("Play from Here", systemImage: "play.fill")
                        }

                        // Single verse only
                        Button {
                            Task {
                                do {
                                    try await audioService.play(verse: verse)
                                } catch {
                                    showAudioError(error)
                                }
                            }
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            Label("Play This Verse", systemImage: "play.circle")
                        }

                        // Full surah
                        Button {
                            audioService.continuousPlaybackEnabled = true
                            Task {
                                do {
                                    try await audioService.playVerses(verses, startingAt: 0)
                                } catch {
                                    showAudioError(error)
                                }
                            }
                            HapticManager.shared.trigger(.selection)
                        } label: {
                            Label("Play Entire Surah", systemImage: "play.rectangle.fill")
                        }
                    } label: {
                        Image(systemName: isCurrentlyPlaying ? "speaker.wave.2.fill" : "play.circle")
                            .font(.system(size: 20))
                            .foregroundColor(isCurrentlyPlaying ? theme.accent : theme.textTertiary)
                    }
                    .accessibilityLabel("Play options for verse \(verse.verseNumber)")

                    // Read status indicator
                    VerseReadIndicator(
                        isRead: verseReadStates[verse.verseNumber]?.isRead ?? false,
                        readDate: verseReadStates[verse.verseNumber]?.timestamp,
                        onToggle: {
                            let currentState = verseReadStates[verse.verseNumber]
                            let newIsRead = !(currentState?.isRead ?? false)
                            verseReadStates[verse.verseNumber] = VerseReadState(
                                isRead: newIsRead,
                                timestamp: newIsRead ? Date() : nil
                            )
                            viewModel.toggleVerseReadStatus(
                                surahNumber: surah.id,
                                verseNumber: verse.verseNumber
                            )
                            if newIsRead {
                                toastMessage = "Verse marked as read"
                                toastStyle = .spiritual
                                showToast = true
                            }
                        }
                    )

                    // Bookmark button
                    Button {
                        toggleBookmark(verse: verse)
                    } label: {
                        Image(systemName: isBookmarked(verse: verse) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18))
                            .foregroundColor(
                                isBookmarked(verse: verse) ? theme.accent : theme.textTertiary
                            )
                    }

                    // Share verse button
                    Button {
                        shareVerse(verse)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }

            // Arabic text -- the HERO
            Text(verse.text + " \u{FD3F}\(verse.verseNumber.arabicNumerals)\u{FD3E}")
                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 28))
                .foregroundColor(isCurrentlyPlaying ? theme.accent : theme.textPrimary)
                .animation(.easeInOut(duration: 0.5), value: isCurrentlyPlaying)
                .lineSpacing(16)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            // Translation
            translationSection(for: verse)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .playingVerseHighlight(isPlaying: isCurrentlyPlaying, accentColor: theme.accent)
    }

    // MARK: - Verse Number Badge

    private func verseNumberBadge(number: Int, isPlaying: Bool) -> some View {
        let theme = themeManager.currentTheme

        return ZStack {
            Circle()
                .stroke(
                    isPlaying ? theme.accent : theme.borderColor,
                    lineWidth: isPlaying ? 2 : 1
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            isPlaying
                                ? theme.accent.opacity(0.12)
                                : theme.backgroundColor.opacity(0.5)
                        )
                )

            Text("\(number)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isPlaying ? theme.accent : theme.textSecondary)
        }
        .scaleEffect(isPlaying ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPlaying)
    }

    // MARK: - Translation Section

    private func translationSection(for verse: Verse) -> some View {
        let theme = themeManager.currentTheme

        return Group {
            if let translation = translations[verse.number] {
                VStack(alignment: .leading, spacing: 6) {
                    Text(translation.text)
                        .font(.system(size: 15))
                        .foregroundColor(theme.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("-- \(translation.author)")
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(theme.textTertiary)
                }
            } else if isLoadingTranslations {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading translation...")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textTertiary)
                }
            } else {
                // Fallback to sample translation
                let fallback = quranService.getSampleTranslation(forVerse: verse)
                Text(fallback.text)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(6)
                    .italic()
                    .opacity(0.7)
            }
        }
    }

    // MARK: - End Ornament

    private var endOrnament: some View {
        let theme = themeManager.currentTheme

        return VStack(spacing: 12) {
            IslamicDivider(style: .crescent, color: theme.accent.opacity(0.4))

            Text("End of Surah \(surah.englishName)")
                .font(.system(size: 13))
                .foregroundColor(theme.textTertiary)

            IslamicDivider(style: .crescent, color: theme.accent.opacity(0.4))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 40)
    }

    // MARK: - Next Surah Continuation Card

    /// Returns the next surah if the current surah is not the last (114)
    private var nextSurah: Surah? {
        guard surah.id < 114 else { return nil }
        return viewModel.surahs.first(where: { $0.id == surah.id + 1 })
    }

    @ViewBuilder
    private func nextSurahContinuationCard(onContinue: @escaping () -> Void) -> some View {
        let theme = themeManager.currentTheme

        if let next = nextSurah {
            // -- Next surah available: show continuation card --
            VStack(spacing: Spacing.md) {
                // Ornamental divider
                IslamicDivider(style: .ornamental, color: theme.accent.opacity(0.3))
                    .padding(.horizontal, 40)

                // Completion summary for current surah
                VStack(spacing: Spacing.xxxs) {
                    Text("End of \(surah.name)")
                        .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 22))
                        .foregroundColor(theme.accent)

                    Text("\(surah.englishName) · \(surah.numberOfVerses) verses")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(theme.textTertiary)
                }

                // Next surah preview card
                VStack(spacing: Spacing.sm) {
                    // Card header label
                    Text("CONTINUE TO NEXT SURAH")
                        .font(.system(size: FontSizes.xs, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .tracking(1.0)

                    // Next surah info
                    VStack(spacing: Spacing.xs) {
                        Text(next.name)
                            .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 30))
                            .foregroundColor(theme.textPrimary)

                        Text(next.englishName)
                            .font(.system(size: FontSizes.lg, weight: .semibold))
                            .foregroundColor(theme.textPrimary)

                        HStack(spacing: Spacing.xxs) {
                            Text(next.revelationType.rawValue)
                                .font(.system(size: FontSizes.xs, weight: .medium))
                                .foregroundColor(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.accent.opacity(0.12))
                                .cornerRadius(BorderRadius.sm)

                            Text("·")
                                .foregroundColor(theme.textTertiary)

                            Text("\(next.numberOfVerses) verses")
                                .font(.system(size: FontSizes.sm))
                                .foregroundColor(theme.textTertiary)

                            Text("·")
                                .foregroundColor(theme.textTertiary)

                            Text("Surah \(next.id)")
                                .font(.system(size: FontSizes.sm))
                                .foregroundColor(theme.textTertiary)
                        }
                    }

                    // Bismillah preview (except for Surah 9 At-Tawbah)
                    if next.id != 9 {
                        VStack(spacing: 6) {
                            Rectangle()
                                .fill(theme.borderColor.opacity(0.4))
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.md)

                            Text("\u{0628}\u{0650}\u{0633}\u{0645}\u{0650} \u{0627}\u{0644}\u{0644}\u{0647}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0645}\u{0670}\u{0646}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{064A}\u{0645}\u{0650}")
                                .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 20))
                                .foregroundColor(theme.accent.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, Spacing.xxs)
                        }
                    }

                    // Continue button
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text("Continue Reading")
                                .font(.system(size: FontSizes.base, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(theme.accent)
                        )
                    }
                    .disabled(isTransitioningToNextSurah)
                    .opacity(isTransitioningToNextSurah ? 0.6 : 1.0)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xxs)
                }
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.sm)
                .background(theme.cardColor)
                .cornerRadius(BorderRadius.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadius.xl)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                // Bottom ornamental divider
                IslamicDivider(style: .ornamental, color: theme.accent.opacity(0.3))
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, Spacing.sm)
        } else {
            // -- Last surah (An-Nas, 114): show Quran completion celebration --
            quranCompletionView
        }
    }

    // MARK: - Quran Completion Celebration

    private var quranCompletionView: some View {
        let theme = themeManager.currentTheme

        return VStack(spacing: Spacing.md) {
            IslamicDivider(style: .ornamental, color: theme.accent.opacity(0.4))
                .padding(.horizontal, 40)

            VStack(spacing: Spacing.sm) {
                // Celebration icon
                Image(systemName: "star.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(theme.accent)
                    .padding(.bottom, Spacing.xxxs)

                Text("Khatm al-Quran")
                    .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 24))
                    .foregroundColor(theme.accent)

                Text("Completion of the Noble Quran")
                    .font(.system(size: FontSizes.lg, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text("You have reached the end of the Holy Quran.\nMay Allah accept your reading and grant you\nits intercession on the Day of Judgment.")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Spacing.md)

                // Dua for completing the Quran
                VStack(spacing: Spacing.xxs) {
                    Rectangle()
                        .fill(theme.borderColor.opacity(0.4))
                        .frame(height: 0.5)
                        .padding(.horizontal, Spacing.md)

                    Text("صَدَقَ اللهُ الْعَظِيمُ")
                        .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 22))
                        .foregroundColor(theme.accent)
                        .padding(.vertical, Spacing.xxs)

                    Text("Allah the Almighty has spoken the truth")
                        .font(.system(size: FontSizes.xs))
                        .italic()
                        .foregroundColor(theme.textTertiary)
                }

                // Return to beginning button
                Button {
                    navigateToSurah(surahNumber: 1)
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Start from Al-Fatihah")
                            .font(.system(size: FontSizes.base, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(theme.accent)
                    )
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xxs)
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.sm)
            .background(theme.cardColor)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.accent.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, Spacing.screenHorizontal)

            IslamicDivider(style: .ornamental, color: theme.accent.opacity(0.4))
                .padding(.horizontal, 40)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Navigate to Next Surah

    private func navigateToNextSurah(proxy: ScrollViewProxy) {
        guard let next = nextSurah, !isTransitioningToNextSurah else { return }
        isTransitioningToNextSurah = true

        // Update the surah
        surah = next
        verses = []
        translations = [:]
        verseReadStates = [:]
        visibleVerses = []
        dwellTask?.cancel()
        isLoading = true
        loadError = nil

        // Scroll to top
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo("surah-header-top", anchor: .top)
        }

        // Load new surah data
        Task {
            await loadVerses()
            isTransitioningToNextSurah = false
        }
    }

    /// Navigate to a specific surah by number (used for Quran completion -> Al-Fatihah)
    private func navigateToSurah(surahNumber: Int) {
        guard let targetSurah = viewModel.surahs.first(where: { $0.id == surahNumber }) else { return }
        guard !isTransitioningToNextSurah else { return }
        isTransitioningToNextSurah = true

        // Update the surah
        surah = targetSurah
        verses = []
        translations = [:]
        verseReadStates = [:]
        visibleVerses = []
        dwellTask?.cancel()
        isLoading = true
        loadError = nil

        // Load new surah data
        Task {
            await loadVerses()
            isTransitioningToNextSurah = false
        }
    }

    // MARK: - Dwell-Based Progress Tracking

    private func handleVerseVisibilityChange(isVisible: Bool, surahNumber: Int, verseNumber: Int) {
        let verseId = "\(surahNumber):\(verseNumber)"

        if isVisible {
            guard visibleVerses.insert(verseId).inserted else { return }
        } else {
            guard visibleVerses.remove(verseId) != nil else { return }
        }

        restartDwellTimer()
    }

    private func restartDwellTimer() {
        dwellTask?.cancel()
        dwellTask = Task { [visibleVerses] in
            try? await Task.sleep(nanoseconds: UInt64(dwellTime * 1_000_000_000))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                markVisibleVersesAsRead(snapshot: visibleVerses)
            }
        }
    }

    private func markVisibleVersesAsRead(snapshot: Set<String>) {
        for verseId in snapshot {
            let parts = verseId.split(separator: ":")
            guard parts.count == 2,
                  let surahNumber = Int(parts[0]),
                  let verseNumber = Int(parts[1]) else { continue }

            guard verseReadStates[verseNumber]?.isRead != true else { continue }

            verseReadStates[verseNumber] = VerseReadState(isRead: true, timestamp: Date())
            viewModel.updateProgress(surahNumber: surahNumber, verseNumber: verseNumber)
        }
    }

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
    }

    // MARK: - Data Loading

    private func loadVerses() async {
        isLoading = true
        loadError = nil

        do {
            verses = try await quranService.getVerses(forSurah: surah.id)
            isLoading = false

            loadVerseReadStates()
            await loadTranslations()
        } catch {
            loadError = error
            isLoading = false
            #if DEBUG
            print("Failed to load verses for Surah \(surah.id): \(error)")
            #endif
            verses = quranService.getSampleVerses(forSurah: surah.id)
            loadVerseReadStates()
        }
    }

    private func loadTranslations(for versesToLoad: [Verse]? = nil) async {
        isLoadingTranslations = true
        let targetVerses = versesToLoad ?? verses

        // Load translations sequentially to avoid API rate limiting.
        // The APIClient's concurrency throttle + cache handles efficiency.
        for verse in targetVerses {
            do {
                let translation = try await self.quranService.getTranslation(
                    forVerse: verse,
                    edition: self.selectedTranslation
                )
                translations[verse.number] = translation
            } catch {
                #if DEBUG
                if case APIError.serverError(let code) = error, code != 429 {
                    print("Failed to load translation for verse \(verse.number): \(error)")
                }
                #endif
            }
        }

        isLoadingTranslations = false
    }

    // MARK: - Bookmarks

    private func isBookmarked(verse: Verse) -> Bool {
        return quranService.isBookmarked(surahNumber: surah.id, verseNumber: verse.verseNumber)
    }

    private func toggleBookmark(verse: Verse) {
        if isBookmarked(verse: verse) {
            if let bookmark = viewModel.bookmarks.first(where: { $0.surahNumber == surah.id && $0.verseNumber == verse.verseNumber }) {
                quranService.removeBookmark(id: bookmark.id)
                HapticManager.shared.triggerPattern(.bookmarkRemoved)
                toastMessage = "Bookmark removed"
                toastStyle = .success
                showToast = true
            }
        } else {
            // Show category picker for new bookmarks
            pendingBookmarkVerse = verse
            showCategoryPicker = true
        }
    }

    private func saveBookmark(verse: Verse, category: String) {
        quranService.addBookmark(surahNumber: surah.id, verseNumber: verse.verseNumber, category: category)
        HapticManager.shared.triggerPattern(.bookmarkAdded)
        toastMessage = "Saved to \(BookmarkCategory.shortLabel(for: category))"
        toastStyle = .success
        showToast = true
    }

    // MARK: - Audio Error Feedback

    private func showAudioError(_ error: Error) {
        if error is CancellationError { return }
        toastMessage = "Audio unavailable — check connection"
        toastStyle = .error
        showToast = true
    }

    // MARK: - Share Functionality

    /// Share the entire surah with metadata
    private func shareSurah() {
        var shareText = "Surah \(surah.englishName) (\(surah.name))\n"
        shareText += "\(surah.englishNameTranslation)\n"
        shareText += "\(surah.revelationType.rawValue) • \(surah.numberOfVerses) verses\n\n"

        // Add first verse or bismillah as preview
        if let firstVerse = verses.first {
            shareText += firstVerse.text + "\n"
            if let translation = translations[firstVerse.number] {
                shareText += "\n\"\(translation.text)\"\n"
                shareText += "— \(translation.author)\n"
            }
        }

        shareText += "\n📖 Shared from Quran Noor"

        shareItems = [shareText]
        showShareSheet = true
        HapticManager.shared.trigger(.selection)
    }

    /// Share a specific verse with Arabic text and translation
    private func shareVerse(_ verse: Verse) {
        var shareText = "Surah \(surah.englishName) (\(surah.name)) - Verse \(verse.verseNumber)\n\n"

        // Arabic text
        shareText += verse.text + "\n\n"

        // Translation if available
        if let translation = translations[verse.number] {
            shareText += "\"\(translation.text)\"\n"
            shareText += "— \(translation.author)\n"
        }

        shareText += "\n📖 Shared from Quran Noor"

        shareItems = [shareText]
        showShareSheet = true
        HapticManager.shared.trigger(.selection)

        toastMessage = "Verse ready to share"
        toastStyle = .info
        showToast = true
    }
}

// MARK: - Bookmark Category Picker Sheet

private struct BookmarkCategoryPickerSheet: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    let onSelect: (String) -> Void

    var body: some View {
        let theme = themeManager.currentTheme

        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    Text("Choose a category for this bookmark")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(theme.textSecondary)
                        .padding(.top, Spacing.sm)

                    VStack(spacing: Spacing.xs) {
                        ForEach(BookmarkCategory.predefined, id: \.self) { category in
                            Button {
                                onSelect(category)
                                dismiss()
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: iconForCategory(category))
                                        .font(.system(size: 18))
                                        .foregroundColor(theme.accent)
                                        .frame(width: 28)

                                    Text(category)
                                        .font(.system(size: FontSizes.base, weight: .medium))
                                        .foregroundColor(theme.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.textTertiary)
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(theme.cardColor)
                                .cornerRadius(BorderRadius.lg)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    Spacer()
                }
            }
            .navigationTitle("Bookmark Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.accent)
                }
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case BookmarkCategory.allBookmarks:
            return "bookmark.fill"
        case BookmarkCategory.favorites:
            return "heart.fill"
        case BookmarkCategory.study:
            return "text.book.closed.fill"
        case BookmarkCategory.memorization:
            return "brain.head.profile"
        default:
            return "folder.fill"
        }
    }
}

// MARK: - Arabic Numeral Conversion

private extension Int {
    /// Convert integer to Eastern Arabic numerals used in the Quran
    var arabicNumerals: String {
        let arabicDigits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(String(self).compactMap { char -> Character? in
            guard let digit = Int(String(char)), digit >= 0 && digit <= 9 else { return nil }
            return arabicDigits[digit]
        })
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
    .environment(ThemeManager())
}
