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

    // MARK: - Fuzzy Search

    /// Perform fuzzy search on a collection of items
    /// - Parameters:
    ///   - items: Collection of items to search
    ///   - query: Search query string
    ///   - keyPath: KeyPath to the searchable property
    ///   - threshold: Minimum similarity score to include (0.0 to 1.0)
    /// - Returns: Sorted array of search results
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
    /// - Parameters:
    ///   - items: Collection of items to search
    ///   - query: Search query string
    ///   - keyPaths: Array of KeyPaths to searchable properties
    ///   - threshold: Minimum similarity score to include
    /// - Returns: Sorted array of search results with best match per item
    static func searchMultipleFields<T>(
        _ items: [T],
        query: String,
        keyPaths: [KeyPath<T, String>],
        threshold: Double = 0.3
    ) -> [SearchResult<T>] {
        guard !query.isEmpty else { return [] }

        let results: [SearchResult<T>] = items.compactMap { item in
            var bestScore: Double = 0.0
            var bestRanges: [Range<String.Index>] = []

            // Check all fields and keep the best match
            for keyPath in keyPaths {
                let text = item[keyPath: keyPath]

                // Exact match
                if text.lowercased() == query.lowercased() {
                    return SearchResult(
                        item: item,
                        score: 1.0,
                        matchedRanges: [text.startIndex..<text.endIndex]
                    )
                }

                // Contains match
                if containsMatch(text, query: query) {
                    let ranges = findMatchRanges(text, query: query)
                    let score = 0.8 + (Double(query.count) / Double(text.count)) * 0.2
                    if score > bestScore {
                        bestScore = score
                        bestRanges = ranges
                    }
                }

                // Fuzzy match
                let fuzzyScore = similarityScore(text, query) * 0.7
                if fuzzyScore > bestScore && fuzzyScore >= threshold {
                    bestScore = fuzzyScore
                    bestRanges = []
                }
            }

            guard bestScore >= threshold else { return nil }

            return SearchResult(
                item: item,
                score: bestScore,
                matchedRanges: bestRanges
            )
        }

        return SearchResult.sorted(results)
    }

    // MARK: - Word-based Search

    /// Search for individual words in query
    /// - Parameters:
    ///   - items: Collection of items to search
    ///   - query: Search query string (can contain multiple words)
    ///   - keyPath: KeyPath to the searchable property
    ///   - requireAll: If true, all words must match; if false, any word can match
    /// - Returns: Sorted array of search results
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
                    // Fuzzy match on word
                    let wordScore = similarityScore(text, word)
                    if wordScore >= 0.7 {
                        matchedWords += 1
                        totalScore += wordScore
                    }
                }
            }

            // Check if enough words matched
            if requireAll && matchedWords < words.count {
                return nil
            }

            guard matchedWords > 0 else { return nil }

            let averageScore = totalScore / Double(words.count)

            return SearchResult(
                item: item,
                score: averageScore,
                matchedRanges: allRanges
            )
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
