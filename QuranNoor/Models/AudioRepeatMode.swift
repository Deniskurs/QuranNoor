// AudioRepeatMode.swift - Repeat mode definitions for Quran audio memorization

import Foundation

// MARK: - Repeat Mode

enum RepeatMode: String, Codable, CaseIterable, Identifiable {
    case off
    case singleVerse
    case range
    case surah

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:          return "Off"
        case .singleVerse:  return "Verse"
        case .range:        return "Range"
        case .surah:        return "Surah"
        }
    }

    var iconName: String {
        switch self {
        case .off:          return "arrow.forward"
        case .singleVerse:  return "repeat.1"
        case .range:        return "repeat.circle"
        case .surah:        return "repeat"
        }
    }

    /// Cycles to the next repeat mode in order.
    var next: RepeatMode {
        switch self {
        case .off:          return .singleVerse
        case .singleVerse:  return .range
        case .range:        return .surah
        case .surah:        return .off
        }
    }
}

// MARK: - Repeat Settings

struct RepeatSettings: Codable {
    var repeatMode: RepeatMode = .off

    /// Number of times to repeat (1–99). 0 means infinite.
    var repeatCount: Int = 3

    /// How many repetitions have been completed so far in the current cycle.
    var currentRepetition: Int = 0

    /// Pause between repetitions in seconds. Options: 0, 1, 2, 3, 5.
    var delayBetweenRepeats: TimeInterval = 0

    /// Verse number (within the surah) marking the start of the range.
    var rangeStart: Int? = nil

    /// Verse number (within the surah) marking the end of the range.
    var rangeEnd: Int? = nil

    // MARK: - Computed Properties

    /// Returns true when repeatCount == 0 (infinite loop).
    var isInfinite: Bool {
        repeatCount == 0
    }

    /// Returns true when a repeat mode other than .off is active.
    var isActive: Bool {
        repeatMode != .off
    }

    /// Returns true when all repetitions have been completed (only for finite repeats).
    var hasCompletedAllRepetitions: Bool {
        !isInfinite && currentRepetition >= repeatCount
    }

    /// Returns a human-readable progress string (e.g. "Rep 2/5") when a mode is
    /// active, nil when off.
    var progressText: String? {
        guard repeatMode != .off else { return nil }
        if isInfinite {
            return "Rep \(currentRepetition + 1)/∞"
        }
        return "Rep \(currentRepetition + 1)/\(repeatCount)"
    }

    // MARK: - Static Helpers

    /// Allowed delay values (seconds) shown in the UI picker.
    static let availableDelays: [TimeInterval] = [0, 1, 2, 3, 5]
}
