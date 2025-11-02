//
//  ProgressHistoryManager.swift
//  QuranNoor
//
//  Manages undo/redo history for reading progress using FileManager-backed storage
//  This keeps UserDefaults clean and prevents the 731KB bloat issue
//

import Foundation
import Combine

@MainActor
class ProgressHistoryManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ProgressHistoryManager()

    // MARK: - Published Properties
    @Published private(set) var history: [ProgressSnapshot] = []

    // MARK: - Private Properties
    private let fileURL: URL
    private let maxSnapshots = 50  // Limit history to prevent file bloat

    // MARK: - Initialization
    private init() {
        // Store history in Documents directory (backed up by iCloud if enabled)
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsDir.appendingPathComponent("progressHistory.json")

        print("📁 ProgressHistoryManager initialized - storing at: \(fileURL.path)")

        // Load existing history from disk
        loadHistory()
    }

    // MARK: - Public Methods

    /// Add a new snapshot to history (for undo/redo)
    func addSnapshot(_ snapshot: ProgressSnapshot) {
        history.append(snapshot)

        // Limit history to maxSnapshots (FIFO - remove oldest)
        if history.count > maxSnapshots {
            let removed = history.removeFirst()
            print("📊 History limit reached - removed oldest snapshot: \(removed.actionType)")
        }

        saveHistory()
        print("📊 Added snapshot: \(snapshot.actionType) - Total: \(history.count)/\(maxSnapshots)")
    }

    /// Get most recent snapshot (for undo)
    func getLastSnapshot() -> ProgressSnapshot? {
        return history.last
    }

    /// Remove last snapshot (after undo is applied)
    func removeLastSnapshot() {
        guard !history.isEmpty else { return }
        let removed = history.removeLast()
        saveHistory()
        print("📊 Removed last snapshot: \(removed.actionType) - Remaining: \(history.count)")
    }

    /// Clear all history
    func clearHistory() {
        history.removeAll()
        saveHistory()
        print("📊 Cleared all history")
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
            let decoder = JSONDecoder()
            history = try decoder.decode([ProgressSnapshot].self, from: data)
            print("✅ Loaded \(history.count) snapshots from disk (\(data.count) bytes)")
        } catch CocoaError.fileReadNoSuchFile {
            // File doesn't exist yet - normal for first launch
            history = []
            print("ℹ️ No history file found - starting fresh")
        } catch {
            // Corrupted data - start fresh
            history = []
            print("⚠️ Failed to load history: \(error.localizedDescription) - starting fresh")
        }
    }

    /// Save history to FileManager
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted  // Make file readable for debugging
            let data = try encoder.encode(history)

            try data.write(to: fileURL, options: .atomic)
            print("💾 Saved \(history.count) snapshots to disk (\(data.count) bytes)")
        } catch {
            print("❌ Failed to save history: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration Support

    /// Migrate old history from UserDefaults (called once during QuranService init)
    func migrateFromUserDefaults(oldHistory: [ProgressSnapshot]) {
        guard !oldHistory.isEmpty else { return }

        print("🔄 Migrating \(oldHistory.count) snapshots from UserDefaults to FileManager...")

        // Merge with existing history (in case of partial migration)
        history = oldHistory

        // Limit to maxSnapshots (keep most recent)
        if history.count > maxSnapshots {
            history = Array(history.suffix(maxSnapshots))
            print("   ⚠️ Limited to \(maxSnapshots) most recent snapshots")
        }

        // Save to FileManager
        saveHistory()
        print("✅ Migration complete - \(history.count) snapshots now in FileManager")
    }
}
