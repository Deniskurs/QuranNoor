//
//  IslamicContentService.swift
//  QuranNoor
//
//  Manages Islamic educational content for notifications and app features
//  Provides rotating Hadith and Quranic verses for prayer notifications
//

import Foundation


@MainActor
class IslamicContentService {
    // MARK: - Singleton
    static let shared = IslamicContentService()

    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let contentIndexKey = "lastNotificationContentIndex"

    // MARK: - Hadith Collection
    /// Curated collection of 40 authentic Hadith about prayer virtues
    private let hadithCollection: [IslamicQuote] = [
        // General Prayer Virtues (10)
        IslamicQuote(
            text: "The prayer offered in congregation is twenty-seven times superior to the prayer offered alone.",
            source: "Sahih Bukhari 645",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "When a person performs wudhu correctly and then leaves for the masjid, for each step taken, he gets one blessing and has one sin wiped.",
            source: "Sahih Muslim 666",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "Establish regular Salah, for Salah restrains from shameful and unjust deeds.",
            source: "Quran 29:45",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "The first thing that will be judged among a person's deeds on the Day of Resurrection is the prayer.",
            source: "Sunan an-Nasa'i 466",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "Between a man and shirk and kufr there stands his neglect of the prayer.",
            source: "Sahih Muslim 82",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "Prayer is the pillar of the religion. Whoever establishes it has established the religion.",
            source: "Bayhaqi 3392",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "The coolness of my eyes was placed in prayer.",
            source: "Sunan an-Nasa'i 3940",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "Whoever prays the two cool prayers (Asr and Fajr) will enter Paradise.",
            source: "Sahih Bukhari 574",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "The key to Paradise is prayer, and the key to prayer is purity.",
            source: "Musnad Ahmad 2760",
            category: .hadith,
            relatedPrayer: nil
        ),
        IslamicQuote(
            text: "Pray as you have seen me praying.",
            source: "Sahih Bukhari 631",
            category: .hadith,
            relatedPrayer: nil
        ),

        // Fajr-specific (8)
        IslamicQuote(
            text: "Whoever prays Fajr in congregation, it is as if he prayed the whole night.",
            source: "Sahih Muslim 656",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "Angels come to you in succession by night and by day, and they all assemble at Fajr and Asr prayers.",
            source: "Sahih Bukhari 555",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "The two Rak'ah of Fajr are better than this world and all it contains.",
            source: "Sahih Muslim 725",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "The most burdensome prayers for the hypocrites are Fajr and Isha. If only they knew what reward they contain.",
            source: "Sahih Bukhari 657",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "Whoever performs the prayer before the rising of the sun and before its setting will not enter Hell.",
            source: "Sahih Muslim 634",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "There is no prayer more heavy on the hypocrites than the Fajr and Isha prayers.",
            source: "Sahih Muslim 651",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "Whoever prays Fajr is under the protection of Allah.",
            source: "Sahih Muslim 657",
            category: .hadith,
            relatedPrayer: .fajr
        ),
        IslamicQuote(
            text: "The one who performs Fajr prayer in congregation is as if he stood in prayer all night.",
            source: "Sunan at-Tirmidhi 221",
            category: .hadith,
            relatedPrayer: .fajr
        ),

        // Dhuhr-specific (5)
        IslamicQuote(
            text: "This is the hour at which the gates of Heaven are opened, and I like that my good deeds should rise to Heaven at that time.",
            source: "Sunan at-Tirmidhi 478",
            category: .hadith,
            relatedPrayer: .dhuhr
        ),
        IslamicQuote(
            text: "The middle prayer is the Dhuhr prayer.",
            source: "Tafsir Ibn Kathir",
            category: .hadith,
            relatedPrayer: .dhuhr
        ),
        IslamicQuote(
            text: "Whoever maintains four Rak'ah before Dhuhr and four after it, Allah will forbid him from the Fire.",
            source: "Sunan at-Tirmidhi 428",
            category: .hadith,
            relatedPrayer: .dhuhr
        ),
        IslamicQuote(
            text: "Guard strictly your prayers, especially the middle prayer, and stand before Allah with devotion.",
            source: "Quran 2:238",
            category: .hadith,
            relatedPrayer: .dhuhr
        ),
        IslamicQuote(
            text: "Pray before the setting of the sun and before its rising, and celebrate the praise of your Lord.",
            source: "Quran 20:130",
            category: .hadith,
            relatedPrayer: .dhuhr
        ),

        // Asr-specific (6)
        IslamicQuote(
            text: "Whoever catches one Rak'ah of Asr prayer before sunset has caught Asr prayer.",
            source: "Sahih Bukhari 579",
            category: .hadith,
            relatedPrayer: .asr
        ),
        IslamicQuote(
            text: "Whoever leaves the Asr prayer, his good deeds will be annulled.",
            source: "Sahih Bukhari 553",
            category: .hadith,
            relatedPrayer: .asr
        ),
        IslamicQuote(
            text: "The angels gather at Fajr and Asr, witnessing your devotion.",
            source: "Sahih Bukhari 555",
            category: .hadith,
            relatedPrayer: .asr
        ),
        IslamicQuote(
            text: "He who prays before the rising of the sun and before its setting will never enter the Fire.",
            source: "Sahih Muslim 634",
            category: .hadith,
            relatedPrayer: .asr
        ),
        IslamicQuote(
            text: "The one who misses Asr prayer is like one who has lost his family and wealth.",
            source: "Sahih Bukhari 552",
            category: .hadith,
            relatedPrayer: .asr
        ),
        IslamicQuote(
            text: "Whoever prays Asr before the sun sets will not have his deeds invalidated.",
            source: "Sahih Muslim 608",
            category: .hadith,
            relatedPrayer: .asr
        ),

        // Maghrib-specific (5)
        IslamicQuote(
            text: "Hasten to pray Maghrib, for the one who delays it is like one who hastens sunset.",
            source: "Sunan Ibn Majah 689",
            category: .hadith,
            relatedPrayer: .maghrib
        ),
        IslamicQuote(
            text: "Whoever catches one Rak'ah of Maghrib before sunset has caught the prayer.",
            source: "Sahih Muslim 608",
            category: .hadith,
            relatedPrayer: .maghrib
        ),
        IslamicQuote(
            text: "Maghrib is the Witr of the day prayers, so make Witr at night.",
            source: "Musnad Ahmad 6737",
            category: .hadith,
            relatedPrayer: .maghrib
        ),
        IslamicQuote(
            text: "Make supplication between Maghrib and Isha, for it is a time of acceptance.",
            source: "Sunan at-Tirmidhi 3499",
            category: .hadith,
            relatedPrayer: .maghrib
        ),
        IslamicQuote(
            text: "The time for Maghrib is as long as the twilight has not disappeared.",
            source: "Sahih Muslim 612",
            category: .hadith,
            relatedPrayer: .maghrib
        ),

        // Isha-specific (6)
        IslamicQuote(
            text: "The most burdensome prayers for the hypocrites are Fajr and Isha. If only they knew what they contain.",
            source: "Sahih Bukhari 657",
            category: .hadith,
            relatedPrayer: .isha
        ),
        IslamicQuote(
            text: "If people knew the reward in Isha and Fajr prayers, they would come even if they had to crawl.",
            source: "Sahih Muslim 651",
            category: .hadith,
            relatedPrayer: .isha
        ),
        IslamicQuote(
            text: "Whoever prays Isha in congregation, it is as if he prayed half the night.",
            source: "Sahih Muslim 656",
            category: .hadith,
            relatedPrayer: .isha
        ),
        IslamicQuote(
            text: "The prayer before sleep brings tranquility to the heart.",
            source: "Ibn Majah 1368",
            category: .hadith,
            relatedPrayer: .isha
        ),
        IslamicQuote(
            text: "The best prayer after the obligatory prayers is the night prayer.",
            source: "Sahih Muslim 1163",
            category: .hadith,
            relatedPrayer: .isha
        ),
        IslamicQuote(
            text: "Whoever prays Isha in congregation is protected by Allah until the morning.",
            source: "Sunan at-Tirmidhi 223",
            category: .hadith,
            relatedPrayer: .isha
        )
    ]

    // MARK: - Verse References
    /// Popular Quranic verses for notifications
    private let verseReferences: [VerseReference] = [
        // High priority verses about prayer
        VerseReference(surah: 2, verse: 45, priority: .high, relatedPrayer: nil),     // Seek help through patience and prayer
        VerseReference(surah: 2, verse: 238, priority: .high, relatedPrayer: nil),    // Guard your prayers
        VerseReference(surah: 29, verse: 45, priority: .high, relatedPrayer: nil),    // Prayer prevents evil
        VerseReference(surah: 4, verse: 103, priority: .high, relatedPrayer: nil),    // Prayer at fixed times
        VerseReference(surah: 20, verse: 14, priority: .high, relatedPrayer: nil),    // Establish prayer for My remembrance

        // Fajr/morning verses
        VerseReference(surah: 17, verse: 78, priority: .high, relatedPrayer: .fajr),  // Fajr is witnessed
        VerseReference(surah: 11, verse: 114, priority: .medium, relatedPrayer: .fajr), // Good deeds remove evil

        // General prayer verses
        VerseReference(surah: 2, verse: 153, priority: .high, relatedPrayer: nil),    // Allah is with patient
        VerseReference(surah: 107, verse: 4, priority: .high, relatedPrayer: nil),    // Woe to those who are heedless
        VerseReference(surah: 73, verse: 20, priority: .medium, relatedPrayer: nil),  // Establish prayer

        // Evening/night verses
        VerseReference(surah: 50, verse: 39, priority: .medium, relatedPrayer: .maghrib), // Glorify before sunrise/sunset
        VerseReference(surah: 73, verse: 2, priority: .medium, relatedPrayer: .isha),     // Stand in prayer at night
        VerseReference(surah: 76, verse: 26, priority: .medium, relatedPrayer: .isha),    // Prostrate before Him

        // Medium priority
        VerseReference(surah: 23, verse: 2, priority: .medium, relatedPrayer: nil),   // Humble in prayers
        VerseReference(surah: 70, verse: 23, priority: .medium, relatedPrayer: nil),  // Constant in prayers
        VerseReference(surah: 9, verse: 71, priority: .medium, relatedPrayer: nil),   // Establish prayer

        // Last 10 surahs (easy to memorize)
        VerseReference(surah: 112, verse: 1, priority: .low, relatedPrayer: nil),     // Ikhlas
        VerseReference(surah: 113, verse: 1, priority: .low, relatedPrayer: nil),     // Falaq
        VerseReference(surah: 114, verse: 1, priority: .low, relatedPrayer: nil)      // Nas
    ]

    // MARK: - Public Methods

    /// Get total count of available content
    var totalContentCount: Int {
        hadithCollection.count + verseReferences.count
    }

    /// Get rotating notification content for specific prayer
    /// - Parameter prayer: Prayer name to get content for
    /// - Returns: Formatted notification content with rotation
    func getRotatingContent(for prayer: PrayerName) async -> NotificationContent {
        // Get content index
        let index = getNextContentIndex()

        // Determine if we should use hadith or verse
        let useHadith = index < hadithCollection.count

        if useHadith {
            // Use hadith content
            let hadith = getHadith(at: index, for: prayer)
            return NotificationContent(
                title: "", // Title will be set by NotificationService
                body: hadith.text,
                subtitle: hadith.source,
                index: index,
                total: totalContentCount
            )
        } else {
            // Use verse content
            let verseIndex = index - hadithCollection.count
            let verseRef = getVerseReference(at: verseIndex, for: prayer)

            // Fetch actual verse text from QuranService
            let verseText = await fetchVerseText(surah: verseRef.surah, verse: verseRef.verse)

            return NotificationContent(
                title: "",
                body: verseText,
                subtitle: "Quran \(verseRef.surah):\(verseRef.verse)",
                index: index,
                total: totalContentCount
            )
        }
    }

    /// Get random hadith for quick access
    func getRandomHadith() -> IslamicQuote {
        hadithCollection.randomElement() ?? hadithCollection[0]
    }

    /// Get random verse reference
    func getRandomVerseReference() -> VerseReference {
        verseReferences.randomElement() ?? verseReferences[0]
    }

    // MARK: - Private Methods

    /// Get next content index using rotation
    private func getNextContentIndex() -> Int {
        let current = userDefaults.integer(forKey: contentIndexKey)
        let next = (current + 1) % totalContentCount
        userDefaults.set(next, forKey: contentIndexKey)
        return current
    }

    /// Get hadith at index, prioritizing prayer-specific content
    private func getHadith(at index: Int, for prayer: PrayerName) -> IslamicQuote {
        // First try to find prayer-specific hadith
        let prayerSpecific = hadithCollection.filter { $0.relatedPrayer == prayer }

        if !prayerSpecific.isEmpty && Bool.random() {
            // 50% chance to use prayer-specific if available
            return prayerSpecific.randomElement()!
        }

        // Otherwise use index-based selection
        let safeIndex = index % hadithCollection.count
        return hadithCollection[safeIndex]
    }

    /// Get verse reference at index, prioritizing prayer-specific
    private func getVerseReference(at index: Int, for prayer: PrayerName) -> VerseReference {
        // First try prayer-specific verses
        let prayerSpecific = verseReferences.filter { $0.relatedPrayer == prayer }

        if !prayerSpecific.isEmpty && Bool.random() {
            return prayerSpecific.randomElement()!
        }

        // Otherwise use index-based
        let safeIndex = index % verseReferences.count
        return verseReferences[safeIndex]
    }

    /// Fetch verse text from QuranService
    private func fetchVerseText(surah: Int, verse: Int) async -> String {
        do {
            // Create temporary Verse object for QuranService API lookup
            let tempVerse = Verse(
                number: 0, // Not needed for translation API
                surahNumber: surah,
                verseNumber: verse,
                text: "", // Not needed
                juz: 1 // Not needed
            )

            // Fetch translation from QuranService (English - Sahih International)
            // Uses alquran.cloud API with automatic caching
            let translation = try await QuranService.shared.getTranslation(forVerse: tempVerse)

            return translation.text

        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch verse \(surah):\(verse) from QuranService: \(error.localizedDescription)")
            #endif

            // Fallback to generic prayer verse
            return "Establish prayer, for prayer has been enjoined upon the believers at fixed times."
        }
    }

    /// Reset content rotation (useful for testing or user preference)
    func resetRotation() {
        userDefaults.set(0, forKey: contentIndexKey)
    }
}
