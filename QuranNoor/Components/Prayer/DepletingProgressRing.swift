//
//  DepletingProgressRing.swift
//  QuranNoor
//
//  Created by Claude Code
//  A progress ring that depletes (empties) over time for loss-aversion psychology
//  Research shows depleting indicators create stronger urgency than filling ones
//

import SwiftUI

/// High-performance depleting progress ring that shows time running out
/// Uses loss aversion psychology - seeing progress DECREASE creates urgency
struct DepletingProgressRing: View {
    // MARK: - Properties

    /// Progress remaining (1.0 = full, 0.0 = empty/depleted)
    let progress: Double

    /// Current urgency level for color adaptation
    let urgencyLevel: UrgencyLevel

    /// Current theme for color adaptation
    let theme: ThemeMode

    /// Ring size (diameter)
    let size: CGFloat

    /// Line width of the ring stroke
    var lineWidth: CGFloat = 4

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Animation State

    @State private var animatedProgress: Double = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    // MARK: - Computed Properties

    private var ringColor: Color {
        urgencyLevel.ringColor(for: theme)
    }

    private var backgroundColor: Color {
        urgencyLevel.ringBackgroundColor(for: theme)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ring (always full)
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Depleting progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top

            // Pulse overlay for critical urgency (respects reduced motion)
            if urgencyLevel.shouldPulse && !reduceMotion {
                Circle()
                    .stroke(ringColor.opacity(pulseOpacity), lineWidth: 2)
                    .frame(width: size, height: size)
                    .scaleEffect(pulseScale)
            }
        }
        .frame(width: size + lineWidth * 2, height: size + lineWidth * 2) // Prevent clipping
        .drawingGroup() // Metal acceleration for 120fps
        .onAppear {
            animatedProgress = progress
            if urgencyLevel.shouldPulse && !reduceMotion {
                startPulsing()
            }
        }
        .onChange(of: progress) { _, newValue in
            // Smooth animation for progress changes
            withAnimation(.linear(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
        .onChange(of: urgencyLevel) { oldValue, newValue in
            // Start/stop pulsing when urgency changes
            if newValue.shouldPulse && !oldValue.shouldPulse && !reduceMotion {
                startPulsing()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time remaining")
        .accessibilityValue("\(Int(progress * 100)) percent remaining. \(urgencyLevel.accessibilityDescription)")
    }

    // MARK: - Animation

    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: urgencyLevel.pulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = urgencyLevel.pulseScale
            pulseOpacity = 0.0
        }
    }
}

// MARK: - Convenience Initializers

extension DepletingProgressRing {
    /// Initialize with a PrayerPeriod for automatic urgency calculation
    init(period: PrayerPeriod, theme: ThemeMode, size: CGFloat = 48, lineWidth: CGFloat = 4) {
        // Calculate depleting progress (1.0 - periodProgress means it depletes)
        self.progress = max(0, 1.0 - period.periodProgress)
        self.urgencyLevel = UrgencyLevel.from(period: period)
        self.theme = theme
        self.size = size
        self.lineWidth = lineWidth
    }
}

// MARK: - Preview

#Preview("Urgency Progression") {
    VStack(spacing: 30) {
        ForEach(UrgencyLevel.allCases, id: \.rawValue) { level in
            HStack(spacing: 20) {
                DepletingProgressRing(
                    progress: Double(level.previewMinutes) / 150.0,
                    urgencyLevel: level,
                    theme: .light,
                    size: 48,
                    lineWidth: 4
                )

                VStack(alignment: .leading) {
                    Text(String(describing: level).capitalized)
                        .font(.headline)
                        .foregroundColor(level.countdownColor(for: .light))

                    Text("\(level.previewMinutes) minutes remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
}

#Preview("Dark Theme") {
    VStack(spacing: 30) {
        ForEach(UrgencyLevel.allCases, id: \.rawValue) { level in
            HStack(spacing: 20) {
                DepletingProgressRing(
                    progress: Double(level.previewMinutes) / 150.0,
                    urgencyLevel: level,
                    theme: .dark,
                    size: 48,
                    lineWidth: 4
                )

                VStack(alignment: .leading) {
                    Text(String(describing: level).capitalized)
                        .font(.headline)
                        .foregroundColor(level.countdownColor(for: .dark))

                    Text("\(level.previewMinutes) minutes remaining")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
    }
    .padding()
    .background(Color(hex: "#1A2332"))
}

#Preview("Size Variations") {
    HStack(spacing: 30) {
        DepletingProgressRing(
            progress: 0.75,
            urgencyLevel: .normal,
            theme: .light,
            size: 32,
            lineWidth: 3
        )

        DepletingProgressRing(
            progress: 0.50,
            urgencyLevel: .elevated,
            theme: .light,
            size: 48,
            lineWidth: 4
        )

        DepletingProgressRing(
            progress: 0.25,
            urgencyLevel: .urgent,
            theme: .light,
            size: 64,
            lineWidth: 5
        )

        DepletingProgressRing(
            progress: 0.10,
            urgencyLevel: .critical,
            theme: .light,
            size: 80,
            lineWidth: 6
        )
    }
    .padding()
    .background(Color(hex: "#F8F4EA"))
}
