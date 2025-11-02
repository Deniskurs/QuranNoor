//
//  HomeView.swift
//  QuranNoor
//
//  Home dashboard with prayer countdown and quick actions
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @State private var prayerViewModel = PrayerViewModel()

    // Hijri calendar
    private let hijriService = HijriCalendarService()
    @State private var hijriDate: HijriDate?
    @State private var isLoadingHijri = true

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                GradientBackground(style: .home, opacity: 0.25)

                // TimelineView updates every second for live countdown and progress
                TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                    ScrollView {
                        VStack(spacing: 24) {
                            // Welcome header
                            welcomeHeader

                            // Next prayer countdown card
                            if let nextPrayer = prayerViewModel.nextPrayer {
                                nextPrayerCountdownCard(nextPrayer)
                            }

                            // Daily verse card
                            dailyVerseCard

                            // Quick actions
                            quickActionsGrid

                            // Hijri date card
                            hijriDateCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Home")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                await prayerViewModel.initialize()
                await loadHijriDate()
            }
        }
    }

    // MARK: - Components

    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            ThemedText.title("Qur'an Noor", italic: false)
                .foregroundColor(AppColors.primary.green)

            ThemedText("Assalamu Alaikum", style: .heading)
                .foregroundColor(AppColors.primary.gold)

            ThemedText.body("Welcome to your spiritual journey")
                .multilineTextAlignment(.center)
                .opacity(0.7)
        }
        .padding(.top, 8)
    }

    private func nextPrayerCountdownCard(_ prayer: PrayerTime) -> some View {
        CardView(showPattern: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("NEXT PRAYER")
                        ThemedText(prayer.name.displayName, style: .heading)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    Image(systemName: prayer.name.icon)
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary.green.opacity(0.6))
                }

                IslamicDivider(style: .ornamental, color: AppColors.primary.gold.opacity(0.3))

                // Time and countdown
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prayer.displayTime)
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundColor(themeManager.currentTheme.textColor)

                        if !prayerViewModel.countdown.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                Text("in \(prayerViewModel.countdown)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(AppColors.primary.teal)
                        }
                    }

                    Spacer()

                    // Progress ring (changes to orange when urgent)
                    ProgressRing(
                        progress: prayerViewModel.periodProgress,
                        lineWidth: 6,
                        size: 90,
                        showPercentage: false,
                        color: prayerViewModel.isUrgent ? .orange : AppColors.primary.green
                    )
                }
            }
        }
    }

    private var dailyVerseCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ThemedText("Daily Verse", style: .heading)
                    Spacer()
                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary.gold)
                }

                IslamicDivider(style: .crescent, color: AppColors.primary.gold.opacity(0.3))

                // Arabic verse
                ThemedText.arabic("وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ")
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 8)

                // Translation
                ThemedText.caption("\"And I did not create the jinn and mankind except to worship Me.\" - Surah Adh-Dhariyat (51:56)")
                    .opacity(0.7)
                    .italic()
            }
        }
    }

    private var quickActionsGrid: some View {
        VStack(spacing: 12) {
            HStack {
                ThemedText("Quick Actions", style: .heading)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "book.fill",
                    title: "Read Quran",
                    color: AppColors.primary.green
                )

                QuickActionCard(
                    icon: "location.north.fill",
                    title: "Qibla",
                    color: AppColors.primary.teal
                )

                QuickActionCard(
                    icon: "building.columns.fill",
                    title: "Find Mosque",
                    color: AppColors.primary.gold
                )

                QuickActionCard(
                    icon: "hand.raised.fill",
                    title: "Duas",
                    color: AppColors.primary.midnight
                )
            }
        }
    }

    private var hijriDateCard: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ThemedText.caption("TODAY")

                    if isLoadingHijri {
                        ThemedText("Loading...", style: .body)
                            .foregroundColor(AppColors.primary.green)
                    } else if let hijriDate = hijriDate {
                        ThemedText(hijriService.getFormattedHijriDate(hijriDate: hijriDate), style: .body)
                            .foregroundColor(AppColors.primary.green)

                        // Show Arabic date
                        ThemedText.arabic(hijriService.getFormattedHijriDateArabic(hijriDate: hijriDate))
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.primary.gold)
                            .opacity(0.8)
                    } else {
                        ThemedText("Islamic Calendar", style: .body)
                            .foregroundColor(AppColors.primary.green)
                    }

                    ThemedText.caption(Date().formatted(date: .long, time: .omitted))
                        .opacity(0.6)
                }

                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.primary.gold.opacity(0.6))
            }
        }
    }

    // MARK: - Private Methods

    private func loadHijriDate() async {
        // Try to load from cache first
        if let cachedDate = hijriService.getCachedHijriDate() {
            hijriDate = cachedDate
            isLoadingHijri = false
        }

        // Then fetch from API
        do {
            let fetchedDate = try await hijriService.getCurrentHijriDate()
            hijriDate = fetchedDate
            isLoadingHijri = false
        } catch {
            print("Failed to fetch Hijri date: \(error)")
            isLoadingHijri = false
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {
            // Action will be implemented later
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                ThemedText.body(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager())
}
