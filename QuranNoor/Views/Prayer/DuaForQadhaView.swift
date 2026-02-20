//
//  DuaForQadhaView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Collection of duas for making up missed prayers
//

import SwiftUI

struct DuaForQadhaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    private let duas: [DuaContent] = [
        DuaContent(
            title: "Seeking Forgiveness",
            arabic: "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
            transliteration: "Rabbi ghfir lee wa tub 'alayya innaka anta at-tawwabu ar-raheem",
            translation: "My Lord, forgive me and accept my repentance, for You are the Accepter of Repentance, the Most Merciful",
            reference: "Sunan Abi Dawud"
        ),
        DuaContent(
            title: "Before Starting Qadha",
            arabic: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
            transliteration: "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik",
            translation: "O Allah, help me to remember You, to thank You, and to worship You in the best manner",
            reference: "Sunan Abi Dawud"
        ),
        DuaContent(
            title: "For Consistency",
            arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الثَّبَاتَ فِي الأَمْرِ، وَالْعَزِيمَةَ عَلَى الرُّشْدِ",
            transliteration: "Allahumma inni as'aluka ath-thabata fil-amr, wal-'azeemata 'ala ar-rushd",
            translation: "O Allah, I ask You for steadfastness in all affairs and determination upon right guidance",
            reference: "Sunan an-Nasa'i"
        ),
        DuaContent(
            title: "After Completing Qadha",
            arabic: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ",
            transliteration: "Alhamdulillahil-ladhi bi ni'matihi tatimmu as-salihat",
            translation: "All praise is due to Allah by Whose favor good works are accomplished",
            reference: "Sahih Ibn Hibban"
        ),
        DuaContent(
            title: "General Repentance",
            arabic: "أَسْتَغْفِرُ اللَّهَ الَّذِي لاَ إِلَهَ إِلاَّ هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ",
            transliteration: "Astaghfirullaha al-ladhi la ilaha illa huwal-hayyul-qayyumu wa atubu ilayh",
            translation: "I seek forgiveness from Allah, there is no deity except Him, the Ever-Living, the Sustainer, and I repent to Him",
            reference: "Sunan at-Tirmidhi"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView

                    // Duas
                    ForEach(duas) { dua in
                        QadhaDuaCard(dua: dua)
                    }

                    // Reminder
                    reminderCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Duas for Qadha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerView: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text("Recite these duas while making up your missed prayers")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }

    private var reminderCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Remember", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.accent)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Make sincere intention (niyyah) for each qadha prayer")
                    bulletPoint("Pray them in order if possible (Fajr first, then Dhuhr, etc.)")
                    bulletPoint("You can pray qadha at any permissible time, except forbidden times")
                    bulletPoint("It's recommended to complete qadha prayers as soon as possible")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(themeManager.currentTheme.accent)

            Text(text)
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - QadhaDuaCard

struct QadhaDuaCard: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let dua: DuaContent

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(dua.title)
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.accent)

                // Arabic Text
                Text(dua.arabic)
                    .font(.title3)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)
                    .environment(\.layoutDirection, .rightToLeft)

                Divider()

                // Transliteration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transliteration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                        .textCase(.uppercase)

                    Text(dua.transliteration)
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .italic()
                }

                // Translation
                VStack(alignment: .leading, spacing: 4) {
                    Text("Translation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                        .textCase(.uppercase)

                    Text(dua.translation)
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                }

                // Reference
                HStack {
                    Spacer()
                    Text(dua.reference)
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                        .italic()
                }
            }
            .padding(16)
        }
    }
}

// MARK: - DuaContent Model

struct DuaContent: Identifiable {
    let id = UUID()
    let title: String
    let arabic: String
    let transliteration: String
    let translation: String
    let reference: String
}

#Preview {
    DuaForQadhaView()
        .environment(ThemeManager())
}
