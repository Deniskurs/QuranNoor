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
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTab: Int

    // MARK: - ViewModels
    @State private var homeVM = HomeViewModel()
    @State private var prayerVM = PrayerViewModel()
    @State private var quranVM = QuranViewModel()

    // MARK: - State
    @State private var isInitialized = false
    @State private var showFirstTimeExperience = false

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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Invisible title for clean look
                    Text("")
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
            LazyVStack(spacing: 20) {
                // Header with greeting and Hijri date
                HomeHeaderView(
                    greeting: homeVM.greeting,
                    hijriDate: homeVM.hijriDate,
                    location: prayerVM.userLocation
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                // Next prayer card (hero section)
                NextPrayerCardView(prayerVM: prayerVM)
                    .transition(.scale.combined(with: .opacity))

                // Daily stats grid
                if let stats = homeVM.dailyStats {
                    DailyStatsRow(stats: stats)
                        .transition(.scale.combined(with: .opacity))
                }

                // Spiritual nourishment carousel
                SpiritualNourishmentCarousel(
                    verseOfDay: homeVM.verseOfDay,
                    hadithOfDay: homeVM.hadithOfDay
                )
                .transition(.move(edge: .leading).combined(with: .opacity))

                // Reading progress card
                if let stats = homeVM.dailyStats {
                    ReadingProgressCard(stats: stats)
                        .transition(.scale.combined(with: .opacity))
                }

                // Hijri calendar card
                HijriCalendarCard(hijriDate: homeVM.hijriDate)
                    .transition(.scale.combined(with: .opacity))

                // Quick actions grid
                if let stats = homeVM.dailyStats {
                    QuickActionsGrid(
                        selectedTab: $selectedTab,
                        lastReadLocation: stats.lastReadLocation
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Recent activity feed
                RecentActivityFeed(
                    bookmarks: Array(quranVM.bookmarks.prefix(3)),
                    lastReadSurah: quranVM.readingProgress?.lastReadSurah.description,
                    lastReadVerse: quranVM.readingProgress?.lastReadVerse,
                    prayersCompleted: PrayerCompletionService.shared.getTodayCompletionCount()
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .padding(.vertical)
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
                    .tint(AppColors.primary.teal)

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
        if quranVM.readingProgress != nil {
            homeVM.dailyStats = homeVM.calculateDailyStats(
                from: quranVM,
                prayerVM: prayerVM
            )
        }

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

        // Recalculate stats
        if quranVM.readingProgress != nil {
            homeVM.dailyStats = homeVM.calculateDailyStats(
                from: quranVM,
                prayerVM: prayerVM
            )
        }
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
            .environmentObject(ThemeManager())
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
            .environmentObject({
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
            .environmentObject({
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
            .environmentObject({
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
