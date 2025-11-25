//
//  UrgencyLevel.swift
//  QuranNoor
//
//  Created by Claude Code
//  Defines urgency levels for prayer time countdown with psychologically-informed color progression
//

import SwiftUI

/// Urgency level based on time remaining until prayer deadline
/// Uses research-backed color progression: cool (relaxed) → warm (urgent) → hot (critical)
enum UrgencyLevel: Int, Comparable, CaseIterable {
    case relaxed = 0     // > 2 hours remaining
    case normal = 1      // 30min - 2hr remaining
    case elevated = 2    // 10-30min remaining
    case urgent = 3      // 5-10min remaining
    case critical = 4    // < 5min remaining

    // MARK: - Factory Methods

    /// Create urgency level from minutes remaining
    static func from(minutesRemaining: Int) -> UrgencyLevel {
        switch minutesRemaining {
        case 120...: return .relaxed
        case 30..<120: return .normal
        case 10..<30: return .elevated
        case 5..<10: return .urgent
        default: return .critical
        }
    }

    /// Create urgency level from a PrayerPeriod
    static func from(period: PrayerPeriod) -> UrgencyLevel {
        let minutes = Int(period.timeUntilNextEvent / 60)
        return from(minutesRemaining: minutes)
    }

    /// Create urgency level from seconds remaining
    static func from(secondsRemaining: TimeInterval) -> UrgencyLevel {
        let minutes = Int(secondsRemaining / 60)
        return from(minutesRemaining: minutes)
    }

    // MARK: - Comparable

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Color Functions

    /// Primary countdown color based on urgency and theme
    /// Uses color temperature: cool (green/teal) → warm (gold) → hot (orange/red)
    func countdownColor(for theme: ThemeMode) -> Color {
        switch self {
        case .relaxed, .normal:
            return theme.accentSecondary
        case .elevated:
            return AppColors.primary.gold // #C7A566
        case .urgent:
            return Color.orange // System orange
        case .critical:
            return Color.red // System red
        }
    }

    /// Progress ring color (matches countdown for visual unity)
    func ringColor(for theme: ThemeMode) -> Color {
        countdownColor(for: theme)
    }

    /// Ring background color with appropriate opacity
    func ringBackgroundColor(for theme: ThemeMode) -> Color {
        switch theme {
        case .light, .sepia:
            return Color.gray.opacity(0.15)
        case .dark:
            return Color.gray.opacity(0.25)
        case .night:
            return Color.gray.opacity(0.30)
        }
    }

    /// Status badge background color
    /// Subtle background that intensifies with urgency
    func badgeBackground(for theme: ThemeMode) -> Color {
        switch self {
        case .relaxed, .normal:
            return Color.clear
        case .elevated:
            return AppColors.primary.gold.opacity(0.12)
        case .urgent:
            return Color.orange.opacity(0.15)
        case .critical:
            return Color.red.opacity(0.18)
        }
    }

    /// Status badge text/icon color
    func badgeForeground(for theme: ThemeMode) -> Color {
        switch self {
        case .relaxed, .normal:
            return theme.textSecondary
        case .elevated:
            return AppColors.primary.gold
        case .urgent:
            return Color.orange
        case .critical:
            return Color.red
        }
    }

    // MARK: - Animation Properties

    /// Whether this urgency level should show pulse animation
    var shouldPulse: Bool {
        self == .critical
    }

    /// Pulse animation duration (slower = less urgent feel)
    var pulseDuration: Double {
        switch self {
        case .critical: return 1.0
        default: return 0 // No pulse
        }
    }

    /// Pulse scale factor
    var pulseScale: CGFloat {
        switch self {
        case .critical: return 1.08
        default: return 1.0
        }
    }

    // MARK: - Accessibility

    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        switch self {
        case .relaxed:
            return "More than 2 hours remaining"
        case .normal:
            return "Between 30 minutes and 2 hours remaining"
        case .elevated:
            return "Between 10 and 30 minutes remaining"
        case .urgent:
            return "Less than 10 minutes remaining"
        case .critical:
            return "Less than 5 minutes remaining, prayer time ending soon"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension UrgencyLevel {
    /// Sample time remaining for previews
    var previewMinutes: Int {
        switch self {
        case .relaxed: return 150
        case .normal: return 60
        case .elevated: return 20
        case .urgent: return 7
        case .critical: return 3
        }
    }
}
#endif
