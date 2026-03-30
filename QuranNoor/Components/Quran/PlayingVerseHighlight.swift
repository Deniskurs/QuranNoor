//
//  PlayingVerseHighlight.swift
//  QuranNoor
//
//  Beautiful verse highlighting for audio playback with
//  multi-layer glow, leading accent bar, and subtle shadow.
//

import SwiftUI

struct PlayingVerseHighlight: ViewModifier {
    let isPlaying: Bool
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                // Multi-layer highlight
                ZStack(alignment: .leading) {
                    // Background fill
                    RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous)
                        .fill(accentColor.opacity(isPlaying ? 0.08 : 0))

                    // Leading accent bar (manuscript margin marker)
                    if isPlaying {
                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(accentColor)
                            .frame(width: 3)
                            .padding(.vertical, 4)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous)
                    .stroke(accentColor.opacity(isPlaying ? 0.25 : 0), lineWidth: 1.5)
            )
            .shadow(color: accentColor.opacity(isPlaying ? 0.10 : 0), radius: 8, x: 0, y: 0)
            .animation(AppAnimation.standard, value: isPlaying)
    }
}

extension View {
    func playingVerseHighlight(isPlaying: Bool, accentColor: Color) -> some View {
        modifier(PlayingVerseHighlight(isPlaying: isPlaying, accentColor: accentColor))
    }
}
