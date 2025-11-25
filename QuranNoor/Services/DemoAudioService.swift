//
//  DemoAudioService.swift
//  QuranNoor
//
//  Lightweight audio service for onboarding demos
//  Uses bundled Al-Fatiha MP3 files for offline playback
//

import AVFoundation
import Combine

/// Audio playback service for onboarding Quran demo
/// Uses bundled verse-by-verse audio files (no network required)
@Observable
final class DemoAudioService {

    // MARK: - Singleton

    static let shared = DemoAudioService()

    // MARK: - Types

    enum PlaybackState: Equatable {
        case idle
        case playing
        case paused
    }

    // MARK: - Published Properties

    var playbackState: PlaybackState = .idle
    var currentVerseIndex: Int = 0
    var progress: Double = 0.0  // 0.0 to 1.0 for current verse
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var isAudioSessionConfigured = false

    /// Verse file names (Al-Fatiha verses 1-4)
    private let verseFiles = ["001001", "001002", "001003", "001004"]

    /// Total number of verses in demo
    var totalVerses: Int { verseFiles.count }

    // MARK: - Initialization

    private init() {
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        guard !isAudioSessionConfigured else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.mixWithOthers, .duckOthers]
            )
            try audioSession.setActive(true)
            isAudioSessionConfigured = true

            #if DEBUG
            print("✅ DemoAudioService: Audio session configured")
            #endif
        } catch {
            print("❌ DemoAudioService: Failed to configure audio session - \(error.localizedDescription)")
        }
    }

    // MARK: - Playback Control

    /// Start playing from a specific verse index
    /// - Parameter fromVerse: The verse index to start from (0-based)
    func play(fromVerse: Int = 0) {
        guard fromVerse < verseFiles.count else { return }

        // Ensure audio session is active
        if !isAudioSessionConfigured {
            configureAudioSession()
        }

        currentVerseIndex = fromVerse
        playCurrentVerse()
    }

    /// Play the current verse
    private func playCurrentVerse() {
        let fileName = verseFiles[currentVerseIndex]

        // Try to find audio file in bundle
        var url: URL?

        // Try subdirectory first (when added as folder reference)
        url = Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Audio/Demo")

        // Try root bundle
        if url == nil {
            url = Bundle.main.url(forResource: fileName, withExtension: "mp3")
        }

        guard let audioURL = url else {
            print("⚠️ DemoAudioService: Audio file not found - \(fileName).mp3")
            return
        }

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = AudioPlayerDelegate.shared
            audioPlayer?.prepareToPlay()

            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            progress = 0

            audioPlayer?.play()
            playbackState = .playing

            startProgressTimer()

            // Set up completion callback
            AudioPlayerDelegate.shared.onFinish = { [weak self] in
                self?.handleVerseFinished()
            }

            #if DEBUG
            print("🔊 DemoAudioService: Playing verse \(currentVerseIndex + 1) - \(fileName)")
            #endif

        } catch {
            print("❌ DemoAudioService: Failed to play audio - \(error.localizedDescription)")
        }
    }

    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        playbackState = .paused
        stopProgressTimer()
    }

    /// Resume playback
    func resume() {
        audioPlayer?.play()
        playbackState = .playing
        startProgressTimer()
    }

    /// Toggle between play and pause
    func togglePlayPause() {
        switch playbackState {
        case .idle:
            play(fromVerse: currentVerseIndex)
        case .playing:
            pause()
        case .paused:
            resume()
        }
    }

    /// Stop playback and reset
    func stop() {
        audioPlayer?.stop()
        stopProgressTimer()
        playbackState = .idle
        progress = 0
        currentTime = 0
    }

    /// Skip to next verse
    func nextVerse() {
        guard currentVerseIndex < verseFiles.count - 1 else {
            // Reached end - stop playback
            stop()
            return
        }

        currentVerseIndex += 1
        playCurrentVerse()
    }

    /// Skip to previous verse
    func previousVerse() {
        guard currentVerseIndex > 0 else { return }

        currentVerseIndex -= 1
        playCurrentVerse()
    }

    // MARK: - Progress Tracking

    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let player = self.audioPlayer else { return }

            self.currentTime = player.currentTime
            self.duration = player.duration

            if player.duration > 0 {
                self.progress = player.currentTime / player.duration
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Verse Completion

    private func handleVerseFinished() {
        // Auto-advance to next verse for continuous playback
        if currentVerseIndex < verseFiles.count - 1 {
            currentVerseIndex += 1

            // Small delay before next verse for natural flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.playCurrentVerse()
            }
        } else {
            // Finished all verses
            stop()
            currentVerseIndex = 0
        }
    }

    // MARK: - Cleanup

    deinit {
        stop()
    }
}

// MARK: - Audio Player Delegate

/// Shared delegate for audio player callbacks
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()

    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinish?()
        }
    }
}
