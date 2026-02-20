//
//  MiniAudioPlayerView.swift
//  QuranNoor
//
//  Unified compact audio player used both as the floating tab-bar overlay
//  (with skip + close controls) and as the inline now-playing indicator
//  inside VerseReaderView (without skip + close).
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
    /// Action when the player card is tapped (expand to full player).
    let onTap: () -> Void

    var body: some View {
        let theme = themeManager.currentTheme

        if audioService.hasActivePlayback,
           let verse = audioService.currentVerse {
            VStack(spacing: 0) {
                // Thin accent progress line at top (seekable)
                progressLine(theme: theme)

                // Player content
                HStack(spacing: Spacing.xs) {
                    playPauseButton(theme: theme)
                    verseInfo(verse: verse, theme: theme)

                    // Skip controls (only when enabled + continuous mode)
                    if showSkipControls,
                       audioService.continuousPlaybackEnabled,
                       audioService.playingVerses.count > 1 {
                        skipControls(theme: theme)
                    }

                    // Expand + optional close
                    trailingControls(theme: theme)
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
            .padding(.horizontal, Spacing.screenHorizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: audioService.hasActivePlayback)
        }
    }

    // MARK: - Progress Line

    private func progressLine(theme: ThemeMode) -> some View {
        GeometryReader { geometry in
            let progress = audioService.duration > 0
                ? CGFloat(audioService.currentTime / audioService.duration)
                : 0

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 2)

                Rectangle()
                    .fill(theme.accent)
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.linear(duration: 0.24), value: audioService.currentTime)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newTime = Double(value.location.x / geometry.size.width) * audioService.duration
                        audioService.seek(to: max(0, min(newTime, audioService.duration)))
                    }
            )
        }
        .frame(height: 2)
    }

    // MARK: - Play/Pause Button

    private func playPauseButton(theme: ThemeMode) -> some View {
        Button {
            audioService.togglePlayPause()
        } label: {
            ZStack {
                Circle()
                    .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(theme.accentTint)
                    )

                Group {
                    if case .loading = audioService.playbackState {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(theme.accent)
                    } else if case .buffering = audioService.playbackState {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(theme.accent)
                    } else if audioService.playbackState.isPlaying {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 13))
                            .foregroundColor(theme.accent)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                            .foregroundColor(theme.accent)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Verse Info

    private func verseInfo(verse: Verse, theme: ThemeMode) -> some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxxs) {
                    // Always show verse number
                    Text("Verse \(verse.verseNumber)")
                        .font(.system(size: FontSizes.sm, weight: .semibold))
                        .foregroundColor(theme.textPrimary)

                    // Append "of N" only in continuous mode with multiple verses
                    if audioService.continuousPlaybackEnabled && audioService.playingVerses.count > 1 {
                        Text("of \(audioService.playingVerses.count)")
                            .font(.system(size: FontSizes.xs))
                            .foregroundColor(theme.textTertiary)
                    }
                }

                Text("\(audioService.selectedReciter.shortName) · \((audioService.duration - audioService.currentTime).formattedPlaybackTime)")
                    .font(.system(size: FontSizes.xs))
                    .foregroundColor(theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Skip Controls

    private func skipControls(theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.xs) {
            Button {
                Task { try? await audioService.playPreviousVerse() }
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textSecondary)
            }
            .disabled(audioService.currentVerseIndex == 0)

            Button {
                Task { try? await audioService.playNextVerse() }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(theme.textSecondary)
            }
            .disabled(audioService.currentVerseIndex >= audioService.playingVerses.count - 1)
        }
    }

    // MARK: - Trailing Controls

    private func trailingControls(theme: ThemeMode) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "chevron.up.circle")
                .font(.system(size: FontSizes.base))
                .foregroundColor(theme.accentMuted)
                .onTapGesture { onTap() }

            if showCloseButton {
                Button {
                    audioService.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
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
                    print("Expand to full player")
                }
                .environment(themeManager)
            }
            .onAppear {
                // Simulate playing state for preview
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
