//
//  SchemaVersioning.swift
//  QuranNoor
//
//  SwiftData schema versioning and migration plan
//  Ensures safe schema evolution across app updates
//

import Foundation
import SwiftData
import os

// MARK: - Schema Version 1 (Initial Release)

/// Version 1.0.0 of the QuranNoor SwiftData schema
/// Contains the initial set of models for the app's first release.
/// Model classes are defined in their own files (BookmarkRecord.swift, ReadingProgressRecord.swift).
/// This enum only references them — do NOT redefine @Model classes inside the VersionedSchema,
/// as that creates separate types (e.g. QuranNoorSchemaV1.ReadingStatsRecord vs ReadingStatsRecord)
/// which causes SwiftData cast failures at runtime.
enum QuranNoorSchemaV1: VersionedSchema {
    /// Semantic versioning identifier for this schema
    static var versionIdentifier = Schema.Version(1, 0, 0)

    /// All model types included in this schema version
    static var models: [any PersistentModel.Type] {
        [
            BookmarkRecord.self,
            ReadingProgressRecord.self,
            ReadingStatsRecord.self
        ]
    }
}

// MARK: - Schema Version 2 (Bookmark Categories)

/// Version 2.0.0 of the QuranNoor SwiftData schema
/// Adds `BookmarkRecord.category` (String, defaulted to "All Bookmarks"),
/// which shipped as an inline default on the live model after V1 was frozen.
/// This version makes that change explicit so stores created before the
/// property existed migrate cleanly instead of relying on undeclared drift.
/// Like V1, this enum only references the live model classes (see the
/// warning above about redefining @Model classes inside a VersionedSchema).
enum QuranNoorSchemaV2: VersionedSchema {
    /// Semantic versioning identifier for this schema
    static var versionIdentifier = Schema.Version(2, 0, 0)

    /// All model types included in this schema version
    static var models: [any PersistentModel.Type] {
        [
            BookmarkRecord.self,
            ReadingProgressRecord.self,
            ReadingStatsRecord.self
        ]
    }
}

// MARK: - Migration Plan

/// Defines the migration stages for QuranNoor SwiftData schema
/// Each time the schema changes, add a new version enum and migration stage
enum QuranNoorMigrationPlan: SchemaMigrationPlan {
    /// Ordered list of schema versions from oldest to newest
    static var schemas: [any VersionedSchema.Type] {
        [
            QuranNoorSchemaV1.self,
            QuranNoorSchemaV2.self
            // Future versions will be added here:
            // QuranNoorSchemaV3.self,
            // etc.
        ]
    }

    /// Migration stages between schema versions
    static var stages: [MigrationStage] {
        [
            migrateV1toV2
            // Future migrations will be added here:
            // migrateV2toV3,
            // etc.
        ]
    }

    // MARK: - V1 → V2 (lightweight)

    /// Adds `BookmarkRecord.category` with a default value. Lightweight is
    /// correct here: adding an attribute that has a default requires no
    /// custom logic — SwiftData infers the mapping and fills existing rows
    /// with "All Bookmarks" in place, preserving the store and all records.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: QuranNoorSchemaV1.self,
        toVersion: QuranNoorSchemaV2.self
    )

    // MARK: - Future Migration Examples (for reference)

    /*
    /// Example: Custom migration (manual logic needed)
    /// Use this for renames, transformations, or data cleanup
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: QuranNoorSchemaV2.self,
        toVersion: QuranNoorSchemaV3.self,
        willMigrate: { context in
            // Pre-migration logic (optional)
            // e.g., validate data, backup critical records
            AppLogger.migration.debug("Starting migration from V2 to V3...")
        },
        didMigrate: { context in
            // Post-migration logic (optional)
            // e.g., transform data, update relationships, cleanup
            AppLogger.migration.debug("Completed migration from V2 to V3")

            // Example: Update all BookmarkRecord instances
            let bookmarks = try? context.fetch(FetchDescriptor<BookmarkRecord>())
            bookmarks?.forEach { bookmark in
                // Transform data as needed
                // bookmark.newProperty = computeValue(from: bookmark.oldProperty)
            }

            try? context.save()
        }
    )
    */
}

// MARK: - Migration Guidelines

/*
 When adding a new schema version:

 1. Create a new VersionedSchema enum (e.g., QuranNoorSchemaV2)
 2. Copy ALL model definitions from the previous version
 3. Make your changes to the models in the new version
 4. Increment the version identifier (e.g., Schema.Version(2, 0, 0))
 5. Add the new schema to the schemas array in QuranNoorMigrationPlan
 6. Create a migration stage (lightweight or custom) and add to stages array
 7. Update QuranNoorApp.swift to reference the new version if needed

 Types of migrations:

 - Lightweight: SwiftData handles automatically (adding optional properties, changing defaults)
 - Custom: Requires manual logic (renaming properties, complex transformations, data cleanup)

 Best practices:

 - Test migrations thoroughly on a copy of production data
 - Never delete old schema versions from this file
 - Use semantic versioning for schema versions
 - Document breaking changes in comments
 - Consider data loss scenarios and provide fallbacks
 */
