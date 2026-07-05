//
//  ProgressHistoryManager.swift
//  QuranNoor
//
//  Manages undo/redo history for reading progress using FileManager-backed storage
//  This keeps UserDefaults clean and prevents the 731KB bloat issue
//
//  All file I/O (multi-MB JSON: up to 50 full-progress snapshots) runs off the
//  main actor on a serialized background chain (`pendingIO`), so launch and
//  undo actions never block the main thread on disk access.
//

import Foundation
import Observation
import os

@Observable
@MainActor
class ProgressHistoryManager {
    // MARK: - Singleton
    static let shared = ProgressHistoryManager()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    // nonisolated(unsafe) is sound here: the decoder is used once (initial
    // load) and the encoder only inside the serialized `pendingIO` chain,
    // so neither is ever touched concurrently.
    nonisolated(unsafe) private static let decoder = JSONDecoder()
    nonisolated(unsafe) private static let encoder = JSONEncoder()

    // MARK: - Observable Properties
    private(set) var history: [ProgressSnapshot] = []

    // MARK: - Private Properties
    private let fileURL: URL
    private let maxSnapshots = 50  // Limit history to prevent file bloat

    /// Serialized background I/O chain. Every disk read/write awaits the
    /// previous link, so writes never race and always observe the state left
    /// by the initial load.
    @ObservationIgnored private var pendingIO: Task<Void, Never>?

    /// Set when the in-memory history was wholesale replaced (clear/migration)
    /// while the initial disk load was still in flight — the loaded snapshots
    /// must then be dropped instead of merged back in.
    @ObservationIgnored private var discardPendingLoad = false

    // MARK: - Initialization
    private init() {
        // Store history in Documents directory (backed up by iCloud if enabled)
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsDir.appendingPathComponent("progressHistory.json")

        // Load existing history off the main actor; the file can be several
        // MB and a synchronous read here would block app launch.
        let url = fileURL
        pendingIO = Task.detached(priority: .utility) {
            let loaded = Self.readHistory(from: url)
            guard !loaded.isEmpty else { return }
            await self.mergeLoadedHistory(loaded)
        }
    }

    // MARK: - Public Methods

    /// Add a new snapshot to history (for undo/redo)
    func addSnapshot(_ snapshot: ProgressSnapshot) {
        history.append(snapshot)

        // Limit history to maxSnapshots (FIFO - remove oldest)
        if history.count > maxSnapshots {
            history.removeFirst()
        }

        saveHistory()
    }

    /// Get most recent snapshot (for undo)
    func getLastSnapshot() -> ProgressSnapshot? {
        return history.last
    }

    /// Remove last snapshot (after undo is applied)
    func removeLastSnapshot() {
        guard !history.isEmpty else { return }
        history.removeLast()
        saveHistory()
    }

    /// Clear all history
    func clearHistory() {
        discardPendingLoad = true
        history.removeAll()
        saveHistory()
    }

    /// Get total size of history in bytes (file metadata only — never reads the payload)
    func getHistorySize() -> Int {
        (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    // MARK: - Private Methods

    /// Fold the initially loaded disk snapshots into the live history.
    ///
    /// Snapshots recorded while the load was in flight (launch-time race) are
    /// newer than anything on disk, so they stay at the end. Any save queued
    /// during that window re-reads `history` when it executes — after this
    /// merge — so the merged state is what ends up persisted.
    private func mergeLoadedHistory(_ loaded: [ProgressSnapshot]) {
        guard !discardPendingLoad else { return }
        history = history.isEmpty ? loaded : Array((loaded + history).suffix(maxSnapshots))
    }

    /// Snapshot of the live history, hopped to from the background I/O chain.
    private func currentHistory() -> [ProgressSnapshot] {
        history
    }

    /// Persist history to disk on the background I/O chain.
    ///
    /// The chained task captures no history itself — it reads the latest
    /// state on the main actor when it executes, so rapid successive saves
    /// coalesce to the final state instead of racing each other.
    private func saveHistory() {
        let url = fileURL
        pendingIO = Task.detached(priority: .utility) { [previous = pendingIO] in
            await previous?.value
            let snapshots = await self.currentHistory()
            do {
                try Self.writeHistory(snapshots, to: url)
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    AppLogger.data.error("Failed to save history: \(message, privacy: .public)")
                }
            }
        }
    }

    // MARK: - Background I/O (never on the main actor)

    nonisolated private static func readHistory(from url: URL) -> [ProgressSnapshot] {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([ProgressSnapshot].self, from: data)
        } catch CocoaError.fileReadNoSuchFile {
            // File doesn't exist yet - normal for first launch
            return []
        } catch {
            // Corrupted data - start fresh
            return []
        }
    }

    nonisolated private static func writeHistory(_ snapshots: [ProgressSnapshot], to url: URL) throws {
        let data = try encoder.encode(snapshots)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Migration Support

    /// Migrate old history from UserDefaults (called once during QuranService init)
    func migrateFromUserDefaults(oldHistory: [ProgressSnapshot]) {
        guard !oldHistory.isEmpty else { return }

        // The migrated snapshots replace whatever is on disk; don't let a
        // still-pending initial load merge stale content back in.
        discardPendingLoad = true
        history = oldHistory

        // Limit to maxSnapshots (keep most recent)
        if history.count > maxSnapshots {
            history = Array(history.suffix(maxSnapshots))
        }

        // Save to FileManager
        saveHistory()
    }
}
