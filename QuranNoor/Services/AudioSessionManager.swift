//
//  AudioSessionManager.swift
//  QuranNoor
//
//  Centralized audio session management to prevent category conflicts
//  between multiple audio services (Quran, Adhan, Demo, UI sounds)
//

import AVFoundation
import Observation

/// Types of audio usage in the app
enum AudioUsageType {
    case quranRecitation    // Primary Quran playback (exclusive, spoken audio)
    case adhanCall          // Adhan/prayer call (exclusive, high priority)
    case demoPlayback       // Onboarding demo (mixable, ducks others)
    case uiSounds           // UI feedback sounds (mixable, ambient)
}

/// Centralized manager for AVAudioSession configuration
/// Prevents conflicts when multiple services try to configure the audio session
@Observable
@MainActor
final class AudioSessionManager {

    // MARK: - Singleton

    static let shared = AudioSessionManager()

    // MARK: - Properties

    private(set) var currentUsage: AudioUsageType?
    private(set) var isSessionActive: Bool = false

    /// Stack to track nested audio usage for proper restoration
    private var usageStack: [AudioUsageType] = []

    // MARK: - Initialization

    private init() {
        setupInterruptionObserver()
    }

    // MARK: - Public Methods

    /// Configure audio session for specific usage
    /// - Parameter usage: The type of audio that will be played
    /// - Throws: AVAudioSession errors if configuration fails
    func configureSession(for usage: AudioUsageType) throws {
        let audioSession = AVAudioSession.sharedInstance()

        // Determine appropriate category and options
        let (category, mode, options) = configuration(for: usage)

        // Only reconfigure if different from current usage
        if currentUsage != usage {
            try audioSession.setCategory(category, mode: mode, options: options)

            #if DEBUG
            print("🔊 AudioSessionManager: Configured for \(usage) - category: \(category), mode: \(mode)")
            #endif
        }

        // Activate session if not already active
        if !isSessionActive {
            try audioSession.setActive(true)
            isSessionActive = true
        }

        // Track usage
        currentUsage = usage
        usageStack.append(usage)
    }

    /// Release audio session for current usage and restore previous configuration
    /// - Parameter usage: The type of audio that finished playing (must match current)
    func releaseSession(for usage: AudioUsageType) {
        // Remove from stack if it's the current usage
        if let lastUsage = usageStack.last, lastUsage == usage {
            usageStack.removeLast()
        }

        // If stack is empty, deactivate session
        if usageStack.isEmpty {
            deactivateSession()
            currentUsage = nil
        } else {
            // Restore previous usage configuration
            if let previousUsage = usageStack.last {
                try? configureSession(for: previousUsage)
            }
        }
    }

    /// Force deactivate the audio session (e.g., when stopping all audio)
    func deactivateSession(notifyOthers: Bool = true) {
        guard isSessionActive else { return }

        let options: AVAudioSession.SetActiveOptions = notifyOthers ? .notifyOthersOnDeactivation : []
        try? AVAudioSession.sharedInstance().setActive(false, options: options)
        isSessionActive = false
        usageStack.removeAll()
        currentUsage = nil

        #if DEBUG
        print("🔊 AudioSessionManager: Session deactivated")
        #endif
    }

    // MARK: - Private Methods

    /// Get audio session configuration for usage type
    private func configuration(for usage: AudioUsageType) -> (
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        switch usage {
        case .quranRecitation:
            // Exclusive playback for Quran with spoken audio optimization
            // No mixing - takes over audio session for focus
            // Optimized for voice clarity and background playback
            return (.playback, .spokenAudio, [])

        case .adhanCall:
            // Exclusive playback for Adhan
            // High priority, should not be interrupted
            return (.playback, .default, [])

        case .demoPlayback:
            // Mix with other audio but duck their volume
            // Allows demo to play during onboarding without stopping music
            return (.playback, .spokenAudio, [.mixWithOthers, .duckOthers])

        case .uiSounds:
            // Mix with everything, don't interrupt or duck
            // UI sounds should be ambient and non-intrusive
            return (.playback, .default, [.mixWithOthers])
        }
    }

    /// Setup observer for audio interruptions (phone calls, Siri, etc.)
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            // Extract Sendable values before crossing isolation boundary
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
            }
        }
    }

    /// Handle audio interruptions
    private func handleInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call, Siri, etc.)
            // Services should pause their playback
            #if DEBUG
            print("🔊 AudioSessionManager: Interruption began")
            #endif

        case .ended:
            // Mark session as inactive so the next configureSession call re-activates it.
            // The audio session is implicitly deactivated by the system during interruptions.
            isSessionActive = false

            if let optionsValue {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Can resume playback - services should handle this
                    #if DEBUG
                    print("🔊 AudioSessionManager: Interruption ended - should resume")
                    #endif
                }
            }

        @unknown default:
            break
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Convenience Methods

extension AudioSessionManager {

    /// Configure for Quran playback — exclusive .playback with .spokenAudio optimisation
    func configureForQuranPlayback() throws {
        try configureSession(for: .quranRecitation)
    }

    /// Configure for Adhan call — exclusive .playback, highest priority
    func configureForAdhan() throws {
        try configureSession(for: .adhanCall)
    }

    /// Configure for UI sound effects — .playback with .mixWithOthers
    func configureForSoundEffects() throws {
        try configureSession(for: .uiSounds)
    }

    /// Configure for onboarding demo audio — .playback with .mixWithOthers + .duckOthers
    func configureForDemoAudio() throws {
        try configureSession(for: .demoPlayback)
    }

    /// Check if session is configured for a specific usage
    func isConfigured(for usage: AudioUsageType) -> Bool {
        return currentUsage == usage
    }

    /// Check if session can be configured for a usage (not blocked by higher priority)
    func canConfigure(for usage: AudioUsageType) -> Bool {
        // Adhan has highest priority and blocks everything
        if let current = currentUsage, current == .adhanCall {
            return usage == .adhanCall
        }

        // Quran recitation blocks demo and UI sounds
        if let current = currentUsage, current == .quranRecitation {
            return usage == .quranRecitation || usage == .adhanCall
        }

        // Demo and UI sounds can always play (they mix)
        return true
    }
}
