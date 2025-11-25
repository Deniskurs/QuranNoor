//
//  QuranReaderDemo.swift
//  QuranNoor
//
//  Interactive Quran reader demo for onboarding
//  Shows Al-Fatiha with translation, page-turning animation, and real audio recitation
//

import SwiftUI
import AVFoundation

struct QuranReaderDemo: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var currentPage = 0
    @State private var showTranslation = true
    @State private var fontSize: CGFloat = 24

    // Audio service for real Quran recitation (observed for UI updates)
    @State private var audioService = DemoAudioService.shared

    // Sample verses (Al-Fatiha - Surah 1, verses 1-4)
    private let verses: [(arabic: String, translation: String, transliteration: String)] = [
        (
            "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
            "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            "Bismillāhi r-raḥmāni r-raḥīm"
        ),
        (
            "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ",
            "All praise is due to Allah, Lord of the worlds.",
            "Al-ḥamdu lillāhi rabbi l-ʿālamīn"
        ),
        (
            "ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
            "The Entirely Merciful, the Especially Merciful.",
            "Ar-raḥmāni r-raḥīm"
        ),
        (
            "مَـٰلِكِ يَوْمِ ٱلدِّينِ",
            "Sovereign of the Day of Recompense.",
            "Māliki yawmi d-dīn"
        )
    ]

    // MARK: - Computed Properties

    private var isPlaying: Bool {
        audioService.playbackState == .playing
    }

    private var isCurrentVersePlaying: Bool {
        isPlaying && audioService.currentVerseIndex == currentPage
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(themeManager.currentTheme.featureAccent)
                    ThemedText("Surah Al-Fatiha", style: .heading)
                        .foregroundColor(AppColors.primary.green)
                    Spacer()
                    Text("1:1-4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("The Opening")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                themeManager.currentTheme.cardColor
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
            )

            Divider()

            // Content area with page turning
            TabView(selection: $currentPage) {
                ForEach(verses.indices, id: \.self) { index in
                    verseView(verse: verses[index], verseNumber: index + 1, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth(duration: 0.4), value: currentPage)

            // Controls
            VStack(spacing: 12) {
                // Progress bar (shows when playing)
                if audioService.playbackState != .idle {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary.green, themeManager.currentTheme.featureAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * audioService.progress, height: 4)
                                .animation(.linear(duration: 0.1), value: audioService.progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Page indicator with verse dots
                HStack(spacing: 8) {
                    ForEach(verses.indices, id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(currentPage == index ? themeManager.currentTheme.featureAccent : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)

                            // Playing indicator ring
                            if isPlaying && audioService.currentVerseIndex == index {
                                Circle()
                                    .stroke(themeManager.currentTheme.featureAccent, lineWidth: 2)
                                    .frame(width: 14, height: 14)
                                    .scaleEffect(isPlaying ? 1.2 : 1.0)
                                    .opacity(isPlaying ? 0.6 : 0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPlaying)
                            }
                        }
                        .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, audioService.playbackState == .idle ? 8 : 4)

                // Interactive controls
                HStack(spacing: 20) {
                    // Previous button
                    Button {
                        if currentPage > 0 {
                            withAnimation(.smooth) {
                                currentPage -= 1
                                HapticManager.shared.trigger(.selection)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(currentPage > 0 ? themeManager.currentTheme.featureAccent : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.cardColor)
                            )
                    }
                    .disabled(currentPage == 0)

                    // Play/Pause audio button
                    Button {
                        toggleAudio()
                    } label: {
                        ZStack {
                            // Outer glow when playing
                            if isPlaying {
                                Circle()
                                    .fill(AppColors.primary.green.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPlaying)
                            }

                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.primary.green)
                                .symbolEffect(.bounce, value: audioService.playbackState)
                        }
                    }

                    // Next button
                    Button {
                        if currentPage < verses.count - 1 {
                            withAnimation(.smooth) {
                                currentPage += 1
                                HapticManager.shared.trigger(.selection)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(currentPage < verses.count - 1 ? themeManager.currentTheme.featureAccent : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.cardColor)
                            )
                    }
                    .disabled(currentPage == verses.count - 1)
                }

                // Toggle translation
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showTranslation.toggle()
                        HapticManager.shared.trigger(.selection)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showTranslation ? "text.quote" : "text.quote.rtl")
                        Text(showTranslation ? "Hide Translation" : "Show Translation")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.featureAccent)
                }
                .buttonStyle(.borderless)

                // Hint text
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                    Text("Swipe to turn pages • Tap play for recitation")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .onChange(of: audioService.currentVerseIndex) { _, newIndex in
            // Auto-advance page when verse changes during playback
            if audioService.playbackState == .playing && newIndex != currentPage {
                withAnimation(.smooth(duration: 0.4)) {
                    currentPage = newIndex
                }
            }
        }
        .onDisappear {
            // Stop audio when view disappears
            audioService.stop()
        }
    }

    // MARK: - Verse View
    @ViewBuilder
    private func verseView(verse: (arabic: String, translation: String, transliteration: String), verseNumber: Int, index: Int) -> some View {
        let isThisVersePlaying = isPlaying && audioService.currentVerseIndex == index

        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Verse number badge with playing indicator
                HStack {
                    Spacer()
                    ZStack {
                        // Outer glow when playing
                        if isThisVersePlaying {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 52))
                                .foregroundColor(AppColors.primary.green.opacity(0.3))
                                .scaleEffect(isThisVersePlaying ? 1.15 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isThisVersePlaying)
                        }

                        Image(systemName: "seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(isThisVersePlaying ? AppColors.primary.green.opacity(0.4) : AppColors.primary.green.opacity(0.2))

                        Text("\(verseNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.primary.green)
                    }
                    Spacer()
                }

                // Arabic text with highlight effect
                Text(verse.arabic)
                    .font(.custom("Arial", size: fontSize))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .environment(\.layoutDirection, .rightToLeft)
                    .shadow(
                        color: isThisVersePlaying ? AppColors.primary.green.opacity(0.3) : .clear,
                        radius: isThisVersePlaying ? 8 : 0
                    )
                    .animation(.easeInOut(duration: 0.3), value: isThisVersePlaying)

                // Transliteration
                Text(verse.transliteration)
                    .font(.caption)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)

                // Translation (with animation)
                if showTranslation {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 40)

                        Text(verse.translation)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.9))
                            .padding(.horizontal, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        // Highlight background when playing
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isThisVersePlaying ? AppColors.primary.green.opacity(0.05) : Color.clear)
                .animation(.easeInOut(duration: 0.3), value: isThisVersePlaying)
        )
    }

    // MARK: - Methods
    private func toggleAudio() {
        HapticManager.shared.trigger(.selection)

        if audioService.playbackState == .playing {
            audioService.pause()
        } else if audioService.playbackState == .paused {
            audioService.resume()
        } else {
            // Start from current page
            audioService.play(fromVerse: currentPage)
        }
    }
}

// MARK: - Preview
#Preview {
    QuranReaderDemo()
        .environment(ThemeManager())
        .frame(height: 500)
}
