//
//  InlineAudioPill.swift
//  QuranNoor
//
//  Collapsible inline audio controls that float above the verse reader
//  Stays visible while reading - no popup sheets that interrupt flow
//

import SwiftUI

struct InlineAudioPill: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Bindable var audioService: QuranAudioService

    @Binding var isExpanded: Bool
    @State private var showingReciterSelector = false

    let verses: [Verse]
    let onStop: () -> Void

    // MARK: - Computed Properties

    private var isVisible: Bool {
        switch audioService.playbackState {
        case .idle:
            return false
        default:
            return true
        }
    }

    private var currentVerseText: String {
        if audioService.continuousPlaybackEnabled && !audioService.playingVerses.isEmpty {
            return "Verse \(audioService.currentVerseIndex + 1) of \(audioService.playingVerses.count)"
        } else if let verse = audioService.currentVerse {
            return "Verse \(verse.verseNumber)"
        }
        return "Loading..."
    }

    // MARK: - Body

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                if isExpanded {
                    expandedView
                } else {
                    collapsedView
                }
            }
            .background(
                RoundedRectangle(cornerRadius: isExpanded ? 20 : 30)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: -4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isExpanded ? 20 : 30)
                    .stroke(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.accentSecondary.opacity(0.3),
                                themeManager.currentTheme.accentSecondary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
            .sheet(isPresented: $showingReciterSelector) {
                ReciterSelectorView(currentReciter: audioService.selectedReciter) { _ in }
            }
        }
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = true
            }
            HapticManager.shared.trigger(.selection)
        } label: {
            HStack(spacing: 12) {
                // Play/Pause button
                playPauseButton(size: 40)

                // Verse info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentVerseText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Text(audioService.selectedReciter.shortName)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                }

                Spacer()

                // Loading indicator or progress
                if case .loading = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(themeManager.currentTheme.featureAccent)
                } else if case .buffering = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(themeManager.currentTheme.featureAccent)
                } else {
                    // Time remaining
                    Text(formatTime(audioService.duration - audioService.currentTime))
                        .font(.system(size: 13, weight: .medium).monospacedDigit())
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                }

                // Expand indicator
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 16) {
            // Header with collapse button
            HStack {
                // Verse info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentVerseText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor)

                    Button {
                        showingReciterSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(audioService.selectedReciter.shortName)
                                .font(.system(size: 13))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                    }
                }

                Spacer()

                // Collapse button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                    HapticManager.shared.trigger(.selection)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(themeManager.currentTheme.textColor.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Progress bar
            progressBar
                .padding(.horizontal, 16)

            // Playback controls
            playbackControls
                .padding(.horizontal, 16)

            // Additional controls
            additionalControls
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeManager.currentTheme.textColor.opacity(0.15))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary.green, themeManager.currentTheme.featureAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(audioService.currentTime / max(audioService.duration, 1)),
                            height: 6
                        )
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newTime = Double(value.location.x / geometry.size.width) * audioService.duration
                            audioService.seek(to: max(0, min(newTime, audioService.duration)))
                        }
                )
            }
            .frame(height: 6)

            // Time labels
            HStack {
                Text(formatTime(audioService.currentTime))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))

                Spacer()

                Text(formatTime(audioService.duration))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 24) {
            // Previous verse
            Button {
                Task {
                    try? await audioService.playPreviousVerse()
                }
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(
                        audioService.currentVerseIndex > 0 ? 0.8 : 0.3
                    ))
            }
            .disabled(audioService.currentVerseIndex == 0)

            Spacer()

            // Play/Pause button (larger)
            playPauseButton(size: 56)

            Spacer()

            // Next verse
            Button {
                Task {
                    try? await audioService.playNextVerse()
                }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(
                        audioService.currentVerseIndex < audioService.playingVerses.count - 1 ? 0.8 : 0.3
                    ))
            }
            .disabled(audioService.currentVerseIndex >= audioService.playingVerses.count - 1)
        }
    }

    // MARK: - Additional Controls

    private var additionalControls: some View {
        HStack(spacing: 20) {
            // Speed selector
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                    Button {
                        audioService.playbackSpeed = Float(speed)
                    } label: {
                        HStack {
                            Text("\(speed, specifier: "%.2f")x")
                            if audioService.playbackSpeed == Float(speed) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                        .font(.system(size: 14))
                    Text("\(audioService.playbackSpeed, specifier: "%.1f")x")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeManager.currentTheme.textColor.opacity(0.1))
                )
            }

            // Continuous playback toggle
            Button {
                audioService.continuousPlaybackEnabled.toggle()
                HapticManager.shared.trigger(.selection)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: audioService.continuousPlaybackEnabled ? "repeat.circle.fill" : "repeat.circle")
                        .font(.system(size: 14))
                    Text("Auto")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(audioService.continuousPlaybackEnabled ?
                               themeManager.currentTheme.featureAccent :
                               themeManager.currentTheme.textColor.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(audioService.continuousPlaybackEnabled ?
                              themeManager.currentTheme.featureAccent.opacity(0.15) :
                              themeManager.currentTheme.textColor.opacity(0.1))
                )
            }

            Spacer()

            // Stop button
            Button {
                audioService.stop()
                onStop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.5))
            }
        }
    }

    // MARK: - Play/Pause Button

    @ViewBuilder
    private func playPauseButton(size: CGFloat) -> some View {
        Button {
            if case .loading = audioService.playbackState {
                return // Don't toggle while loading
            }
            audioService.togglePlayPause()
            HapticManager.shared.trigger(.selection)
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
                    .frame(width: size, height: size)
                    .shadow(color: AppColors.primary.green.opacity(0.3), radius: 6, x: 0, y: 3)

                if case .loading = audioService.playbackState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(size > 50 ? 1.0 : 0.7)
                } else {
                    Image(systemName: audioService.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.white)
                        .offset(x: audioService.playbackState.isPlaying ? 0 : size * 0.05)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else { return "0:00" }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    VStack {
        Spacer()
        InlineAudioPill(
            audioService: QuranAudioService.shared,
            isExpanded: .constant(false),
            verses: [],
            onStop: {}
        )
    }
    .environment(ThemeManager())
}

#Preview("Expanded") {
    VStack {
        Spacer()
        InlineAudioPill(
            audioService: QuranAudioService.shared,
            isExpanded: .constant(true),
            verses: [],
            onStop: {}
        )
    }
    .environment(ThemeManager())
}
