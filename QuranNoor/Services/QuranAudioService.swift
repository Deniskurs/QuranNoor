//
//  QuranAudioService.swift
//  QuranNoor
//
//  Manages Quran audio playback with multiple reciters
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - Reciter Model
enum Reciter: String, CaseIterable, Identifiable, Codable {
    case misharyRashid = "ar.alafasy"
    case abdulBasit = "ar.abdulbasitmurattal"
    case saadAlGhamdi = "ar.saoodshuraym"
    case mahmoudKhalil = "ar.khalilalhusary"
    case mahirAlMuaiqly = "ar.mahermuaiqly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .misharyRashid:
            return "Mishary Rashid Al-Afasy"
        case .abdulBasit:
            return "Abdul Basit (Murattal)"
        case .saadAlGhamdi:
            return "Saad Al-Ghamdi"
        case .mahmoudKhalil:
            return "Mahmoud Khalil Al-Husary"
        case .mahirAlMuaiqly:
            return "Mahir Al-Muaiqly"
        }
    }

    var shortName: String {
        switch self {
        case .misharyRashid:
            return "Al-Afasy"
        case .abdulBasit:
            return "Abdul Basit"
        case .saadAlGhamdi:
            return "Al-Ghamdi"
        case .mahmoudKhalil:
            return "Al-Husary"
        case .mahirAlMuaiqly:
            return "Al-Muaiqly"
        }
    }

    var description: String {
        switch self {
        case .misharyRashid:
            return "Clear and melodious recitation from Kuwait"
        case .abdulBasit:
            return "Classic Egyptian recitation with Tajweed"
        case .saadAlGhamdi:
            return "Beautiful recitation from Saudi Arabia"
        case .mahmoudKhalil:
            return "Traditional Egyptian recitation"
        case .mahirAlMuaiqly:
            return "Imam of Masjid al-Haram, Makkah"
        }
    }

    var country: String {
        switch self {
        case .misharyRashid:
            return "Kuwait"
        case .abdulBasit, .mahmoudKhalil:
            return "Egypt"
        case .saadAlGhamdi, .mahirAlMuaiqly:
            return "Saudi Arabia"
        }
    }
}

// MARK: - Playback State
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case buffering
    case error(String)

    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
}

// MARK: - Audio Service
@MainActor
@Observable
class QuranAudioService: NSObject {
    // MARK: - Singleton
    static let shared = QuranAudioService()

    // MARK: - Observable Properties
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentVerse: Verse?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isLoading: Bool = false

    // Continuous playback
    private(set) var playingVerses: [Verse] = [] // Queue of verses to play
    private(set) var currentVerseIndex: Int = 0

    // Internal state for throttling (not observed by SwiftUI)
    @ObservationIgnored private var _internalCurrentTime: TimeInterval = 0
    @ObservationIgnored private var _lastPublishedTime: TimeInterval = 0
    var continuousPlaybackEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "continuous_playback_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "continuous_playback_enabled")
        }
    }

    // MARK: - Settings
    var selectedReciter: Reciter {
        get {
            if let data = UserDefaults.standard.data(forKey: "selected_reciter"),
               let reciter = try? JSONDecoder().decode(Reciter.self, from: data) {
                return reciter
            }
            return .misharyRashid // Default
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "selected_reciter")
                print("✅ Reciter saved: \(newValue.displayName)")
            }
        }
    }

    var playbackSpeed: Float {
        get {
            let speed = UserDefaults.standard.float(forKey: "playback_speed")
            return speed == 0 ? 1.0 : speed
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "playback_speed")
            player?.rate = newValue
        }
    }

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var lastNowPlayingUpdate: TimeInterval = 0
    private let quranService = QuranService.shared

    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        print("✅ QuranAudioService.shared initialized")
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Enable background playback
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Lock Screen Controls Setup
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            Task { @MainActor in
                self?.resume()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            Task { @MainActor in
                self?.pause()
            }
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            Task { @MainActor in
                self?.togglePlayPause()
            }
            return .success
        }

        // Next track command (next verse in continuous mode)
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                if self.continuousPlaybackEnabled && self.currentVerseIndex < self.playingVerses.count - 1 {
                    try? await self.playNextVerse()
                }
            }
            return .success
        }

        // Previous track command (previous verse in continuous mode)
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                if self.continuousPlaybackEnabled && self.currentVerseIndex > 0 {
                    try? await self.playPreviousVerse()
                }
            }
            return .success
        }

        // Seek forward command (skip 10 seconds)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                self.seek(to: min(self.duration, self.currentTime + 10))
            }
            return .success
        }

        // Seek backward command (go back 10 seconds)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                self.seek(to: max(0, self.currentTime - 10))
            }
            return .success
        }

        // Change playback position command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            Task { @MainActor in
                guard let self = self,
                      let event = event as? MPChangePlaybackPositionCommandEvent else { return }
                self.seek(to: event.positionTime)
            }
            return .success
        }

        print("✅ Remote command center configured for lock screen controls")
    }

    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let verse = currentVerse else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = [String: Any]()

        // Verse metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Surah \(verse.surahNumber), Verse \(verse.verseNumber)"
        nowPlayingInfo[MPMediaItemPropertyArtist] = selectedReciter.displayName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Quran Recitation"

        // Playback info
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackState.isPlaying ? Double(playbackSpeed) : 0.0

        // Queue info (for continuous playback)
        if continuousPlaybackEnabled && !playingVerses.isEmpty {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = currentVerseIndex
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = playingVerses.count
        }

        // Set the info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        print("🎵 Updated Now Playing: Surah \(verse.surahNumber):\(verse.verseNumber) - \(selectedReciter.shortName)")
    }

    // MARK: - Playback Control

    /// Play audio for a specific verse
    /// - Parameters:
    ///   - verse: The verse to play
    ///   - preserveQueue: If true, keeps the existing playingVerses queue (used by playVerses/playNextVerse)
    func play(verse: Verse, preserveQueue: Bool = false) async throws {
        print("🎵 Playing verse \(verse.surahNumber):\(verse.verseNumber) (preserveQueue: \(preserveQueue))")

        // If already playing the same verse, just resume
        if currentVerse?.id == verse.id, case .paused = playbackState {
            resume()
            return
        }

        // Stop current playback but preserve queue info if needed
        let savedVerses = playingVerses
        let savedIndex = currentVerseIndex
        stop()

        // Restore queue if preserving, otherwise set single verse
        if preserveQueue {
            playingVerses = savedVerses
            currentVerseIndex = savedIndex
        } else {
            playingVerses = [verse]
            currentVerseIndex = 0
        }

        playbackState = .loading
        isLoading = true
        currentVerse = verse

        do {
            // Fetch audio URL from API
            let audioURL = try await fetchAudioURL(for: verse)

            guard let url = audioURL else {
                throw AudioError.noAudioAvailable
            }

            // Create player
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)

            // Setup observers
            setupPlayerObservers()

            // Wait for player to be ready
            try await waitForPlayerReady()

            // Start playback
            player?.rate = playbackSpeed
            playbackState = .playing
            isLoading = false

            // Update lock screen info
            updateNowPlayingInfo()

            print("✅ Started playing verse \(verse.surahNumber):\(verse.verseNumber)")
        } catch {
            playbackState = .error(error.localizedDescription)
            isLoading = false
            print("❌ Failed to play verse: \(error)")
            throw error
        }
    }

    /// Resume playback
    func resume() {
        guard player != nil else { return }
        player?.rate = playbackSpeed
        playbackState = .playing
        updateNowPlayingInfo()
        print("▶️ Resumed playback")
    }

    /// Pause playback
    func pause() {
        guard player != nil else { return }
        player?.pause()
        playbackState = .paused
        updateNowPlayingInfo()
        print("⏸️ Paused playback")
    }

    /// Stop playback and clean up
    func stop() {
        player?.pause()
        removePlayerObservers()
        player = nil
        currentVerse = nil
        currentTime = 0
        duration = 0
        playbackState = .idle
        playingVerses = []
        currentVerseIndex = 0

        // Clear lock screen info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        print("⏹️ Stopped playback")
    }

    /// Play multiple verses in sequence (continuous playback)
    func playVerses(_ verses: [Verse], startingAt index: Int = 0) async throws {
        guard !verses.isEmpty else { return }

        // Set up the queue first
        playingVerses = verses
        currentVerseIndex = index

        // Play first verse, preserving the queue we just set
        try await play(verse: verses[index], preserveQueue: true)
    }

    /// Play next verse in queue
    func playNextVerse() async throws {
        guard currentVerseIndex < playingVerses.count - 1 else {
            print("✅ Reached end of verse queue")
            stop()
            return
        }

        currentVerseIndex += 1
        let nextVerse = playingVerses[currentVerseIndex]
        try await play(verse: nextVerse, preserveQueue: true)
    }

    /// Play previous verse in queue
    func playPreviousVerse() async throws {
        guard currentVerseIndex > 0 else {
            print("⚠️ Already at first verse")
            return
        }

        currentVerseIndex -= 1
        let previousVerse = playingVerses[currentVerseIndex]
        try await play(verse: previousVerse, preserveQueue: true)
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = player else { return }

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] completed in
            Task { @MainActor [weak self] in
                guard let self = self, completed else { return }
                self.currentTime = time
                self.updateNowPlayingInfo()
                print("⏩ Seeked to \(time)s")
            }
        }
    }

    /// Toggle play/pause
    func togglePlayPause() {
        if case .playing = playbackState {
            pause()
        } else if case .paused = playbackState {
            resume()
        }
    }

    // MARK: - Audio URL Fetching

    private func fetchAudioURL(for verse: Verse) async throws -> URL? {
        // Use AlQuran.cloud API to get audio URL
        let editionId = selectedReciter.rawValue
        let urlString = "https://api.alquran.cloud/v1/ayah/\(verse.surahNumber):\(verse.verseNumber)/\(editionId)"

        guard let url = URL(string: urlString) else {
            throw AudioError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AudioError.networkError
        }

        // Parse response
        struct AudioResponse: Codable {
            let data: AudioData

            struct AudioData: Codable {
                let audio: String?
            }
        }

        let decoder = JSONDecoder()
        let audioResponse = try decoder.decode(AudioResponse.self, from: data)

        guard let audioURLString = audioResponse.data.audio,
              let audioURL = URL(string: audioURLString) else {
            throw AudioError.noAudioAvailable
        }

        return audioURL
    }

    // MARK: - Player Observers

    private func setupPlayerObservers() {
        guard let player = player else { return }

        // Time observer - fires every 1.0s for UI updates (reduced from 0.1s for performance)
        // This prevents excessive SwiftUI re-renders that cause heating and lag
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            // Dispatch to MainActor for Swift 6 concurrency safety
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let timeSeconds = time.seconds

                // Update internal time immediately
                self._internalCurrentTime = timeSeconds

                // Update duration once if not set
                if self.duration == 0,
                   let itemDuration = self.player?.currentItem?.duration.seconds,
                   itemDuration.isFinite {
                    self.duration = itemDuration
                }

                // Only publish time if changed by more than 0.5s (throttle SwiftUI updates)
                if abs(self._internalCurrentTime - self._lastPublishedTime) >= 0.5 {
                    self._lastPublishedTime = self._internalCurrentTime
                    self.currentTime = self._internalCurrentTime

                    // Update Now Playing info
                    self.updateNowPlayingInfo()
                }
            }
        }

        // Status observer
        statusObserver = player.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                switch item.status {
                case .readyToPlay:
                    if case .loading = self.playbackState {
                        // Will transition to playing when play() is called
                    }
                case .failed:
                    self.playbackState = .error(item.error?.localizedDescription ?? "Unknown error")
                    self.isLoading = false
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Playback finished observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    private func removePlayerObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        statusObserver?.invalidate()
        statusObserver = nil

        NotificationCenter.default.removeObserver(self)
    }

    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            print("✅ Finished playing verse")

            // Auto-advance to next verse if continuous playback is enabled
            if continuousPlaybackEnabled && currentVerseIndex < playingVerses.count - 1 {
                print("⏭️ Auto-advancing to next verse...")
                do {
                    try await playNextVerse()
                } catch {
                    print("❌ Failed to play next verse: \(error)")
                    playbackState = .idle
                    currentTime = 0
                }
            } else {
                playbackState = .idle
                currentTime = 0
            }
        }
    }

    private func waitForPlayerReady() async throws {
        guard let player = player else {
            throw AudioError.playerNotReady
        }

        // Wait up to 10 seconds for player to be ready
        let startTime = Date()
        while player.currentItem?.status != .readyToPlay {
            if Date().timeIntervalSince(startTime) > 10 {
                throw AudioError.timeout
            }

            if player.currentItem?.status == .failed {
                throw player.currentItem?.error ?? AudioError.playerNotReady
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }

    // MARK: - Cleanup
    deinit {
        // Note: Cannot access @Observable properties from deinit
        // Observer cleanup will happen automatically when properties are deallocated
        // NSKeyValueObservation auto-invalidates, AVPlayer auto-stops on dealloc
        NotificationCenter.default.removeObserver(self)
        print("🗑️ QuranAudioService deinitialized")
    }
}

// MARK: - Audio Errors
enum AudioError: LocalizedError {
    case noAudioAvailable
    case invalidURL
    case networkError
    case playerNotReady
    case timeout

    var errorDescription: String? {
        switch self {
        case .noAudioAvailable:
            return "No audio available for this verse"
        case .invalidURL:
            return "Invalid audio URL"
        case .networkError:
            return "Network error while loading audio"
        case .playerNotReady:
            return "Audio player not ready"
        case .timeout:
            return "Audio loading timeout"
        }
    }
}
