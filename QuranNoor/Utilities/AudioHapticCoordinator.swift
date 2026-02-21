//
//  AudioHapticCoordinator.swift
//  QuranNoor
//
//  Created on 2025-11-03
//  Coordinates audio and haptic feedback for unified user experience
//

import Foundation
import UIKit

/// Unified coordinator for audio and haptic feedback
/// Provides simple methods for common UI interactions
class AudioHapticCoordinator {

    // MARK: - Singleton

    static let shared = AudioHapticCoordinator()

    // MARK: - Services

    private let audioService = AudioService.shared
    private let hapticManager = HapticManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Navigation Feedback

    /// Play feedback for forward navigation (Next, Continue, Confirm)
    /// - Parameter customVolume: Optional custom audio volume
    func playConfirm(customVolume: Float? = nil) {
        audioService.playConfirm(customVolume: customVolume)
        hapticManager.trigger(.light)
    }

    /// Play feedback for backward navigation (Back, Cancel, Dismiss)
    /// - Parameter customVolume: Optional custom audio volume
    func playBack(customVolume: Float? = nil) {
        audioService.playBack(customVolume: customVolume)
        hapticManager.trigger(.light)
    }

    /// Play feedback for successful completion (Get Started, Done, Success)
    /// - Parameter customVolume: Optional custom audio volume
    func playSuccess(customVolume: Float? = nil) {
        audioService.playConfirm(customVolume: customVolume)
        hapticManager.trigger(.success)
    }

    /// Play startup sound with gentle haptic
    /// - Parameter customVolume: Optional custom audio volume
    func playStartup(customVolume: Float? = nil) {
        audioService.playStartup(customVolume: customVolume)
        hapticManager.trigger(.light)
    }

    // MARK: - UI Interaction Feedback

    /// Play feedback for button taps (general purpose)
    /// - Parameter customVolume: Optional custom audio volume
    func playButtonTap(customVolume: Float? = nil) {
        audioService.playConfirm(customVolume: customVolume)
        hapticManager.trigger(.medium)
    }

    /// Alias for playButtonTap for consistency across codebase
    /// - Parameter customVolume: Optional custom audio volume
    func playButtonPress(customVolume: Float? = nil) {
        playButtonTap(customVolume: customVolume)
    }

    /// Play feedback for selection changes (toggles, radio buttons)
    /// - Parameter customVolume: Optional custom audio volume
    func playSelection(customVolume: Float? = nil) {
        audioService.playConfirm(customVolume: customVolume)
        hapticManager.trigger(.selection)
    }

    /// Play feedback for notifications and popups
    /// - Parameter customVolume: Optional custom audio volume
    func playNotification(customVolume: Float? = nil) {
        audioService.playNotification(customVolume: customVolume)
        hapticManager.trigger(.medium)
    }

    /// Play feedback for warnings and destructive actions
    /// - Parameter customVolume: Optional custom audio volume
    func playWarning(customVolume: Float? = nil) {
        audioService.playBack(customVolume: customVolume)
        hapticManager.trigger(.warning)
    }

    // MARK: - Prayer-Specific Feedback

    /// Play feedback for prayer completion
    /// - Parameter customVolume: Optional custom audio volume
    func playPrayerComplete(customVolume: Float? = nil) {
        audioService.playNotification(customVolume: customVolume)

        // Use existing prayer complete haptic pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.hapticManager.triggerPattern(.prayerComplete)
        }
    }

    /// Play feedback for all prayers completed (celebration)
    /// - Parameter customVolume: Optional custom audio volume
    func playAllPrayersComplete(customVolume: Float? = nil) {
        audioService.playNotification(customVolume: 0.7) // Louder for celebration

        // Use streak achieved haptic pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hapticManager.triggerPattern(.streakAchieved)
        }
    }

    /// Play feedback for prayer checkbox tap
    /// - Parameter customVolume: Optional custom audio volume
    func playPrayerCheckbox(customVolume: Float? = nil) {
        audioService.playConfirm(customVolume: customVolume)
        hapticManager.trigger(.medium)
    }

    /// Play feedback for prayer reminder popup appearance
    /// - Parameter customVolume: Optional custom audio volume
    func playPrayerReminderAppear(customVolume: Float? = nil) {
        audioService.playNotification(customVolume: 0.4) // Subtle
        hapticManager.trigger(.light)
    }

    /// Play feedback for toast notifications
    /// - Parameter customVolume: Optional custom audio volume
    func playToast(customVolume: Float? = nil) {
        audioService.playNotification(customVolume: 0.3) // Very subtle
        // No haptic for toasts to avoid overwhelming feedback
    }

    // MARK: - Onboarding-Specific Feedback

    /// Play feedback for onboarding page changes (swipe or button navigation)
    /// - Parameter direction: Forward or backward
    func playPageChange(direction: PageChangeDirection) {
        switch direction {
        case .forward:
            playConfirm()
        case .backward:
            playBack()
        }
    }

    /// Play feedback for completing onboarding
    func playOnboardingComplete() {
        playSuccess()

        // After a brief delay, play startup sound for transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.playStartup(customVolume: 0.6)
        }
    }

    // MARK: - Audio-Only Methods (No Haptics)

    /// Play only audio without haptic (for subtle feedback)
    /// - Parameters:
    ///   - sound: The sound effect to play
    ///   - customVolume: Optional custom audio volume
    func playAudioOnly(_ sound: SoundEffect, customVolume: Float? = nil) {
        audioService.play(sound, customVolume: customVolume)
    }

    // MARK: - Haptic-Only Methods (No Audio)

    /// Play only haptic without audio (for silent feedback)
    /// - Parameter type: The haptic type to trigger
    func playHapticOnly(_ type: HapticType) {
        hapticManager.trigger(type)
    }

    /// Play only haptic pattern without audio
    /// - Parameter pattern: The haptic pattern to trigger
    func playHapticPatternOnly(_ pattern: HapticPattern) {
        hapticManager.triggerPattern(pattern)
    }

    // MARK: - Control Methods

    /// Stop all audio playback
    func stopAllAudio() {
        audioService.stopAllSounds()
    }

    /// Set global audio volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setVolume(_ volume: Float) {
        audioService.setVolume(volume)
    }
}

// MARK: - Supporting Types

/// Direction of page change
enum PageChangeDirection {
    case forward
    case backward
}
