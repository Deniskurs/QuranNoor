//
//  QadhaTrackerService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Manages tracking of qadha (missed) prayers with persistent storage
//

import Foundation
import Observation

/// Service for managing qadha (missed) prayer tracking
@Observable
@MainActor
final class QadhaTrackerService {

    // MARK: - Singleton
    static let shared = QadhaTrackerService()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Properties

    /// Current qadha counts for each prayer
    private(set) var qadhaCounts: [PrayerName: Int] = [:]

    /// Total qadha prayers across all types
    var totalQadha: Int {
        qadhaCounts.values.reduce(0, +)
    }

    /// History of qadha adjustments (for undo/analytics)
    private(set) var history: [QadhaHistoryEntry] = []

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let qadhaCounts = "qadhaCounts"
        static let qadhaHistory = "qadhaHistory"
        static let maxHistoryEntries = 100
    }

    // MARK: - Initialization

    private init() {
        loadQadhaCounts()
        loadHistory()
    }

    // MARK: - Public Methods

    /// Increment qadha count for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer type to increment
    ///   - count: Number of prayers to add (default: 1)
    func incrementQadha(for prayer: PrayerName, by count: Int = 1) {
        let oldCount = qadhaCounts[prayer] ?? 0
        let newCount = oldCount + count
        qadhaCounts[prayer] = newCount

        // Add to history
        let entry = QadhaHistoryEntry(
            prayer: prayer,
            change: count,
            timestamp: Date(),
            type: .increment
        )
        addToHistory(entry)

        saveQadhaCounts()
    }

    /// Decrement qadha count for a specific prayer
    /// - Parameters:
    ///   - prayer: The prayer type to decrement
    ///   - count: Number of prayers to subtract (default: 1)
    func decrementQadha(for prayer: PrayerName, by count: Int = 1) {
        let oldCount = qadhaCounts[prayer] ?? 0
        let newCount = max(0, oldCount - count) // Never go below 0
        qadhaCounts[prayer] = newCount

        // Add to history
        let entry = QadhaHistoryEntry(
            prayer: prayer,
            change: -count,
            timestamp: Date(),
            type: .decrement
        )
        addToHistory(entry)

        saveQadhaCounts()
    }

    /// Set qadha count for a specific prayer directly
    /// - Parameters:
    ///   - prayer: The prayer type
    ///   - count: The new count
    func setQadha(for prayer: PrayerName, to count: Int) {
        let oldCount = qadhaCounts[prayer] ?? 0
        let newCount = max(0, count)
        qadhaCounts[prayer] = newCount

        // Add to history
        let entry = QadhaHistoryEntry(
            prayer: prayer,
            change: newCount - oldCount,
            timestamp: Date(),
            type: .directSet
        )
        addToHistory(entry)

        saveQadhaCounts()
    }

    /// Get qadha count for a specific prayer
    /// - Parameter prayer: The prayer type
    /// - Returns: Current qadha count
    func getQadhaCount(for prayer: PrayerName) -> Int {
        return qadhaCounts[prayer] ?? 0
    }

    /// Reset all qadha counts to zero
    func resetAllQadha() {
        let oldCounts = qadhaCounts
        qadhaCounts = [:]

        // Add to history
        for (prayer, count) in oldCounts where count > 0 {
            let entry = QadhaHistoryEntry(
                prayer: prayer,
                change: -count,
                timestamp: Date(),
                type: .reset
            )
            addToHistory(entry)
        }

        saveQadhaCounts()
    }

    /// Reset qadha count for specific prayer
    /// - Parameter prayer: The prayer to reset
    func resetQadha(for prayer: PrayerName) {
        let oldCount = qadhaCounts[prayer] ?? 0
        qadhaCounts[prayer] = 0

        if oldCount > 0 {
            let entry = QadhaHistoryEntry(
                prayer: prayer,
                change: -oldCount,
                timestamp: Date(),
                type: .reset
            )
            addToHistory(entry)
        }

        saveQadhaCounts()
    }

    /// Get history entries for a specific prayer
    /// - Parameter prayer: The prayer to filter by (nil for all prayers)
    /// - Returns: Filtered history entries
    func getHistory(for prayer: PrayerName? = nil) -> [QadhaHistoryEntry] {
        if let prayer = prayer {
            return history.filter { $0.prayer == prayer }
        }
        return history
    }

    /// Clear all history
    func clearHistory() {
        history = []
        saveHistory()
    }

    // MARK: - Private Methods

    private func addToHistory(_ entry: QadhaHistoryEntry) {
        history.insert(entry, at: 0) // Most recent first

        // Limit history size
        if history.count > Keys.maxHistoryEntries {
            history = Array(history.prefix(Keys.maxHistoryEntries))
        }

        saveHistory()
    }

    private func saveQadhaCounts() {
        // Convert to dictionary with string keys for UserDefaults
        let countsDict = Dictionary(uniqueKeysWithValues: qadhaCounts.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(countsDict, forKey: Keys.qadhaCounts)
    }

    private func loadQadhaCounts() {
        guard let countsDict = UserDefaults.standard.dictionary(forKey: Keys.qadhaCounts) as? [String: Int] else {
            // Initialize with zero counts
            qadhaCounts = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, 0) })
            return
        }

        // Convert back to PrayerName keys
        qadhaCounts = Dictionary(uniqueKeysWithValues: countsDict.compactMap { key, value in
            guard let prayerName = PrayerName(rawValue: key) else { return nil }
            return (prayerName, value)
        })

        // Ensure all prayers have entries
        for prayer in PrayerName.allCases {
            if qadhaCounts[prayer] == nil {
                qadhaCounts[prayer] = 0
            }
        }
    }

    private func saveHistory() {
        if let encoded = try? Self.encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: Keys.qadhaHistory)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Keys.qadhaHistory) else {
            history = []
            return
        }

        history = (try? Self.decoder.decode([QadhaHistoryEntry].self, from: data)) ?? []
    }
}

// MARK: - QadhaHistoryEntry

/// Represents a single qadha adjustment in history
struct QadhaHistoryEntry: Codable, Identifiable {
    let id: UUID
    let prayer: PrayerName
    let change: Int // Positive for increment, negative for decrement
    let timestamp: Date
    let type: HistoryType

    init(prayer: PrayerName, change: Int, timestamp: Date, type: HistoryType) {
        self.id = UUID()
        self.prayer = prayer
        self.change = change
        self.timestamp = timestamp
        self.type = type
    }

    enum HistoryType: String, Codable {
        case increment
        case decrement
        case directSet
        case reset
    }

    /// Human-readable description of this history entry
    var description: String {
        let absChange = abs(change)
        let prayerName = prayer.displayName

        switch type {
        case .increment:
            return "Added \(absChange) \(prayerName) prayer\(absChange > 1 ? "s" : "")"
        case .decrement:
            return "Completed \(absChange) \(prayerName) prayer\(absChange > 1 ? "s" : "")"
        case .directSet:
            return "Set \(prayerName) to \(change < 0 ? 0 : change)"
        case .reset:
            return "Reset \(prayerName) to 0"
        }
    }
}
