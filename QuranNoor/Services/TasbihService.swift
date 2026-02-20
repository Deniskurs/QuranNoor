//
//  TasbihService.swift
//  QuranNoor
//
//  Service for managing digital tasbih counter
//

import Foundation
import Observation
import UIKit
import AudioToolbox

@Observable
@MainActor
final class TasbihService {
    // MARK: - Singleton

    static let shared = TasbihService()

    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Properties

    private(set) var currentSession: TasbihSession?
    private(set) var history: [TasbihHistoryEntry] = []
    private(set) var statistics: TasbihStatistics

    // Settings
    var hapticEnabled = true
    var soundEnabled = false
    var vibrateOnTarget = true
    var showArabic = true
    var showTransliteration = true
    var showTranslation = true

    private let statisticsKey = "tasbih_statistics"
    private let historyKey = "tasbih_history"
    private let settingsKey = "tasbih_settings"

    // MARK: - Initialization

    private init() {
        self.statistics = Self.loadStatistics()
        self.history = Self.loadHistory()
        self.loadSettings()
        statistics.checkAndResetDaily()
    }

    // MARK: - Session Management

    /// Start a new tasbih session
    func startSession(preset: TasbihPreset, target: Int) {
        let session = TasbihSession(
            preset: preset,
            targetCount: target
        )
        currentSession = session
    }

    /// Increment current session count
    func increment() {
        guard var session = currentSession else { return }

        session.currentCount += 1

        // Haptic feedback
        if hapticEnabled {
            triggerHapticFeedback(count: session.currentCount, target: session.targetCount)
        }

        // Check if target reached
        if session.currentCount == session.targetCount && !session.isCompleted {
            completeSession()
        }

        currentSession = session
    }

    /// Decrement current session count
    func decrement() {
        guard var session = currentSession, session.currentCount > 0 else { return }

        session.currentCount -= 1
        session.isCompleted = false
        currentSession = session

        // Light haptic
        if hapticEnabled {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    /// Reset current session
    func resetSession() {
        guard var session = currentSession else { return }

        session.currentCount = 0
        session.isCompleted = false
        currentSession = session

        // Medium haptic
        if hapticEnabled {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }

    /// Complete current session
    private func completeSession() {
        guard var session = currentSession else { return }

        session.isCompleted = true
        session.endDate = Date()
        currentSession = session

        // Success haptic + vibration
        if hapticEnabled {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }

        if vibrateOnTarget {
            // Pattern: short-short-long
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }

        // Update statistics
        updateStatistics(for: session)

        // Save to history
        saveToHistory(session)
    }

    /// Save current session and start new one
    func saveAndStartNew(preset: TasbihPreset, target: Int) {
        if let session = currentSession {
            saveToHistory(session)
        }
        startSession(preset: preset, target: target)
    }

    /// End current session without completing
    func endSession() {
        if let session = currentSession {
            // Save partial session to history
            var partialSession = session
            partialSession.endDate = Date()
            saveToHistory(partialSession)
        }
        currentSession = nil
    }

    // MARK: - History Management

    private func saveToHistory(_ session: TasbihSession) {
        let entry = TasbihHistoryEntry(session: session)
        history.insert(entry, at: 0)

        // Keep only last 100 entries
        if history.count > 100 {
            history = Array(history.prefix(100))
        }

        saveHistory()
    }

    /// Get history for today
    func getTodayHistory() -> [TasbihHistoryEntry] {
        let calendar = Calendar.current
        return history.filter { calendar.isDateInToday($0.date) }
    }

    /// Get history for last 7 days
    func getWeekHistory() -> [TasbihHistoryEntry] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return history.filter { $0.date >= sevenDaysAgo }
    }

    /// Clear all history
    func clearHistory() {
        history = []
        saveHistory()
    }

    // MARK: - Statistics

    private func updateStatistics(for session: TasbihSession) {
        statistics.totalSessions += 1
        statistics.totalCount += session.currentCount
        statistics.todayCount += session.currentCount

        if session.isCompleted {
            statistics.completedSessions += 1
        }

        statistics.updateStreak()
        statistics.lastSessionDate = Date()

        saveStatistics()
    }

    /// Reset all statistics
    func resetStatistics() {
        statistics = TasbihStatistics()
        saveStatistics()
    }

    // MARK: - Haptic Feedback

    private func triggerHapticFeedback(count: Int, target: Int) {
        // Different haptics for milestones
        if count == target {
            // Target reached - success notification
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        } else if count % 10 == 0 && count > 0 {
            // Every 10 counts - medium impact
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } else if count == target - 10 && target > 10 {
            // 10 away from target - warning
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.warning)
        } else {
            // Regular count - light impact
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    // MARK: - Persistence

    private func saveStatistics() {
        if let encoded = try? Self.encoder.encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statisticsKey)
        }
    }

    private static func loadStatistics() -> TasbihStatistics {
        guard let data = UserDefaults.standard.data(forKey: "tasbih_statistics"),
              let stats = try? decoder.decode(TasbihStatistics.self, from: data) else {
            return TasbihStatistics()
        }
        return stats
    }

    private func saveHistory() {
        if let encoded = try? Self.encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private static func loadHistory() -> [TasbihHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: "tasbih_history"),
              let history = try? decoder.decode([TasbihHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    private func saveSettings() {
        let settings: [String: Bool] = [
            "hapticEnabled": hapticEnabled,
            "soundEnabled": soundEnabled,
            "vibrateOnTarget": vibrateOnTarget,
            "showArabic": showArabic,
            "showTransliteration": showTransliteration,
            "showTranslation": showTranslation
        ]
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }

    private func loadSettings() {
        if let settings = UserDefaults.standard.dictionary(forKey: settingsKey) {
            hapticEnabled = settings["hapticEnabled"] as? Bool ?? true
            soundEnabled = settings["soundEnabled"] as? Bool ?? false
            vibrateOnTarget = settings["vibrateOnTarget"] as? Bool ?? true
            showArabic = settings["showArabic"] as? Bool ?? true
            showTransliteration = settings["showTransliteration"] as? Bool ?? true
            showTranslation = settings["showTranslation"] as? Bool ?? true
        }
    }

    // MARK: - Public Methods

    /// Update settings and save
    func updateSettings(
        haptic: Bool? = nil,
        sound: Bool? = nil,
        vibrate: Bool? = nil,
        arabic: Bool? = nil,
        transliteration: Bool? = nil,
        translation: Bool? = nil
    ) {
        if let haptic = haptic { hapticEnabled = haptic }
        if let sound = sound { soundEnabled = sound }
        if let vibrate = vibrate { vibrateOnTarget = vibrate }
        if let arabic = arabic { showArabic = arabic }
        if let transliteration = transliteration { showTransliteration = transliteration }
        if let translation = translation { showTranslation = translation }

        saveSettings()
    }
}
