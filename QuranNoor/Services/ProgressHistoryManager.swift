//
//  ProgressHistoryManager.swift
//  QuranNoor
//
//  Manages undo/redo history for reading progress using FileManager-backed storage
//  This keeps UserDefaults clean and prevents the 731KB bloat issue
//

import Foundation
import Observation

@Observable
@MainActor
class ProgressHistoryManager {
    // MARK: - Singleton
    static let shared = ProgressHistoryManager()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted  // Make file readable for debugging
        return encoder
    }()

    // MARK: - Observable Properties
    private(set) var history: [ProgressSnapshot] = []

    // MARK: - Private Properties
    private let fileURL: URL
    private let maxSnapshots = 50  // Limit history to prevent file bloat

    // MARK: - Initialization
    private init() {
        // Store history in Documents directory (backed up by iCloud if enabled)
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsDir.appendingPathComponent("progressHistory.json")

        // Load existing history from disk
        loadHistory()
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
        history.removeAll()
        saveHistory()
    }

    /// Get total size of history in bytes
    func getHistorySize() -> Int {
        guard let data = try? Data(contentsOf: fileURL) else { return 0 }
        return data.count
    }

    // MARK: - Private Methods

    /// Load history from FileManager
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: fileURL)
            history = try Self.decoder.decode([ProgressSnapshot].self, from: data)
        } catch CocoaError.fileReadNoSuchFile {
            // File doesn't exist yet - normal for first launch
            history = []
        } catch {
            // Corrupted data - start fresh
            history = []
        }
    }

    /// Save history to FileManager
    private func saveHistory() {
        do {
            let data = try Self.encoder.encode(history)

            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("❌ Failed to save history: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Migration Support

    /// Migrate old history from UserDefaults (called once during QuranService init)
    func migrateFromUserDefaults(oldHistory: [ProgressSnapshot]) {
        guard !oldHistory.isEmpty else { return }

        // Merge with existing history (in case of partial migration)
        history = oldHistory

        // Limit to maxSnapshots (keep most recent)
        if history.count > maxSnapshots {
            history = Array(history.suffix(maxSnapshots))
        }

        // Save to FileManager
        saveHistory()
    }
}
