//
//  PerformanceOptimizationService.swift
//  QuranNoor
//
//  Created by Claude Code
//  Centralized performance optimization and monitoring
//

import Foundation
import SwiftUI
import Observation

/// Service for managing app performance optimizations
@Observable
@MainActor
final class PerformanceOptimizationService {

    // MARK: - Singleton
    static let shared = PerformanceOptimizationService()

    // MARK: - Cached Formatter (Performance: avoid repeated allocation)
    private static let cacheDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    // MARK: - Properties
    private(set) var timelineUpdateInterval: TimeInterval = 1.0
    private(set) var isLowPowerModeEnabled: Bool = false
    private(set) var lastCacheCleanup: Date?
    private(set) var cacheSize: Int = 0

    // MARK: - Constants
    private let defaultUpdateInterval: TimeInterval = 1.0
    private let relaxedUpdateInterval: TimeInterval = 5.0
    private let lowPowerUpdateInterval: TimeInterval = 15.0
    private let urgentUpdateInterval: TimeInterval = 1.0
    private let cacheCleanupInterval: TimeInterval = 86400 * 7 // 7 days

    private init() {
        observeLowPowerMode()
        loadLastCleanupDate()
    }

    // MARK: - Timeline Update Frequency

    /// Get optimal TimelineView update interval based on prayer state
    /// - Parameter state: Current prayer period state
    /// - Returns: Optimal update interval in seconds
    func getOptimalUpdateInterval(for state: PrayerPeriodState?) -> TimeInterval {
        // If low power mode, use slower updates
        guard !isLowPowerModeEnabled else {
            return lowPowerUpdateInterval
        }

        guard let state = state else {
            return defaultUpdateInterval
        }

        switch state {
        case .inProgress(_, let deadline):
            // Check urgency based on time remaining
            let remaining = deadline.timeIntervalSince(Date())
            if remaining <= 5 * 60 {
                return urgentUpdateInterval      // 1s when < 5 min (critical)
            } else if remaining <= 30 * 60 {
                return defaultUpdateInterval      // 1s when < 30 min (elevated)
            }
            return relaxedUpdateInterval          // 5s when plenty of time

        case .betweenPrayers(_, _, let nextStart):
            let remaining = nextStart.timeIntervalSince(Date())
            if remaining <= 5 * 60 {
                return urgentUpdateInterval        // 1s when next prayer imminent
            } else if remaining <= 30 * 60 {
                return defaultUpdateInterval        // 1s when < 30 min
            }
            return relaxedUpdateInterval            // 5s when plenty of time

        case .beforeFajr(let fajrTime):
            let remaining = fajrTime.timeIntervalSince(Date())
            if remaining <= 30 * 60 {
                return defaultUpdateInterval
            }
            return relaxedUpdateInterval

        case .afterIsha(_):
            return relaxedUpdateInterval            // 5s after Isha - no urgency
        }
    }

    /// Update timeline interval based on current state
    func updateTimelineInterval(for state: PrayerPeriodState?) {
        let newInterval = getOptimalUpdateInterval(for: state)
        if newInterval != timelineUpdateInterval {
            timelineUpdateInterval = newInterval
        }
    }

    // MARK: - Cache Management

    /// Perform automatic cache cleanup if needed
    func performAutomaticCacheCleanup() async {
        let shouldCleanup: Bool

        if let lastCleanup = lastCacheCleanup {
            let timeSinceCleanup = Date().timeIntervalSince(lastCleanup)
            shouldCleanup = timeSinceCleanup > cacheCleanupInterval
        } else {
            shouldCleanup = true
        }

        guard shouldCleanup else { return }

        await cleanupOldCaches()
    }

    /// Clean up old prayer time caches
    func cleanupOldCaches() async {
        let userDefaults = UserDefaults.standard
        let calendar = Calendar.current
        let today = Date()

        var removedCount = 0
        var totalSize = 0

        // Get all keys
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)

        // Find and remove old prayer time caches (older than 7 days)
        for key in allKeys where key.hasPrefix("cachedPrayerTimes") {
            // Extract date from key (format: cachedPrayerTimes_MM/DD/YYYY)
            if let dateString = key.split(separator: "_").last {
                if let cacheDate = Self.cacheDateFormatter.date(from: String(dateString)) {
                    let daysDifference = calendar.dateComponents([.day], from: cacheDate, to: today).day ?? 0

                    if daysDifference > 7 {
                        // Calculate approximate size
                        if let cacheData = userDefaults.dictionary(forKey: key),
                           let data = try? JSONSerialization.data(withJSONObject: cacheData) {
                            totalSize += data.count
                        }

                        userDefaults.removeObject(forKey: key)
                        removedCount += 1
                    }
                }
            }
        }

        // Update cache size and last cleanup date
        cacheSize = calculateCurrentCacheSize()
        lastCacheCleanup = Date()
        saveLastCleanupDate()

    
    }

    /// Force cleanup all caches
    func forceCleanupAllCaches() {
        let userDefaults = UserDefaults.standard
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        var removedCount = 0

        for key in allKeys where key.hasPrefix("cachedPrayerTimes") || key.hasPrefix("qadhaHistory") {
            userDefaults.removeObject(forKey: key)
            removedCount += 1
        }

        cacheSize = 0
        lastCacheCleanup = Date()
        saveLastCleanupDate()

    
    }

    /// Calculate current cache size
    func calculateCurrentCacheSize() -> Int {
        let userDefaults = UserDefaults.standard
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        var size = 0

        for key in allKeys where key.hasPrefix("cachedPrayerTimes") {
            if let cacheData = userDefaults.dictionary(forKey: key),
               let data = try? JSONSerialization.data(withJSONObject: cacheData) {
                size += data.count
            }
        }

        cacheSize = size
        return size
    }

    /// Get formatted cache size
    func getFormattedCacheSize() -> String {
        let sizeInKB = Double(cacheSize) / 1024.0

        if sizeInKB < 1024 {
            return String(format: "%.1f KB", sizeInKB)
        } else {
            let sizeInMB = sizeInKB / 1024.0
            return String(format: "%.2f MB", sizeInMB)
        }
    }

    // MARK: - Low Power Mode

    private func observeLowPowerMode() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        // Observe low power mode changes
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        }
    }

    // MARK: - Memory Profiling

    /// Log current memory usage (for development/debugging)
    func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            #if DEBUG
            print("💾 Memory usage: \(String(format: "%.2f MB", usedMB))")
            #endif
        }
    }

    // MARK: - Helper Methods

    private func calculatePeriodInfo(for state: PrayerPeriodState) -> (isUrgent: Bool, progress: Double) {
        // Simplified calculation - full implementation would match PrayerViewModel
        return (false, 0.0)
    }

    private func saveLastCleanupDate() {
        if let lastCleanup = lastCacheCleanup {
            UserDefaults.standard.set(lastCleanup.timeIntervalSince1970, forKey: "lastCacheCleanup")
        }
    }

    private func loadLastCleanupDate() {
        let timestamp = UserDefaults.standard.double(forKey: "lastCacheCleanup")
        if timestamp > 0 {
            lastCacheCleanup = Date(timeIntervalSince1970: timestamp)
        }
    }
}

// MARK: - Performance Monitoring Extensions

extension PerformanceOptimizationService {

    /// Measure execution time of a block
    func measureExecutionTime(label: String, block: () async throws -> Void) async rethrows {
        let startTime = CFAbsoluteTimeGetCurrent()

        try await block()

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #if DEBUG
        print("⏱️ \(label): \(String(format: "%.4f", timeElapsed))s")
        #endif
    }

    /// Check if performance optimizations should be more aggressive
    var shouldUseAggressiveOptimizations: Bool {
        return isLowPowerModeEnabled
    }
}
