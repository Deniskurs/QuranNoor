//
//  QuranWord.swift
//  QuranNoor
//
//  Word-level data model for Quran text supporting word-by-word display and morphology lookup.
//

import Foundation

// MARK: - Word Character Type

/// Classifies each token in a verse as either readable word or end marker.
enum WordCharType: String, Codable, Sendable {
    case word = "word"
    case end  = "end"

    /// Only actual words are tappable; verse-end markers are decorative.
    var isTappable: Bool {
        self == .word
    }
}

// MARK: - Quran Word

/// Represents a single word (or end marker) within a Quran verse.
///
/// The `id` follows the convention "surah:verse:position" (e.g. "1:1:1"),
/// making it globally unique and suitable for SwiftData / List identifiers.
struct QuranWord: Codable, Sendable, Identifiable {
    /// Globally unique identifier in "surah:verse:position" format.
    let id: String

    /// 1-based position of this word within its verse.
    let position: Int

    /// Arabic word text in Uthmani script.
    let textUthmani: String

    /// English translation of the word (optional).
    let translation: String?

    /// Romanized transliteration (optional).
    let transliteration: String?

    /// Whether this token is a tappable word or a decorative verse-end marker.
    let charType: WordCharType

    /// Relative audio path such as "wbw/001_001_001.mp3".
    /// Base URL: https://audio.qurancdn.com/
    let audioURL: String?
}
