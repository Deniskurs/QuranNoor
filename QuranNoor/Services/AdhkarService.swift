//
//  AdhkarService.swift
//  QuranNoor
//
//  Service for managing adhkar (Islamic remembrances)
//

import Foundation
import Observation

@Observable
final class AdhkarService {
    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Properties

    private(set) var allAdhkar: [Dhikr] = []
    private(set) var progress: AdhkarProgress

    private let progressKey = "adhkar_progress"

    // MARK: - Initialization

    init() {
        self.progress = Self.loadProgress()
        self.allAdhkar = Self.createAdhkarDatabase()
        progress.checkAndResetForNewDay()
    }

    // MARK: - Public Methods

    /// Get adhkar for a specific category
    func getAdhkar(for category: AdhkarCategory) -> [Dhikr] {
        allAdhkar
            .filter { $0.category == category }
            .sorted { $0.order < $1.order }
    }

    /// Get all categories with adhkar count
    func getCategoriesWithCount() -> [(category: AdhkarCategory, count: Int)] {
        AdhkarCategory.allCases.map { category in
            let count = allAdhkar.filter { $0.category == category }.count
            return (category, count)
        }
    }

    /// Mark dhikr as completed
    func markCompleted(dhikrId: UUID) {
        progress.markCompleted(dhikrId: dhikrId)
        saveProgress()
    }

    /// Check if dhikr is completed today
    func isCompleted(dhikrId: UUID) -> Bool {
        progress.isCompleted(dhikrId: dhikrId)
    }

    /// Get statistics for a category
    func getStatistics(for category: AdhkarCategory) -> AdhkarStatistics {
        let categoryAdhkar = getAdhkar(for: category)
        let totalCount = categoryAdhkar.count
        let completedCount = categoryAdhkar.filter { isCompleted(dhikrId: $0.id) }.count
        let percentage = totalCount > 0 ? (Double(completedCount) / Double(totalCount)) * 100.0 : 0.0

        return AdhkarStatistics(
            totalDhikr: totalCount,
            completedToday: completedCount,
            completionPercentage: percentage,
            currentStreak: progress.streak,
            longestStreak: progress.streak, // TODO: Track longest streak separately
            totalCompletions: progress.totalCompletions
        )
    }

    /// Reset all progress (for testing)
    func resetProgress() {
        progress = AdhkarProgress()
        saveProgress()
    }

    // MARK: - Private Methods

    private func saveProgress() {
        if let encoded = try? Self.encoder.encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private static func loadProgress() -> AdhkarProgress {
        guard let data = UserDefaults.standard.data(forKey: "adhkar_progress"),
              let progress = try? decoder.decode(AdhkarProgress.self, from: data) else {
            return AdhkarProgress()
        }
        return progress
    }

    // MARK: - Adhkar Database

    private static func createAdhkarDatabase() -> [Dhikr] {
        var adhkar: [Dhikr] = []

        // MARK: Morning Adhkar

        // 1. Ayat al-Kursi
        adhkar.append(Dhikr(
            arabicText: """
            اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
            """,
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'a. Wasi'a Kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma. Wa Huwal-'Aliyyul-'Adheem.",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
            reference: "Quran 2:255",
            repetitions: 1,
            benefits: "Whoever recites Ayat al-Kursi after every obligatory prayer, nothing prevents him from entering Paradise except death.",
            category: .morning,
            order: 1
        ))

        // 2. Last two verses of Al-Baqarah
        adhkar.append(Dhikr(
            arabicText: """
            آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ. لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ
            """,
            transliteration: "Aamanar-Rasulu bima unzila ilayhi mir-Rabbihi wal-mu'minoon. Kullun aamana billahi wa mala'ikatihi wa kutubihi wa Rusulihi la nufarriqu bayna ahadim-mir-Rusulihi wa qalu sami'na wa ata'na ghufranaka Rabbana wa ilaykal-maseer. La yukallifullahu nafsan illa wus'aha. Laha ma kasabat wa 'alayha maktasabat. Rabbana la tu'akhidhna in naseena aw akhta'na. Rabbana wa la tahmil 'alayna isran kama hamaltahu 'alal-ladheena min qablina. Rabbana wa la tuhammilna ma la taqata lana bihi wa'fu 'anna waghfir lana wairhamna. Anta Mawlana fansurna 'alal-qawmil-kafireen.",
            translation: "The Messenger has believed in what was revealed to him from his Lord, and the believers. All of them have believed in Allah and His angels and His books and His messengers, [saying], \"We make no distinction between any of His messengers.\" And they say, \"We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the [final] destination.\" Allah does not charge a soul except [with that within] its capacity. It will have [the consequence of] what [good] it has gained, and it will bear [the consequence of] what [evil] it has earned. \"Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people.\"",
            reference: "Quran 2:285-286",
            repetitions: 1,
            benefits: "Whoever recites these two verses at night, they will suffice him.",
            category: .morning,
            order: 2
        ))

        // 3. Surah Al-Ikhlas, Al-Falaq, An-Nas
        adhkar.append(Dhikr(
            arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
            transliteration: "Qul Huwa Allahu Ahad, Allahus-Samad, lam yalid wa lam yulad, wa lam yakul-lahu kufuwan ahad.",
            translation: "Say, \"He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.\"",
            reference: "Quran 112:1-4",
            repetitions: 3,
            benefits: "Equivalent to one-third of the Quran. Protection from all harm.",
            category: .morning,
            order: 3
        ))

        adhkar.append(Dhikr(
            arabicText: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
            transliteration: "Qul a'udhu bi Rabbil-falaq, min sharri ma khalaq, wa min sharri ghasiqin idha waqab, wa min sharrin-naffathati fil-'uqad, wa min sharri hasidin idha hasad.",
            translation: "Say, \"I seek refuge in the Lord of daybreak from the evil of that which He created and from the evil of darkness when it settles and from the evil of the blowers in knots and from the evil of an envier when he envies.\"",
            reference: "Quran 113:1-5",
            repetitions: 3,
            benefits: "Protection from evil eye, black magic, and envy.",
            category: .morning,
            order: 4
        ))

        adhkar.append(Dhikr(
            arabicText: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
            transliteration: "Qul a'udhu bi Rabbin-nas, Malikin-nas, Ilahin-nas, min sharril-waswasil-khannas, alladhi yuwaswisu fi sudoorin-nas, minal-jinnati wan-nas.",
            translation: "Say, \"I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer - who whispers [evil] into the breasts of mankind - from among the jinn and mankind.\"",
            reference: "Quran 114:1-6",
            repetitions: 3,
            benefits: "Protection from evil whispers and satanic influence.",
            category: .morning,
            order: 5
        ))

        // 4. Morning remembrance
        adhkar.append(Dhikr(
            arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
            transliteration: "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer. Rabbi as'aluka khayra ma fi hadhal-yawmi wa khayra ma ba'dahu, wa a'udhu bika min sharri ma fi hadhal-yawmi wa sharri ma ba'dahu. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
            translation: "We have entered a new day and with it all dominion belongs to Allah. Praise is to Allah. There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything. My Lord, I ask You for the good of this day and the good that follows it, and I seek refuge in You from the evil of this day and the evil that follows it. My Lord, I seek refuge in You from laziness and helpless old age. My Lord, I seek refuge in You from the punishment of the Fire and the punishment of the grave.",
            reference: "Muslim 2723",
            repetitions: 1,
            benefits: "Comprehensive protection for the day.",
            category: .morning,
            order: 6
        ))

        // 5. SubhanAllah wa bihamdihi
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa bihamdihi",
            translation: "Glory is to Allah and praise is to Him.",
            reference: "Bukhari 6405, Muslim 2691",
            repetitions: 100,
            benefits: "Whoever says this 100 times in the morning and evening, none will bring better than what he brought except one who does more than that.",
            category: .morning,
            order: 7
        ))

        // 6. La ilaha illallah wahdahu
        adhkar.append(Dhikr(
            arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer",
            translation: "There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything.",
            reference: "Bukhari 3293, Muslim 2691",
            repetitions: 10,
            benefits: "Whoever says this 10 times will have the reward of freeing four slaves from the children of Isma'il.",
            category: .morning,
            order: 8
        ))

        // 7. SubhanAllah al-Adheem
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahil-'Adheem wa bihamdihi",
            translation: "Glory is to Allah, the Magnificent, and praise is to Him.",
            reference: "Tirmidhi 3467",
            repetitions: 100,
            benefits: "A date-palm tree will be planted for him in Paradise.",
            category: .morning,
            order: 9
        ))

        // 8. Astaghfirullah
        adhkar.append(Dhikr(
            arabicText: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
            transliteration: "Astaghfirullaha wa atubu ilayh",
            translation: "I seek forgiveness from Allah and repent to Him.",
            reference: "Bukhari 6307",
            repetitions: 100,
            benefits: "The Prophet ﷺ used to seek forgiveness 100 times a day.",
            category: .morning,
            order: 10
        ))

        // 9. Seeking Allah's protection
        adhkar.append(Dhikr(
            arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ",
            transliteration: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wa a'udhu bika minal-'ajzi wal-kasal, wa a'udhu bika minal-jubni wal-bukhl, wa a'udhu bika min ghalabatid-dayni wa qahrir-rijal",
            translation: "O Allah, I seek refuge in You from worry and sadness, and I seek refuge in You from weakness and laziness, and I seek refuge in You from cowardice and miserliness, and I seek refuge in You from being overcome by debt and overpowered by men.",
            reference: "Bukhari 6369",
            repetitions: 1,
            benefits: "Protection from various spiritual and worldly challenges.",
            category: .morning,
            order: 11
        ))

        // 10. Hasbi Allahu
        adhkar.append(Dhikr(
            arabicText: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
            transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem",
            translation: "Allah is sufficient for me. There is no deity except Him. Upon Him I have relied, and He is the Lord of the Great Throne.",
            reference: "Abu Dawud 5081",
            repetitions: 7,
            benefits: "Whoever says this seven times morning and evening, Allah will suffice him in whatever concerns him.",
            category: .morning,
            order: 12
        ))

        // MARK: Evening Adhkar (same as morning but with evening-specific wording)

        // Copy morning adhkar to evening with updated text where needed
        let eveningAdhkar = [
            Dhikr(
                arabicText: """
                اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
                """,
                transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...",
                translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence...",
                reference: "Quran 2:255",
                repetitions: 1,
                benefits: "Protection throughout the night.",
                category: .evening,
                order: 1
            ),
            Dhikr(
                arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
                transliteration: "Amsayna wa amsal-mulku lillah...",
                translation: "We have entered the evening and with it all dominion belongs to Allah...",
                reference: "Muslim 2723",
                repetitions: 1,
                benefits: "Comprehensive protection for the night.",
                category: .evening,
                order: 2
            )
        ]

        adhkar.append(contentsOf: eveningAdhkar)

        // Add more evening adhkar (similar to morning)
        for order in 3...12 {
            if let morningDhikr = adhkar.first(where: { $0.category == .morning && $0.order == order }) {
                adhkar.append(Dhikr(
                    arabicText: morningDhikr.arabicText,
                    transliteration: morningDhikr.transliteration,
                    translation: morningDhikr.translation,
                    reference: morningDhikr.reference,
                    repetitions: morningDhikr.repetitions,
                    benefits: morningDhikr.benefits,
                    category: .evening,
                    order: order
                ))
            }
        }

        return adhkar
    }
}
