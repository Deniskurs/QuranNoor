//
//  FuzzySearchUtility.swift
//  QuranNoor
//
//  Fuzzy search utility for improved search functionality
//

import Foundation
import SwiftUI

// MARK: - Search Result
struct SearchResult<T>: Identifiable {
    let id = UUID()
    let item: T
    let score: Double
    let matchedRanges: [Range<String.Index>]

    /// Sort results by score (highest first)
    static func sorted(_ results: [SearchResult<T>]) -> [SearchResult<T>] {
        results.sorted { $0.score > $1.score }
    }
}

// MARK: - Parsed Verse Reference

/// A parsed verse reference like "2:255" or "surah 36 verse 12"
struct ParsedVerseRef {
    let surahNumber: Int
    let verseNumber: Int?   // nil means "go to surah, no specific verse"
}

// MARK: - Fuzzy Search Utility
struct FuzzySearchUtility {

    // MARK: - Levenshtein Distance

    /// Calculate Levenshtein distance between two strings (edit distance)
    /// Lower distance = more similar strings
    /// Optimized to use O(min(m,n)) memory with two-row approach instead of full matrix
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let source = Array(s1.lowercased())
        let target = Array(s2.lowercased())

        let m = source.count
        let n = target.count

        guard m > 0 else { return n }
        guard n > 0 else { return m }

        // Two-row approach: O(min(m,n)) memory instead of O(m*n)
        var previousRow = Array(0...n)
        var currentRow = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            currentRow[0] = i
            for j in 1...n {
                let cost = source[i - 1] == target[j - 1] ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,         // deletion
                    currentRow[j - 1] + 1,      // insertion
                    previousRow[j - 1] + cost   // substitution
                )
            }
            swap(&previousRow, &currentRow)
        }

        return previousRow[n]
    }

    // MARK: - Similarity Score

    /// Calculate similarity score between two strings (0.0 to 1.0)
    /// 1.0 = perfect match, 0.0 = completely different
    static func similarityScore(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    // MARK: - Contains Match

    /// Check if query is contained in text (case-insensitive)
    static func containsMatch(_ text: String, query: String) -> Bool {
        text.lowercased().contains(query.lowercased())
    }

    /// Find all ranges where query matches in text
    static func findMatchRanges(_ text: String, query: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()

        var searchStartIndex = lowercasedText.startIndex

        while searchStartIndex < lowercasedText.endIndex,
              let range = lowercasedText.range(of: lowercasedQuery, range: searchStartIndex..<lowercasedText.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }

        return ranges
    }

    // MARK: - Verse Reference Parsing

    /// Parse a search query for verse references like "2:255", "36:12", "surah 2 verse 5", "al-baqarah 255"
    static func parseVerseReference(_ query: String, surahs: [Surah]) -> ParsedVerseRef? {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()

        // Pattern 1: "2:255" or "2:255" (surah:verse)
        if let colonIdx = trimmed.firstIndex(of: ":") {
            let beforeColon = String(trimmed[trimmed.startIndex..<colonIdx])
            let afterColon = String(trimmed[trimmed.index(after: colonIdx)...])
            if let surahNum = Int(beforeColon.trimmingCharacters(in: .whitespaces)),
               let verseNum = Int(afterColon.trimmingCharacters(in: .whitespaces)),
               surahNum >= 1, surahNum <= 114 {
                return ParsedVerseRef(surahNumber: surahNum, verseNumber: verseNum)
            }
        }

        // Pattern 2: "surah 2 verse 5", "surah 2 ayah 5", "surah 36"
        if let surahPattern = try? NSRegularExpression(pattern: #"surah\s+(\d+)(?:\s+(?:verse|ayah|ayat)\s+(\d+))?"#),
           let match = surahPattern.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
            let surahRange = Range(match.range(at: 1), in: trimmed)
            let verseRange = match.range(at: 2).location != NSNotFound ? Range(match.range(at: 2), in: trimmed) : nil
            if let surahRange, let surahNum = Int(trimmed[surahRange]), surahNum >= 1, surahNum <= 114 {
                let verseNum = verseRange.flatMap { Int(trimmed[$0]) }
                return ParsedVerseRef(surahNumber: surahNum, verseNumber: verseNum)
            }
        }

        // Pattern 3: Surah name + optional verse number, e.g. "al-baqarah 255", "fatiha 3"
        // Try matching the last token as a verse number
        let tokens = trimmed.split(separator: " ").map(String.init)
        if let lastToken = tokens.last, let verseNum = Int(lastToken), tokens.count >= 2 {
            let namePart = tokens.dropLast().joined(separator: " ")
            if let surah = findSurahByName(namePart, in: surahs) {
                return ParsedVerseRef(surahNumber: surah.id, verseNumber: verseNum)
            }
        }

        return nil
    }

    /// Find a surah by name using fuzzy matching (for verse reference parsing)
    private static func findSurahByName(_ name: String, in surahs: [Surah]) -> Surah? {
        let normalized = normalizeArabicTransliteration(name)

        // Check common aliases first
        if let aliasNumber = surahAliases[normalized] {
            return surahs.first { $0.id == aliasNumber }
        }

        // Try exact/prefix match on English name
        for surah in surahs {
            let englishLower = surah.englishName.lowercased()
            let normalizedEnglish = normalizeArabicTransliteration(englishLower)
            if normalizedEnglish == normalized || englishLower == normalized {
                return surah
            }
            // Prefix match: "baqar" matches "al-baqarah"
            if normalizedEnglish.hasPrefix(normalized) && normalized.count >= 3 {
                return surah
            }
            // Without "al-" prefix: "baqarah" matches "al-baqarah"
            let withoutAl = normalizedEnglish.replacingOccurrences(of: "al-", with: "")
            if withoutAl == normalized || withoutAl.hasPrefix(normalized) && normalized.count >= 3 {
                return surah
            }
        }

        // Fuzzy match as last resort (high threshold)
        var bestMatch: (surah: Surah, score: Double)?
        for surah in surahs {
            let normalizedEnglish = normalizeArabicTransliteration(surah.englishName.lowercased())
            let score = similarityScore(normalized, normalizedEnglish)
            if score >= 0.7, score > (bestMatch?.score ?? 0) {
                bestMatch = (surah, score)
            }
        }
        return bestMatch?.surah
    }

    // MARK: - Arabic Transliteration Normalization

    /// Normalize common Arabic transliteration variations so fuzzy matching works better.
    /// "fatiha" / "fatihah" / "faatiha" → same normalized form
    static func normalizeArabicTransliteration(_ text: String) -> String {
        var s = text.lowercased()

        // Strip diacritical marks (accents) — handles 'ā', 'ī', 'ū' etc.
        s = s.folding(options: .diacriticInsensitive, locale: .current)

        // Common transliteration equivalences
        let replacements: [(String, String)] = [
            ("'", ""),       // Remove apostrophes (Qur'an → quran)
            ("'", ""),       // curly apostrophe
            ("-", ""),       // hyphens (al-fatiha → alfatiha)
            ("aa", "a"),     // long vowels
            ("ee", "i"),
            ("oo", "u"),
            ("ii", "i"),
            ("uu", "u"),
            ("th", "t"),     // common variant
            ("dh", "d"),
            ("sh", "sh"),    // keep sh as-is
            ("kh", "kh"),    // keep kh as-is
            ("gh", "gh"),    // keep gh as-is
            ("ph", "f"),     // fatiha sometimes written as "fatihah"
        ]

        for (from, to) in replacements {
            s = s.replacingOccurrences(of: from, with: to)
        }

        // Remove trailing 'h' variants (fatihah → fatiha → fatia... no, keep it reasonable)
        // Just strip trailing "ah" vs "a" normalization
        if s.hasSuffix("ah") {
            s = String(s.dropLast(1)) // "fatihah" → "fatiha"
        }

        return s
    }

    // MARK: - Common Surah Aliases

    /// Maps common informal names/transliterations to surah numbers
    private static let surahAliases: [String: Int] = [
        "fatiha": 1, "opening": 1, "alfatiha": 1,
        "baqara": 2, "baqra": 2, "cow": 2, "albaqara": 2,
        "imran": 3, "alimran": 3,
        "nisa": 4, "women": 4,
        "maida": 5, "maidah": 5, "table": 5,
        "anam": 6, "cattle": 6,
        "araf": 7,
        "anfal": 8,
        "tauba": 9, "tawba": 9, "repentance": 9,
        "yunus": 10, "yonus": 10, "jonah": 10,
        "hud": 11,
        "yusuf": 12, "yousuf": 12, "joseph": 12,
        "raad": 13, "thunder": 13,
        "ibrahim": 14, "abraham": 14,
        "hijr": 15,
        "nahl": 16, "bee": 16,
        "isra": 17, "israa": 17,
        "kahf": 18, "cave": 18, "alkahf": 18,
        "maryam": 19, "mary": 19,
        "taha": 20,
        "anbiya": 21, "prophets": 21,
        "hajj": 22,
        "muminun": 23, "believers": 23,
        "nur": 24, "noor": 24, "light": 24,
        "furqan": 25,
        "shuara": 26, "poets": 26,
        "naml": 27, "ant": 27, "ants": 27,
        "qasas": 28, "stories": 28,
        "ankabut": 29, "spider": 29,
        "rum": 30, "romans": 30,
        "luqman": 31,
        "sajda": 32, "prostration": 32,
        "ahzab": 33,
        "saba": 34, "sheba": 34,
        "fatir": 35, "originator": 35,
        "yasin": 36, "yaseen": 36, "ya sin": 36, "ya-sin": 36,
        "saffat": 37,
        "sad": 38,
        "zumar": 39, "crowds": 39,
        "ghafir": 40, "forgiver": 40,
        "fussilat": 41,
        "shura": 42, "consultation": 42,
        "zukhruf": 43,
        "dukhan": 44, "smoke": 44,
        "jatiya": 45, "jasiya": 45,
        "ahqaf": 46,
        "muhammad": 47,
        "fath": 48, "victory": 48,
        "hujurat": 49, "rooms": 49,
        "qaf": 50,
        "dhariyat": 51, "zariyat": 51,
        "tur": 52, "mount": 52,
        "najm": 53, "star": 53,
        "qamar": 54, "moon": 54,
        "rahman": 55, "merciful": 55, "arrahman": 55,
        "waqia": 56, "waqiah": 56, "event": 56,
        "hadid": 57, "iron": 57,
        "mujadila": 58, "mujadilah": 58,
        "hashr": 59, "exile": 59,
        "mumtahina": 60, "mumtahinah": 60,
        "saff": 61,
        "jumua": 62, "juma": 62, "friday": 62,
        "munafiqun": 63, "hypocrites": 63,
        "taghabun": 64,
        "talaq": 65, "divorce": 65,
        "tahrim": 66,
        "mulk": 67, "sovereignty": 67, "almulk": 67, "dominion": 67,
        "qalam": 68, "pen": 68,
        "haqqa": 69, "haqqah": 69,
        "maarij": 70,
        "nuh": 71, "noah": 71,
        "jinn": 72,
        "muzzammil": 73, "muzammil": 73,
        "muddathir": 74, "mudathir": 74,
        "qiyama": 75, "qiyamah": 75, "resurrection": 75,
        "insan": 76, "dahr": 76,
        "mursalat": 77,
        "naba": 78,
        "naziat": 79,
        "abasa": 80,
        "takwir": 81,
        "infitar": 82,
        "mutaffifin": 83,
        "inshiqaq": 84,
        "buruj": 85, "buroog": 85,
        "tariq": 86,
        "ala": 87,
        "ghashiya": 88, "ghashiyah": 88,
        "fajr": 89, "dawn": 89,
        "balad": 90, "city": 90,
        "shams": 91, "sun": 91,
        "layl": 92, "lail": 92, "night": 92,
        "duha": 93, "forenoon": 93,
        "sharh": 94, "inshirah": 94,
        "tin": 95, "fig": 95,
        "alaq": 96, "clot": 96,
        "qadr": 97, "power": 97,
        "bayyina": 98, "bayyinah": 98,
        "zalzala": 99, "zilzal": 99, "earthquake": 99,
        "adiyat": 100,
        "qaria": 101, "qariah": 101,
        "takathur": 102,
        "asr": 103, "time": 103,
        "humaza": 104, "humazah": 104,
        "fil": 105, "elephant": 105,
        "quraysh": 106, "quraish": 106,
        "maun": 107, "maaun": 107,
        "kauthar": 108, "kawthar": 108, "kawsar": 108,
        "kafirun": 109, "disbelievers": 109,
        "nasr": 110, "help": 110,
        "masad": 111, "lahab": 111, "flame": 111,
        "ikhlas": 112, "sincerity": 112, "purity": 112,
        "falaq": 113, "daybreak": 113,
        "nas": 114, "mankind": 114, "people": 114,
    ]

    // MARK: - Fuzzy Search

    /// Perform fuzzy search on a collection of items
    static func search<T>(
        _ items: [T],
        query: String,
        keyPath: KeyPath<T, String>,
        threshold: Double = 0.3
    ) -> [SearchResult<T>] {
        guard !query.isEmpty else { return [] }

        let results: [SearchResult<T>] = items.compactMap { item in
            let text = item[keyPath: keyPath]

            // Exact match gets highest score
            if text.lowercased() == query.lowercased() {
                return SearchResult(
                    item: item,
                    score: 1.0,
                    matchedRanges: [text.startIndex..<text.endIndex]
                )
            }

            // Contains match gets high score
            if containsMatch(text, query: query) {
                let ranges = findMatchRanges(text, query: query)
                let score = 0.8 + (Double(query.count) / Double(text.count)) * 0.2
                return SearchResult(
                    item: item,
                    score: score,
                    matchedRanges: ranges
                )
            }

            // Fuzzy match based on similarity
            let score = similarityScore(text, query)
            guard score >= threshold else { return nil }

            return SearchResult(
                item: item,
                score: score * 0.7, // Fuzzy matches get lower score than exact/contains
                matchedRanges: []
            )
        }

        return SearchResult.sorted(results)
    }

    // MARK: - Multi-field Search

    /// Perform fuzzy search across multiple fields
    static func searchMultipleFields<T>(
        _ items: [T],
        query: String,
        keyPaths: [KeyPath<T, String>],
        threshold: Double = 0.3
    ) -> [SearchResult<T>] {
        guard !query.isEmpty else { return [] }

        let normalizedQuery = normalizeArabicTransliteration(query)

        let results: [SearchResult<T>] = items.compactMap { item in
            var bestScore: Double = 0.0
            var bestRanges: [Range<String.Index>] = []

            for keyPath in keyPaths {
                let text = item[keyPath: keyPath]
                let queryLower = query.lowercased()
                let textLower = text.lowercased()

                // Exact match
                if textLower == queryLower {
                    return SearchResult(item: item, score: 1.0, matchedRanges: [text.startIndex..<text.endIndex])
                }

                // Contains match
                if textLower.contains(queryLower) {
                    let ranges = findMatchRanges(text, query: query)
                    let score = 0.8 + (Double(query.count) / Double(text.count)) * 0.2
                    if score > bestScore {
                        bestScore = score
                        bestRanges = ranges
                    }
                }

                // Prefix match — "baqar" matching "Al-Baqarah" should score high
                let normalizedText = normalizeArabicTransliteration(textLower)
                let withoutAl = normalizedText.replacingOccurrences(of: "al", with: "")
                if normalizedText.hasPrefix(normalizedQuery) || withoutAl.hasPrefix(normalizedQuery) {
                    let score = 0.75 + (Double(normalizedQuery.count) / Double(normalizedText.count)) * 0.2
                    if score > bestScore {
                        bestScore = score
                        bestRanges = []
                    }
                }

                // Normalized transliteration contains match
                if normalizedText.contains(normalizedQuery) && normalizedQuery.count >= 3 {
                    let score = 0.7 + (Double(normalizedQuery.count) / Double(normalizedText.count)) * 0.2
                    if score > bestScore {
                        bestScore = score
                        bestRanges = []
                    }
                }

                // Fuzzy match on normalized forms
                let fuzzyScore = max(
                    similarityScore(textLower, queryLower),
                    similarityScore(normalizedText, normalizedQuery)
                ) * 0.7
                if fuzzyScore > bestScore && fuzzyScore >= threshold {
                    bestScore = fuzzyScore
                    bestRanges = []
                }
            }

            guard bestScore >= threshold else { return nil }

            return SearchResult(item: item, score: bestScore, matchedRanges: bestRanges)
        }

        return SearchResult.sorted(results)
    }

    // MARK: - Token-based Word Search (Improved)

    /// Search by matching query words against individual words in the target text.
    /// Much more accurate than comparing query words against the entire text string.
    static func tokenWordSearch<T>(
        _ items: [T],
        query: String,
        keyPath: KeyPath<T, String>,
        requireAll: Bool = false
    ) -> [SearchResult<T>] {
        let queryWords = query.lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map(String.init)
            .filter { $0.count >= 2 } // Skip single-char tokens
        guard !queryWords.isEmpty else { return [] }

        let results: [SearchResult<T>] = items.compactMap { item in
            let text = item[keyPath: keyPath]
            let textLower = text.lowercased()

            // Fast path: check if full query phrase is contained
            let fullQueryLower = query.lowercased().trimmingCharacters(in: .whitespaces)
            if textLower.contains(fullQueryLower) {
                let ranges = findMatchRanges(text, query: query)
                return SearchResult(item: item, score: 1.0, matchedRanges: ranges)
            }

            // Split target text into words for word-level matching
            let textWords = textLower
                .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
                .map(String.init)

            var matchedQueryWords = 0
            var totalScore = 0.0
            var allRanges: [Range<String.Index>] = []

            for qWord in queryWords {
                var bestWordScore = 0.0

                // Check for exact word containment in text
                if textLower.contains(qWord) {
                    bestWordScore = 1.0
                    allRanges.append(contentsOf: findMatchRanges(text, query: qWord))
                } else {
                    // Compare against each word in the text
                    for tWord in textWords {
                        // Prefix match: "merci" should match "merciful"
                        if tWord.hasPrefix(qWord) {
                            let prefixScore = 0.85 + (Double(qWord.count) / Double(tWord.count)) * 0.15
                            bestWordScore = max(bestWordScore, prefixScore)
                        }
                        // Suffix match: "ful" matching "merciful" (lower score)
                        else if tWord.hasSuffix(qWord) && qWord.count >= 3 {
                            bestWordScore = max(bestWordScore, 0.7)
                        }
                        // Edit distance for short words (typo tolerance)
                        else if qWord.count >= 3 {
                            let dist = levenshteinDistance(qWord, tWord)
                            let maxAllowedDist = qWord.count <= 4 ? 1 : 2
                            if dist <= maxAllowedDist {
                                let score = 1.0 - (Double(dist) / Double(max(qWord.count, tWord.count)))
                                bestWordScore = max(bestWordScore, score * 0.8)
                            }
                        }
                    }
                }

                if bestWordScore > 0.3 {
                    matchedQueryWords += 1
                    totalScore += bestWordScore
                }
            }

            if requireAll && matchedQueryWords < queryWords.count { return nil }
            guard matchedQueryWords > 0 else { return nil }

            // Score formula: reward matching more words, penalize partial coverage
            let coverage = Double(matchedQueryWords) / Double(queryWords.count)
            let averageWordScore = totalScore / Double(queryWords.count)
            let finalScore = averageWordScore * (0.5 + 0.5 * coverage)

            return SearchResult(item: item, score: finalScore, matchedRanges: allRanges)
        }

        return SearchResult.sorted(results)
    }

    // MARK: - Word-based Search (Legacy)

    /// Search for individual words in query
    static func wordSearch<T>(
        _ items: [T],
        query: String,
        keyPath: KeyPath<T, String>,
        requireAll: Bool = false
    ) -> [SearchResult<T>] {
        let words = query.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }

        let results: [SearchResult<T>] = items.compactMap { item in
            let text = item[keyPath: keyPath].lowercased()

            var matchedWords = 0
            var totalScore = 0.0
            var allRanges: [Range<String.Index>] = []

            for word in words {
                if text.contains(word) {
                    matchedWords += 1
                    totalScore += 1.0
                    allRanges.append(contentsOf: findMatchRanges(text, query: word))
                } else {
                    // Fuzzy match on individual words in the text
                    let textTokens = text.split(separator: " ").map(String.init)
                    var bestTokenScore = 0.0
                    for token in textTokens {
                        let score = similarityScore(word, token)
                        bestTokenScore = max(bestTokenScore, score)
                    }
                    if bestTokenScore >= 0.6 {
                        matchedWords += 1
                        totalScore += bestTokenScore
                    }
                }
            }

            if requireAll && matchedWords < words.count { return nil }
            guard matchedWords > 0 else { return nil }

            let averageScore = totalScore / Double(words.count)

            return SearchResult(item: item, score: averageScore, matchedRanges: allRanges)
        }

        return SearchResult.sorted(results)
    }
}

// MARK: - String Extensions for Highlighting

extension String {
    /// Get attributed string with highlighted matches
    func highlighted(ranges: [Range<String.Index>]) -> AttributedString {
        var attributed = AttributedString(self)

        for range in ranges {
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].foregroundColor = .accentColor
                attributed[attributedRange].font = .bold(.body)()
            }
        }

        return attributed
    }
}
