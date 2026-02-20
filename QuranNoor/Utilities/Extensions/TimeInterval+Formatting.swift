//
//  TimeInterval+Formatting.swift
//  QuranNoor
//
//  Shared playback time formatting for audio player views
//

import Foundation

extension TimeInterval {
    /// Formats a time interval as "M:SS" for audio playback display.
    /// Returns "0:00" for invalid values (NaN, infinite, negative).
    var formattedPlaybackTime: String {
        guard self.isFinite && !self.isNaN && self >= 0 else { return "0:00" }
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
