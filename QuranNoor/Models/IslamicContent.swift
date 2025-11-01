//
//  IslamicContent.swift
//  QuranNoor
//
//  Islamic educational content models for notifications and app features
//

import Foundation

// MARK: - Islamic Quote (Hadith or General)
struct IslamicQuote: Identifiable {
    let id = UUID()
    let text: String
    let source: String
    let category: QuoteCategory
    let relatedPrayer: PrayerName?

    enum QuoteCategory: String {
        case hadith = "Hadith"
        case dua = "Dua"
        case wisdom = "Islamic Wisdom"
    }
}

// MARK: - Verse Reference
struct VerseReference: Identifiable {
    let id = UUID()
    let surah: Int
    let verse: Int
    let priority: Priority
    let relatedPrayer: PrayerName?

    enum Priority {
        case high
        case medium
        case low
    }
}

// MARK: - Notification Content
struct NotificationContent {
    let title: String
    let body: String
    let subtitle: String?
    let index: Int
    let total: Int

    /// Format body with rotation indicator and action hint
    var formattedBody: String {
        var result = body
        result += "\n\n(\(index + 1) of \(total))"
        if let subtitle = subtitle {
            result += "\n\(subtitle)"
        }
        result += "\n\nTap to mark as prayed"
        return result
    }
}

// MARK: - Islamic Content Type
enum IslamicContentType {
    case hadith(IslamicQuote)
    case verse(text: String, reference: String)
    case mixed

    var displaySource: String {
        switch self {
        case .hadith(let quote):
            return quote.source
        case .verse(_, let reference):
            return reference
        case .mixed:
            return "Various Sources"
        }
    }
}
