//
//  QuranAudioService.swift
//  QuranNoor
//
//  Manages Quran audio playback with multiple reciters
//

import Foundation
import AVFoundation
import UIKit

import MediaPlayer

// MARK: - Reciter Model
enum Reciter: String, CaseIterable, Identifiable, Codable {
    case misharyRashid = "ar.alafasy"
    case abdulBasit = "ar.abdulbasitmurattal"
    case saudAlShuraym = "ar.saoodshuraym"
    case mahmoudKhalil = "ar.husary"
    case mahirAlMuaiqly = "ar.mahermuaiqly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .misharyRashid:
            return "Mishary Rashid Al-Afasy"
        case .abdulBasit:
            return "Abdul Basit (Murattal)"
        case .saudAlShuraym:
            return "Saud Al-Shuraym"
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
        case .saudAlShuraym:
            return "Al-Shuraym"
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
        case .saudAlShuraym:
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
        case .saudAlShuraym, .mahirAlMuaiqly:
            return "Saudi Arabia"
        }
    }

    /// Folder name on the EveryAyah / QuranicAudio CDN
    var audioFolder: String {
        switch self {
        case .misharyRashid:
            return "Alafasy_128kbps"
        case .abdulBasit:
            return "Abdul_Basit_Murattal_192kbps"
        case .saudAlShuraym:
            return "Saood_ash-Shuraym_128kbps"
        case .mahmoudKhalil:
            return "Husary_128kbps"
        case .mahirAlMuaiqly:
            return "MaherAlMuaiqly128kbps"
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

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Observable Properties
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentVerse: Verse?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isLoading: Bool = false

    // UI visibility state (decoupled from audio lifecycle)
    var isFullPlayerPresented: Bool = false

    /// True when audio is active (playing, paused, loading, or buffering) — use for mini player visibility
    var hasActivePlayback: Bool {
        switch playbackState {
        case .playing, .paused, .loading, .buffering:
            return true
        case .idle, .error:
            return false
        }
    }

    // Continuous playback
    private(set) var playingVerses: [Verse] = [] // Queue of verses to play
    private(set) var currentVerseIndex: Int = 0

    // Internal state for throttling (not observed by SwiftUI)
    @ObservationIgnored private var _internalCurrentTime: TimeInterval = 0
    @ObservationIgnored private var _lastPublishedTime: TimeInterval = 0
    var continuousPlaybackEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(continuousPlaybackEnabled, forKey: "continuous_playback_enabled")
        }
    }

    // MARK: - Settings
    // Stored properties so @Observable can track mutations and notify SwiftUI views.
    var selectedReciter: Reciter = .misharyRashid {
        didSet {
            if let encoded = try? Self.encoder.encode(selectedReciter) {
                UserDefaults.standard.set(encoded, forKey: "selected_reciter")
            }
        }
    }

    var playbackSpeed: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(playbackSpeed, forKey: "playback_speed")
            player?.rate = playbackSpeed
        }
    }

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var lastNowPlayingUpdate: TimeInterval = 0
    private let quranService = QuranService.shared

    // MARK: - Audio URL Cache
    @ObservationIgnored private let urlCache = AudioURLCache()

    // MARK: - Now Playing Artwork (lazy-loaded once)
    @ObservationIgnored private lazy var nowPlayingArtwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "AppIcon") ?? loadAppIconFromBundle() else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()

    private func loadAppIconFromBundle() -> UIImage? {
        guard let iconFiles = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = iconFiles["CFBundlePrimaryIcon"] as? [String: Any],
              let iconNames = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconNames.last else { return nil }
        return UIImage(named: iconName)
    }

    // MARK: - Preloading
    @ObservationIgnored private var preloadedItems: [String: AVPlayerItem] = [:]
    @ObservationIgnored private var preloadTask: Task<Void, Never>?
    private let preloadCount = 2

    // MARK: - Initialization
    private var hasSetupAudioSession = false

    private override init() {
        super.init()

        // Restore persisted settings after super.init() so @Observable registrar is ready.
        // didSet won't fire during init of the declaring class, so no double-write.
        if let data = UserDefaults.standard.data(forKey: "selected_reciter"),
           let reciter = try? Self.decoder.decode(Reciter.self, from: data) {
            self.selectedReciter = reciter
        }
        let speed = UserDefaults.standard.float(forKey: "playback_speed")
        if speed != 0 { self.playbackSpeed = speed }
        self.continuousPlaybackEnabled = UserDefaults.standard.bool(forKey: "continuous_playback_enabled")
    }

    private func ensureAudioSessionReady() {
        guard !hasSetupAudioSession else { return }
        hasSetupAudioSession = true
        setupAudioSession()
        setupRemoteCommandCenter()
    }

    // MARK: - Idle Timer Management

    /// Prevents screen sleep while audio is playing, re-enables when stopped/paused.
    private func updateIdleTimerState() {
        UIApplication.shared.isIdleTimerDisabled = playbackState.isPlaying
    }

    // MARK: - Audio Session Reactivation

    /// Re-activates the audio session if it was deactivated by an interruption.
    private func reactivateAudioSessionIfNeeded() {
        guard !AudioSessionManager.shared.isSessionActive else { return }
        try? AudioSessionManager.shared.configureSession(for: .quranRecitation)
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // Configure category and mode once — AVPlayer auto-activates
            // the session when playback starts, so we don't need to call
            // setActive(true) on every play.
            try AudioSessionManager.shared.configureSession(for: .quranRecitation)

            // Handle audio interruptions (phone calls, Siri, other apps)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
        } catch {
            #if DEBUG
            print("Failed to setup audio session: \(error)")
            #endif
        }
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                // Phone call, Siri, etc. — pause playback
                if playbackState.isPlaying {
                    pause()
                }
            case .ended:
                // Interruption ended — resume if appropriate
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume), case .paused = playbackState {
                        resume()
                    }
                }
            @unknown default:
                break
            }
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

        // Remote command center configured
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

        // Artwork
        if let artwork = nowPlayingArtwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        // Queue info (for continuous playback)
        if continuousPlaybackEnabled && !playingVerses.isEmpty {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = currentVerseIndex
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = playingVerses.count
        }

        // Set the info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Playback Control

    /// Play audio for a specific verse
    /// - Parameters:
    ///   - verse: The verse to play
    ///   - preserveQueue: If true, keeps the existing playingVerses queue (used by playVerses/playNextVerse)
    func play(verse: Verse, preserveQueue: Bool = false) async throws {
        ensureAudioSessionReady()

        // If already playing the same verse, just resume
        if currentVerse?.id == verse.id, case .paused = playbackState {
            resume()
            return
        }

        if preserveQueue {
            // Verse transition: light cleanup preserves queue, index, and UI state
            cleanupCurrentPlayer()
        } else {
            // Fresh play: full reset
            stop()
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

            // Check for preloaded item first (zero-gap playback)
            let cacheKey = audioCacheKey(for: verse)
            let playerItem: AVPlayerItem
            if let preloaded = preloadedItems.removeValue(forKey: cacheKey) {
                playerItem = preloaded
            } else {
                playerItem = AVPlayerItem(url: url)
            }

            // Reuse existing AVPlayer when possible to avoid re-allocation gaps
            if let existingPlayer = player {
                existingPlayer.replaceCurrentItem(with: playerItem)
            } else {
                player = AVPlayer(playerItem: playerItem)
            }

            // Setup observers
            setupPlayerObservers()

            // Wait for player to be ready
            try await waitForPlayerReady()

            // Start playback
            player?.rate = playbackSpeed
            playbackState = .playing
            isLoading = false
            updateIdleTimerState()

            // Update lock screen info
            updateNowPlayingInfo()

            // Preload upcoming verses in background
            preloadUpcoming()
        } catch {
            playbackState = .error(error.localizedDescription)
            isLoading = false
            updateIdleTimerState()
            throw error
        }
    }

    /// Resume playback
    func resume() {
        guard player != nil else { return }
        reactivateAudioSessionIfNeeded()
        player?.rate = playbackSpeed
        playbackState = .playing
        updateIdleTimerState()
        updateNowPlayingInfo()
    }

    /// Pause playback
    func pause() {
        guard player != nil else { return }
        player?.pause()
        playbackState = .paused
        updateIdleTimerState()
        updateNowPlayingInfo()
        saveSession()
    }

    /// Light cleanup for verse transitions: pause and remove observers but keep
    /// the player instance, queue, and UI state (isFullPlayerPresented) intact.
    private func cleanupCurrentPlayer() {
        player?.pause()
        removePlayerObservers()
        currentTime = 0
        duration = 0
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
        updateIdleTimerState()
        playingVerses = []
        currentVerseIndex = 0

        // Clear preloaded items
        preloadTask?.cancel()
        preloadTask = nil
        preloadedItems.removeAll()

        // Clear persisted session
        PlaybackSessionStore.shared.clear()

        // Clear lock screen info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        // Release audio session so other apps can resume
        AudioSessionManager.shared.releaseSession(for: .quranRecitation)
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
            stop()
            return
        }

        currentVerseIndex += 1
        let nextVerse = playingVerses[currentVerseIndex]
        try await play(verse: nextVerse, preserveQueue: true)

        // Save session after transitioning
        saveSession()
    }

    /// Play previous verse in queue
    func playPreviousVerse() async throws {
        guard currentVerseIndex > 0 else { return }

        currentVerseIndex -= 1
        let previousVerse = playingVerses[currentVerseIndex]
        try await play(verse: previousVerse, preserveQueue: true)

        // Save session after transitioning
        saveSession()
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

    // MARK: - Preloading

    /// Preload AVPlayerItems for the next `preloadCount` verses to minimize gaps
    private func preloadUpcoming() {
        preloadTask?.cancel()
        preloadTask = Task { [weak self] in
            guard let self else { return }
            let startIndex = self.currentVerseIndex + 1
            let endIndex = min(startIndex + self.preloadCount, self.playingVerses.count)
            guard startIndex < endIndex else { return }

            for i in startIndex..<endIndex {
                guard !Task.isCancelled else { return }
                let verse = self.playingVerses[i]
                let key = self.audioCacheKey(for: verse)
                guard self.preloadedItems[key] == nil else { continue }

                do {
                    guard let url = try await self.fetchAudioURL(for: verse) else { continue }
                    guard !Task.isCancelled else { return }
                    let item = AVPlayerItem(url: url)
                    // Buffer the asset so it's ready to play instantly
                    _ = try await item.asset.load(.isPlayable)
                    guard !Task.isCancelled else { return }
                    self.preloadedItems[key] = item
                } catch {
                    // Preloading is best-effort — don't fail playback
                    continue
                }
            }
        }
    }

    // MARK: - Session Persistence

    /// Save current playback state for later resume
    private func saveSession() {
        guard let verse = currentVerse else { return }
        let queueSurah = playingVerses.first?.surahNumber ?? verse.surahNumber
        let session = PlaybackSession(
            surahNumber: verse.surahNumber,
            verseNumber: verse.verseNumber,
            reciterRawValue: selectedReciter.rawValue,
            queueSurahNumber: queueSurah,
            currentVerseIndex: currentVerseIndex,
            currentTime: currentTime,
            continuousEnabled: continuousPlaybackEnabled
        )
        PlaybackSessionStore.shared.save(session)
    }

    // MARK: - Audio URL Fetching

    /// Build a cache key for a given reciter + verse
    private func audioCacheKey(for verse: Verse) -> String {
        "\(selectedReciter.rawValue)_\(verse.surahNumber)_\(verse.verseNumber)"
    }

    private func fetchAudioURL(for verse: Verse) async throws -> URL? {
        // Check cache first
        let cacheKey = audioCacheKey(for: verse)
        if let cached = urlCache.cachedURL(for: cacheKey) {
            return cached
        }

        // Construct URL directly from CDN — no API call needed.
        // Format: {surah 3-digit}{verse 3-digit}.mp3
        let fileName = String(format: "%03d%03d.mp3", verse.surahNumber, verse.verseNumber)
        let folder = selectedReciter.audioFolder
        let cdnURLString = "https://everyayah.com/data/\(folder)/\(fileName)"

        guard let audioURL = URL(string: cdnURLString) else {
            throw AudioError.invalidURL
        }

        // Store in cache
        urlCache.store(url: audioURL, for: cacheKey)

        return audioURL
    }

    // MARK: - Player Observers

    private func setupPlayerObservers() {
        guard let player = player else { return }

        // Time observer - fires every 0.25s for smooth progress bar animation
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let timeSeconds = time.seconds
                self._internalCurrentTime = timeSeconds

                // Update duration once if not set
                if self.duration == 0,
                   let itemDuration = self.player?.currentItem?.duration.seconds,
                   itemDuration.isFinite {
                    self.duration = itemDuration
                }

                // Publish time every tick for smooth progress bars
                self.currentTime = timeSeconds

                // Throttle Now Playing info updates to ~1s (lock screen doesn't need 4Hz)
                let now = CACurrentMediaTime()
                if now - self.lastNowPlayingUpdate >= 1.0 {
                    self.lastNowPlayingUpdate = now
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

        if let currentItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
    }

    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            // Auto-advance to next verse if continuous playback is enabled
            if continuousPlaybackEnabled && currentVerseIndex < playingVerses.count - 1 {
                do {
                    try await playNextVerse()
                } catch {
                    playbackState = .idle
                    currentTime = 0
                }
            } else {
                // Save session before stopping so resume is possible
                saveSession()
                playbackState = .idle
                currentTime = 0
                updateIdleTimerState()
            }
        }
    }

    private func waitForPlayerReady() async throws {
        guard let playerItem = player?.currentItem else {
            throw AudioError.playerNotReady
        }

        // Fast path: already ready
        if playerItem.status == .readyToPlay { return }
        if playerItem.status == .failed {
            throw playerItem.error ?? AudioError.playerNotReady
        }

        // Use continuation + KVO instead of busy-wait polling
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var observation: NSKeyValueObservation?
            var timeoutTask: Task<Void, Never>?
            var resumed = false

            observation = playerItem.observe(\.status, options: [.new]) { item, _ in
                guard !resumed else { return }
                switch item.status {
                case .readyToPlay:
                    resumed = true
                    timeoutTask?.cancel()
                    observation?.invalidate()
                    continuation.resume()
                case .failed:
                    resumed = true
                    timeoutTask?.cancel()
                    observation?.invalidate()
                    continuation.resume(throwing: item.error ?? AudioError.playerNotReady)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }

            // 10-second timeout
            timeoutTask = Task { [weak observation] in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard !Task.isCancelled, !resumed else { return }
                resumed = true
                observation?.invalidate()
                continuation.resume(throwing: AudioError.timeout)
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        // Note: Cannot access @Observable properties from deinit
        // Observer cleanup will happen automatically when properties are deallocated
        // NSKeyValueObservation auto-invalidates, AVPlayer auto-stops on dealloc
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Audio URL Cache
@MainActor private final class AudioURLCache {
    private var memory: [String: URL] = [:]
    private let diskURL: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let cacheDir = caches.appendingPathComponent("AudioURLCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        diskURL = cacheDir.appendingPathComponent("urls.json")

        // Load disk cache into memory
        if let data = try? Data(contentsOf: diskURL),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            memory = dict.compactMapValues { URL(string: $0) }
        }
    }

    func cachedURL(for key: String) -> URL? {
        if let url = memory[key] { return url }
        // Memory miss but disk might have it (if memory was cleared)
        return nil
    }

    func store(url: URL, for key: String) {
        memory[key] = url
        persistToDisk()
    }

    private func persistToDisk() {
        let stringDict = memory.mapValues { $0.absoluteString }
        if let data = try? JSONEncoder().encode(stringDict) {
            try? data.write(to: diskURL, options: .atomic)
        }
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
