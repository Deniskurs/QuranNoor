//
//  AudioService.swift
//  QuranNoor
//
//  Created on 2025-11-03
//  Audio feedback service for UI interactions
//

import AVFoundation
import UIKit
import Combine

/// Sound effects available in the app
enum SoundEffect: String, CaseIterable {
    case confirmSelect = "confirmselect"
    case backReverse = "backreverse"
    case startup = "startup"
    case notificationPopup = "notificationpopup"

    var fileName: String { rawValue }
    var fileExtension: String { "mp3" }
}

/// Centralized audio playback service
/// Manages UI sound effects with zero-latency playback
class AudioService: ObservableObject {

    // MARK: - Singleton

    static let shared = AudioService()

    // MARK: - Properties

    /// Preloaded audio players for instant playback
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]

    /// Default volume for UI sounds (0.0 to 1.0)
    @Published var volume: Float = 0.5

    /// Whether sound effects are enabled (always true per user request)
    @Published var soundEffectsEnabled: Bool = true

    /// Audio session configured
    private var isAudioSessionConfigured = false

    // MARK: - Initialization

    private init() {
        configureAudioSession()
        preloadAllSounds()
    }

    // MARK: - Audio Session Configuration

    /// Configure audio session to play even when device is in silent mode
    private func configureAudioSession() {
        guard !isAudioSessionConfigured else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Use .playback category to ignore silent mode
            // Use .mixWithOthers to not interrupt Quran recitation or other audio
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )

            try audioSession.setActive(true)
            isAudioSessionConfigured = true

            #if DEBUG
            print("✅ AudioService: Audio session configured successfully")
            #endif

        } catch {
            print("❌ AudioService: Failed to configure audio session - \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Preloading

    /// Preload all sound effects for zero-latency playback
    private func preloadAllSounds() {
        for sound in SoundEffect.allCases {
            // Try multiple locations to find the audio files
            var url: URL?

            // Try 1: Look in sounds subdirectory (when added to Xcode with folder)
            url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension, subdirectory: "sounds")

            // Try 2: Look at bundle root (when added directly)
            if url == nil {
                url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension)
            }

            guard let audioURL = url else {
                print("⚠️ AudioService: Sound file not found - \(sound.fileName).\(sound.fileExtension)")
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: audioURL)
                player.volume = volume
                player.prepareToPlay() // Preload to buffer for instant playback
                audioPlayers[sound] = player

                #if DEBUG
                print("✅ AudioService: Preloaded sound - \(sound.fileName)")
                #endif

            } catch {
                print("❌ AudioService: Failed to preload sound \(sound.fileName) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Playback Methods

    /// Play a sound effect
    /// - Parameters:
    ///   - sound: The sound effect to play
    ///   - customVolume: Optional custom volume for this playback (overrides default)
    func play(_ sound: SoundEffect, customVolume: Float? = nil) {
        guard soundEffectsEnabled else { return }

        // Ensure audio session is active
        if !isAudioSessionConfigured {
            configureAudioSession()
        }

        guard let player = audioPlayers[sound] else {
            print("⚠️ AudioService: Player not found for sound - \(sound.fileName)")
            return
        }

        // Apply custom volume if provided
        if let customVolume = customVolume {
            player.volume = customVolume
        } else {
            player.volume = volume
        }

        // Reset to beginning and play
        player.currentTime = 0
        player.play()

        #if DEBUG
        print("🔊 AudioService: Playing sound - \(sound.fileName) at volume \(player.volume)")
        #endif
    }

    /// Play confirm/forward navigation sound (confirmselect.mp3)
    func playConfirm(customVolume: Float? = nil) {
        play(.confirmSelect, customVolume: customVolume)
    }

    /// Play back/reverse navigation sound (backreverse.mp3)
    func playBack(customVolume: Float? = nil) {
        play(.backReverse, customVolume: customVolume)
    }

    /// Play startup sound (startup.mp3)
    func playStartup(customVolume: Float? = nil) {
        play(.startup, customVolume: customVolume)
    }

    /// Play notification popup sound (notificationpopup.mp3)
    func playNotification(customVolume: Float? = nil) {
        play(.notificationPopup, customVolume: customVolume)
    }

    // MARK: - Volume Control

    /// Update volume for all future sound playbacks
    /// - Parameter newVolume: Volume level (0.0 to 1.0)
    func setVolume(_ newVolume: Float) {
        let clampedVolume = max(0.0, min(1.0, newVolume))
        volume = clampedVolume

        // Update all preloaded players
        for (_, player) in audioPlayers {
            player.volume = clampedVolume
        }
    }

    // MARK: - Control Methods

    /// Stop all currently playing sounds
    func stopAllSounds() {
        for (_, player) in audioPlayers {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
        }
    }

    /// Enable or disable sound effects
    /// - Parameter enabled: Whether sound effects should play
    func setSoundEffectsEnabled(_ enabled: Bool) {
        soundEffectsEnabled = enabled

        // Stop all sounds if disabling
        if !enabled {
            stopAllSounds()
        }
    }

    // MARK: - Cleanup

    deinit {
        stopAllSounds()
        audioPlayers.removeAll()
    }
}
