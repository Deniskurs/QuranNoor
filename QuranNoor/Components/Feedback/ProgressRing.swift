//
//  ProgressRing.swift
//  QuranNoor
//
//  Animated circular progress ring for prayer times and reading progress
//

import SwiftUI

// MARK: - Progress Ring Component
struct ProgressRing: View {
    // MARK: - Properties
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let showPercentage: Bool
    let color: Color

    @State private var animatedProgress: Double = 0

    // MARK: - Initializer
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        showPercentage: Bool = false,
        color: Color = AppColors.primary.gold
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
        self.color = color
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background circle (track)
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)

            // Optional percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: size * 0.25, weight: .bold))
                    Text("%")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .opacity(0.7)
                }
                .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Prayer Time Progress Ring
struct PrayerProgressRing: View {
    // MARK: - Properties
    let timeRemaining: TimeInterval // seconds until next prayer
    let totalDuration: TimeInterval // total seconds between prayers
    let size: CGFloat

    // MARK: - Body
    var body: some View {
        let progress = 1.0 - (timeRemaining / totalDuration)

        ZStack {
            ProgressRing(
                progress: progress,
                lineWidth: 6,
                size: size,
                showPercentage: false,
                color: AppColors.primary.green
            )

            // Time remaining in center
            VStack(spacing: 0) {
                Text(formattedTime)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(AppColors.primary.green)
                Text("left")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Format Time
    private var formattedTime: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Quran Reading Progress Ring
struct QuranProgressRing: View {
    // MARK: - Properties
    let versesRead: Int
    let totalVerses: Int
    let size: CGFloat

    // MARK: - Body
    var body: some View {
        let progress = Double(versesRead) / Double(totalVerses)

        ProgressRing(
            progress: progress,
            lineWidth: 8,
            size: size,
            showPercentage: true,
            color: AppColors.primary.gold
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 48) {
        // Basic progress ring
        HStack(spacing: 24) {
            ProgressRing(progress: 0.25, size: 80)
            ProgressRing(progress: 0.5, size: 80)
            ProgressRing(progress: 0.75, size: 80)
            ProgressRing(progress: 1.0, size: 80)
        }

        // Progress ring with percentage
        HStack(spacing: 24) {
            ProgressRing(progress: 0.33, size: 100, showPercentage: true)
            ProgressRing(progress: 0.67, size: 100, showPercentage: true)
        }

        // Prayer time progress
        PrayerProgressRing(
            timeRemaining: 3665, // 1h 1m 5s
            totalDuration: 14400, // 4 hours
            size: 120
        )

        // Quran reading progress
        QuranProgressRing(
            versesRead: 4200,
            totalVerses: 6236,
            size: 120
        )

        // Different colors and sizes
        HStack(spacing: 16) {
            ProgressRing(
                progress: 0.6,
                lineWidth: 4,
                size: 50,
                color: AppColors.primary.green
            )

            ProgressRing(
                progress: 0.6,
                lineWidth: 10,
                size: 100,
                color: AppColors.primary.teal
            )

            ProgressRing(
                progress: 0.6,
                lineWidth: 12,
                size: 120,
                color: AppColors.primary.gold
            )
        }
    }
    .padding()
    .background(ThemeManager().currentTheme.backgroundColor)
    .environmentObject(ThemeManager())
}
