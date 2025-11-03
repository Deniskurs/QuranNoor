//
//  QuranReaderDemo.swift
//  QuranNoor
//
//  Interactive Quran reader demo for onboarding
//  Shows Al-Fatiha with translation, page-turning animation, and audio preview
//

import SwiftUI
import AVFoundation

struct QuranReaderDemo: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentPage = 0
    @State private var isPlaying = false
    @State private var showTranslation = true
    @State private var fontSize: CGFloat = 24

    // Sample verses (Al-Fatiha - Surah 1)
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

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(AppColors.primary.teal)
                    ThemedText("Surah Al-Fatiha", style: .heading)
                        .foregroundColor(AppColors.primary.green)
                    Spacer()
                    Text("1:1-7")
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
                    verseView(verse: verses[index], verseNumber: index + 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth(duration: 0.4), value: currentPage)

            // Controls
            VStack(spacing: 12) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(verses.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? AppColors.primary.teal : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 8)

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
                            .foregroundColor(currentPage > 0 ? AppColors.primary.teal : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager.currentTheme.cardColor)
                            )
                    }
                    .disabled(currentPage == 0)

                    // Play audio button
                    Button {
                        toggleAudio()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.primary.green)
                            .symbolEffect(.bounce, value: isPlaying)
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
                            .foregroundColor(currentPage < verses.count - 1 ? AppColors.primary.teal : .secondary)
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
                    .foregroundColor(AppColors.primary.teal)
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
    }

    // MARK: - Verse View
    @ViewBuilder
    private func verseView(verse: (arabic: String, translation: String, transliteration: String), verseNumber: Int) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Verse number badge
                HStack {
                    Spacer()
                    ZStack {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.primary.green.opacity(0.2))

                        Text("\(verseNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.primary.green)
                    }
                    Spacer()
                }

                // Arabic text
                Text(verse.arabic)
                    .font(.custom("Arial", size: fontSize))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .environment(\.layoutDirection, .rightToLeft)

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
    }

    // MARK: - Methods
    private func toggleAudio() {
        withAnimation(.spring(response: 0.3)) {
            isPlaying.toggle()
        }

        if isPlaying {
            HapticManager.shared.trigger(.success)
            AudioHapticCoordinator.shared.playSuccess()

            // Simulate audio playback (3 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(response: 0.3)) {
                    isPlaying = false
                }
            }
        } else {
            HapticManager.shared.trigger(.light)
        }
    }
}

// MARK: - Preview
#Preview {
    QuranReaderDemo()
        .environmentObject(ThemeManager())
        .frame(height: 500)
}
