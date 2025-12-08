//
//  HeroCountdownDisplay.swift
//  QuranNoor
//
//  Large 72pt countdown timer with smooth digit animations
//  Supports urgency-based color changes and accessibility
//

import SwiftUI

/// Large hero countdown display with animated digit transitions
struct HeroCountdownDisplay: View {
    // MARK: - Properties

    let countdownString: String
    let isUrgent: Bool
    let urgencyLevel: UrgencyLevel

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var isPulsing: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // Main countdown
            Text(countdownString)
                .font(.system(size: 72, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundColor(countdownColor)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: countdownString)
                .scaleEffect(isPulsing && urgencyLevel == .critical ? 1.02 : 1.0)
                .accessibilityLabel("Time remaining: \(accessibleCountdown)")

            // Subtle label
            Text(countdownLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .onChange(of: urgencyLevel) { _, newLevel in
            if newLevel == .critical && !reduceMotion {
                startPulseAnimation()
            } else {
                isPulsing = false
            }
        }
        .onAppear {
            if urgencyLevel == .critical && !reduceMotion {
                startPulseAnimation()
            }
        }
    }

    // MARK: - Computed Properties

    private var countdownColor: Color {
        switch urgencyLevel {
        case .relaxed, .normal:
            return themeManager.currentTheme.accentPrimary
        case .elevated:
            return AppColors.primary.gold
        case .urgent:
            return .orange
        case .critical:
            return .red
        }
    }

    private var countdownLabel: String {
        if isUrgent {
            return "remaining"
        }
        return "until next prayer"
    }

    private var accessibleCountdown: String {
        // Convert "02:31:47" to "2 hours, 31 minutes, 47 seconds"
        let components = countdownString.split(separator: ":")
        var parts: [String] = []

        if components.count == 3 {
            if let hours = Int(components[0]), hours > 0 {
                parts.append("\(hours) hour\(hours == 1 ? "" : "s")")
            }
            if let minutes = Int(components[1]) {
                parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
            }
            if let seconds = Int(components[2]) {
                parts.append("\(seconds) second\(seconds == 1 ? "" : "s")")
            }
        } else if components.count == 2 {
            if let minutes = Int(components[0]) {
                parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
            }
            if let seconds = Int(components[1]) {
                parts.append("\(seconds) second\(seconds == 1 ? "" : "s")")
            }
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Animation

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    VStack(spacing: 40) {
        HeroCountdownDisplay(
            countdownString: "02:31:47",
            isUrgent: false,
            urgencyLevel: .normal
        )

        HeroCountdownDisplay(
            countdownString: "45:30",
            isUrgent: false,
            urgencyLevel: .normal
        )
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}

#Preview("Urgency Levels") {
    VStack(spacing: 30) {
        ForEach([UrgencyLevel.relaxed, .normal, .elevated, .urgent, .critical], id: \.self) { level in
            VStack(spacing: 4) {
                Text(String(describing: level))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                HeroCountdownDisplay(
                    countdownString: level == .critical ? "04:30" : "12:45",
                    isUrgent: level.rawValue >= UrgencyLevel.urgent.rawValue,
                    urgencyLevel: level
                )
            }
        }
    }
    .padding()
    .background(Color(hex: "#1A2332"))
    .environment(ThemeManager())
}

#Preview("Light Theme") {
    HeroCountdownDisplay(
        countdownString: "01:15:30",
        isUrgent: false,
        urgencyLevel: .normal
    )
    .padding()
    .background(Color(hex: "#F8F4EA"))
    .environment(ThemeManager())
}
