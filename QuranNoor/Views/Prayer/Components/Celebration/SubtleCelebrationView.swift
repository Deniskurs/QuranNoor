//
//  SubtleCelebrationView.swift
//  QuranNoor
//
//  Subtle glow and pulse celebration when all prayers are completed
//  Respects reduceMotion accessibility setting
//

import SwiftUI

/// Subtle celebration overlay with glow and pulse effects
struct SubtleCelebrationView: View {
    // MARK: - Properties

    let isAllCompleted: Bool

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var borderOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(glowColor.opacity(glowOpacity * 0.3))
                .blur(radius: 20)

            // Pulsing border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(borderOpacity * 0.8),
                            glowColor.opacity(borderOpacity * 0.4),
                            glowColor.opacity(borderOpacity * 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .scaleEffect(pulseScale)
        }
        .allowsHitTesting(false)
        .onChange(of: isAllCompleted) { _, completed in
            if completed {
                startCelebration()
            } else {
                stopCelebration()
            }
        }
        .onAppear {
            if isAllCompleted {
                startCelebration()
            }
        }
    }

    // MARK: - Animation

    private func startCelebration() {
        if reduceMotion {
            // Static glow for reduced motion
            withAnimation(.easeIn(duration: 0.3)) {
                glowOpacity = 0.6
                borderOpacity = 0.8
            }
        } else {
            // Animated glow
            withAnimation(.easeIn(duration: 0.5)) {
                glowOpacity = 0.6
                borderOpacity = 0.8
            }

            // Continuous pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.02
                glowOpacity = 0.8
            }
        }
    }

    private func stopCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 0
            borderOpacity = 0
            pulseScale = 1.0
        }
    }

    // MARK: - Colors

    private var glowColor: Color {
        switch themeManager.currentTheme {
        case .light:
            return themeManager.currentTheme.accentMuted
        case .dark:
            return themeManager.currentTheme.accentMuted
        case .night:
            return themeManager.currentTheme.accentMuted
        case .sepia:
            return themeManager.currentTheme.accent
        }
    }
}

// MARK: - Enhanced Completion Statistics Card

/// Enhanced completion statistics card with celebration effect
struct CelebrationCompletionCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var completionService = PrayerCompletionService.shared

    var body: some View {
        let _ = completionService.changeCounter
        let stats = completionService.getTodayStatistics()

        ZStack {
            // Celebration glow overlay (behind card)
            SubtleCelebrationView(isAllCompleted: stats.isAllCompleted)

            // Card content
            CardView(intensity: .moderate) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TODAY'S PROGRESS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .tracking(1.5)

                            Text("Prayer Completion")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.accent)
                        }

                        Spacer()

                        // Progress ring
                        ZStack {
                            // Background track
                            Circle()
                                .stroke(themeManager.currentTheme.textTertiary.opacity(0.2), lineWidth: 6)

                            // Progress
                            Circle()
                                .trim(from: 0, to: CGFloat(stats.completedCount) / CGFloat(stats.totalCount))
                                .stroke(
                                    stats.isAllCompleted ? themeManager.currentTheme.accentMuted : themeManager.currentTheme.accent,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stats.completedCount)

                            // Percentage
                            Text("\(stats.percentage)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                        }
                        .frame(width: 60, height: 60)
                    }

                    IslamicDivider(style: .simple)

                    // Stats row
                    HStack(spacing: 0) {
                        statItem(
                            icon: "checkmark.circle.fill",
                            value: "\(stats.completedCount)",
                            label: "Completed",
                            color: themeManager.currentTheme.accent
                        )

                        Spacer()

                        statItem(
                            icon: "circle.dashed",
                            value: "\(stats.totalCount - stats.completedCount)",
                            label: "Remaining",
                            color: themeManager.currentTheme.accent
                        )

                        Spacer()

                        statItem(
                            icon: "flame.fill",
                            value: "\(stats.percentage)",
                            label: "Progress",
                            color: themeManager.currentTheme.accentMuted
                        )
                    }

                    // All complete celebration message
                    if stats.isAllCompleted {
                        allCompletedMessage
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stats.isAllCompleted)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var allCompletedMessage: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.accentMuted)

            Text("All prayers completed!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.accentMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(themeManager.currentTheme.accentMuted.opacity(0.15))
        )
        .accessibilityLabel("Congratulations! All five daily prayers completed")
    }
}

// MARK: - Preview

#Preview("Celebration Active") {
    VStack(spacing: 24) {
        // With celebration
        ZStack {
            SubtleCelebrationView(isAllCompleted: true)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#2A3342"))
                .frame(height: 150)
                .overlay(
                    Text("All Prayers Complete!")
                        .foregroundColor(.white)
                )
        }
        .frame(height: 180)

        // Without celebration
        ZStack {
            SubtleCelebrationView(isAllCompleted: false)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#2A3342"))
                .frame(height: 150)
                .overlay(
                    Text("3/5 Prayers")
                        .foregroundColor(.white)
                )
        }
        .frame(height: 180)
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}

#Preview("Completion Card") {
    VStack(spacing: 24) {
        CelebrationCompletionCard()
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment({
        let manager = ThemeManager()
        manager.setTheme(.dark)
        return manager
    }())
}
