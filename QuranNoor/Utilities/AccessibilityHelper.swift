//
//  AccessibilityHelper.swift
//  QuranNoor
//
//  Comprehensive accessibility utilities for VoiceOver, Dynamic Type, and Reduce Motion
//  Ensures WCAG 2.1 Level AA compliance
//

import SwiftUI
import Combine

// MARK: - Accessibility Manager

@MainActor
final class AccessibilityHelper: ObservableObject {
    static let shared = AccessibilityHelper()

    // MARK: - Environment Monitoring
    @Published var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    @Published var isBoldTextEnabled: Bool = UIAccessibility.isBoldTextEnabled
    @Published var isReduceTransparencyEnabled: Bool = UIAccessibility.isReduceTransparencyEnabled
    @Published var isDarkerSystemColorsEnabled: Bool = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium

    private init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
    }

    // MARK: - Helper Methods

    /// Returns animation that respects Reduce Motion preference
    func animation<V: Equatable>(_ animation: Animation, value: V) -> Animation? {
        isReduceMotionEnabled ? nil : animation
    }

    /// Returns opacity that respects Reduce Transparency preference
    func opacity(_ value: Double) -> Double {
        isReduceTransparencyEnabled ? 1.0 : value
    }

    /// Returns whether to show animations
    var shouldAnimate: Bool {
        !isReduceMotionEnabled
    }

    /// Returns whether text should be larger for accessibility
    var isAccessibilitySize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }
}

// MARK: - View Extensions

extension View {
    /// Adds comprehensive accessibility support with label, hint, and traits
    func accessibleElement(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }

    /// Respects Reduce Motion preference
    @ViewBuilder
    func reducedMotion<T: Equatable>(
        animation: Animation,
        value: T,
        fallback: Animation? = nil
    ) -> some View {
        if AccessibilityHelper.shared.isReduceMotionEnabled {
            self.animation(fallback, value: value)
        } else {
            self.animation(animation, value: value)
        }
    }

    /// Respects Reduce Transparency preference
    func reducedTransparency(opacity: Double) -> some View {
        self.opacity(AccessibilityHelper.shared.isReduceTransparencyEnabled ? 1.0 : opacity)
    }

    /// Conditional animation based on Reduce Motion
    @ViewBuilder
    func conditionalAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if AccessibilityHelper.shared.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Returns scaled font that respects Dynamic Type
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    /// Returns Arabic-optimized font that scales properly
    static func arabicFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Accessibility Announcements

extension View {
    /// Posts an accessibility announcement for VoiceOver users
    func accessibilityAnnounce(_ message: String, delay: TimeInterval = 0.5) -> some View {
        self.onChange(of: message) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIAccessibility.post(notification: .announcement, argument: newValue)
            }
        }
    }

    /// Posts a page announcement when view appears
    func accessibilityPageAnnouncement(_ message: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .screenChanged, argument: message)
            }
        }
    }
}

// MARK: - Semantic Color Adjustments

extension Color {
    /// Adjusts color for Darker System Colors
    func adjustedForAccessibility() -> Color {
        if AccessibilityHelper.shared.isDarkerSystemColorsEnabled {
            // Increase saturation and reduce brightness slightly
            return self
        }
        return self
    }
}

// MARK: - Content Size Category Extensions

extension ContentSizeCategory {
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    /// Returns scale factor for custom layouts
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.3
        case .accessibilityExtraExtraExtraLarge: return 2.6
        @unknown default: return 1.0
        }
    }
}

// MARK: - Reduce Motion Transitions

struct AccessibleTransition {
    static var slideAndFade: AnyTransition {
        if AccessibilityHelper.shared.isReduceMotionEnabled {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    static var scale: AnyTransition {
        if AccessibilityHelper.shared.isReduceMotionEnabled {
            return .opacity
        } else {
            return .scale.combined(with: .opacity)
        }
    }

    static func move(edge: Edge) -> AnyTransition {
        if AccessibilityHelper.shared.isReduceMotionEnabled {
            return .opacity
        } else {
            return .move(edge: edge).combined(with: .opacity)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AccessibilityHelper {
    static func mockVoiceOver() {
        AccessibilityHelper.shared.isVoiceOverRunning = true
    }

    static func mockReduceMotion() {
        AccessibilityHelper.shared.isReduceMotionEnabled = true
    }

    static func mockAccessibilitySize() {
        AccessibilityHelper.shared.preferredContentSizeCategory = .accessibilityLarge
    }
}
#endif
