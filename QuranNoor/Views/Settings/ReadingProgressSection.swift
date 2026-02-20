//
//  ReadingProgressSection.swift
//  QuranNoor
//
//  Reading progress stats section for Settings
//

import SwiftUI

struct ReadingProgressSection: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var showProgressManagement: Bool
    let quranService: QuranService

    // MARK: - Computed Properties

    private var completedSurahsCount: Int {
        guard let progress = quranService.readingProgress else { return 0 }
        let surahs = quranService.getSampleSurahs()

        return surahs.filter { surah in
            let stats = progress.surahProgress(surahNumber: surah.id, totalVerses: surah.numberOfVerses)
            return stats.isCompleted
        }.count
    }

    private var suraCompletionText: String {
        let percentage = Int((Double(completedSurahsCount) / 114.0) * 100)
        return "\(completedSurahsCount)/114 surahs \u{2022} \(percentage)%"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Reading Progress", icon: "book.pages.fill")

            CardView {
                Button {
                    showProgressManagement = true
                } label: {
                    VStack(spacing: 16) {
                        // Progress Stats Row
                        HStack(spacing: 12) {
                            // Progress Ring
                            ProgressRing(
                                progress: min(Double(quranService.readingProgress?.totalVersesRead ?? 0) / 6236.0, 1.0),
                                lineWidth: 4,
                                size: 50,
                                showPercentage: false,
                                color: themeManager.currentTheme.accent
                            )

                            // Stats
                            VStack(alignment: .leading, spacing: 6) {
                                ThemedText.body("Manage Your Progress")

                                // Surahs completed format
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption2)
                                        .foregroundColor(themeManager.currentTheme.semanticSuccess)
                                    ThemedText.caption(suraCompletionText)
                                        .foregroundColor(themeManager.currentTheme.accent)
                                }

                                // Mini progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(themeManager.currentTheme.textTertiary.opacity(themeManager.currentTheme.disabledOpacity))
                                            .frame(height: 3)

                                        Rectangle()
                                            .fill(themeManager.currentTheme.accent)
                                            .frame(
                                                width: geometry.size.width * CGFloat(completedSurahsCount) / 114.0,
                                                height: 3
                                            )
                                    }
                                }
                                .frame(height: 3)

                                // Secondary stats
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.fill")
                                            .font(.caption2)
                                        ThemedText.caption("\(quranService.readingProgress?.totalVersesRead ?? 0) verses")
                                    }
                                    .foregroundColor(themeManager.currentTheme.textSecondary)

                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption2)
                                        ThemedText.caption("\(quranService.readingProgress?.streakDays ?? 0) days")
                                    }
                                    .foregroundColor(themeManager.currentTheme.accentMuted)
                                }
                                .opacity(themeManager.currentTheme.secondaryOpacity)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }

                        IslamicDivider(style: .simple)

                        // Features Grid
                        HStack(spacing: 12) {
                            progressFeatureItem(
                                icon: "chart.bar.fill",
                                title: "Statistics",
                                color: themeManager.currentTheme.accent
                            )

                            progressFeatureItem(
                                icon: "arrow.counterclockwise",
                                title: "Reset",
                                color: themeManager.currentTheme.accent
                            )

                            progressFeatureItem(
                                icon: "square.and.arrow.up",
                                title: "Export",
                                color: themeManager.currentTheme.accentMuted
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Views

    private func progressFeatureItem(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            ThemedText.caption(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(themeManager.currentTheme == .sepia ? 0 : (themeManager.currentTheme == .light ? 0.12 : 0.30)))
        .cornerRadius(8)
    }
}
