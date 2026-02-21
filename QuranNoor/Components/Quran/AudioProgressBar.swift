//
//  AudioProgressBar.swift
//  QuranNoor
//
//  Shared seekable progress bar used by both mini and full audio players.
//  Mini style: thin 3pt bar with glow. Full style: 6pt bar with scrubber knob.
//

import SwiftUI

struct AudioProgressBar: View {
    enum Style { case mini, full }

    let style: Style
    let progress: Double       // 0...1
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    var animationNamespace: Namespace.ID?
    var isGeometrySource: Bool = true

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var isTouching = false
    @State private var dragProgress: Double?

    private var displayProgress: Double {
        dragProgress ?? progress
    }

    var body: some View {
        let theme = themeManager.currentTheme

        let bar = Group {
            switch style {
            case .mini:
                miniBar(theme: theme)
            case .full:
                fullBar(theme: theme)
            }
        }

        if let ns = animationNamespace {
            bar.matchedGeometryEffect(id: "playerProgress", in: ns, isSource: isGeometrySource)
        } else {
            bar
        }
    }

    // MARK: - Mini Bar (3pt, glow effect)

    private func miniBar(theme: ThemeMode) -> some View {
        GeometryReader { geometry in
            let fillWidth = geometry.size.width * CGFloat(displayProgress)

            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(height: 3)

                // Fill with glow
                Rectangle()
                    .fill(theme.accent)
                    .frame(width: max(0, fillWidth), height: 3)
                    .shadow(color: theme.accent.opacity(0.5), radius: 4, x: 0, y: 0)
                    .animation(dragProgress != nil ? nil : .linear(duration: 0.25), value: displayProgress)
            }
            .clipShape(Capsule())
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = Double(value.location.x / geometry.size.width)
                        let clamped = max(0, min(1, ratio))
                        dragProgress = clamped
                        onSeek(clamped * duration)
                    }
                    .onEnded { _ in
                        dragProgress = nil
                    }
            )
        }
        .frame(height: 3)
    }

    // MARK: - Full Bar (6pt→8pt on touch, scrubber knob)

    private func fullBar(theme: ThemeMode) -> some View {
        VStack(spacing: Spacing.xxs) {
            GeometryReader { geometry in
                let fillWidth = geometry.size.width * CGFloat(displayProgress)
                let trackHeight: CGFloat = isTouching ? 8 : 6

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(theme.textSecondary.opacity(0.12))
                        .frame(height: trackHeight)

                    // Gradient fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.accent, theme.accentMuted],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, fillWidth), height: trackHeight)
                        .animation(isTouching ? nil : .linear(duration: 0.25), value: displayProgress)

                    // Scrubber knob
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .frame(width: 16, height: 16)
                        .scaleEffect(isTouching ? 1.2 : 1.0)
                        .offset(x: max(0, min(fillWidth - 8, geometry.size.width - 16)))
                        .opacity(isTouching ? 1.0 : 0.0)
                        .animation(isTouching ? nil : .linear(duration: 0.25), value: displayProgress)
                }
                .animation(.easeOut(duration: 0.15), value: isTouching)
                .contentShape(Rectangle().inset(by: -16))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isTouching {
                                isTouching = true
                                HapticManager.shared.trigger(.selection)
                            }
                            let ratio = Double(value.location.x / geometry.size.width)
                            let clamped = max(0, min(1, ratio))
                            dragProgress = clamped
                            onSeek(clamped * duration)
                        }
                        .onEnded { _ in
                            isTouching = false
                            dragProgress = nil
                        }
                )
            }
            .frame(height: isTouching ? 8 : 6)
            .animation(.easeOut(duration: 0.15), value: isTouching)

            // Time labels
            HStack {
                Text(currentTime.formattedPlaybackTime)
                    .font(.system(size: FontSizes.xs, weight: .medium))
                    .foregroundColor(theme.textTertiary)
                    .monospacedDigit()
                Spacer()
                Text(duration.formattedPlaybackTime)
                    .font(.system(size: FontSizes.xs, weight: .medium))
                    .foregroundColor(theme.textTertiary)
                    .monospacedDigit()
            }
        }
    }
}
