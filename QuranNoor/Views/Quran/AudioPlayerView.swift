//
//  AudioPlayerView.swift
//  QuranNoor
//
//  Immersive full-screen audio player for Quran recitations.
//  Inspired by Apple Music with large transport controls, gradient background,
//  scrubber knob, swipe-down dismiss, and haptic feedback.
//

import SwiftUI

struct AudioPlayerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared
    @State private var currentTranslation: Translation?
    @State private var surahName: String = ""
    @State private var isPlayPausePressed = false

    // Swipe-down dismiss state
    @State private var dismissDragOffset: CGFloat = 0
    @State private var isDismissDragging = false

    private let quranService = QuranService.shared

    var animationNamespace: Namespace.ID?
    let onClose: () -> Void

    private var verse: Verse? { audioService.currentVerse }

    var body: some View {
        let theme = themeManager.currentTheme

        GeometryReader { geometry in
            ZStack {
                // Background: theme color + radial accent wash
                theme.backgroundColor.ignoresSafeArea()

                RadialGradient(
                    colors: [
                        theme.accent.opacity(0.12),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.7
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let verse = verse {
                        playerContent(verse: verse, theme: theme)
                    } else {
                        emptyState(theme: theme)
                    }
                }
            }
        }
        .offset(y: dismissDragOffset)
        .gesture(dismissGesture)
        .onChange(of: audioService.currentVerse) { _, newVerse in
            loadTranslation(for: newVerse)
            loadSurahName(for: newVerse)
        }
        .onAppear {
            loadTranslation(for: verse)
            loadSurahName(for: verse)
        }
    }

    // MARK: - Dismiss Gesture

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onChanged { value in
                // Only respond to downward drags
                if value.translation.height > 0 {
                    isDismissDragging = true
                    dismissDragOffset = value.translation.height * 0.5
                }
            }
            .onEnded { value in
                isDismissDragging = false
                if value.translation.height > 100 {
                    HapticManager.shared.trigger(.medium)
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dismissDragOffset = 0
                    }
                }
            }
    }

    // MARK: - Player Content (fixed layout, no ScrollView)

    private func playerContent(verse: Verse, theme: ThemeMode) -> some View {
        VStack(spacing: 0) {
            // Top bar: drag indicator + close
            topBar(theme: theme)

            Spacer(minLength: Spacing.sm)

            // Arabic text artwork card
            SurahArtworkBadge(
                surahNumber: verse.surahNumber,
                arabicText: verse.text,
                size: .full,
                animationNamespace: animationNamespace
            )
            .animation(.easeInOut(duration: 0.3), value: verse.id)

            // Verse info
            verseInfo(verse: verse, theme: theme)
                .padding(.top, Spacing.sm)

            // Error banner
            errorBanner(verse: verse, theme: theme)
                .padding(.horizontal, Spacing.screenHorizontal)

            // Translation (3 lines max with fade)
            translationText(theme: theme)
                .padding(.top, Spacing.xxs)
                .padding(.horizontal, Spacing.screenHorizontal)

            Spacer(minLength: Spacing.sm)

            // Progress bar with scrubber
            AudioProgressBar(
                style: .full,
                progress: audioService.duration > 0
                    ? audioService.currentTime / audioService.duration
                    : 0,
                currentTime: audioService.currentTime,
                duration: audioService.duration,
                onSeek: { time in audioService.seek(to: time) },
                animationNamespace: animationNamespace
            )
            .padding(.horizontal, Spacing.screenHorizontal)

            // Transport controls
            transportControls(theme: theme)
                .padding(.top, Spacing.sm)

            // Bottom pills row
            bottomRow(theme: theme)
                .padding(.top, Spacing.xs)
                .padding(.horizontal, Spacing.screenHorizontal)

            Spacer(minLength: Spacing.sm)
        }
    }

    // MARK: - Top Bar

    private func topBar(theme: ThemeMode) -> some View {
        ZStack {
            // Drag indicator
            Capsule()
                .fill(theme.textSecondary.opacity(0.3))
                .frame(width: 36, height: 5)

            // Close button
            HStack {
                Spacer()
                Button {
                    HapticManager.shared.trigger(.light)
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: FontSizes.sm, weight: .medium))
                        .foregroundColor(theme.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(theme.cardColor.opacity(0.8))
                        )
                }
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Verse Info

    private func verseInfo(verse: Verse, theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Text(surahName.isEmpty ? "" : surahName)
                .font(.system(size: FontSizes.sm, weight: .semibold))
                .foregroundColor(theme.accent)
                .textCase(.uppercase)
                .tracking(1.2)

            Group {
                if audioService.continuousPlaybackEnabled && !audioService.playingVerses.isEmpty {
                    Text("Verse \(verse.verseNumber) of \(audioService.playingVerses.count)")
                } else {
                    Text("Verse \(verse.verseNumber)")
                }
            }
            .font(.system(size: FontSizes.sm))
            .foregroundColor(theme.textTertiary)
        }
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
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentTranslation?.id)
            }
        }
    }

    // MARK: - Transport Controls

    private func transportControls(theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.lg) {
            // Previous verse
            Button {
                HapticManager.shared.trigger(.light)
                Task { try? await audioService.playPreviousVerse() }
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.textPrimary.opacity(previousDisabled ? 0.25 : 0.7))
            }
            .disabled(previousDisabled)
            .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)

            // Skip back 15s
            Button {
                HapticManager.shared.trigger(.light)
                let newTime = max(0, audioService.currentTime - 15)
                audioService.seek(to: newTime)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22))
                    .foregroundColor(theme.textPrimary.opacity(0.7))
            }
            .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)

            // Play/Pause (72pt)
            Button {
                HapticManager.shared.trigger(.medium)
                audioService.togglePlayPause()
            } label: {
                playPauseIcon(theme: theme)
            }
            .scaleEffect(isPlayPausePressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPlayPausePressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPlayPausePressed = pressing
            }, perform: {})

            // Skip forward 15s
            Button {
                HapticManager.shared.trigger(.light)
                let newTime = min(audioService.duration, audioService.currentTime + 15)
                audioService.seek(to: newTime)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 22))
                    .foregroundColor(theme.textPrimary.opacity(0.7))
            }
            .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)

            // Next verse
            Button {
                HapticManager.shared.trigger(.light)
                Task { try? await audioService.playNextVerse() }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.textPrimary.opacity(nextDisabled ? 0.25 : 0.7))
            }
            .disabled(nextDisabled)
            .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)
        }
    }

    private func playPauseIcon(theme: ThemeMode) -> some View {
        ZStack {
            Circle()
                .fill(theme.accent)
                .frame(width: 72, height: 72)
                .shadow(color: theme.accent.opacity(0.3), radius: 12, x: 0, y: 4)

            Group {
                if case .loading = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                } else if case .buffering = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                } else {
                    Image(systemName: audioService.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .regular))
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
            AirPlayButton(tintColor: theme.textSecondary)
                .frame(width: 28, height: 28)
        }
    }

    // MARK: - Speed Pill

    private func speedPill(theme: ThemeMode) -> some View {
        Menu {
            ForEach(speedOptions, id: \.self) { speed in
                Button {
                    audioService.playbackSpeed = Float(speed)
                    HapticManager.shared.trigger(.selection)
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
            HapticManager.shared.trigger(.selection)
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
        HapticManager.shared.trigger(.selection)
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
        .frame(minHeight: Spacing.tapTarget)
        .background(
            Capsule()
                .fill(isActive ? theme.accent.opacity(0.12) : theme.cardColor)
        )
    }

    // MARK: - Empty State

    private func emptyState(theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer()

            Image(systemName: "waveform")
                .font(.largeTitle.weight(.ultraLight))
                .foregroundColor(theme.textTertiary)

            Text("No audio playing")
                .font(.body)
                .foregroundColor(theme.textSecondary)

            Text("Select a surah to begin listening")
                .font(.subheadline)
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

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

            Spacer()
        }
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

    // MARK: - Data Loading

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
