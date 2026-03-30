//
//  AppLogger.swift
//  QuranNoor
//
//  Centralized logging using os.Logger to replace print() statements.
//  Debug-level logs are suppressed from Xcode console by default,
//  keeping it clean while remaining accessible via Console.app.
//

import Foundation
import os

enum AppLogger {
    // MARK: - Categorized Loggers

    static let audio = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Audio")
    static let quran = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Quran")
    static let prayer = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Prayer")
    static let location = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Location")
    static let notification = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Notification")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Data")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Network")
    static let navigation = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Navigation")
    static let onboarding = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Onboarding")
    static let performance = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Performance")
    static let settings = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Settings")
    static let migration = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "Migration")
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.quranoor", category: "General")
}
