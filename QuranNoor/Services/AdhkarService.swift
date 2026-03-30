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
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private static func loadProgress() -> AdhkarProgress {
        guard let data = UserDefaults.standard.data(forKey: "adhkar_progress"),
              let progress = try? JSONDecoder().decode(AdhkarProgress.self, from: data) else {
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

        // MARK: Evening Adhkar

        // 1. Ayat al-Kursi (same for evening)
        adhkar.append(Dhikr(
            arabicText: """
            اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
            """,
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'a. Wasi'a Kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma. Wa Huwal-'Aliyyul-'Adheem.",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
            reference: "Quran 2:255",
            repetitions: 1,
            benefits: "Protection throughout the night.",
            category: .evening,
            order: 1
        ))

        // 2. Evening remembrance (with Amsayna)
        adhkar.append(Dhikr(
            arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
            transliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer. Rabbi as'aluka khayra ma fi hadhihil-laylati wa khayra ma ba'daha, wa a'udhu bika min sharri ma fi hadhihil-laylati wa sharri ma ba'daha. Rabbi a'udhu bika minal-kasali wa su'il-kibar. Rabbi a'udhu bika min 'adhabin fin-nari wa 'adhabin fil-qabr.",
            translation: "We have entered the evening and with it all dominion belongs to Allah. Praise is to Allah. There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything. My Lord, I ask You for the good of this night and the good that follows it, and I seek refuge in You from the evil of this night and the evil that follows it. My Lord, I seek refuge in You from laziness and helpless old age. My Lord, I seek refuge in You from the punishment of the Fire and the punishment of the grave.",
            reference: "Muslim 2723",
            repetitions: 1,
            benefits: "Comprehensive protection for the night.",
            category: .evening,
            order: 2
        ))

        // 3-5. Quranic surahs (same for evening)
        adhkar.append(Dhikr(
            arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
            transliteration: "Qul Huwa Allahu Ahad, Allahus-Samad, lam yalid wa lam yulad, wa lam yakul-lahu kufuwan ahad.",
            translation: "Say, \"He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.\"",
            reference: "Quran 112:1-4",
            repetitions: 3,
            benefits: "Equivalent to one-third of the Quran. Protection from all harm.",
            category: .evening,
            order: 3
        ))

        adhkar.append(Dhikr(
            arabicText: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِن شَرِّ مَا خَلَقَ، وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
            transliteration: "Qul a'udhu bi Rabbil-falaq, min sharri ma khalaq, wa min sharri ghasiqin idha waqab, wa min sharrin-naffathati fil-'uqad, wa min sharri hasidin idha hasad.",
            translation: "Say, \"I seek refuge in the Lord of daybreak from the evil of that which He created and from the evil of darkness when it settles and from the evil of the blowers in knots and from the evil of an envier when he envies.\"",
            reference: "Quran 113:1-5",
            repetitions: 3,
            benefits: "Protection from evil eye, black magic, and envy.",
            category: .evening,
            order: 4
        ))

        adhkar.append(Dhikr(
            arabicText: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ",
            transliteration: "Qul a'udhu bi Rabbin-nas, Malikin-nas, Ilahin-nas, min sharril-waswasil-khannas, alladhi yuwaswisu fi sudoorin-nas, minal-jinnati wan-nas.",
            translation: "Say, \"I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer - who whispers [evil] into the breasts of mankind - from among the jinn and mankind.\"",
            reference: "Quran 114:1-6",
            repetitions: 3,
            benefits: "Protection from evil whispers and satanic influence.",
            category: .evening,
            order: 5
        ))

        // 6. Evening-specific dua (Amsayna already covered in order 2, skip to shared adhkar)

        // 7. SubhanAllah wa bihamdihi (same for evening)
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa bihamdihi",
            translation: "Glory is to Allah and praise is to Him.",
            reference: "Bukhari 6405, Muslim 2691",
            repetitions: 100,
            benefits: "Whoever says this 100 times in the morning and evening, none will bring better than what he brought except one who does more than that.",
            category: .evening,
            order: 7
        ))

        // 8. La ilaha illallah (same for evening)
        adhkar.append(Dhikr(
            arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer",
            translation: "There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything.",
            reference: "Bukhari 3293, Muslim 2691",
            repetitions: 10,
            benefits: "Whoever says this 10 times will have the reward of freeing four slaves from the children of Isma'il.",
            category: .evening,
            order: 8
        ))

        // 9. SubhanAllah al-Adheem (same for evening)
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahil-'Adheem wa bihamdihi",
            translation: "Glory is to Allah, the Magnificent, and praise is to Him.",
            reference: "Tirmidhi 3467",
            repetitions: 100,
            benefits: "A date-palm tree will be planted for him in Paradise.",
            category: .evening,
            order: 9
        ))

        // 10. Astaghfirullah (same for evening)
        adhkar.append(Dhikr(
            arabicText: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
            transliteration: "Astaghfirullaha wa atubu ilayh",
            translation: "I seek forgiveness from Allah and repent to Him.",
            reference: "Bukhari 6307",
            repetitions: 100,
            benefits: "The Prophet ﷺ used to seek forgiveness 100 times a day.",
            category: .evening,
            order: 10
        ))

        // 11. Seeking Allah's protection (same for evening)
        adhkar.append(Dhikr(
            arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ",
            transliteration: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wa a'udhu bika minal-'ajzi wal-kasal, wa a'udhu bika minal-jubni wal-bukhl, wa a'udhu bika min ghalabatid-dayni wa qahrir-rijal",
            translation: "O Allah, I seek refuge in You from worry and sadness, and I seek refuge in You from weakness and laziness, and I seek refuge in You from cowardice and miserliness, and I seek refuge in You from being overcome by debt and overpowered by men.",
            reference: "Bukhari 6369",
            repetitions: 1,
            benefits: "Protection from various spiritual and worldly challenges.",
            category: .evening,
            order: 11
        ))

        // 12. Hasbi Allahu (same for evening)
        adhkar.append(Dhikr(
            arabicText: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
            transliteration: "Hasbiyallahu la ilaha illa Huwa 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Adheem",
            translation: "Allah is sufficient for me. There is no deity except Him. Upon Him I have relied, and He is the Lord of the Great Throne.",
            reference: "Abu Dawud 5081",
            repetitions: 7,
            benefits: "Whoever says this seven times morning and evening, Allah will suffice him in whatever concerns him.",
            category: .evening,
            order: 12
        ))

        // MARK: After Prayer Adhkar

        // 1. Astaghfirullah (3 times)
        adhkar.append(Dhikr(
            arabicText: "أَسْتَغْفِرُ اللَّهَ",
            transliteration: "Astaghfirullah",
            translation: "I seek forgiveness from Allah.",
            reference: "Muslim 591",
            repetitions: 3,
            benefits: "Seeking forgiveness immediately after completing the prayer.",
            category: .afterPrayer,
            order: 1
        ))

        // 2. Allahumma antas-Salam
        adhkar.append(Dhikr(
            arabicText: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ",
            transliteration: "Allahumma antas-Salam wa minkas-Salam, tabarakta ya Dhal-Jalali wal-Ikram",
            translation: "O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Glory and Honor.",
            reference: "Muslim 591",
            repetitions: 1,
            benefits: "The Prophet ﷺ used to say this after every prayer before turning to face the congregation.",
            category: .afterPrayer,
            order: 2
        ))

        // 3. After-prayer tasbih
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ (٣٣) وَالْحَمْدُ لِلَّهِ (٣٣) وَاللَّهُ أَكْبَرُ (٣٣) لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            transliteration: "SubhanAllah (33), Alhamdulillah (33), Allahu Akbar (33), La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer",
            translation: "Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (33 times), then say: There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything.",
            reference: "Muslim 597",
            repetitions: 1,
            benefits: "Whoever glorifies Allah after every prayer 33 times, praises Allah 33 times, and magnifies Allah 33 times - that is 99 - then completes 100 by saying La ilaha illallah, his sins will be forgiven even if they are like the foam of the sea.",
            category: .afterPrayer,
            order: 3
        ))

        // 4. Ayat al-Kursi after every fard prayer
        adhkar.append(Dhikr(
            arabicText: """
            اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
            """,
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'a. Wasi'a Kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma. Wa Huwal-'Aliyyul-'Adheem.",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
            reference: "Quran 2:255 - An-Nasa'i",
            repetitions: 1,
            benefits: "Whoever recites Ayat al-Kursi after every obligatory prayer, nothing prevents him from entering Paradise except death.",
            category: .afterPrayer,
            order: 4
        ))

        // 5. La ilaha illallahu wahdahu
        adhkar.append(Dhikr(
            arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
            transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadeer",
            translation: "There is no deity except Allah, alone, without any partners. To Him belongs the Kingdom, and to Him is all praise, and He has power over everything.",
            reference: "Muslim 593",
            repetitions: 1,
            benefits: "Said after every obligatory prayer as reported by the Prophet ﷺ.",
            category: .afterPrayer,
            order: 5
        ))

        // MARK: Before Sleep Adhkar

        // 1. Ayat al-Kursi before sleep
        adhkar.append(Dhikr(
            arabicText: """
            اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
            """,
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'a. Wasi'a Kursiyyuhus-samawati wal-ard, wa la ya'uduhu hifdhuhuma. Wa Huwal-'Aliyyul-'Adheem.",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
            reference: "Quran 2:255 - Bukhari 2311",
            repetitions: 1,
            benefits: "If you recite it before sleeping, a guardian from Allah will protect you all night, and no devil will come near you until morning.",
            category: .beforeSleep,
            order: 1
        ))

        // 2. Al-Ikhlas, Al-Falaq, An-Nas before sleep
        adhkar.append(Dhikr(
            arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ... قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ... قُلْ أَعُوذُ بِرَبِّ النَّاسِ",
            transliteration: "Qul Huwa Allahu Ahad... Qul a'udhu bi Rabbil-falaq... Qul a'udhu bi Rabbin-nas",
            translation: "Recite Surah Al-Ikhlas, Al-Falaq, and An-Nas, then blow into your cupped hands and wipe over as much of your body as you can, starting with the head and face.",
            reference: "Bukhari 5017",
            repetitions: 3,
            benefits: "The Prophet ﷺ used to do this every night before sleeping. Blow into your hands and wipe over your body.",
            category: .beforeSleep,
            order: 2
        ))

        // 3. Bismika Allahumma amutu wa ahya
        adhkar.append(Dhikr(
            arabicText: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            transliteration: "Bismika Allahumma amutu wa ahya",
            translation: "In Your name, O Allah, I die and I live.",
            reference: "Bukhari 6312",
            repetitions: 1,
            benefits: "The Prophet ﷺ used to say this when going to sleep, and upon waking he would say: Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur.",
            category: .beforeSleep,
            order: 3
        ))

        // 4. Tasbih before sleep
        adhkar.append(Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ (٣٣) وَالْحَمْدُ لِلَّهِ (٣٣) وَاللَّهُ أَكْبَرُ (٣٤)",
            transliteration: "SubhanAllah (33), Alhamdulillah (33), Allahu Akbar (34)",
            translation: "Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times).",
            reference: "Bukhari 5362",
            repetitions: 1,
            benefits: "When Fatimah asked the Prophet ﷺ for a servant, he told her and Ali to say this before sleeping, saying it would be better for them than a servant.",
            category: .beforeSleep,
            order: 4
        ))

        // 5. Dua for protection before sleep
        adhkar.append(Dhikr(
            arabicText: "اللَّهُمَّ إِنِّي أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَنَبِيِّكَ الَّذِي أَرْسَلْتَ",
            transliteration: "Allahumma inni aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu dhahri ilayk, raghbatan wa rahbatan ilayk, la malja'a wa la manja minka illa ilayk, amantu bi kitabikal-ladhi anzalt, wa nabiyyikal-ladhi arsalt",
            translation: "O Allah, I have submitted myself to You, entrusted my affairs to You, turned my face to You, and laid myself down depending on You, hoping in You and fearing You. There is no refuge and no escape from You except to You. I believe in Your Book which You have revealed, and Your Prophet whom You have sent.",
            reference: "Bukhari 6313, Muslim 2710",
            repetitions: 1,
            benefits: "The Prophet ﷺ said: If you die that night, you will die upon the fitrah (natural disposition). Make these the last words you say before sleeping.",
            category: .beforeSleep,
            order: 5
        ))

        return adhkar
    }
}
