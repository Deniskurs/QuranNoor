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
            print("ℹ️ SwiftData migration already complete - skipping")
            return (0, 0)
        }

        print("🔄 Starting SwiftData migration from UserDefaults...")

        var versesMigrated = 0
        var bookmarksMigrated = 0

        // Migrate reading progress
        versesMigrated = await migrateReadingProgress(context: context)

        // Migrate bookmarks
        bookmarksMigrated = await migrateBookmarks(context: context)

        // Save changes
        do {
            try context.save()
            print("✅ SwiftData migration saved successfully")

            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)

            // Clean up old UserDefaults data (optional - keep for backup)
            // cleanupOldData()

            print("✅ Migration complete: \(versesMigrated) verses, \(bookmarksMigrated) bookmarks")
        } catch {
            print("❌ Failed to save SwiftData migration: \(error)")
        }

        return (versesMigrated, bookmarksMigrated)
    }

    // MARK: - Private Migration Methods

    /// Migrate reading progress from UserDefaults to SwiftData
    private func migrateReadingProgress(context: ModelContext) async -> Int {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else {
            print("ℹ️ No reading progress data to migrate")
            return 0
        }

        do {
            let progress = try JSONDecoder().decode(ReadingProgress.self, from: data)

            // Create or update global stats record
            let statsRecord = ReadingStatsRecord(from: progress)
            context.insert(statsRecord)

            // Migrate individual verse records
            var count = 0
            for (verseId, verseData) in progress.readVerses {
                let record = ReadingProgressRecord(verseId: verseId, data: verseData)
                context.insert(record)
                count += 1

                // Log progress every 500 verses
                if count % 500 == 0 {
                    print("   Migrated \(count) verses...")
                }
            }

            print("✅ Migrated reading progress: \(count) verses, streak: \(progress.streakDays) days")
            return count
        } catch {
            print("❌ Failed to decode reading progress for migration: \(error)")
            return 0
        }
    }

    /// Migrate bookmarks from UserDefaults to SwiftData
    private func migrateBookmarks(context: ModelContext) async -> Int {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else {
            print("ℹ️ No bookmarks data to migrate")
            return 0
        }

        do {
            let bookmarks = try JSONDecoder().decode([Bookmark].self, from: data)

            for bookmark in bookmarks {
                let record = BookmarkRecord(from: bookmark)
                context.insert(record)
            }

            print("✅ Migrated \(bookmarks.count) bookmarks")
            return bookmarks.count
        } catch {
            print("❌ Failed to decode bookmarks for migration: \(error)")
            return 0
        }
    }

    /// Clean up old UserDefaults data after successful migration
    /// Note: Called optionally - keeping data as backup is safer
    private func cleanupOldData() {
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.removeObject(forKey: bookmarksKey)
        print("🗑️ Cleaned up old UserDefaults data")
    }

    // MARK: - Utility Methods

    /// Reset migration status (for debugging only)
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationCompleteKey)
        print("⚠️ Migration status reset - will re-migrate on next launch")
    }

    /// Get migration statistics without performing migration
    func getMigrationStats() -> (pendingVerses: Int, pendingBookmarks: Int) {
        var verses = 0
        var bookmarks = 0

        if let data = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode(ReadingProgress.self, from: data) {
            verses = progress.readVerses.count
        }

        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let bookmarkList = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = bookmarkList.count
        }

        return (verses, bookmarks)
    }
}
