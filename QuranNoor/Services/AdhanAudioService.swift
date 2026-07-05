//
//  AdhanAudioService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Service for playing Adhan (call to prayer) audio
//

import Foundation
import AVFoundation
import Observation
import os

/// Service for managing Adhan audio playback
@Observable
@MainActor
final class AdhanAudioService: NSObject {

    // MARK: - Singleton
    static let shared = AdhanAudioService()

    // MARK: - Properties

    /// Current audio player
    private var audioPlayer: AVAudioPlayer?

    /// Explicit playback state — a lone isPlaying Bool made "paused" and
    /// "stopped" indistinguishable, so a paused adhan could never be stopped
    /// and its audio session was never released.
    enum PlaybackState {
        case stopped
        case playing
        case paused
    }

    private(set) var playbackState: PlaybackState = .stopped

    /// Is Adhan currently playing (kept for existing UI call sites)
    var isPlaying: Bool { playbackState == .playing }

    /// Selected Adhan audio
    private(set) var selectedAdhan: AdhanAudio

    /// Volume level (0.0 to 1.0)
    private(set) var volume: Float = 0.8

    /// Whether Adhan audio is enabled
    private(set) var isEnabled: Bool = true

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let selectedAdhan = "selectedAdhan"
        static let adhanVolume = "adhanVolume"
        static let adhanEnabled = "adhanEnabled"
    }

    // MARK: - Initialization

    private override init() {
        // Load saved preferences
        if let savedAdhanRaw = UserDefaults.standard.string(forKey: Keys.selectedAdhan),
           let savedAdhan = AdhanAudio(rawValue: savedAdhanRaw) {
            self.selectedAdhan = savedAdhan
        } else {
            self.selectedAdhan = .makkah
        }

        self.volume = UserDefaults.standard.object(forKey: Keys.adhanVolume) as? Float ?? 0.8
        self.isEnabled = UserDefaults.standard.object(forKey: Keys.adhanEnabled) as? Bool ?? true

        super.init()

        // Audio session setup is deferred to playAdhan() to avoid
        // configuring the session at launch (which can override Quran playback's session)
    }

    // MARK: - Public Methods

    /// Play the selected Adhan audio
    /// - Parameter prayer: The prayer for which Adhan is being played (optional, for logging)
    func playAdhan(for prayer: PrayerName? = nil) async {
        guard isEnabled else { return }
        guard playbackState == .stopped else { return }

        // Get the audio file URL
        guard let audioURL = selectedAdhan.fileURL else {
            AppLogger.audio.error("Adhan audio file not found: \(self.selectedAdhan.fileName, privacy: .public)")
            return
        }

        // Load audio file off main thread to prevent UI blocking
        let loadedPlayer: AVAudioPlayer?
        do {
            loadedPlayer = try await Task.detached(priority: .userInitiated) {
                try AVAudioPlayer(contentsOf: audioURL)
            }.value
        } catch {
            AppLogger.audio.error("Error loading Adhan audio: \(error.localizedDescription, privacy: .public)")
            return
        }

        guard let player = loadedPlayer else { return }

        // Configure player and start playback on main thread
        player.delegate = self
        player.volume = volume
        player.prepareToPlay()

        do {
            // Activate audio session via centralized manager
            try AudioSessionManager.shared.configureForAdhan()

            // Play the audio
            let success = player.play()
            if success {
                audioPlayer = player
                playbackState = .playing
            }
        } catch {
            AppLogger.audio.error("Error playing Adhan: \(error.localizedDescription, privacy: .public)")
            playbackState = .stopped
        }
    }

    /// Stop the Adhan — works from both playing and paused states
    func stopAdhan() {
        guard playbackState != .stopped else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        playbackState = .stopped

        // Release audio session
        AudioSessionManager.shared.releaseSession(for: .adhanCall)
    }

    /// Pause the currently playing Adhan
    func pauseAdhan() {
        guard playbackState == .playing else { return }

        audioPlayer?.pause()
        playbackState = .paused
    }

    /// Resume the paused Adhan
    func resumeAdhan() {
        guard playbackState == .paused, audioPlayer != nil else { return }

        audioPlayer?.play()
        playbackState = .playing
    }

    /// Change the selected Adhan audio
    /// - Parameter adhan: The new Adhan to use
    func selectAdhan(_ adhan: AdhanAudio) {
        selectedAdhan = adhan
        UserDefaults.standard.set(adhan.rawValue, forKey: Keys.selectedAdhan)
    }

    /// Set the volume level
    /// - Parameter volume: Volume level from 0.0 to 1.0
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        self.volume = clampedVolume
        audioPlayer?.volume = clampedVolume
        UserDefaults.standard.set(clampedVolume, forKey: Keys.adhanVolume)
    }

    /// Enable or disable Adhan playback
    /// - Parameter enabled: Whether Adhan should be enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Keys.adhanEnabled)

        if !enabled {
            stopAdhan()
        }
    }

    /// Preview the selected Adhan (for testing in settings)
    func previewAdhan(_ adhan: AdhanAudio) async {
        let previousAdhan = selectedAdhan
        selectedAdhan = adhan
        await playAdhan()
        // Restore after audio finishes (delegate sets isPlaying = false)
        while playbackState != .stopped {
            try? await Task.sleep(for: .milliseconds(200))
        }
        selectedAdhan = previousAdhan
    }

}


// MARK: - AVAudioPlayerDelegate

extension AdhanAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            playbackState = .stopped
            audioPlayer = nil

            // Release audio session
            AudioSessionManager.shared.releaseSession(for: .adhanCall)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            playbackState = .stopped
            audioPlayer = nil
            // Release the session here too — the decode-error path leaked it
            AudioSessionManager.shared.releaseSession(for: .adhanCall)
            AppLogger.audio.error("Adhan decode error: \(error?.localizedDescription ?? "Unknown error", privacy: .public)")
        }
    }
}

// MARK: - AdhanAudio Enum

/// Available Adhan audio options
enum AdhanAudio: String, CaseIterable, Identifiable {
    case makkah = "makkah"
    case madinah = "madinah"
    case abdulBasit = "abdul_basit"
    case mishary = "mishary"
    case local = "local"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .makkah:
            return "Makkah (Masjid al-Haram)"
        case .madinah:
            return "Madinah (Masjid an-Nabawi)"
        case .abdulBasit:
            return "Abdul Basit Abdul Samad"
        case .mishary:
            return "Mishary Rashid Alafasy"
        case .local:
            return "Traditional (Local Masjid)"
        }
    }

    var description: String {
        switch self {
        case .makkah:
            return "Beautiful call to prayer from the Grand Mosque in Makkah"
        case .madinah:
            return "Serene Adhan from the Prophet's Mosque in Madinah"
        case .abdulBasit:
            return "Renowned Egyptian Qari with a powerful voice"
        case .mishary:
            return "Popular Kuwaiti Qari with a melodious style"
        case .local:
            return "Traditional neighborhood mosque style Adhan"
        }
    }

    var fileName: String {
        "\(rawValue).mp3"
    }

    var fileURL: URL? {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "mp3", inDirectory: "Audio/Adhan") else {
            // Fallback: Try to find in main bundle
            return Bundle.main.url(forResource: rawValue, withExtension: "mp3")
        }
        return URL(fileURLWithPath: path)
    }

}
