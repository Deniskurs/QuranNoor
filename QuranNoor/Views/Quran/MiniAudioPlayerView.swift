//
//  MiniAudioPlayerView.swift
//  QuranNoor
//
//  Compact floating audio player pill inspired by Apple Music's mini player.
//  Entire pill is tappable to expand; swipe up also expands.
//  Used both as the floating tab-bar overlay and as the inline indicator
//  inside VerseReaderView.
//

import SwiftUI

struct MiniAudioPlayerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared

    // MARK: - Configuration

    /// Show skip forward/backward buttons (continuous playback only). Default: true.
    var showSkipControls: Bool = true
    /// Show the close (stop) button. Default: true.
    var showCloseButton: Bool = true
    /// Optional namespace for matchedGeometryEffect with the full player.
    var animationNamespace: Namespace.ID?
    /// Action when the player card is tapped (expand to full player).
    let onTap: () -> Void

    // MARK: - Drag State

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        let theme = themeManager.currentTheme

        if audioService.hasActivePlayback,
           let verse = audioService.currentVerse {
            VStack(spacing: 0) {
                // Progress bar at top with glow
                AudioProgressBar(
                    style: .mini,
                    progress: audioService.duration > 0
                        ? audioService.currentTime / audioService.duration
                        : 0,
                    currentTime: audioService.currentTime,
                    duration: audioService.duration,
                    onSeek: { time in audioService.seek(to: time) },
                    animationNamespace: animationNamespace
                )

                // Player content
                HStack(spacing: Spacing.xs) {
                    // Artwork badge
                    SurahArtworkBadge(
                        surahNumber: verse.surahNumber,
                        size: .mini,
                        animationNamespace: animationNamespace
                    )

                    // Verse info
                    verseInfo(verse: verse, theme: theme)

                    // Play/pause button
                    playPauseButton(theme: theme)

                    // Skip controls (only when enabled + continuous mode)
                    if showSkipControls,
                       audioService.continuousPlaybackEnabled,
                       audioService.playingVerses.count > 1 {
                        skipForwardButton(theme: theme)
                    }

                    // Close button
                    if showCloseButton {
                        closeButton(theme: theme)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .fill(theme.cardColor)
                    .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius / 2, x: 0, y: -2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.accent.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .offset(y: min(0, dragOffset))
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.trigger(.medium)
                onTap()
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // Only respond to upward drags
                        if value.translation.height < 0 {
                            isDragging = true
                            dragOffset = value.translation.height * 0.3
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        if value.translation.height < -40 {
                            HapticManager.shared.trigger(.medium)
                            onTap()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
            .padding(.horizontal, Spacing.screenHorizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: audioService.hasActivePlayback)
        }
    }

    // MARK: - Verse Info

    private func verseInfo(verse: Verse, theme: ThemeMode) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xxxs) {
                Text("Verse \(verse.verseNumber)")
                    .font(.system(size: FontSizes.sm, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                if audioService.continuousPlaybackEnabled && audioService.playingVerses.count > 1 {
                    Text("of \(audioService.playingVerses.count)")
                        .font(.system(size: FontSizes.xs))
                        .foregroundColor(theme.textTertiary)
                }
            }

            Text("\(audioService.selectedReciter.shortName) \u{00B7} \((audioService.duration - audioService.currentTime).formattedPlaybackTime)")
                .font(.system(size: FontSizes.xs))
                .foregroundColor(theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
    }

    // MARK: - Play/Pause Button

    private func playPauseButton(theme: ThemeMode) -> some View {
        ZStack {
            Circle()
                .fill(theme.accent)
                .frame(width: 40, height: 40)

            Group {
                if case .loading = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                } else if case .buffering = audioService.playbackState {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                } else if audioService.playbackState.isPlaying {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .offset(x: 1)
                }
            }
        }
        .contentShape(Circle())
        .highPriorityGesture(TapGesture().onEnded {
            HapticManager.shared.trigger(.light)
            audioService.togglePlayPause()
        })
    }

    // MARK: - Skip Forward Button

    private var isSkipForwardDisabled: Bool {
        audioService.currentVerseIndex >= audioService.playingVerses.count - 1
    }

    private func skipForwardButton(theme: ThemeMode) -> some View {
        Image(systemName: "forward.end.fill")
            .font(.system(size: FontSizes.sm))
            .foregroundColor(isSkipForwardDisabled ? theme.textSecondary.opacity(0.3) : theme.textSecondary)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded {
                guard !isSkipForwardDisabled else { return }
                Task { try? await audioService.playNextVerse() }
            })
    }

    // MARK: - Close Button

    private func closeButton(theme: ThemeMode) -> some View {
        Image(systemName: "xmark")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(theme.textTertiary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded {
                audioService.stop()
            })
    }
}

// MARK: - Preview
#Preview("Mini Audio Player") {
    struct PreviewWrapper: View {
        @State private var themeManager = ThemeManager()
        @State private var audioService = QuranAudioService.shared

        var body: some View {
            VStack {
                Spacer()

                Text("Main Content Area")
                    .font(.title)

                Spacer()

                MiniAudioPlayerView {
                    #if DEBUG
                    print("Expand to full player")
                    #endif
                }
                .environment(themeManager)
            }
            .onAppear {
                Task {
                    let mockVerse = Verse(
                        number: 1,
                        surahNumber: 1,
                        verseNumber: 1,
                        text: "\u{0628}\u{0650}\u{0633}\u{06E1}\u{0645}\u{0650} \u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{06E1}\u{0645}\u{064E}\u{0640}\u{0670}\u{0646}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{06CC}\u{0645}\u{0650}",
                        juz: 1
                    )
                    try? await audioService.play(verse: mockVerse)
                }
            }
        }
    }

    return PreviewWrapper()
}
