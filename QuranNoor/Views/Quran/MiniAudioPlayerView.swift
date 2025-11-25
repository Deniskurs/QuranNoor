//
//  MiniAudioPlayerView.swift
//  QuranNoor
//
//  Minimized floating audio player shown at bottom of screen
//

import SwiftUI

struct MiniAudioPlayerView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var audioService = QuranAudioService.shared
    let onTap: () -> Void

    var body: some View {
        if audioService.playbackState.isPlaying || audioService.playbackState == .paused,
           let verse = audioService.currentVerse {
            VStack(spacing: 0) {
                // Progress bar at top
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 2)

                        // Progress fill
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary.green, themeManager.currentTheme.featureAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(audioService.currentTime / max(audioService.duration, 1)),
                                height: 2
                            )
                    }
                }
                .frame(height: 2)

                // Mini player content
                HStack(spacing: 12) {
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
                                .frame(width: 44, height: 44)
                                .shadow(color: AppColors.primary.green.opacity(0.3), radius: 4, x: 0, y: 2)

                            Image(systemName: audioService.playbackState.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .offset(x: audioService.playbackState.isPlaying ? 0 : 1)
                        }
                    }

                    // Verse info (tappable to expand)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Surah \(verse.surahNumber), Verse \(verse.verseNumber)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textColor)

                            // Show position in queue during continuous playback
                            if audioService.continuousPlaybackEnabled && audioService.playingVerses.count > 1 {
                                Text("(\(audioService.currentVerseIndex + 1)/\(audioService.playingVerses.count))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.featureAccent)
                            }
                        }

                        Text(audioService.selectedReciter.shortName)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap()
                    }

                    Spacer()

                    // Next button (if continuous playback enabled)
                    if audioService.continuousPlaybackEnabled && !audioService.playingVerses.isEmpty {
                        Button {
                            Task {
                                try? await audioService.playNextVerse()
                            }
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                        }
                        .disabled(audioService.currentVerseIndex >= audioService.playingVerses.count - 1)
                    }

                    // Close button
                    Button {
                        audioService.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    themeManager.currentTheme.backgroundColor
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: audioService.playbackState)
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
                        text: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
                        juz: 1
                    )
                    try? await audioService.play(verse: mockVerse)
                }
            }
        }
    }

    return PreviewWrapper()
}
