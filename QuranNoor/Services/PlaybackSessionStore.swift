//
//  PlaybackSessionStore.swift
//  QuranNoor
//
//  Persists playback session state for resume functionality
//

import Foundation

struct PlaybackSession: Codable {
    let surahNumber: Int
    let verseNumber: Int
    let reciterRawValue: String
    let queueSurahNumber: Int
    let currentVerseIndex: Int
    let currentTime: TimeInterval
    let continuousEnabled: Bool
}

@MainActor
class PlaybackSessionStore {
    static let shared = PlaybackSessionStore()

    private let key = "playback_session"

    func save(_ session: PlaybackSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func restore() -> PlaybackSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlaybackSession.self, from: data)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
