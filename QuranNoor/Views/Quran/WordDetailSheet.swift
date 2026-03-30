//
//  WordDetailSheet.swift
//  QuranNoor
//
//  Detail sheet presented when a user taps a word in WordByWordView.
//  Shows the Arabic word, its translation, transliteration, and an audio play button.
//

import SwiftUI
import AVFoundation

// MARK: - Word Audio Player (lightweight, fire-and-forget)

@Observable
@MainActor
private final class WordAudioPlayer {
    var isPlaying = false
    private var player: AVPlayer?

    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true

        // Observe playback end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
    }
}

// MARK: - Word Detail Sheet

/// A medium-height sheet presenting full detail for a tapped Quran word.
struct WordDetailSheet: View {
    let word: QuranWord
    let mushafType: MushafType

    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var audioPlayer = WordAudioPlayer()

    private let audioBaseURL = "https://audio.qurancdn.com/"

    // MARK: - Computed

    private var arabicFont: Font {
        AppTypography.arabicFont(for: mushafType, size: FontSizes.xxxl)
    }

    private var audioStreamURL: URL? {
        guard let path = word.audioURL else { return nil }
        return URL(string: audioBaseURL + path)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        arabicWordSection
                        translationSection
                        transliterationSection

                        if word.translation != nil || word.transliteration != nil {
                            Divider()
                                .background(theme.borderColor)
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        if audioStreamURL != nil {
                            audioSection
                        }
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        audioPlayer.stop()
                        dismiss()
                    }
                    .font(AppTypography.button)
                    .foregroundStyle(theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.backgroundColor)
        .onDisappear {
            audioPlayer.stop()
        }
    }

    // MARK: - Sections

    private var arabicWordSection: some View {
        Text(word.textUthmani)
            .font(arabicFont)
            .foregroundStyle(theme.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var translationSection: some View {
        if let translation = word.translation, !translation.isEmpty {
            Text(translation)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Translation: \(translation)")
        }
    }

    @ViewBuilder
    private var transliterationSection: some View {
        if let transliteration = word.transliteration, !transliteration.isEmpty {
            Text(transliteration)
                .font(.system(size: FontSizes.base, weight: .regular, design: .default).italic())
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Transliteration: \(transliteration)")
        }
    }

    private var audioSection: some View {
        Button {
            if audioPlayer.isPlaying {
                audioPlayer.stop()
            } else if let url = audioStreamURL {
                audioPlayer.play(urlString: url.absoluteString)
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: audioPlayer.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: FontSizes.lg, weight: .medium))
                    .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)

                Text(audioPlayer.isPlaying ? "Playing…" : "Play Pronunciation")
                    .font(AppTypography.button)
            }
            .foregroundStyle(theme.accent)
            .padding(.horizontal, Spacing.buttonHorizontal)
            .padding(.vertical, Spacing.buttonVertical)
            .background(
                Capsule()
                    .fill(theme.accentTint)
            )
            .overlay(
                Capsule()
                    .strokeBorder(theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(audioPlayer.isPlaying ? "Stop audio" : "Play word pronunciation")
    }
}
