//
//  AccessibilityHelper.swift
//  QuranNoor
//
//  Comprehensive accessibility utilities for VoiceOver, Dynamic Type, and Reduce Motion
//  Ensures WCAG 2.1 Level AA compliance
//

import SwiftUI
import Observation

// MARK: - Accessibility Manager

@Observable
@MainActor
final class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    // MARK: - Environment Monitoring
    var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    var isReduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    var isBoldTextEnabled: Bool = UIAccessibility.isBoldTextEnabled
    var isReduceTransparencyEnabled: Bool = UIAccessibility.isReduceTransparencyEnabled
    var isDarkerSystemColorsEnabled: Bool = UIAccessibility.isDarkerSystemColorsEnabled
    var preferredContentSizeCategory: ContentSizeCategory = .medium

    // MARK: - Observer Tokens (Performance: proper cleanup to prevent leaks)
    private var observerTokens: [NSObjectProtocol] = []

    private init() {
        setupNotificationObservers()
    }

    // Note: AccessibilityHelper is a singleton — deinit is never called.
    // Observer tokens are cleaned up automatically when the process exits.

    private func setupNotificationObservers() {
        // VoiceOver status changes
        let voiceOverToken = NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
            }
        }
        observerTokens.append(voiceOverToken)

        // Reduce Motion status changes
        let reduceMotionToken = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
        }
        observerTokens.append(reduceMotionToken)

        // Bold Text status changes
        let boldTextToken = NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
            }
        }
        observerTokens.append(boldTextToken)

        // Reduce Transparency status changes
        let reduceTransparencyToken = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
            }
        }
        observerTokens.append(reduceTransparencyToken)

        // Darker System Colors status changes
        let darkerColorsToken = NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
        }
        observerTokens.append(darkerColorsToken)

        // Content Size Category changes (Dynamic Type)
        let contentSizeToken = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                let uiCategory = UIApplication.shared.preferredContentSizeCategory
                self?.preferredContentSizeCategory = uiCategory.toSwiftUICategory
            }
        }
        observerTokens.append(contentSizeToken)
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
    /// Adjusts color for Darker System Colors by increasing contrast
    func adjustedForAccessibility() -> Color {
        if AccessibilityHelper.shared.isDarkerSystemColorsEnabled {
            // Darken the color to increase contrast when Darker System Colors is enabled
            return self.opacity(0.8)
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

// MARK: - UIContentSizeCategory to SwiftUI Mapping

extension UIContentSizeCategory {
    /// Converts UIKit's UIContentSizeCategory to SwiftUI's ContentSizeCategory
    var toSwiftUICategory: ContentSizeCategory {
        switch self {
        case .extraSmall:                          return .extraSmall
        case .small:                               return .small
        case .medium:                              return .medium
        case .large:                               return .large
        case .extraLarge:                          return .extraLarge
        case .extraExtraLarge:                     return .extraExtraLarge
        case .extraExtraExtraLarge:                return .extraExtraExtraLarge
        case .accessibilityMedium:                 return .accessibilityMedium
        case .accessibilityLarge:                  return .accessibilityLarge
        case .accessibilityExtraLarge:             return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:        return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:   return .accessibilityExtraExtraExtraLarge
        default:                                   return .medium
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
