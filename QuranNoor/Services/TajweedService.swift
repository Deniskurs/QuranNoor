//
//  TajweedService.swift
//  QuranNoor
//
//  Fetches and parses tajweed-annotated Arabic text from the Quran.com v4 API.
//  Parsed results are cached to disk so subsequent requests are instant and
//  the app works offline after the first load.
//

import Foundation
import Observation
import os

// MARK: - API Response Models (internal)

private struct QuranComResponse: Decodable {
    let verses: [QuranComVerse]
}

private struct QuranComVerse: Decodable {
    let id: Int
    let verseKey: String
    let textUthmaniTajweed: String

    enum CodingKeys: String, CodingKey {
        case id
        case verseKey = "verse_key"
        case textUthmaniTajweed = "text_uthmani_tajweed"
    }
}

// MARK: - TajweedService

/// Singleton service responsible for fetching, parsing, and caching
/// tajweed-annotated verse data from the Quran.com v4 API.
@Observable
@MainActor
final class TajweedService {

    // MARK: - Singleton

    static let shared = TajweedService()

    // MARK: - Private State

    /// In-memory cache: surah number → array of verses, each verse = [TajweedSegment]
    private var memoryCache: [Int: [[TajweedSegment]]] = [:]

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Returns tajweed-segmented verses for a complete surah.
    ///
    /// Lookup order:
    /// 1. In-memory cache (fastest)
    /// 2. Disk cache (fast, works offline)
    /// 3. Quran.com v4 API (network, then writes to disk cache)
    ///
    /// - Parameter surahNumber: Surah number in [1, 114].
    /// - Returns: Array of verses; each verse is an ordered array of `TajweedSegment`.
    func getTajweedVerses(forSurah surahNumber: Int) async throws -> [[TajweedSegment]] {
        // 1. Memory cache
        if let cached = memoryCache[surahNumber] {
            AppLogger.quran.debug("TajweedService: memory cache hit for surah \(surahNumber)")
            return cached
        }

        // 2. Disk cache
        if let diskCached = loadFromDisk(surahNumber: surahNumber) {
            AppLogger.quran.debug("TajweedService: disk cache hit for surah \(surahNumber)")
            memoryCache[surahNumber] = diskCached
            return diskCached
        }

        // 3. Network fetch
        AppLogger.quran.info("TajweedService: fetching surah \(surahNumber) from network")
        let verses = try await fetchFromNetwork(surahNumber: surahNumber)

        // Store in both caches
        memoryCache[surahNumber] = verses
        saveToDisk(verses: verses, surahNumber: surahNumber)

        return verses
    }

    // MARK: - Network

    private func fetchFromNetwork(surahNumber: Int) async throws -> [[TajweedSegment]] {
        let urlString = "https://api.quran.com/api/v4/verses/by_chapter/\(surahNumber)?fields=text_uthmani_tajweed&per_page=300"
        guard let url = URL(string: urlString) else {
            AppLogger.quran.error("TajweedService: invalid URL for surah \(surahNumber)")
            throw TajweedError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            AppLogger.quran.error("TajweedService: HTTP \(httpResponse.statusCode) for surah \(surahNumber)")
            throw TajweedError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(QuranComResponse.self, from: data)
        AppLogger.quran.info("TajweedService: received \(decoded.verses.count) verses for surah \(surahNumber)")

        return decoded.verses.map { verse in
            parseHTML(verse.textUthmaniTajweed)
        }
    }

    // MARK: - HTML Parsing

    /// Parses Quran.com tajweed HTML into an ordered array of TajweedSegments.
    ///
    /// Input example:
    /// `"بِسۡمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ "`
    ///
    /// Segments alternate between plain text and tajweed-annotated runs.
    private func parseHTML(_ html: String) -> [TajweedSegment] {
        var segments: [TajweedSegment] = []
        // Matches: <tajweed class=CLASSNAME>TEXT</tajweed>
        // The class attribute value uses underscores and lowercase letters only.
        let pattern = #"<tajweed class=(\w+)>(.*?)<\/tajweed>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: treat entire string as plain text
            let plain = stripAllTags(html)
            if !plain.isEmpty {
                segments.append(TajweedSegment(text: plain, rule: nil))
            }
            return segments
        }

        let nsString = html as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: html, options: [], range: fullRange)

        var cursor = 0

        for match in matches {
            let matchStart = match.range.location

            // Plain text before this match
            if matchStart > cursor {
                let plainRange = NSRange(location: cursor, length: matchStart - cursor)
                let plain = stripAllTags(nsString.substring(with: plainRange))
                if !plain.isEmpty {
                    segments.append(TajweedSegment(text: plain, rule: nil))
                }
            }

            // Annotated text
            if match.numberOfRanges == 3 {
                let classRange = match.range(at: 1)
                let textRange  = match.range(at: 2)

                let cssClass = nsString.substring(with: classRange)
                let text     = nsString.substring(with: textRange)

                if !text.isEmpty {
                    let rule = TajweedRule.from(cssClass: cssClass)
                    if rule == nil {
                        AppLogger.quran.debug("TajweedService: unknown CSS class '\(cssClass)'")
                    }
                    segments.append(TajweedSegment(text: text, rule: rule))
                }
            }

            cursor = match.range.location + match.range.length
        }

        // Any remaining plain text after the last match
        if cursor < nsString.length {
            let plain = stripAllTags(nsString.substring(from: cursor))
            if !plain.isEmpty {
                segments.append(TajweedSegment(text: plain, rule: nil))
            }
        }

        return segments
    }

    /// Removes any remaining HTML tags from a string and trims whitespace.
    private func stripAllTags(_ input: String) -> String {
        let tagPattern = "<[^>]+>"
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return input
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
    }

    // MARK: - Disk Cache

    private var cacheDirectory: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("TajweedCache", isDirectory: true)
    }

    private func cacheURL(surahNumber: Int) -> URL? {
        cacheDirectory?.appendingPathComponent("surah_\(surahNumber).json")
    }

    private func loadFromDisk(surahNumber: Int) -> [[TajweedSegment]]? {
        guard let url = cacheURL(surahNumber: surahNumber) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([[TajweedSegment]].self, from: data)
            return decoded
        } catch {
            AppLogger.quran.debug("TajweedService: disk cache miss for surah \(surahNumber): \(error.localizedDescription)")
            return nil
        }
    }

    private func saveToDisk(verses: [[TajweedSegment]], surahNumber: Int) {
        guard let dirURL = cacheDirectory, let fileURL = cacheURL(surahNumber: surahNumber) else { return }

        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(verses)
            try data.write(to: fileURL, options: .atomic)
            AppLogger.quran.info("TajweedService: cached surah \(surahNumber) to disk (\(data.count) bytes)")
        } catch {
            AppLogger.quran.error("TajweedService: failed to write disk cache for surah \(surahNumber): \(error.localizedDescription)")
        }
    }
}

// MARK: - TajweedError

enum TajweedError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Tajweed API request."
        case .httpError(let code):
            return "Tajweed API returned HTTP \(code)."
        }
    }
}
