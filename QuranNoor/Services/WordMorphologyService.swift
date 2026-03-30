//
//  WordMorphologyService.swift
//  QuranNoor
//
//  Fetches and caches word-by-word morphology data from the Quran.com v4 API.
//  Results are permanently cached to disk so subsequent loads are instant.
//

import Foundation
import Observation
import os

// MARK: - Private API Response Types

private struct WordAPIResponse: Decodable {
    let verses: [APIVerse]
    let meta: APIMeta?
}

private struct APIMeta: Decodable {
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case totalPages = "total_pages"
    }
}

private struct APIVerse: Decodable {
    let verseKey: String
    let words: [APIWord]

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case words
    }
}

private struct APIWord: Decodable {
    let position: Int
    let audioUrl: String?
    let charTypeName: String
    let textUthmani: String?
    let translation: APITextPayload?
    let transliteration: APITextPayload?

    enum CodingKeys: String, CodingKey {
        case position
        case audioUrl      = "audio_url"
        case charTypeName  = "char_type_name"
        case textUthmani   = "text_uthmani"
        case translation
        case transliteration
    }
}

private struct APITextPayload: Decodable {
    let text: String?
}

// MARK: - Word Morphology Service

/// Singleton service that fetches word-by-word data for full surahs.
///
/// Caches results permanently under:
///   `<Caches>/WordMorphologyCache/surah_{N}.json`
///
/// Usage:
/// ```swift
/// let verses = try await WordMorphologyService.shared.getWords(forSurah: 1)
/// // verses[verseIndex][wordIndex]
/// ```
@Observable
@MainActor
final class WordMorphologyService {

    // MARK: - Singleton
    static let shared = WordMorphologyService()

    // MARK: - Constants
    private let baseURL = "https://api.quran.com/api/v4"
    private let audioBaseURL = "https://audio.qurancdn.com"
    private let perPage = 300

    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WordMorphologyCache", isDirectory: true)
    }

    // MARK: - Init
    private init() {
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Returns all words for a surah, grouped by verse.
    ///
    /// - Parameter surahNumber: 1–114
    /// - Returns: Array of verses, each verse being an array of `QuranWord`.
    func getWords(forSurah surahNumber: Int) async throws -> [[QuranWord]] {
        // 1. Return from disk cache if available
        if let cached = loadFromCache(surahNumber: surahNumber) {
            AppLogger.quran.debug("WordMorphologyService: cache hit for surah \(surahNumber, privacy: .public)")
            return cached
        }

        // 2. Fetch page 1 to discover total page count
        AppLogger.quran.info("WordMorphologyService: fetching surah \(surahNumber, privacy: .public) from API")
        let firstResponse = try await fetchPage(surahNumber: surahNumber, page: 1)
        var allVerses = firstResponse.verses

        // 3. Fetch remaining pages if needed
        let totalPages = firstResponse.meta?.totalPages ?? 1
        if totalPages > 1 {
            for page in 2...totalPages {
                let response = try await fetchPage(surahNumber: surahNumber, page: page)
                allVerses.append(contentsOf: response.verses)
            }
        }

        // 4. Map API response to our domain model
        let mapped = mapVerses(allVerses, surahNumber: surahNumber)

        // 5. Cache to disk
        saveToCache(mapped, surahNumber: surahNumber)

        return mapped
    }

    // MARK: - Networking

    private func fetchPage(surahNumber: Int, page: Int) async throws -> WordAPIResponse {
        var components = URLComponents(string: "\(baseURL)/verses/by_chapter/\(surahNumber)")!
        components.queryItems = [
            URLQueryItem(name: "words",             value: "true"),
            URLQueryItem(name: "word_fields",       value: "text_uthmani"),
            URLQueryItem(name: "translation_fields",value: "text"),
            URLQueryItem(name: "per_page",          value: "\(perPage)"),
            URLQueryItem(name: "language",          value: "en"),
            URLQueryItem(name: "page",              value: "\(page)")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            AppLogger.quran.error("WordMorphologyService: non-2xx response for surah \(surahNumber, privacy: .public) page \(page, privacy: .public)")
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(WordAPIResponse.self, from: data)
    }

    // MARK: - Mapping

    private func mapVerses(_ apiVerses: [APIVerse], surahNumber: Int) -> [[QuranWord]] {
        apiVerses.map { verse in
            // Parse verse number from "surah:verse"
            let verseNumber = verse.verseKey.split(separator: ":").last.flatMap { Int($0) } ?? 0

            return verse.words.map { word in
                let charType = WordCharType(rawValue: word.charTypeName) ?? .word
                return QuranWord(
                    id: "\(surahNumber):\(verseNumber):\(word.position)",
                    position: word.position,
                    textUthmani: word.textUthmani ?? "",
                    translation: word.translation?.text,
                    transliteration: word.transliteration?.text,
                    charType: charType,
                    audioURL: word.audioUrl
                )
            }
        }
    }

    // MARK: - Disk Cache

    private func cacheURL(forSurah surahNumber: Int) -> URL {
        cacheDirectory.appendingPathComponent("surah_\(surahNumber).json")
    }

    private func loadFromCache(surahNumber: Int) -> [[QuranWord]]? {
        let url = cacheURL(forSurah: surahNumber)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([[QuranWord]].self, from: data) else {
            return nil
        }
        return decoded
    }

    private func saveToCache(_ verses: [[QuranWord]], surahNumber: Int) {
        let url = cacheURL(forSurah: surahNumber)
        guard let data = try? JSONEncoder().encode(verses) else {
            AppLogger.quran.error("WordMorphologyService: failed to encode surah \(surahNumber, privacy: .public) for cache")
            return
        }
        do {
            try data.write(to: url, options: .atomic)
            AppLogger.quran.debug("WordMorphologyService: cached surah \(surahNumber, privacy: .public)")
        } catch {
            AppLogger.quran.error("WordMorphologyService: cache write error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
