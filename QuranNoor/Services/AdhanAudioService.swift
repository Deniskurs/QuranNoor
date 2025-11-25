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

/// Service for managing Adhan audio playback
@Observable
@MainActor
final class AdhanAudioService: NSObject {

    // MARK: - Singleton
    static let shared = AdhanAudioService()

    // MARK: - Properties

    /// Current audio player
    private var audioPlayer: AVAudioPlayer?

    /// Is Adhan currently playing
    private(set) var isPlaying: Bool = false

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

        setupAudioSession()
    }

    // MARK: - Public Methods

    /// Play the selected Adhan audio
    /// - Parameter prayer: The prayer for which Adhan is being played (optional, for logging)
    func playAdhan(for prayer: PrayerName? = nil) async {
        guard isEnabled else {
            print("⏸️ Adhan is disabled by user")
            return
        }

        guard !isPlaying else {
            print("⏸️ Adhan is already playing")
            return
        }

        // Get the audio file URL
        guard let audioURL = selectedAdhan.fileURL else {
            print("❌ Adhan audio file not found: \(selectedAdhan.fileName)")
            return
        }

        // Load audio file off main thread to prevent UI blocking
        let loadedPlayer: AVAudioPlayer?
        do {
            loadedPlayer = try await Task.detached(priority: .userInitiated) {
                try AVAudioPlayer(contentsOf: audioURL)
            }.value
        } catch {
            print("❌ Error loading Adhan audio: \(error.localizedDescription)")
            return
        }

        guard let player = loadedPlayer else {
            print("❌ Failed to create audio player for Adhan")
            return
        }

        // Configure player and start playback on main thread
        player.delegate = self
        player.volume = volume
        player.prepareToPlay()

        do {
            // Activate audio session
            try AVAudioSession.sharedInstance().setActive(true)

            // Play the audio
            let success = player.play()
            if success {
                audioPlayer = player
                isPlaying = true
                if let prayer = prayer {
                    print("🔊 Playing Adhan (\(selectedAdhan.displayName)) for \(prayer.displayName)")
                } else {
                    print("🔊 Playing Adhan (\(selectedAdhan.displayName))")
                }
            }
        } catch {
            print("❌ Error playing Adhan: \(error.localizedDescription)")
            isPlaying = false
        }
    }

    /// Stop the currently playing Adhan
    func stopAdhan() {
        guard isPlaying else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        print("⏹️ Adhan playback stopped")
    }

    /// Pause the currently playing Adhan
    func pauseAdhan() {
        guard isPlaying else { return }

        audioPlayer?.pause()
        isPlaying = false
        print("⏸️ Adhan playback paused")
    }

    /// Resume the paused Adhan
    func resumeAdhan() {
        guard !isPlaying, audioPlayer != nil else { return }

        audioPlayer?.play()
        isPlaying = true
        print("▶️ Adhan playback resumed")
    }

    /// Change the selected Adhan audio
    /// - Parameter adhan: The new Adhan to use
    func selectAdhan(_ adhan: AdhanAudio) {
        selectedAdhan = adhan
        UserDefaults.standard.set(adhan.rawValue, forKey: Keys.selectedAdhan)
        print("✅ Selected Adhan: \(adhan.displayName)")
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

        print("🔔 Adhan \(enabled ? "enabled" : "disabled")")
    }

    /// Preview the selected Adhan (for testing in settings)
    func previewAdhan(_ adhan: AdhanAudio) async {
        _ = selectedAdhan  // Store for potential future use
        selectedAdhan = adhan

        await playAdhan()

        // Restore previous selection after playback ends
        // (will be handled in delegate method)
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            // Set category to playback to allow background audio and bypass silent mode
            // Note: Only call setCategory ONCE to avoid redundancy and potential conflicts
            try session.setCategory(.playback, mode: .default, options: [])

            print("✅ Audio session configured for Adhan playback")
        } catch {
            print("❌ Failed to set up audio session: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AdhanAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            audioPlayer = nil

            // Deactivate audio session
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

            print("✅ Adhan playback finished")
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            audioPlayer = nil
            print("❌ Adhan decode error: \(error?.localizedDescription ?? "Unknown error")")
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

    var duration: TimeInterval {
        // Approximate durations (in seconds)
        switch self {
        case .makkah: return 180 // 3 minutes
        case .madinah: return 210 // 3.5 minutes
        case .abdulBasit: return 150 // 2.5 minutes
        case .mishary: return 165 // 2.75 minutes
        case .local: return 120 // 2 minutes
        }
    }
}
