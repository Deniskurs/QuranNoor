//
//  HomeView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Professional home page with user-journey-focused design
//

import SwiftUI

struct HomeView: View {
    // MARK: - Environment
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Binding var selectedTab: Int

    // MARK: - Shared ViewModels (injected from ContentView - single source of truth)
    var prayerVM: PrayerViewModel
    var quranVM: QuranViewModel

    // MARK: - Local ViewModels (owned by this view)
    @State private var homeVM = HomeViewModel()

    // MARK: - State
    @State private var isInitialized = false
    @State private var showFirstTimeExperience = false
    @State private var showWelcomeMoment = false
    @State private var lastStatsCalculation: Date = .distantPast

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay
                GradientBackground(style: .home, opacity: 0.2)

                // Main content
                mainContent

                // Welcome moment overlay (shown after onboarding)
                if showWelcomeMoment {
                    WelcomeMomentView(selectedTab: $selectedTab) {
                        UserDefaults.standard.set(true, forKey: "hasSeenWelcomeMoment")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showWelcomeMoment = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // iOS 26: Use native ToolbarSpacer for clean look
                    Spacer()
                }
            }
            .refreshable {
                await refresh()
            }
        }
        .task {
            await initialize()
        }
        .onAppear {
            homeVM.updateGreeting()
        }
        .onChange(of: quranVM.readingProgress) { oldValue, newValue in
            // Real-time update: recalculate stats when user reads verses
            guard newValue != nil else { return }

            // Throttle: only recalculate if at least 5 seconds since last calculation
            let now = Date()
            guard now.timeIntervalSince(lastStatsCalculation) >= 5 else { return }
            lastStatsCalculation = now

            homeVM.dailyStats = homeVM.calculateDailyStats(
                from: quranVM,
                prayerVM: prayerVM
            )

            // Update cache with fresh data
            homeVM.cacheHomeData()
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if showFirstTimeExperience {
            // First-time user experience
            firstTimeContent
        } else {
            // Regular home page
            regularContent
        }
    }

    // MARK: - First Time Content
    private var firstTimeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            FirstTimeUserView(
                selectedTab: $selectedTab,
                onDismiss: {
                    // Mark as launched after user interacts
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showFirstTimeExperience = false
                    }

                    // Show welcome moment after brief delay (lifecycle-safe)
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcomeMoment")
                        if !hasSeenWelcome {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showWelcomeMoment = true
                            }
                        }
                    }

                    // Initialize the home page after dismissing welcome screen
                    Task { await initialize() }
                }
            )
            .padding()
            .transition(.scale.combined(with: .opacity))
            Spacer()
        }
    }

    // MARK: - Regular Content
    private var regularContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sectionSpacing) {
                // 1. Header with greeting and Hijri date (always visible immediately)
                HomeHeaderView(
                    greeting: homeVM.greeting,
                    hijriDate: homeVM.currentHijriDate
                )

                // 2. Next prayer card (HERO SECTION — shows loading state internally)
                NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)

                // 3. Islamic divider
                IslamicDivider(style: .crescent)

                // 4. Ramadan Suhoor/Iftar countdown card (shown only during Ramadan)
                RamadanTimesCard(prayerTimes: prayerVM.todayPrayerTimes)

                // 5. Ramadan tracker card (shown only during Ramadan)
                RamadanHomeCard(prayerTimes: prayerVM.todayPrayerTimes)

                // 6. Spiritual nourishment carousel
                SpiritualNourishmentCarousel(
                    verseOfDay: homeVM.verseOfDay,
                    hadithOfDay: homeVM.hadithOfDay
                )

                // 7. Islamic divider
                IslamicDivider(style: .ornamental)

                // 8. Quick actions grid (always show — uses default location if stats not ready)
                QuickActionsGrid(
                    selectedTab: $selectedTab,
                    lastReadLocation: homeVM.dailyStats?.lastReadLocation
                )

                // 9. Reading progress card
                if let stats = homeVM.dailyStats {
                    ReadingProgressCard(stats: stats) {
                        selectedTab = 1
                        HapticManager.shared.trigger(.light)
                    }
                }

                // 10. Daily stats row
                if let stats = homeVM.dailyStats {
                    DailyStatsRow(stats: stats)
                }

                // 11. Islamic divider before Adhkar
                IslamicDivider(style: .ornamental)

                // 12. Adhkar Quick Access (integrated from orphaned component)
                AdhkarQuickAccessCard()

                // 13. Hijri Calendar Card (integrated from orphaned component)
                HijriCalendarCard(hijriDate: homeVM.currentHijriDate)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Data Loading

    /// Initialize home page data — UI is shown immediately, data loads in background
    private func initialize() async {
        // Check if this is first launch
        checkFirstTimeUser()

        guard !showFirstTimeExperience else { return }
        guard !isInitialized else { return }

        // Load cached data first (instant, synchronous) so UI has content immediately
        homeVM.updateGreeting()

        // Initialize ViewModels in parallel (non-blocking — UI is already visible)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.prayerVM.initialize() }
            group.addTask { await self.quranVM.loadSurahs() }
            group.addTask { await self.homeVM.initialize() }
        }

        // Calculate daily stats from loaded ViewModels
        homeVM.dailyStats = homeVM.calculateDailyStats(
            from: quranVM,
            prayerVM: prayerVM
        )

        homeVM.cacheHomeData()
        isInitialized = true
    }

    /// Refresh all data (pull-to-refresh)
    private func refresh() async {
        // Update greeting
        homeVM.updateGreeting()

        // Refresh all data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.prayerVM.refreshPrayerTimes() }
            group.addTask { await self.homeVM.refresh() }
        }

        // Recalculate stats with fresh data
        homeVM.dailyStats = homeVM.calculateDailyStats(
            from: quranVM,
            prayerVM: prayerVM
        )

        // Cache the fresh stats
        homeVM.cacheHomeData()
    }

    /// Check if this is a first-time user
    private func checkFirstTimeUser() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        showFirstTimeExperience = !hasLaunchedBefore
    }
}

// MARK: - Preview

#Preview("Regular Home") {
    @Previewable @State var selectedTab = 0

    TabView(selection: $selectedTab) {
        HomeView(selectedTab: $selectedTab, prayerVM: PrayerViewModel(), quranVM: QuranViewModel())
            .environment(ThemeManager())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
    }
}

#Preview("Dark Mode") {
    @Previewable @State var selectedTab = 0

    TabView(selection: $selectedTab) {
        HomeView(selectedTab: $selectedTab, prayerVM: PrayerViewModel(), quranVM: QuranViewModel())
            .environment({
                let manager = ThemeManager()
                manager.setTheme(.dark)
                return manager
            }())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
    }
}

#Preview("Night Mode") {
    @Previewable @State var selectedTab = 0

    TabView(selection: $selectedTab) {
        HomeView(selectedTab: $selectedTab, prayerVM: PrayerViewModel(), quranVM: QuranViewModel())
            .environment({
                let manager = ThemeManager()
                manager.setTheme(.night)
                return manager
            }())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
    }
}

#Preview("Sepia Mode") {
    @Previewable @State var selectedTab = 0

    TabView(selection: $selectedTab) {
        HomeView(selectedTab: $selectedTab, prayerVM: PrayerViewModel(), quranVM: QuranViewModel())
            .environment({
                let manager = ThemeManager()
                manager.setTheme(.sepia)
                return manager
            }())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
    }
}
