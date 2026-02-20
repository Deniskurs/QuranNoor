//
//  AudioPlayerView.swift
//  QuranNoor
//
//  Immersive full-screen audio player for Quran recitations.
//  Designed as a sacred reading experience with Arabic calligraphy
//  as the visual centerpiece.
//

import SwiftUI

struct AudioPlayerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared
    @State private var isSeeking = false
    @State private var currentTranslation: Translation?
    @State private var surahName: String = ""

    private let quranService = QuranService.shared

    let onClose: () -> Void

    private var verse: Verse? { audioService.currentVerse }

    var body: some View {
        let theme = themeManager.currentTheme

        ZStack(alignment: .top) {
            theme.backgroundColor.ignoresSafeArea()
            GradientBackground(style: .quran, opacity: 0.3)

            VStack(spacing: 0) {
                if let verse = verse {
                    playerContent(verse: verse, theme: theme)
                } else {
                    emptyState(theme: theme)
                }
            }
        }
        .onChange(of: audioService.currentVerse) { _, newVerse in
            loadTranslation(for: newVerse)
            loadSurahName(for: newVerse)
        }
        .onAppear {
            loadTranslation(for: verse)
            loadSurahName(for: verse)
        }
    }

    // MARK: - Top-Level Sections

    private func playerContent(verse: Verse, theme: ThemeMode) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.md) {
                closeButton(theme: theme)
                arabicCard(verse: verse, theme: theme)
                errorBanner(verse: verse, theme: theme)
                translationText(theme: theme)
                verseInfo(verse: verse, theme: theme)
                progressBar(theme: theme)
                transportControls(theme: theme)
                bottomRow(theme: theme)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func emptyState(theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            emptyIcon(theme: theme)
            emptyLabel(theme: theme)
            emptyInstructions(theme: theme)
            closeButtonForEmpty(theme: theme)
            Spacer()
        }
    }

    // MARK: - Drag Indicator

    private func dragIndicator(theme: ThemeMode) -> some View {
        Capsule()
            .fill(theme.textSecondary.opacity(0.3))
            .frame(width: 36, height: 4)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.xxs)
    }

    // MARK: - Close Button

    private func closeButton(theme: ThemeMode) -> some View {
        HStack {
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: FontSizes.sm, weight: .medium))
                    .foregroundColor(theme.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(theme.cardColor))
            }
        }
    }

    // MARK: - Arabic Calligraphy Card

    private func arabicCard(verse: Verse, theme: ThemeMode) -> some View {
        VStack(spacing: 0) {
            arabicText(verse: verse, theme: theme)
        }
        .background(arabicCardBackground(theme: theme))
        .animation(.easeInOut(duration: 0.3), value: verse.id)
    }

    private func arabicText(verse: Verse, theme: ThemeMode) -> some View {
        Text(verse.text)
            .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 30))
            .foregroundColor(theme.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(16)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
            .frame(maxWidth: .infinity)
            .transition(.opacity)
            .id(verse.id)
    }

    private func arabicCardBackground(theme: ThemeMode) -> some View {
        RoundedRectangle(cornerRadius: BorderRadius.xl)
            .fill(theme.cardColor)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.accent.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius / 2, x: 0, y: 2)
    }

    // MARK: - Translation

    private func translationText(theme: ThemeMode) -> some View {
        Group {
            if let translation = currentTranslation {
                Text(translation.text)
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, Spacing.xxs)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentTranslation?.id)
            }
        }
    }

    // MARK: - Verse Info

    private func verseInfo(verse: Verse, theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.xxxs) {
            surahLabel(theme: theme)
            versePositionLabel(verse: verse, theme: theme)
        }
    }

    private func surahLabel(theme: ThemeMode) -> some View {
        Text(surahName.isEmpty ? "" : surahName)
            .font(.system(size: FontSizes.xs, weight: .semibold))
            .foregroundColor(theme.accent)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func versePositionLabel(verse: Verse, theme: ThemeMode) -> some View {
        Group {
            if audioService.continuousPlaybackEnabled && !audioService.playingVerses.isEmpty {
                Text("Verse \(verse.verseNumber) of \(audioService.playingVerses.count)")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textTertiary)
            } else {
                Text("Verse \(verse.verseNumber)")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textTertiary)
            }
        }
    }

    // MARK: - Progress Bar

    private func progressBar(theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.xxs) {
            progressTrack(theme: theme)
            progressTimeLabels(theme: theme)
        }
        .padding(.top, Spacing.xxs)
    }

    private func progressTrack(theme: ThemeMode) -> some View {
        GeometryReader { geometry in
            let progress = audioService.duration > 0
                ? CGFloat(audioService.currentTime / audioService.duration)
                : 0

            ZStack(alignment: .leading) {
                trackBackground(theme: theme)
                trackFill(width: geometry.size.width * progress, theme: theme)
            }
            .frame(height: 4)
            .clipShape(Capsule())
            .contentShape(Rectangle().inset(by: -12))
            .gesture(seekGesture(in: geometry.size.width))
        }
        .frame(height: 4)
    }

    private func trackBackground(theme: ThemeMode) -> some View {
        Capsule()
            .fill(theme.textSecondary.opacity(0.12))
            .frame(height: 4)
    }

    private func trackFill(width: CGFloat, theme: ThemeMode) -> some View {
        Capsule()
            .fill(theme.accent)
            .frame(width: max(0, width), height: 4)
            .animation(isSeeking ? nil : .linear(duration: 0.24), value: audioService.currentTime)
    }

    private func seekGesture(in totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isSeeking = true
                let ratio = Double(value.location.x / totalWidth)
                let newTime = ratio * audioService.duration
                audioService.seek(to: max(0, min(newTime, audioService.duration)))
            }
            .onEnded { _ in
                isSeeking = false
            }
    }

    private func progressTimeLabels(theme: ThemeMode) -> some View {
        HStack {
            Text(audioService.currentTime.formattedPlaybackTime)
                .font(.system(size: FontSizes.xs, weight: .medium))
                .foregroundColor(theme.textTertiary)
                .monospacedDigit()
            Spacer()
            Text(audioService.duration.formattedPlaybackTime)
                .font(.system(size: FontSizes.xs, weight: .medium))
                .foregroundColor(theme.textTertiary)
                .monospacedDigit()
        }
    }

    // MARK: - Transport Controls

    private func transportControls(theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.lg) {
            previousButton(theme: theme)
            playPauseButton(theme: theme)
            nextButton(theme: theme)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func previousButton(theme: ThemeMode) -> some View {
        Button {
            Task { try? await audioService.playPreviousVerse() }
        } label: {
            Image(systemName: "backward.end.fill")
                .font(.title3)
                .foregroundColor(theme.textPrimary.opacity(previousDisabled ? 0.25 : 0.7))
        }
        .disabled(previousDisabled)
        .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)
    }

    private func nextButton(theme: ThemeMode) -> some View {
        Button {
            Task { try? await audioService.playNextVerse() }
        } label: {
            Image(systemName: "forward.end.fill")
                .font(.title3)
                .foregroundColor(theme.textPrimary.opacity(nextDisabled ? 0.25 : 0.7))
        }
        .disabled(nextDisabled)
        .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)
    }

    private func playPauseButton(theme: ThemeMode) -> some View {
        Button {
            audioService.togglePlayPause()
        } label: {
            playPauseIcon(theme: theme)
        }
        .scaleEffect(audioService.playbackState.isPlaying ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioService.playbackState.isPlaying)
    }

    private func playPauseIcon(theme: ThemeMode) -> some View {
        ZStack {
            Circle()
                .fill(theme.accent)
                .frame(width: 64, height: 64)

            Group {
                if case .loading = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(.white)
                } else if case .buffering = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(.white)
                } else {
                    Image(systemName: audioService.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title.weight(.regular))
                        .foregroundColor(.white)
                        .offset(x: audioService.playbackState.isPlaying ? 0 : 2)
                }
            }
        }
    }

    private var previousDisabled: Bool {
        audioService.currentVerseIndex == 0 || audioService.playingVerses.isEmpty
    }

    private var nextDisabled: Bool {
        audioService.currentVerseIndex >= audioService.playingVerses.count - 1
            || audioService.playingVerses.isEmpty
    }

    // MARK: - Bottom Row

    private func bottomRow(theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.xs) {
            speedPill(theme: theme)
            continuousPill(theme: theme)
            reciterPill(theme: theme)
            Spacer()
        }
        .padding(.top, Spacing.xxs)
    }

    // MARK: - Speed Pill

    private func speedPill(theme: ThemeMode) -> some View {
        Menu {
            ForEach(speedOptions, id: \.self) { speed in
                Button {
                    audioService.playbackSpeed = Float(speed)
                } label: {
                    Label(speedLabel(for: speed),
                          systemImage: audioService.playbackSpeed == Float(speed) ? "checkmark" : "")
                }
            }
        } label: {
            pillLabel(
                icon: "gauge.with.dots.needle.50percent",
                text: speedLabel(for: Double(audioService.playbackSpeed)),
                isActive: audioService.playbackSpeed != 1.0,
                theme: theme
            )
        }
    }

    private var speedOptions: [Double] {
        [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    }

    private func speedLabel(for speed: Double) -> String {
        if speed == 1.0 { return "1\u{00D7}" }
        if speed == floor(speed) { return String(format: "%.0f\u{00D7}", speed) }
        return String(format: "%.2g\u{00D7}", speed)
    }

    // MARK: - Continuous Toggle Pill

    private func continuousPill(theme: ThemeMode) -> some View {
        Button {
            audioService.continuousPlaybackEnabled.toggle()
        } label: {
            pillLabel(
                icon: audioService.continuousPlaybackEnabled ? "repeat.circle.fill" : "repeat.circle",
                text: "Auto",
                isActive: audioService.continuousPlaybackEnabled,
                theme: theme
            )
        }
    }

    // MARK: - Reciter Pill

    private func reciterPill(theme: ThemeMode) -> some View {
        Menu {
            ForEach(Reciter.allCases) { reciter in
                Button {
                    switchReciter(to: reciter)
                } label: {
                    Label(reciter.displayName,
                          systemImage: audioService.selectedReciter == reciter ? "checkmark" : "")
                }
            }
        } label: {
            pillLabel(
                icon: "person.wave.2",
                text: audioService.selectedReciter.shortName,
                isActive: false,
                theme: theme
            )
        }
    }

    private func switchReciter(to reciter: Reciter) {
        let wasPlaying = audioService.playbackState.isPlaying
        audioService.selectedReciter = reciter
        if (wasPlaying || audioService.playbackState == .paused),
           let verse = audioService.currentVerse {
            Task {
                try? await audioService.play(verse: verse, preserveQueue: true)
            }
        }
    }

    // MARK: - Shared Pill Label

    private func pillLabel(icon: String, text: String, isActive: Bool, theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.xxxs) {
            Image(systemName: icon)
                .font(.system(size: FontSizes.xs))
            Text(text)
                .font(.system(size: FontSizes.xs, weight: .medium))
        }
        .foregroundColor(isActive ? theme.accent : theme.textSecondary)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(isActive ? theme.accent.opacity(0.12) : theme.cardColor)
        )
    }

    // MARK: - Empty State Elements

    private func emptyIcon(theme: ThemeMode) -> some View {
        Image(systemName: "waveform")
            .font(.largeTitle.weight(.ultraLight))
            .foregroundColor(theme.textTertiary)
    }

    private func emptyLabel(theme: ThemeMode) -> some View {
        Text("No audio playing")
            .font(.body)
            .foregroundColor(theme.textSecondary)
    }

    private func emptyInstructions(theme: ThemeMode) -> some View {
        Text("Select a surah to begin listening")
            .font(.subheadline)
            .foregroundColor(theme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
    }

    private func closeButtonForEmpty(theme: ThemeMode) -> some View {
        Button {
            onClose()
        } label: {
            Text("Close")
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.accent)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(theme.accent.opacity(0.12))
                )
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: - Error Banner

    private func errorBanner(verse: Verse, theme: ThemeMode) -> some View {
        Group {
            if case .error(let message) = audioService.playbackState {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(theme.semanticWarning)

                    Text(message)
                        .font(.system(size: FontSizes.xs))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)

                    Spacer()

                    Button {
                        Task {
                            try? await audioService.play(verse: verse, preserveQueue: true)
                        }
                    } label: {
                        Text("Retry")
                            .font(.system(size: FontSizes.xs, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                }
                .padding(Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BorderRadius.md)
                        .fill(theme.semanticWarning.opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.25), value: audioService.playbackState)
    }

    private func loadTranslation(for verse: Verse?) {
        guard let verse = verse else {
            currentTranslation = nil
            return
        }
        Task {
            let preferredEdition = quranService.getTranslationPreferences().primaryTranslation
            currentTranslation = try? await quranService.getTranslation(forVerse: verse, edition: preferredEdition)
        }
    }

    private func loadSurahName(for verse: Verse?) {
        guard let verse = verse else {
            surahName = ""
            return
        }
        Task {
            if let surahs = try? await quranService.getSurahs() {
                if let surah = surahs.first(where: { $0.id == verse.surahNumber }) {
                    surahName = surah.englishName
                } else {
                    surahName = "Surah \(verse.surahNumber)"
                }
            } else {
                surahName = "Surah \(verse.surahNumber)"
            }
        }
    }
}

// MARK: - Reciter Selector View
struct ReciterSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared
    @State private var selectedReciter: Reciter

    init(currentReciter: Reciter, onSelect: @escaping (Reciter) -> Void) {
        self._selectedReciter = State(initialValue: currentReciter)
        self.onSelect = onSelect
    }

    let onSelect: (Reciter) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Reciter.allCases) { reciter in
                        ReciterRow(
                            reciter: reciter,
                            isSelected: selectedReciter == reciter
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedReciter = reciter
                                audioService.selectedReciter = reciter
                                onSelect(reciter)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Reciter")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                } footer: {
                    Text("Choose your preferred Quran reciter. Audio will be downloaded from AlQuran.cloud.")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            .navigationTitle("Reciters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Reciter Row
struct ReciterRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    let reciter: Reciter
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary.opacity(0.3))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(reciter.displayName)
                    .font(.system(size: FontSizes.base, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(reciter.description)
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: FontSizes.xs))
                    Text(reciter.country)
                        .font(.system(size: FontSizes.xs, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.8))
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Preview
#Preview("Audio Player") {
    struct PreviewWrapper: View {
        @State private var themeManager = ThemeManager()

        var body: some View {
            AudioPlayerView {
                #if DEBUG
                print("Close tapped")
                #endif
            }
            .environment(themeManager)
        }
    }

    return PreviewWrapper()
}

#Preview("Reciter Selector") {
    ReciterSelectorView(currentReciter: .misharyRashid) { reciter in
        #if DEBUG
        print("Selected: \(reciter.displayName)")
        #endif
    }
}
