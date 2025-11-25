//
//  AudioPlayerView.swift
//  QuranNoor
//
//  Beautiful audio player for Quran recitations
//

import SwiftUI

struct AudioPlayerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared
    @State private var showingReciterSelector = false
    @State private var isSeeking = false

    let verse: Verse
    let allVerses: [Verse]? // Optional: All verses in surah for continuous playback
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Audio Waveform Visualization (placeholder)
                    waveformVisualization

                    // Progress Slider
                    progressSection

                    // Playback Controls
                    playbackControls

                    // Additional Controls
                    additionalControls
                }
                .padding(20)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onAppear {
            Task {
                do {
                    // If all verses provided and continuous playback enabled, play queue
                    if let allVerses = allVerses,
                       audioService.continuousPlaybackEnabled,
                       let startIndex = allVerses.firstIndex(where: { $0.id == verse.id }) {
                        try await audioService.playVerses(allVerses, startingAt: startIndex)
                    } else {
                        try await audioService.play(verse: verse)
                    }
                } catch {
                    print("Failed to play: \(error)")
                }
            }
        }
        .onDisappear {
            audioService.stop()
        }
        .sheet(isPresented: $showingReciterSelector) {
            ReciterSelectorView(currentReciter: audioService.selectedReciter) { reciter in
                // Reciter already saved in ReciterSelectorView
                // Could restart playback with new reciter if desired
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Verse info
            VStack(spacing: 6) {
                Text("Surah \(verse.surahNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))

                Text("Verse \(verse.verseNumber)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textColor)
            }

            // Reciter selector button
            Button {
                showingReciterSelector = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.wave.2")
                        .font(.system(size: 14))
                    Text(audioService.selectedReciter.displayName)
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(AppColors.primary.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppColors.primary.green.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Verse Display (replaces animated waveform for performance)
    private var waveformVisualization: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.primary.green.opacity(0.1),
                            themeManager.currentTheme.featureAccent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)

            // Clean verse info display (no animation - prevents GPU thrashing)
            VStack(spacing: 12) {
                // Playing indicator
                HStack(spacing: 8) {
                    if audioService.playbackState.isPlaying {
                        // Simple pulsing dot (single animation, not 30)
                        Circle()
                            .fill(themeManager.currentTheme.featureAccent)
                            .frame(width: 8, height: 8)
                            .opacity(audioService.playbackState.isPlaying ? 1.0 : 0.3)
                    }

                    Text(audioService.playbackState.isPlaying ? "Now Playing" : "Paused")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                }

                // Current verse being played (in continuous mode)
                if audioService.continuousPlaybackEnabled && !audioService.playingVerses.isEmpty {
                    VStack(spacing: 4) {
                        Text("Verse \(audioService.currentVerseIndex + 1) of \(audioService.playingVerses.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textColor)

                        // Progress indicator (static bars representing verse position)
                        HStack(spacing: 2) {
                            ForEach(0..<min(audioService.playingVerses.count, 20), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(index <= audioService.currentVerseIndex ?
                                          themeManager.currentTheme.featureAccent :
                                          Color.secondary.opacity(0.2))
                                    .frame(width: 8, height: 4)
                            }
                            if audioService.playingVerses.count > 20 {
                                Text("...")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    // Single verse mode
                    Text(verse.text)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Time labels
            HStack {
                Text(formatTime(audioService.currentTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                    .monospacedDigit()

                Spacer()

                Text(formatTime(audioService.duration))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                    .monospacedDigit()
            }

            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary.green, themeManager.currentTheme.featureAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(audioService.currentTime / max(audioService.duration, 1)),
                            height: 8
                        )

                    // Thumb
                    Circle()
                        .fill(themeManager.currentTheme.featureAccent)
                        .frame(width: 20, height: 20)
                        .shadow(color: themeManager.currentTheme.featureAccent.opacity(0.5), radius: 4, x: 0, y: 2)
                        .offset(
                            x: geometry.size.width * CGFloat(audioService.currentTime / max(audioService.duration, 1)) - 10
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isSeeking = true
                            let newTime = Double(value.location.x / geometry.size.width) * audioService.duration
                            audioService.seek(to: max(0, min(newTime, audioService.duration)))
                        }
                        .onEnded { _ in
                            isSeeking = false
                        }
                )
            }
            .frame(height: 20)
        }
    }

    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 30) {
            // Previous verse (if continuous playback)
            if audioService.continuousPlaybackEnabled && allVerses != nil {
                Button {
                    Task {
                        try? await audioService.playPreviousVerse()
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                }
                .disabled(audioService.currentVerseIndex == 0)
            } else {
                // Skip backward 10s (non-continuous mode)
                Button {
                    audioService.seek(to: max(0, audioService.currentTime - 10))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                }
                .disabled(audioService.currentTime < 10)
            }

            // Play/Pause button
            Button {
                audioService.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary.green, themeManager.currentTheme.featureAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: AppColors.primary.green.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: audioService.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .offset(x: audioService.playbackState.isPlaying ? 0 : 2) // Center play icon
                }
            }
            .scaleEffect(audioService.playbackState.isPlaying ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioService.playbackState.isPlaying)

            // Next verse (if continuous playback)
            if audioService.continuousPlaybackEnabled && allVerses != nil {
                Button {
                    Task {
                        try? await audioService.playNextVerse()
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                }
                .disabled(audioService.currentVerseIndex >= audioService.playingVerses.count - 1)
            } else {
                // Skip forward 10s (non-continuous mode)
                Button {
                    audioService.seek(to: min(audioService.duration, audioService.currentTime + 10))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                }
                .disabled(audioService.currentTime >= audioService.duration - 10)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Additional Controls
    private var additionalControls: some View {
        HStack(spacing: 24) {
            // Playback speed
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                    Button {
                        audioService.playbackSpeed = Float(speed)
                    } label: {
                        HStack {
                            Text("\(speed, specifier: "%.2f")×")
                            if audioService.playbackSpeed == Float(speed) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                        .font(.system(size: 20))
                    Text("\(audioService.playbackSpeed, specifier: "%.2f")×")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
            }

            // Continuous playback toggle (if verses available)
            if allVerses != nil {
                Button {
                    audioService.continuousPlaybackEnabled.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: audioService.continuousPlaybackEnabled ? "repeat.circle.fill" : "repeat.circle")
                            .font(.system(size: 20))
                        Text("Auto")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(audioService.continuousPlaybackEnabled ?
                                   themeManager.currentTheme.featureAccent :
                                   themeManager.currentTheme.textColor.opacity(0.7))
                }
            }

            Spacer()

            // Close button
            Button {
                onClose()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Close")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
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

                                // Auto-dismiss after selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Reciter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Choose your preferred Quran reciter. Audio will be downloaded from AlQuran.cloud.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    let reciter: Reciter
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? AppColors.primary.green : .secondary.opacity(0.3))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(reciter.displayName)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Text(reciter.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                    Text(reciter.country)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview("Audio Player") {
    struct PreviewWrapper: View {
        @State private var themeManager = ThemeManager()

        var body: some View {
            AudioPlayerView(
                verse: Verse(
                    number: 1,
                    surahNumber: 1,
                    verseNumber: 1,
                    text: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
                    juz: 1
                ),
                allVerses: nil
            ) {
                print("Close tapped")
            }
            .environment(themeManager)
        }
    }

    return PreviewWrapper()
}

#Preview("Reciter Selector") {
    ReciterSelectorView(currentReciter: .misharyRashid) { reciter in
        print("Selected: \(reciter.displayName)")
    }
}
