//
//  UserDefaults+CorruptionBackup.swift
//  QuranNoor
//
//  Preserves undecodable persisted blobs instead of letting the next save
//  overwrite the user's only copy.
//

import Foundation
import os

extension UserDefaults {
    /// Call when a persisted blob fails to decode. The raw data is copied to
    /// "<key>_backup_v1" so a build with a fixed schema can still recover it —
    /// returning fresh state and then saving over the original silently
    /// destroyed streaks/favorites on every schema change.
    func backupCorruptedBlob(_ data: Data, forKey key: String) {
        set(data, forKey: "\(key)_backup_v1")
        AppLogger.data.error("Decode failed for \(key, privacy: .public); raw blob preserved under \(key, privacy: .public)_backup_v1")
    }
}
