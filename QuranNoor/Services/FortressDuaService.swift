//
//  FortressDuaService.swift
//  QuranNoor
//
//  Service for managing Fortress of the Muslim duas
//

import Foundation
import Observation

@Observable
final class FortressDuaService {
    // MARK: - Properties

    private(set) var allDuas: [FortressDua] = []
    private(set) var progress: DuaProgress

    private let progressKey = "fortress_dua_progress"

    // MARK: - Initialization

    init() {
        self.progress = Self.loadProgress()
        self.allDuas = Self.createDuaDatabase()
    }

    // MARK: - Public Methods

    /// Get all duas for a category
    func getDuas(for category: DuaCategory) -> [FortressDua] {
        allDuas.filter { $0.category == category }
            .sorted { $0.order < $1.order }
    }

    /// Get all categories with dua counts
    func getCategoriesWithCount() -> [(category: DuaCategory, count: Int)] {
        DuaCategory.allCases.map { category in
            let count = allDuas.filter { $0.category == category }.count
            return (category, count)
        }
    }

    /// Get favorite duas
    func getFavoriteDuas() -> [FortressDua] {
        allDuas.filter { progress.isFavorite(duaId: $0.id) }
            .sorted { $0.order < $1.order }
    }

    /// Get most used duas
    func getMostUsedDuas(limit: Int = 5) -> [FortressDua] {
        let mostUsedIds = progress.getMostUsed(limit: limit)
        return allDuas.filter { mostUsedIds.contains($0.id) }
            .sorted {
                let count1 = progress.getUsageCount(duaId: $0.id)
                let count2 = progress.getUsageCount(duaId: $1.id)
                return count1 > count2
            }
    }

    /// Search duas
    func searchDuas(query: String) -> [FortressDua] {
        guard !query.isEmpty else { return allDuas }

        let lowercasedQuery = query.lowercased()
        return allDuas.filter { dua in
            dua.title.lowercased().contains(lowercasedQuery) ||
            dua.translation.lowercased().contains(lowercasedQuery) ||
            dua.occasion.lowercased().contains(lowercasedQuery) ||
            dua.transliteration.lowercased().contains(lowercasedQuery)
        }.sorted { $0.order < $1.order }
    }

    /// Toggle favorite
    func toggleFavorite(duaId: UUID) {
        progress.toggleFavorite(duaId: duaId)
        saveProgress()
    }

    /// Increment usage
    func incrementUsage(duaId: UUID) {
        progress.incrementUsage(duaId: duaId)
        saveProgress()
    }

    /// Check if favorite
    func isFavorite(duaId: UUID) -> Bool {
        progress.isFavorite(duaId: duaId)
    }

    // MARK: - Private Methods

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private static func loadProgress() -> DuaProgress {
        guard let data = UserDefaults.standard.data(forKey: "fortress_dua_progress"),
              let progress = try? JSONDecoder().decode(DuaProgress.self, from: data) else {
            return DuaProgress()
        }
        return progress
    }

    // MARK: - Dua Database

    private static func createDuaDatabase() -> [FortressDua] {
        var duas: [FortressDua] = []

        // MARK: - Upon Waking

        duas.append(FortressDua(
            category: .waking,
            title: "Upon Waking Up",
            arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
            transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
            translation: "All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.",
            reference: "Bukhari 6312",
            occasion: "When waking up from sleep",
            benefits: "Expressing gratitude for being granted another day.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .waking,
            title: "Wiping Sleep from Face",
            arabicText: "الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ",
            transliteration: "Alhamdu lillahil-ladhi 'afani fi jasadi, wa radda 'alayya ruhi, wa adhina li bidhikrihi",
            translation: "All praise is for Allah who restored to me my health and returned my soul and has allowed me to remember Him.",
            reference: "Tirmidhi 3401",
            occasion: "Upon wiping sleep from the face",
            order: 2
        ))

        // MARK: - Wearing Clothes

        duas.append(FortressDua(
            category: .dressing,
            title: "Wearing New Clothes",
            arabicText: "اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ",
            transliteration: "Allahumma lakal-hamdu anta kasawtanih, as'aluka min khayrihi wa khayri ma suni'a lah, wa a'udhu bika min sharrihi wa sharri ma suni'a lah",
            translation: "O Allah, for You is all praise, You have clothed me with it, I ask You for the good of it and the good for which it was made, and I seek refuge in You from the evil of it and the evil for which it was made.",
            reference: "Abu Dawud 4020, Tirmidhi 1767",
            occasion: "When wearing new clothes",
            benefits: "Seeking protection and blessing in new possessions.",
            order: 1
        ))

        // MARK: - Entering/Leaving Home

        duas.append(FortressDua(
            category: .entering_leaving_home,
            title: "Leaving Home",
            arabicText: "بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
            transliteration: "Bismillah, tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah",
            translation: "In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.",
            reference: "Abu Dawud 5095, Tirmidhi 3426",
            occasion: "When leaving your home",
            benefits: "Allah will say: You are guided, defended and protected. The devils will go far from him.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .entering_leaving_home,
            title: "Entering Home",
            arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلَجِ وَخَيْرَ الْمَخْرَجِ، بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا",
            transliteration: "Allahumma inni as'aluka khayral-mawlaji wa khayral-makhraji, bismillahi walajná, wa bismillahi kharajná, wa 'alallahi rabbina tawakkalna",
            translation: "O Allah, I ask You for the best entering and the best exiting. In the name of Allah we enter, in the name of Allah we exit, and upon Allah, our Lord, we depend.",
            reference: "Abu Dawud 5096",
            occasion: "When entering your home",
            benefits: "Protection and blessings upon entering the home.",
            order: 2
        ))

        // MARK: - Mosque

        duas.append(FortressDua(
            category: .mosque,
            title: "Going to Mosque",
            arabicText: "اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي لِسَانِي نُورًا، وَاجْعَلْ فِي سَمْعِي نُورًا، وَاجْعَلْ فِي بَصَرِي نُورًا، وَاجْعَلْ مِنْ خَلْفِي نُورًا، وَمِنْ أَمَامِي نُورًا، وَاجْعَلْ مِنْ فَوْقِي نُورًا، وَمِنْ تَحْتِي نُورًا، اللَّهُمَّ أَعْطِنِي نُورًا",
            transliteration: "Allahumma ij'al fi qalbi nura, wa fi lisani nura, waj'al fi sam'i nura, waj'al fi basari nura, waj'al min khalfi nura, wa min amami nura, waj'al min fawqi nura, wa min tahti nura. Allahumma a'tini nura",
            translation: "O Allah, place light in my heart, light in my tongue, light in my hearing, light in my sight, light behind me, light in front of me, light above me, and light below me. O Allah, grant me light.",
            reference: "Bukhari 6316, Muslim 763",
            occasion: "When going to the mosque",
            benefits: "Seeking spiritual enlightenment and guidance.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .mosque,
            title: "Entering Mosque",
            arabicText: "أَعُوذُ بِاللَّهِ الْعَظِيمِ، وَبِوَجْهِهِ الْكَرِيمِ، وَسُلْطَانِهِ الْقَدِيمِ، مِنَ الشَّيْطَانِ الرَّجِيمِ",
            transliteration: "A'udhu billahil-'Adhim, wa biwajhihil-Karim, wa sultanihil-qadim, minash-Shaytanir-rajim",
            translation: "I seek refuge in Allah the Magnificent, in His Noble Face, and His Eternal Authority from the accursed Satan.",
            reference: "Abu Dawud 466",
            occasion: "When entering the mosque",
            benefits: "Satan says: He has been protected from me for the whole day.",
            order: 2
        ))

        // MARK: - Prayer Duas

        duas.append(FortressDua(
            category: .prayer,
            title: "Opening Dua",
            arabicText: "اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ، كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنْ خَطَايَايَ كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْنِي مِنْ خَطَايَايَ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ",
            transliteration: "Allahumma ba'id bayni wa bayna khatayaya kama ba'adta baynal-mashriqi wal-maghrib. Allahumma naqqini min khatayaya kama yunaqqa ath-thawbul-abyadu minad-danas. Allahumma ighsilni min khatayaya bil-ma'i wath-thalji wal-barad",
            translation: "O Allah, separate me from my sins as You have separated the East from the West. O Allah, cleanse me of my transgressions as the white garment is cleansed of stains. O Allah, wash away my sins with water, ice and snow.",
            reference: "Bukhari 744, Muslim 598",
            occasion: "After opening takbir in prayer",
            benefits: "Seeking forgiveness before standing before Allah.",
            order: 1
        ))

        // MARK: - Eating & Drinking

        duas.append(FortressDua(
            category: .eating_drinking,
            title: "Before Eating",
            arabicText: "بِسْمِ اللَّهِ",
            transliteration: "Bismillah",
            translation: "In the name of Allah.",
            reference: "Bukhari 5376, Muslim 2017",
            occasion: "Before eating or drinking",
            benefits: "Satan cannot partake in the meal when Allah's name is mentioned.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .eating_drinking,
            title: "After Eating",
            arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ، مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ",
            transliteration: "Alhamdu lillahil-ladhi at'amani hadha, wa razaqanihi, min ghayri hawlin minni wa la quwwah",
            translation: "All praise is for Allah who fed me this and provided it for me without any might nor power from myself.",
            reference: "Abu Dawud 4023, Tirmidhi 3458",
            occasion: "After finishing a meal",
            benefits: "Your past sins will be forgiven.",
            order: 2
        ))

        // MARK: - Travel

        duas.append(FortressDua(
            category: .travel,
            title: "Travel Dua",
            arabicText: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ",
            transliteration: "Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun",
            translation: "Glory is to Him who has subjected this to us, and we could never have it by our efforts. Surely, unto our Lord we are returning.",
            reference: "Abu Dawud 2602, Tirmidhi 3446",
            occasion: "When embarking on a journey",
            benefits: "Protection during travel and acknowledgment of Allah's blessings.",
            order: 1
        ))

        // MARK: - Sleep

        duas.append(FortressDua(
            category: .sleep,
            title: "Before Sleep",
            arabicText: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            transliteration: "Bismika Allahumma amutu wa ahya",
            translation: "In Your name O Allah, I die and I live.",
            reference: "Bukhari 6312",
            occasion: "Before going to sleep",
            benefits: "Acknowledging Allah before sleep, which is like a minor death.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .sleep,
            title: "Ayat al-Kursi Before Sleep",
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...",
            transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...",
            translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence...",
            reference: "Bukhari 2311",
            occasion: "Before sleeping",
            benefits: "A guardian from Allah will be with you and Satan will not come near you until morning.",
            order: 2
        ))

        // MARK: - Sickness & Healing

        duas.append(FortressDua(
            category: .sickness,
            title: "Dua for Healing",
            arabicText: "اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا",
            transliteration: "Allahumma Rabban-nas, adh-hibil-ba's, ishfi Antash-Shafi, la shifa'a illa shifa'uk, shifa'an la yughadiru saqama",
            translation: "O Allah, Lord of mankind, remove the harm, cure him, for You are the Healer. There is no cure except Your cure, a cure that leaves no sickness.",
            reference: "Bukhari 5675, Muslim 2191",
            occasion: "When someone is sick",
            benefits: "Seeking Allah's healing for the sick person.",
            order: 1
        ))

        // MARK: - Times of Distress

        duas.append(FortressDua(
            category: .distress,
            title: "Dua for Anxiety",
            arabicText: "اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ سَمَّيْتَ بِهِ نَفْسَكَ، أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ، أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ، أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي",
            transliteration: "Allahumma inni 'abduka, ibnu 'abdika, ibnu amatika, nasiyati biyadika, madin fiyya hukmuka, 'adlun fiyya qada'uka, as'aluka bikulli ismin huwa laka sammayta bihi nafsaka, aw anzaltahu fi kitabika, aw 'allamtahu ahadan min khalqika, awista'tharta bihi fi 'ilmil-ghaybi 'indaka, an taj'alal-Qur'ana rabi'a qalbi, wa nura sadri, wa jala'a huzni, wa dhahaba hammi",
            translation: "O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand. Your command over me is forever executed and Your decree over me is just. I ask You by every name belonging to You which You have named Yourself with, or revealed in Your Book, or taught to any of Your creation, or have preserved in the knowledge of the unseen with You, that You make the Quran the life of my heart and the light of my breast, and a departure for my sorrow and a release for my anxiety.",
            reference: "Ahmad 3712",
            occasion: "During times of worry and distress",
            benefits: "Allah will remove worries and replace them with happiness.",
            order: 1
        ))

        // MARK: - Gratitude

        duas.append(FortressDua(
            category: .gratitude,
            title: "Gratitude for Blessings",
            arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
            transliteration: "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatika",
            translation: "O Allah, help me remember You, to be grateful to You, and to worship You in an excellent manner.",
            reference: "Abu Dawud 1522",
            occasion: "Seeking help in gratitude",
            benefits: "Strengthening one's ability to be grateful and worship properly.",
            order: 1
        ))

        // MARK: - General Supplications

        duas.append(FortressDua(
            category: .general,
            title: "Master of Supplications",
            arabicText: "اللَّهُمَّ أَنْتَ رَبِّي، لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
            transliteration: "Allahumma anta Rabbi, la ilaha illa Anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya wa abu'u bidhanbi, faghfir li fa-innahu la yaghfirudh-dhunuba illa Anta",
            translation: "O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of which I have committed. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for verily none can forgive sin except You.",
            reference: "Bukhari 6306",
            occasion: "Best dua for seeking forgiveness (Sayyidul-Istighfar)",
            benefits: "Whoever says it during the day with firm faith and dies on that day will enter Paradise. Same for night.",
            order: 1
        ))

        duas.append(FortressDua(
            category: .general,
            title: "For Good in Both Worlds",
            arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
            transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
            translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.",
            reference: "Quran 2:201",
            occasion: "General comprehensive dua",
            benefits: "The Prophet ﷺ used to say this dua most often.",
            order: 2
        ))

        return duas
    }
}
