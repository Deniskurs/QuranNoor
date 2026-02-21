//
//  SurahArtworkBadge.swift
//  QuranNoor
//
//  Visual anchor for the audio player — shows surah number in a themed badge.
//  Two sizes: .mini (44pt circle) for the mini player, .full (card) for expanded.
//

import SwiftUI

struct SurahArtworkBadge: View {
    enum Size { case mini, full }

    let surahNumber: Int
    let arabicText: String?
    let size: Size
    var animationNamespace: Namespace.ID?

    @Environment(ThemeManager.self) var themeManager: ThemeManager

    init(
        surahNumber: Int,
        arabicText: String? = nil,
        size: Size,
        animationNamespace: Namespace.ID? = nil
    ) {
        self.surahNumber = surahNumber
        self.arabicText = arabicText
        self.size = size
        self.animationNamespace = animationNamespace
    }

    // Accent gradient varies by surah for subtle variety
    private var gradientColors: [Color] {
        let theme = themeManager.currentTheme
        let index = surahNumber % 7
        let base = theme.accent
        let shifts: [(Color, Color)] = [
            (base, base.opacity(0.7)),
            (base.opacity(0.9), theme.accentMuted),
            (base, base.opacity(0.8)),
            (theme.accentMuted, base),
            (base.opacity(0.85), base.opacity(0.6)),
            (base, theme.accentMuted.opacity(0.8)),
            (base.opacity(0.95), base.opacity(0.65)),
        ]
        return [shifts[index].0, shifts[index].1]
    }

    var body: some View {
        let theme = themeManager.currentTheme

        Group {
            switch size {
            case .mini:
                miniBadge(theme: theme)
            case .full:
                fullCard(theme: theme)
            }
        }
    }

    // MARK: - Mini Badge (44pt circle)

    private func miniBadge(theme: ThemeMode) -> some View {
        let badge = ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("\(surahNumber)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)

        return Group {
            if let ns = animationNamespace {
                badge.matchedGeometryEffect(id: "playerArtwork", in: ns)
            } else {
                badge
            }
        }
    }

    // MARK: - Full Card (expanded player artwork)

    private func fullCard(theme: ThemeMode) -> some View {
        let card = VStack(spacing: 0) {
            if let text = arabicText {
                Text(text)
                    .font(.custom("KFGQPC HAFS Uthmanic Script Regular", size: 30))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(16)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardColor)
                .overlay(
                    // Inner border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 0.5)
                        .padding(1)
                )
                .overlay(
                    // Outer border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.accentMuted.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, x: 0, y: 4)
        .shadow(color: theme.accent.opacity(0.08), radius: 20, x: 0, y: 8)
        .padding(.horizontal, Spacing.screenHorizontal)

        return Group {
            if let ns = animationNamespace {
                card.matchedGeometryEffect(id: "playerArtwork", in: ns)
            } else {
                card
            }
        }
    }
}
