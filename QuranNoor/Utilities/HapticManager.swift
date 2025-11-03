//
//  HapticManager.swift
//  QuranNoor
//
//  Centralized haptic feedback management with accessibility support
//

import SwiftUI
import UIKit

// MARK: - Haptic Types
enum HapticType {
    case success        // Task completion, prayer marked complete
    case warning        // Caution, approaching deadline
    case error          // Failed action, network error
    case light          // Subtle feedback, button tap
    case medium         // Standard feedback, selection
    case heavy          // Strong feedback, important action
    case selection      // Tab switch, picker change
    case rigid          // Solid impact, confirmation
}

// MARK: - Haptic Manager
@MainActor
class HapticManager {
    // MARK: - Singleton
    static let shared = HapticManager()

    // MARK: - Properties
    private var isHapticEnabled: Bool {
        // Respect system settings
        guard !UIAccessibility.isReduceMotionEnabled else { return false }

        // Check user preference (if implemented)
        return UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled", defaultValue: true)
    }

    // Feedback generators (reuse for better performance)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)

    // Debouncing to prevent haptic spam
    private var lastHapticTime: [HapticType: Date] = [:]
    private let minimumInterval: TimeInterval = 0.05 // 50ms between same haptic type

    // MARK: - Initializer
    private init() {
        // Prepare generators for immediate response
        prepareGenerators()
    }

    // MARK: - Public Methods

    /// Trigger haptic feedback
    func trigger(_ type: HapticType) {
        guard isHapticEnabled else { return }
        guard !isDebounced(type) else { return }

        // Update last haptic time
        lastHapticTime[type] = Date()

        // Trigger appropriate haptic
        switch type {
        case .success:
            notificationGenerator.notificationOccurred(.success)

        case .warning:
            notificationGenerator.notificationOccurred(.warning)

        case .error:
            notificationGenerator.notificationOccurred(.error)

        case .light:
            lightImpactGenerator.impactOccurred()

        case .medium:
            mediumImpactGenerator.impactOccurred()

        case .heavy:
            heavyImpactGenerator.impactOccurred()

        case .selection:
            selectionGenerator.selectionChanged()

        case .rigid:
            rigidImpactGenerator.impactOccurred()
        }
    }

    /// Trigger haptic with custom intensity (0.0 to 1.0)
    func trigger(_ type: HapticType, intensity: CGFloat) {
        guard isHapticEnabled else { return }
        guard !isDebounced(type) else { return }

        let clampedIntensity = max(0, min(1, intensity))
        lastHapticTime[type] = Date()

        switch type {
        case .light:
            lightImpactGenerator.impactOccurred(intensity: clampedIntensity)
        case .medium:
            mediumImpactGenerator.impactOccurred(intensity: clampedIntensity)
        case .heavy:
            heavyImpactGenerator.impactOccurred(intensity: clampedIntensity)
        case .rigid:
            rigidImpactGenerator.impactOccurred(intensity: clampedIntensity)
        default:
            // Notification and selection generators don't support custom intensity
            trigger(type)
        }
    }

    /// Prepare generators for optimal responsiveness
    func prepareGenerators() {
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
    }

    /// Complex haptic pattern for special occasions
    func triggerPattern(_ pattern: HapticPattern) {
        guard isHapticEnabled else { return }

        switch pattern {
        case .prayerComplete:
            // Medium impact followed by success notification
            trigger(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.trigger(.success)
            }

        case .streakAchieved:
            // Triple light impacts with success
            trigger(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.trigger(.light)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.trigger(.success)
            }

        case .qiblaAligned:
            // Heavy impact with success
            trigger(.heavy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.trigger(.success)
            }

        case .bookmarkAdded:
            // Medium impact only
            trigger(.medium)

        case .bookmarkRemoved:
            // Light impact only
            trigger(.light)
        }
    }

    // MARK: - Private Methods

    /// Check if haptic should be debounced
    private func isDebounced(_ type: HapticType) -> Bool {
        guard let lastTime = lastHapticTime[type] else { return false }
        return Date().timeIntervalSince(lastTime) < minimumInterval
    }
}

// MARK: - Haptic Patterns
enum HapticPattern {
    case prayerComplete
    case streakAchieved
    case qiblaAligned
    case bookmarkAdded
    case bookmarkRemoved
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Add haptic feedback to any view interaction
    func hapticFeedback(_ type: HapticType, trigger: Binding<Bool>) -> some View {
        self.onChange(of: trigger.wrappedValue) { _, newValue in
            if newValue {
                HapticManager.shared.trigger(type)
            }
        }
    }

    /// Add haptic feedback on tap
    func onTapWithHaptic(_ type: HapticType = .light, perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.trigger(type)
            action()
        }
    }
}
