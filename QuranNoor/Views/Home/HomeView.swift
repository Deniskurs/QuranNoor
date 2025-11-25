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

    // MARK: - ViewModels
    @State private var homeVM = HomeViewModel()
    @State private var prayerVM = PrayerViewModel()
    @State private var quranVM = QuranViewModel()

    // MARK: - State
    @State private var isInitialized = false
    @State private var showFirstTimeExperience = false
    @State private var showWelcomeMoment = false

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

            homeVM.dailyStats = homeVM.calculateDailyStats(
                from: quranVM,
                prayerVM: prayerVM
            )

            // Update cache with fresh data
            homeVM.cacheHomeData()

            #if DEBUG
            print("🔄 [HomeView] Progress updated - recalculated stats")
            #endif
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

                    // Show welcome moment after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Check if welcome moment hasn't been seen
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
            LazyVStack(spacing: Spacing.sectionSpacing) { // Enhanced from 20 to 32
                // Header with greeting and Hijri date
                HomeHeaderView(
                    greeting: homeVM.greeting,
                    hijriDate: homeVM.currentHijriDate
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                // Next prayer card (HERO SECTION - enhanced visual hierarchy)
                NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
                    .scaleEffect(1.02) // Slightly larger to draw attention
                    .shadow(color: themeManager.currentTheme.featureAccent.opacity(0.15), radius: 12, x: 0, y: 8)
                    .transition(.scale.combined(with: .opacity))

                // Spiritual nourishment carousel
                SpiritualNourishmentCarousel(
                    verseOfDay: homeVM.verseOfDay,
                    hadithOfDay: homeVM.hadithOfDay
                )
                .transition(.move(edge: .leading).combined(with: .opacity))

                // Quick actions grid (moved up for easier access)
                if let stats = homeVM.dailyStats {
                    QuickActionsGrid(
                        selectedTab: $selectedTab,
                        lastReadLocation: stats.lastReadLocation
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Reading progress card
                if let stats = homeVM.dailyStats {
                    ReadingProgressCard(stats: stats) {
                        // Switch to Quran tab when Continue is tapped
                        selectedTab = 1
                        HapticManager.shared.trigger(.light)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Hijri calendar card
                HijriCalendarCard(hijriDate: homeVM.currentHijriDate)
                    .transition(.scale.combined(with: .opacity))

                // Recent activity feed
                RecentActivityFeed(
                    bookmarks: Array(quranVM.bookmarks.prefix(3)),
                    lastReadSurah: quranVM.readingProgress?.lastReadSurah.description,
                    lastReadVerse: quranVM.readingProgress?.lastReadVerse,
                    prayersCompleted: PrayerCompletionService.shared.getTodayCompletionCount()
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .padding(.horizontal, Spacing.screenHorizontal) // 24pt edge spacing for all cards
            .padding(.vertical, Spacing.md) // Enhanced with specific spacing (24pt)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isInitialized)
        }
        .overlay {
            if homeVM.isLoading && !isInitialized {
                loadingOverlay
            }
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(themeManager.currentTheme.featureAccent)

                Text("Preparing your spiritual journey...")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Data Loading

    /// Initialize home page data
    private func initialize() async {
        // Check if this is first launch
        checkFirstTimeUser()

        guard !showFirstTimeExperience else { return }

        homeVM.isLoading = true

        // Initialize ViewModels in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.prayerVM.initialize() }
            group.addTask { await self.quranVM.loadSurahs() }
        }

        // Initialize HomeViewModel with calculated stats
        await homeVM.initialize()

        // Calculate daily stats from other ViewModels
        // ALWAYS recalculate to ensure fresh data (overwrites any stale cached data)
        homeVM.dailyStats = homeVM.calculateDailyStats(
            from: quranVM,
            prayerVM: prayerVM
        )

        // Cache the fresh stats
        homeVM.cacheHomeData()

        homeVM.isLoading = false
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
        HomeView(selectedTab: $selectedTab)
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
        HomeView(selectedTab: $selectedTab)
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
        HomeView(selectedTab: $selectedTab)
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
        HomeView(selectedTab: $selectedTab)
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
