//
//  DataMigrationService.swift
//  QuranNoor
//
//  Service for migrating data from UserDefaults to SwiftData
//

import Foundation
import SwiftData

/// Service responsible for one-time migration of data from UserDefaults to SwiftData
@MainActor
final class DataMigrationService {
    // MARK: - Singleton
    static let shared = DataMigrationService()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()

    // MARK: - Migration Keys
    private let migrationCompleteKey = "swiftDataMigration_v1_complete"
    private let progressKey = "reading_progress"
    private let bookmarksKey = "quran_bookmarks"

    private init() {}

    // MARK: - Public Methods

    /// Check if migration has been completed
    var isMigrationComplete: Bool {
        UserDefaults.standard.bool(forKey: migrationCompleteKey)
    }

    /// Perform migration from UserDefaults to SwiftData
    /// - Parameter context: The SwiftData ModelContext to insert records into
    /// - Returns: Migration statistics (verses migrated, bookmarks migrated)
    @discardableResult
    func migrateIfNeeded(context: ModelContext) async -> (versesMigrated: Int, bookmarksMigrated: Int) {
        // Check if migration already completed
        guard !isMigrationComplete else {
            return (0, 0)
        }

        var versesMigrated = 0
        var bookmarksMigrated = 0

        // Migrate reading progress
        versesMigrated = await migrateReadingProgress(context: context)

        // Migrate bookmarks
        bookmarksMigrated = await migrateBookmarks(context: context)

        // Save changes
        do {
            try context.save()

            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
        } catch {
            #if DEBUG
            print("❌ Failed to save SwiftData migration: \(error)")
            #endif
        }

        return (versesMigrated, bookmarksMigrated)
    }

    // MARK: - Private Migration Methods

    /// Migrate reading progress from UserDefaults to SwiftData
    private func migrateReadingProgress(context: ModelContext) async -> Int {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else {
            return 0
        }

        do {
            let progress = try Self.decoder.decode(ReadingProgress.self, from: data)

            // Create or update global stats record
            let statsRecord = ReadingStatsRecord(from: progress)
            context.insert(statsRecord)

            // Migrate individual verse records
            var count = 0
            for (verseId, verseData) in progress.readVerses {
                let record = ReadingProgressRecord(verseId: verseId, data: verseData)
                context.insert(record)
                count += 1

            }

            return count
        } catch {
            #if DEBUG
            print("❌ Failed to decode reading progress for migration: \(error)")
            #endif
            return 0
        }
    }

    /// Migrate bookmarks from UserDefaults to SwiftData
    private func migrateBookmarks(context: ModelContext) async -> Int {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else {
            return 0
        }

        do {
            let bookmarks = try Self.decoder.decode([Bookmark].self, from: data)

            for bookmark in bookmarks {
                let record = BookmarkRecord(from: bookmark)
                context.insert(record)
            }

            return bookmarks.count
        } catch {
            #if DEBUG
            print("❌ Failed to decode bookmarks for migration: \(error)")
            #endif
            return 0
        }
    }

    /// Clean up old UserDefaults data after successful migration
    /// Note: Called optionally - keeping data as backup is safer
    private func cleanupOldData() {
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.removeObject(forKey: bookmarksKey)
    }

    // MARK: - Utility Methods

    /// Reset migration status (for debugging only)
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationCompleteKey)
    }

    /// Get migration statistics without performing migration
    func getMigrationStats() -> (pendingVerses: Int, pendingBookmarks: Int) {
        var verses = 0
        var bookmarks = 0

        if let data = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? Self.decoder.decode(ReadingProgress.self, from: data) {
            verses = progress.readVerses.count
        }

        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let bookmarkList = try? Self.decoder.decode([Bookmark].self, from: data) {
            bookmarks = bookmarkList.count
        }

        return (verses, bookmarks)
    }
}
