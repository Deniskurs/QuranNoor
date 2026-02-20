//
//  NamesOfAllahService.swift
//  QuranNoor
//
//  Service for managing the 99 Names of Allah (Asma ul Husna)
//

import Foundation
import Observation

@Observable
@MainActor
final class NamesOfAllahService {
    // MARK: - Cached Codecs (Performance: avoid repeated allocation)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Properties

    private(set) var allNames: [NameOfAllah] = []
    private(set) var progress: NamesProgress

    private let progressKey = "names_of_allah_progress"

    // MARK: - Initialization

    init() {
        self.progress = Self.loadProgress()
        self.allNames = Self.createNamesDatabase()
    }

    // MARK: - Public Methods

    /// Get all names
    func getAllNames() -> [NameOfAllah] {
        allNames.sorted { $0.number < $1.number }
    }

    /// Get favorite names
    func getFavoriteNames() -> [NameOfAllah] {
        allNames.filter { progress.isFavorite(number: $0.number) }
            .sorted { $0.number < $1.number }
    }

    /// Get learned names
    func getLearnedNames() -> [NameOfAllah] {
        allNames.filter { progress.isLearned(number: $0.number) }
            .sorted { $0.number < $1.number }
    }

    /// Search names
    func searchNames(query: String) -> [NameOfAllah] {
        guard !query.isEmpty else { return getAllNames() }

        let lowercasedQuery = query.lowercased()
        return allNames.filter { name in
            name.transliteration.lowercased().contains(lowercasedQuery) ||
            name.translation.lowercased().contains(lowercasedQuery) ||
            name.meaning.lowercased().contains(lowercasedQuery) ||
            name.arabicName.contains(query)
        }.sorted { $0.number < $1.number }
    }

    /// Toggle favorite status
    func toggleFavorite(number: Int) {
        progress.toggleFavorite(number: number)
        saveProgress()
    }

    /// Mark as learned
    func markAsLearned(number: Int) {
        progress.markAsLearned(number: number)
        saveProgress()
    }

    /// Check if favorite
    func isFavorite(number: Int) -> Bool {
        progress.isFavorite(number: number)
    }

    /// Check if learned
    func isLearned(number: Int) -> Bool {
        progress.isLearned(number: number)
    }

    // MARK: - Private Methods

    private func saveProgress() {
        if let encoded = try? Self.encoder.encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private static func loadProgress() -> NamesProgress {
        guard let data = UserDefaults.standard.data(forKey: "names_of_allah_progress"),
              let progress = try? decoder.decode(NamesProgress.self, from: data) else {
            return NamesProgress()
        }
        return progress
    }

    // MARK: - Names Database

    private static func createNamesDatabase() -> [NameOfAllah] {
        return [
            // 1-10
            NameOfAllah(number: 1, arabicName: "الرَّحْمَنُ", transliteration: "Ar-Rahman", translation: "The Most Merciful", meaning: "The One who has plenty of mercy for the believers and the disbelievers in this world and especially for the believers in the hereafter.", benefit: "Recite 100 times after Fajr prayer for opening the heart to Allah's mercy."),

            NameOfAllah(number: 2, arabicName: "الرَّحِيمُ", transliteration: "Ar-Rahim", translation: "The Most Compassionate", meaning: "The One who has plenty of mercy for the believers.", benefit: "Recite 100 times for mercy in all affairs."),

            NameOfAllah(number: 3, arabicName: "الْمَلِكُ", transliteration: "Al-Malik", translation: "The King", meaning: "The One with the complete Dominion, the One whose Dominion is clear from imperfection.", benefit: "Recite 100 times for respect and honor."),

            NameOfAllah(number: 4, arabicName: "الْقُدُّوسُ", transliteration: "Al-Quddus", translation: "The Most Holy", meaning: "The One who is pure from any imperfection and clear from children and adversaries.", benefit: "Recite frequently for purification of the heart."),

            NameOfAllah(number: 5, arabicName: "السَّلاَمُ", transliteration: "As-Salam", translation: "The Source of Peace", meaning: "The One who is free from every imperfection.", benefit: "Recite for peace of mind and heart."),

            NameOfAllah(number: 6, arabicName: "الْمُؤْمِنُ", transliteration: "Al-Mu'min", translation: "The Granter of Security", meaning: "The One who witnessed for Himself that no one is God but Him, and witnessed for His believers that they are truthful in their belief that no one is God but Him.", benefit: "Recite for safety and security."),

            NameOfAllah(number: 7, arabicName: "الْمُهَيْمِنُ", transliteration: "Al-Muhaymin", translation: "The Guardian", meaning: "The One who witnesses the saying and deeds of His creatures.", benefit: "Recite for divine protection."),

            NameOfAllah(number: 8, arabicName: "الْعَزِيزُ", transliteration: "Al-Aziz", translation: "The Almighty", meaning: "The Defeater who is not defeated.", benefit: "Recite 41 times daily for strength and honor."),

            NameOfAllah(number: 9, arabicName: "الْجَبَّارُ", transliteration: "Al-Jabbar", translation: "The Compeller", meaning: "The One that nothing happens in His Dominion except that which He willed.", benefit: "Recite for overcoming difficulties."),

            NameOfAllah(number: 10, arabicName: "الْمُتَكَبِّرُ", transliteration: "Al-Mutakabbir", translation: "The Supreme", meaning: "The One who is clear from the attributes of the creatures and from resembling them.", benefit: "Recite for self-purification from arrogance."),

            // 11-20
            NameOfAllah(number: 11, arabicName: "الْخَالِقُ", transliteration: "Al-Khaliq", translation: "The Creator", meaning: "The One who brings everything from non-existence to existence.", benefit: "Recite for creativity and innovation."),

            NameOfAllah(number: 12, arabicName: "الْبَارِئُ", transliteration: "Al-Bari", translation: "The Evolver", meaning: "The Maker of the soul.", benefit: "Recite for relief from grief."),

            NameOfAllah(number: 13, arabicName: "الْمُصَوِّرُ", transliteration: "Al-Musawwir", translation: "The Fashioner", meaning: "The One who forms His creatures in different pictures.", benefit: "Recite during pregnancy for a healthy child."),

            NameOfAllah(number: 14, arabicName: "الْغَفَّارُ", transliteration: "Al-Ghaffar", translation: "The Oft-Forgiving", meaning: "The Forgiver of sins again and again.", benefit: "Recite after each prayer for forgiveness."),

            NameOfAllah(number: 15, arabicName: "الْقَهَّارُ", transliteration: "Al-Qahhar", translation: "The Subduer", meaning: "The Dominant One who has the perfect Power and is not unable over anything.", benefit: "Recite for victory over enemies."),

            NameOfAllah(number: 16, arabicName: "الْوَهَّابُ", transliteration: "Al-Wahhab", translation: "The Bestower", meaning: "The One who is Generous in giving plenty without any return.", benefit: "Recite 40 times for sustenance."),

            NameOfAllah(number: 17, arabicName: "الرَّزَّاقُ", transliteration: "Ar-Razzaq", translation: "The Provider", meaning: "The One who creates all things that are beneficial.", benefit: "Recite for increase in provision."),

            NameOfAllah(number: 18, arabicName: "الْفَتَّاحُ", transliteration: "Al-Fattah", translation: "The Opener", meaning: "The One who opens for His slaves the closed worldly and religious matters.", benefit: "Recite for opening of doors."),

            NameOfAllah(number: 19, arabicName: "اَلْعَلِيْمُ", transliteration: "Al-Alim", translation: "The All-Knowing", meaning: "The One who knows everything.", benefit: "Recite for increase in knowledge."),

            NameOfAllah(number: 20, arabicName: "الْقَابِضُ", transliteration: "Al-Qabid", translation: "The Withholder", meaning: "The One who constricts the sustenance by His wisdom.", benefit: "Recite for patience in hardship."),

            // 21-30
            NameOfAllah(number: 21, arabicName: "الْبَاسِطُ", transliteration: "Al-Basit", translation: "The Extender", meaning: "The One who expands and widens.", benefit: "Recite for expansion in rizq."),

            NameOfAllah(number: 22, arabicName: "الْخَافِضُ", transliteration: "Al-Khafid", translation: "The Reducer", meaning: "The One who lowers whoever He willed by His Destruction.", benefit: "Recite for humility."),

            NameOfAllah(number: 23, arabicName: "الرَّافِعُ", transliteration: "Ar-Rafi", translation: "The Exalter", meaning: "The One who raises the believers by His endowment.", benefit: "Recite for elevation in status."),

            NameOfAllah(number: 24, arabicName: "الْمُعِزُّ", transliteration: "Al-Mu'izz", translation: "The Honorer", meaning: "The One who gives glory to whoever He willed.", benefit: "Recite for honor and dignity."),

            NameOfAllah(number: 25, arabicName: "المُذِلُّ", transliteration: "Al-Mudhill", translation: "The Dishonorer", meaning: "The One who degrades the pretender who does not deserve honor.", benefit: "Recite for humility before Allah."),

            NameOfAllah(number: 26, arabicName: "السَّمِيعُ", transliteration: "As-Sami", translation: "The All-Hearing", meaning: "The One who hears all voices and sounds.", benefit: "Recite for acceptance of prayers."),

            NameOfAllah(number: 27, arabicName: "الْبَصِيرُ", transliteration: "Al-Basir", translation: "The All-Seeing", meaning: "The One who sees all that is seen.", benefit: "Recite for spiritual vision."),

            NameOfAllah(number: 28, arabicName: "الْحَكَمُ", transliteration: "Al-Hakam", translation: "The Judge", meaning: "The One who judges between His servants.", benefit: "Recite for justice in matters."),

            NameOfAllah(number: 29, arabicName: "الْعَدْلُ", transliteration: "Al-Adl", translation: "The Just", meaning: "The One who is Just in His judgement.", benefit: "Recite for fairness."),

            NameOfAllah(number: 30, arabicName: "اللَّطِيفُ", transliteration: "Al-Latif", translation: "The Subtle One", meaning: "The One who is kind to His slaves and endows upon them.", benefit: "Recite for gentleness in affairs."),

            // 31-40
            NameOfAllah(number: 31, arabicName: "الْخَبِيرُ", transliteration: "Al-Khabir", translation: "The All-Aware", meaning: "The One who knows the truth of things.", benefit: "Recite for awareness of truth."),

            NameOfAllah(number: 32, arabicName: "الْحَلِيمُ", transliteration: "Al-Halim", translation: "The Forbearing", meaning: "The One who delays the punishment for those who deserve it.", benefit: "Recite for patience and tolerance."),

            NameOfAllah(number: 33, arabicName: "الْعَظِيمُ", transliteration: "Al-Azim", translation: "The Magnificent", meaning: "The One deserving the attributes of Exaltment, Glory, Extolement, and Purity.", benefit: "Recite for greatness of character."),

            NameOfAllah(number: 34, arabicName: "الْغَفُورُ", transliteration: "Al-Ghafur", translation: "The Great Forgiver", meaning: "The One who forgives the sins of His slaves.", benefit: "Recite constantly for forgiveness."),

            NameOfAllah(number: 35, arabicName: "الشَّكُورُ", transliteration: "Ash-Shakur", translation: "The Appreciative", meaning: "The One who gives a lot of reward for a little obedience.", benefit: "Recite for gratitude."),

            NameOfAllah(number: 36, arabicName: "الْعَلِيُّ", transliteration: "Al-Ali", translation: "The Most High", meaning: "The One who is clear from the attributes of the creatures.", benefit: "Recite for spiritual elevation."),

            NameOfAllah(number: 37, arabicName: "الْكَبِيرُ", transliteration: "Al-Kabir", translation: "The Most Great", meaning: "The One who is greater than everything in status.", benefit: "Recite for magnanimity."),

            NameOfAllah(number: 38, arabicName: "الْحَفِيظُ", transliteration: "Al-Hafiz", translation: "The Preserver", meaning: "The One who protects whatever He willed.", benefit: "Recite for protection."),

            NameOfAllah(number: 39, arabicName: "المُقيِت", transliteration: "Al-Muqit", translation: "The Sustainer", meaning: "The One who has the Power.", benefit: "Recite for sustenance."),

            NameOfAllah(number: 40, arabicName: "الْحسِيبُ", transliteration: "Al-Hasib", translation: "The Reckoner", meaning: "The One who gives the satisfaction.", benefit: "Recite for sufficiency."),

            // 41-50
            NameOfAllah(number: 41, arabicName: "الْجَلِيلُ", transliteration: "Al-Jalil", translation: "The Majestic", meaning: "The One who is attributed with greatness of Power and Glory of status.", benefit: "Recite for majesty of character."),

            NameOfAllah(number: 42, arabicName: "الْكَرِيمُ", transliteration: "Al-Karim", translation: "The Generous", meaning: "The One who is clear from abjectness.", benefit: "Recite 41 times for honor."),

            NameOfAllah(number: 43, arabicName: "الرَّقِيبُ", transliteration: "Ar-Raqib", translation: "The Watchful", meaning: "The One that nothing is absent from Him.", benefit: "Recite for awareness of Allah's watch."),

            NameOfAllah(number: 44, arabicName: "الْمُجِيبُ", transliteration: "Al-Mujib", translation: "The Responsive", meaning: "The One who answers the one in need if he asks Him.", benefit: "Recite for answered prayers."),

            NameOfAllah(number: 45, arabicName: "الْوَاسِعُ", transliteration: "Al-Wasi", translation: "The All-Encompassing", meaning: "The Knowledgeable; The One whose knowledge is all-encompassing.", benefit: "Recite for expansion in knowledge."),

            NameOfAllah(number: 46, arabicName: "الْحَكِيمُ", transliteration: "Al-Hakim", translation: "The Wise", meaning: "The One who is correct in His doings.", benefit: "Recite 100 times for wisdom."),

            NameOfAllah(number: 47, arabicName: "الْوَدُودُ", transliteration: "Al-Wadud", translation: "The Loving", meaning: "The One who loves His believing slaves.", benefit: "Recite for love between people."),

            NameOfAllah(number: 48, arabicName: "الْمَجِيدُ", transliteration: "Al-Majid", translation: "The Glorious", meaning: "The One who is with perfect Power, High Status, Compassion, Generosity and Kindness.", benefit: "Recite for glory."),

            NameOfAllah(number: 49, arabicName: "الْبَاعِثُ", transliteration: "Al-Ba'ith", translation: "The Resurrector", meaning: "The One who resurrects His slaves after death for reward and/or punishment.", benefit: "Recite for remembrance of afterlife."),

            NameOfAllah(number: 50, arabicName: "الشَّهِيدُ", transliteration: "Ash-Shahid", translation: "The Witness", meaning: "The One from whom nothing is absent.", benefit: "Recite for truthfulness."),

            // 51-60
            NameOfAllah(number: 51, arabicName: "الْحَقُّ", transliteration: "Al-Haqq", translation: "The Truth", meaning: "The One who truly exists.", benefit: "Recite for guidance to truth."),

            NameOfAllah(number: 52, arabicName: "الْوَكِيلُ", transliteration: "Al-Wakil", translation: "The Trustee", meaning: "The One who gives the satisfaction and is relied upon.", benefit: "Recite for tawakkul."),

            NameOfAllah(number: 53, arabicName: "الْقَوِيُّ", transliteration: "Al-Qawiyy", translation: "The Strong", meaning: "The One with the complete Power.", benefit: "Recite for strength."),

            NameOfAllah(number: 54, arabicName: "الْمَتِينُ", transliteration: "Al-Matin", translation: "The Firm", meaning: "The One with extreme Power which is un-interrupted and He does not get tired.", benefit: "Recite for steadfastness."),

            NameOfAllah(number: 55, arabicName: "الْوَلِيُّ", transliteration: "Al-Waliyy", translation: "The Protecting Friend", meaning: "The Supporter, The Friend of Believers.", benefit: "Recite for divine friendship."),

            NameOfAllah(number: 56, arabicName: "الْحَمِيدُ", transliteration: "Al-Hamid", translation: "The Praiseworthy", meaning: "The praised One who deserves to be praised.", benefit: "Recite for gaining praise."),

            NameOfAllah(number: 57, arabicName: "الْمُحْصِي", transliteration: "Al-Muhsi", translation: "The Reckoner", meaning: "The One who the count of things are known to Him.", benefit: "Recite for accountability."),

            NameOfAllah(number: 58, arabicName: "الْمُبْدِئُ", transliteration: "Al-Mubdi", translation: "The Originator", meaning: "The One who started the human being.", benefit: "Recite for new beginnings."),

            NameOfAllah(number: 59, arabicName: "الْمُعِيدُ", transliteration: "Al-Mu'id", translation: "The Restorer", meaning: "The One who brings back the creatures after death.", benefit: "Recite for restoration."),

            NameOfAllah(number: 60, arabicName: "الْمُحْيِي", transliteration: "Al-Muhyi", translation: "The Giver of Life", meaning: "The One who took out a living human from semen that does not have a soul.", benefit: "Recite for vitality."),

            // 61-70
            NameOfAllah(number: 61, arabicName: "اَلْمُمِيتُ", transliteration: "Al-Mumit", translation: "The Bringer of Death", meaning: "The One who renders the living dead.", benefit: "Recite for remembrance of death."),

            NameOfAllah(number: 62, arabicName: "الْحَيُّ", transliteration: "Al-Hayy", translation: "The Ever-Living", meaning: "The One attributed with a life that is unlike our life and is not that of a combination of soul, flesh or blood.", benefit: "Recite for spiritual life."),

            NameOfAllah(number: 63, arabicName: "الْقَيُّومُ", transliteration: "Al-Qayyum", translation: "The Self-Subsisting", meaning: "The One who remains and does not end.", benefit: "Recite with Al-Hayy for spiritual awakening."),

            NameOfAllah(number: 64, arabicName: "الْوَاجِدُ", transliteration: "Al-Wajid", translation: "The Finder", meaning: "The Rich who is never poor.", benefit: "Recite for finding lost things."),

            NameOfAllah(number: 65, arabicName: "الْمَاجِدُ", transliteration: "Al-Majid", translation: "The Noble", meaning: "The One who is Majid.", benefit: "Recite for nobility."),

            NameOfAllah(number: 66, arabicName: "الْواحِدُ", transliteration: "Al-Wahid", translation: "The Unique", meaning: "The One without a partner.", benefit: "Recite for Tawheed strengthening."),

            NameOfAllah(number: 67, arabicName: "اَلاَحَدُ", transliteration: "Al-Ahad", translation: "The One", meaning: "The Only One.", benefit: "Recite for unity with Allah."),

            NameOfAllah(number: 68, arabicName: "الصَّمَدُ", transliteration: "As-Samad", translation: "The Eternal", meaning: "The Master who is relied upon in matters.", benefit: "Recite for reliance on Allah."),

            NameOfAllah(number: 69, arabicName: "الْقَادِرُ", transliteration: "Al-Qadir", translation: "The Capable", meaning: "The One attributed with Power.", benefit: "Recite for capability."),

            NameOfAllah(number: 70, arabicName: "الْمُقْتَدِرُ", transliteration: "Al-Muqtadir", translation: "The Powerful", meaning: "The One with the perfect Power that nothing is withheld from Him.", benefit: "Recite for overcoming obstacles."),

            // 71-80
            NameOfAllah(number: 71, arabicName: "الْمُقَدِّمُ", transliteration: "Al-Muqaddim", translation: "The Expediter", meaning: "The One who puts forward whoever He wills.", benefit: "Recite for advancement."),

            NameOfAllah(number: 72, arabicName: "الْمُؤَخِّرُ", transliteration: "Al-Mu'akhkhir", translation: "The Delayer", meaning: "The One who delays whatever He wills.", benefit: "Recite for patience in delays."),

            NameOfAllah(number: 73, arabicName: "الأوَّلُ", transliteration: "Al-Awwal", translation: "The First", meaning: "The One whose Existence is without a beginning.", benefit: "Recite for understanding origins."),

            NameOfAllah(number: 74, arabicName: "الآخِرُ", transliteration: "Al-Akhir", translation: "The Last", meaning: "The One whose Existence is without an end.", benefit: "Recite for understanding endings."),

            NameOfAllah(number: 75, arabicName: "الظَّاهِرُ", transliteration: "Az-Zahir", translation: "The Manifest", meaning: "The One that nothing is above Him and nothing is underneath Him.", benefit: "Recite for manifestation of truth."),

            NameOfAllah(number: 76, arabicName: "الْبَاطِنُ", transliteration: "Al-Batin", translation: "The Hidden", meaning: "The One that nothing is closer than Him.", benefit: "Recite for inner knowledge."),

            NameOfAllah(number: 77, arabicName: "الْوَالِي", transliteration: "Al-Wali", translation: "The Governor", meaning: "The One who owns things and manages them.", benefit: "Recite for leadership."),

            NameOfAllah(number: 78, arabicName: "الْمُتَعَالِي", transliteration: "Al-Muta'ali", translation: "The Most Exalted", meaning: "The One who is clear from the attributes of the creation.", benefit: "Recite for spiritual ascension."),

            NameOfAllah(number: 79, arabicName: "الْبَرُّ", transliteration: "Al-Barr", translation: "The Source of Goodness", meaning: "The One who is kind to His creatures.", benefit: "Recite for goodness."),

            NameOfAllah(number: 80, arabicName: "التَّوَابُ", transliteration: "At-Tawwab", translation: "The Acceptor of Repentance", meaning: "The One who grants repentance to whoever He willed.", benefit: "Recite 360 times for acceptance of repentance."),

            // 81-90
            NameOfAllah(number: 81, arabicName: "الْمُنْتَقِمُ", transliteration: "Al-Muntaqim", translation: "The Avenger", meaning: "The One who victoriously prevails over His enemies.", benefit: "Recite for justice against oppressors."),

            NameOfAllah(number: 82, arabicName: "العَفُوُّ", transliteration: "Al-Afuww", translation: "The Pardoner", meaning: "The One with wide forgiveness.", benefit: "Recite constantly for pardon."),

            NameOfAllah(number: 83, arabicName: "الرَّؤُوفُ", transliteration: "Ar-Ra'uf", translation: "The Most Kind", meaning: "The One with extreme Mercy.", benefit: "Recite for kindness."),

            NameOfAllah(number: 84, arabicName: "مَالِكُ الْمُلْكِ", transliteration: "Malik-ul-Mulk", translation: "Master of the Kingdom", meaning: "The One who controls the Dominion.", benefit: "Recite for dominion."),

            NameOfAllah(number: 85, arabicName: "ذُوالْجَلاَلِ وَالإكْرَامِ", transliteration: "Dhul-Jalali wal-Ikram", translation: "Possessor of Glory and Honor", meaning: "The One who deserves to be Exalted and not denied.", benefit: "Recite for glory and honor."),

            NameOfAllah(number: 86, arabicName: "الْمُقْسِطُ", transliteration: "Al-Muqsit", translation: "The Equitable", meaning: "The One who is Just in His judgement.", benefit: "Recite for justice."),

            NameOfAllah(number: 87, arabicName: "الْجَامِعُ", transliteration: "Al-Jami", translation: "The Gatherer", meaning: "The One who gathers the creatures.", benefit: "Recite for gathering goodness."),

            NameOfAllah(number: 88, arabicName: "الْغَنِيُّ", transliteration: "Al-Ghani", translation: "The Self-Sufficient", meaning: "The One who does not need anything.", benefit: "Recite for self-sufficiency."),

            NameOfAllah(number: 89, arabicName: "الْمُغْنِي", transliteration: "Al-Mughni", translation: "The Enricher", meaning: "The One who satisfies the necessities of the creatures.", benefit: "Recite for wealth."),

            NameOfAllah(number: 90, arabicName: "اَلْمَانِعُ", transliteration: "Al-Mani'", translation: "The Preventer", meaning: "The One who prevents harm and difficulty.", benefit: "Recite for protection from harm."),

            // 91-99
            NameOfAllah(number: 91, arabicName: "الضَّارَّ", transliteration: "Ad-Darr", translation: "The Distresser", meaning: "The One who makes harm reach to whoever He willed.", benefit: "Recite for understanding trials."),

            NameOfAllah(number: 92, arabicName: "النَّافِعُ", transliteration: "An-Nafi'", translation: "The Beneficial", meaning: "The One who gives benefit to whoever He wills.", benefit: "Recite for benefit in all things."),

            NameOfAllah(number: 93, arabicName: "النُّورُ", transliteration: "An-Nur", translation: "The Light", meaning: "The One who guides.", benefit: "Recite for enlightenment."),

            NameOfAllah(number: 94, arabicName: "الْهَادِي", transliteration: "Al-Hadi", translation: "The Guide", meaning: "The One whom with His Guidance His believers were guided.", benefit: "Recite 1000 times for guidance."),

            NameOfAllah(number: 95, arabicName: "الْبَدِيعُ", transliteration: "Al-Badi'", translation: "The Incomparable", meaning: "The One who created the creation without any precedent.", benefit: "Recite for uniqueness."),

            NameOfAllah(number: 96, arabicName: "اَلْبَاقِي", transliteration: "Al-Baqi", translation: "The Everlasting", meaning: "The One that the state of non-existence is impossible for Him.", benefit: "Recite for permanence in good."),

            NameOfAllah(number: 97, arabicName: "الْوَارِثُ", transliteration: "Al-Warith", translation: "The Inheritor", meaning: "The One whose Existence remains.", benefit: "Recite for inheritance of goodness."),

            NameOfAllah(number: 98, arabicName: "الرَّشِيدُ", transliteration: "Ar-Rashid", translation: "The Guide to the Right Path", meaning: "The One who guides.", benefit: "Recite for right guidance."),

            NameOfAllah(number: 99, arabicName: "الصَّبُورُ", transliteration: "As-Sabur", translation: "The Patient", meaning: "The One who does not quickly punish the sinners.", benefit: "Recite 100 times for patience in adversity.")
        ]
    }
}
