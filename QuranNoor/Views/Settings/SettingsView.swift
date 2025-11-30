//
//  SettingsView.swift
//  QuranNoor
//
//  App settings and preferences with premium UI
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var notificationsEnabled = false  // Start false, sync from service on appear
    @State private var hasInitializedNotifications = false  // Track initial sync
    @State private var soundEnabled = true
    @State private var showPrayerCalcInfo = false
    @State private var showMethodSheet = false
    @State private var showMadhabSheet = false
    @State private var prayerVM = PrayerViewModel()
    @State private var showVersionInfo = false
    @State private var showDeveloperInfo = false
    @State private var showLanguageAlert = false
    @State private var showProgressManagement = false
    @State private var quranVM = QuranViewModel()

    // MARK: - Computed Properties

    private var completedSurahsCount: Int {
        guard let progress = quranVM.readingProgress else { return 0 }
        let surahs = QuranService.shared.getSampleSurahs()

        return surahs.filter { surah in
            let stats = progress.surahProgress(surahNumber: surah.id, totalVerses: surah.numberOfVerses)
            return stats.isCompleted
        }.count
    }

    private var suraCompletionText: String {
        let percentage = Int((Double(completedSurahsCount) / 114.0) * 100)
        return "\(completedSurahsCount)/114 surahs • \(percentage)%"
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Base theme background (ensures pure black in night mode for OLED)
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay (automatically suppressed in night mode)
                GradientBackground(style: BackgroundGradientStyle.settings, opacity: 0.25)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Appearance Section
                        appearanceSection

                        // Reading Progress Section
                        readingProgressSection

                        // Prayer Settings Section
                        prayerSettingsSection

                        // Notifications Section
                        notificationsSection

                        // Language Section
                        languageSection

                        // About Section
                        aboutSection

                        #if DEBUG
                        // Developer Tools Section (only visible in debug builds)
                        developerToolsSection
                        #endif
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                // Sync toggle state with actual notification service
                // Do this BEFORE setting hasInitializedNotifications to avoid triggering onChange
                notificationsEnabled = prayerVM.notificationService.notificationsEnabled

                // Mark as initialized AFTER setting the value
                // This prevents onChange from firing during initial sync
                DispatchQueue.main.async {
                    hasInitializedNotifications = true
                }
            }
            .onDisappear {
                // Reset initialization flag so it works correctly when returning
                hasInitializedNotifications = false
            }
            .onChange(of: notificationsEnabled) { oldValue, newValue in
                // Skip if this is the initial sync from onAppear
                guard hasInitializedNotifications else { return }

                // React to user-initiated notification toggle changes
                Task {
                    // Set notifications state directly (not toggle!)
                    // setNotificationsEnabled() handles permission requests and ALWAYS saves
                    await prayerVM.setNotificationsEnabled(newValue)

                    // Sync local state with actual service state (in case permission was denied)
                    if notificationsEnabled != prayerVM.notificationService.notificationsEnabled {
                        notificationsEnabled = prayerVM.notificationService.notificationsEnabled
                    }
                }
            }
        }
        .sheet(isPresented: $showPrayerCalcInfo) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ThemedText.heading("How Prayer Times Are Calculated")
                        ThemedText.body("The calculation method defines parameters like sun depression angles for Fajr and Isha, and other adjustments used by regional councils or organizations (e.g., ISNA, MWL, Umm al-Qura).")
                        ThemedText.heading("Madhab and Asr Time")
                        ThemedText.body("The chosen madhab affects only the Asr time: \n• Shafi / Standard: Asr begins when an object's shadow equals its length (after noon).\n• Hanafi: Asr begins when the shadow is twice the object's length.")
                        ThemedText.caption("Tip: If you are unsure, Shafi / Standard is commonly used in many regions.")
                            .foregroundColor(themeManager.currentTheme.featureAccent)
                    }
                    .padding()
                }
                .navigationTitle("Prayer Time Rules")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showPrayerCalcInfo = false } } }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMethodSheet) {
            NavigationStack {
                List {
                    ForEach(CalculationMethod.allCases) { method in
                        Button {
                            Task { await prayerVM.changeCalculationMethod(method) }
                            showMethodSheet = false
                        } label: {
                            HStack {
                                Text(method.rawValue)
                                Spacer()
                                if method == prayerVM.selectedCalculationMethod {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary.green)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Calculation Method")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showMethodSheet = false } } }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMadhabSheet) {
            NavigationStack {
                List {
                    ForEach(Madhab.allCases) { madhab in
                        Button {
                            Task { await prayerVM.changeMadhab(madhab) }
                            showMadhabSheet = false
                        } label: {
                            HStack {
                                Text(madhab.rawValue)
                                Spacer()
                                if madhab == prayerVM.selectedMadhab {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary.green)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Madhab")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showMadhabSheet = false } } }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDeveloperInfo) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ThemedText.heading("About the Developer")
                        ThemedText.body("Qur'an Noor Team is dedicated to crafting a serene and accurate experience for prayer times, Qur'an reading, and spiritual tools.")
                        ThemedText.caption("Contact")
                            .foregroundColor(themeManager.currentTheme.featureAccent)
                        VStack(alignment: .leading, spacing: 8) {
                            Link("Website", destination: URL(string: "https://example.com")!)
                            Link("Support Email", destination: URL(string: "mailto:support@example.com")!)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Developer")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showDeveloperInfo = false } } }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showProgressManagement) {
            ProgressManagementView()
                .environment(themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Coming Soon", isPresented: $showLanguageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Language selection will be available in a future update.")
        }
        .alert("App Version", isPresented: $showVersionInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(getAppVersionDetails())
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary.green)

            ThemedText("Settings", style: .heading)
                .foregroundColor(AppColors.primary.green)

            ThemedText.caption("Customize your experience")
                // Caption style already uses textTertiary - no additional opacity needed
        }
        .padding(.top, 8)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Appearance", icon: "paintbrush.fill")

            CardView {
                VStack(spacing: 16) {
                    ForEach(ThemeMode.allCases) { mode in
                        Button {
                            // Haptic feedback for better UX
                            #if canImport(UIKit)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif

                            withAnimation {
                                themeManager.currentTheme = mode
                            }
                        } label: {
                            HStack {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(mode.accentColor)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    ThemedText.body(mode.rawValue)
                                    ThemedText.caption(mode.description)
                                        // Caption style already uses textTertiary - no additional opacity needed
                                }

                                Spacer()

                                if themeManager.currentTheme == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary.green)
                                        .font(.system(size: 24))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if mode != ThemeMode.allCases.last {
                            IslamicDivider(style: .simple)
                        }
                    }
                }
            }
        }
    }

    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Reading Progress", icon: "book.pages.fill")

            CardView {
                Button {
                    showProgressManagement = true
                } label: {
                    VStack(spacing: 16) {
                        // Progress Stats Row
                        HStack(spacing: 12) {
                            // Progress Ring
                            ProgressRing(
                                progress: quranVM.getProgressPercentage() / 100,
                                lineWidth: 4,
                                size: 50,
                                showPercentage: false,
                                color: AppColors.primary.green
                            )

                            // Stats
                            VStack(alignment: .leading, spacing: 6) {
                                ThemedText.body("Manage Your Progress")

                                // Surahs completed format
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.primary.green)
                                    ThemedText.caption(suraCompletionText)
                                        .foregroundColor(AppColors.primary.green)
                                }

                                // Mini progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(themeManager.currentTheme.textTertiary.opacity(themeManager.currentTheme.disabledOpacity))
                                            .frame(height: 3)

                                        Rectangle()
                                            .fill(AppColors.primary.green)
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
                                        ThemedText.caption("\(quranVM.readingProgress?.totalVersesRead ?? 0) verses")
                                    }
                                    .foregroundColor(.secondary)

                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption2)
                                        ThemedText.caption("\(quranVM.readingProgress?.streakDays ?? 0) days")
                                    }
                                    .foregroundColor(AppColors.primary.gold)
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
                                color: themeManager.currentTheme.featureAccent
                            )

                            progressFeatureItem(
                                icon: "arrow.counterclockwise",
                                title: "Reset",
                                color: AppColors.primary.green
                            )

                            progressFeatureItem(
                                icon: "square.and.arrow.up",
                                title: "Export",
                                color: AppColors.primary.gold
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func progressFeatureItem(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            ThemedText.caption(title)
                // Caption style already uses textTertiary - no additional opacity needed
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(themeManager.currentTheme.gradientOpacity(for: color) * 2))
        .cornerRadius(8)
    }

    private var prayerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Prayer Settings", icon: "clock.fill")

            CardView {
                VStack(spacing: 12) {
                    // Calculation Method row
                    Button {
                        showMethodSheet = true
                    } label: {
                        settingRow(
                            icon: "function",
                            title: "Calculation Method",
                            value: prayerVM.selectedCalculationMethod.rawValue,
                            color: AppColors.primary.green
                        )
                    }

                    // Subtitle for Calculation Method
                    ThemedText.caption("Determines Fajr/Isha angles and other parameters used to compute daily prayer times.")
                        // Caption style already uses textTertiary - no additional opacity needed
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Madhab row
                    Button {
                        showMadhabSheet = true
                    } label: {
                        settingRow(
                            icon: "globe",
                            title: "Madhab",
                            value: prayerVM.selectedMadhab.rawValue,
                            color: themeManager.currentTheme.featureAccent
                        )
                    }

                    // Subtitle for Madhab
                    ThemedText.caption("Affects Asr time: Shafi/Standard uses shadow length = 1x; Hanafi uses 2x.")
                        // Caption style already uses textTertiary - no additional opacity needed
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Adhan Settings row
                    NavigationLink {
                        AdhanSettingsView()
                            .environment(themeManager)
                    } label: {
                        settingRow(
                            icon: "speaker.wave.3.fill",
                            title: "Adhan Audio",
                            value: AdhanAudioService.shared.isEnabled ? "Enabled" : "Disabled",
                            color: AppColors.primary.gold
                        )
                    }

                    // Subtitle for Adhan
                    ThemedText.caption("Configure beautiful call to prayer audio at prayer times.")
                        // Caption style already uses textTertiary - no additional opacity needed
                        .padding(.leading, 44)

                    IslamicDivider(style: .simple)

                    // Prayer Time Adjustments row
                    NavigationLink {
                        PrayerTimeAdjustmentView()
                            .environment(themeManager)
                    } label: {
                        settingRow(
                            icon: "clock.badge.checkmark",
                            title: "Adjust Prayer Times",
                            value: PrayerTimeAdjustmentService.shared.hasAdjustments
                                ? "\(PrayerTimeAdjustmentService.shared.adjustedPrayerCount) custom"
                                : "Not adjusted",
                            color: AppColors.primary.midnight
                        )
                    }

                    // Subtitle for Adjustments
                    ThemedText.caption("Manually adjust times to sync with your local mosque schedule.")
                        // Caption style already uses textTertiary - no additional opacity needed
                        .padding(.leading, 44)

                    // Learn more link
                    HStack {
                        Spacer()
                        TertiaryButton("Learn more", icon: "book") {
                            showPrayerCalcInfo = true
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notifications", icon: "bell.fill")

            CardView {
                VStack(spacing: 16) {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary.gold)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Prayer Reminders")
                                ThemedText.caption("Get notified before prayer times")
                                    // Caption style already uses textTertiary - no additional opacity needed
                            }
                        }
                    }
                    .tint(themeManager.currentTheme.accentColor)

                    IslamicDivider(style: .simple)

                    Toggle(isOn: $soundEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.featureAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Sound Alerts")
                                ThemedText.caption("Play adhan when prayer time arrives")
                                    // Caption style already uses textTertiary - no additional opacity needed
                            }
                        }
                    }
                    .tint(themeManager.currentTheme.accentColor)
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1.0 : themeManager.currentTheme.disabledOpacity)

                    IslamicDivider(style: .simple)

                    // Advanced Notification Settings Link
                    NavigationLink {
                        NotificationSettingsView()
                            .environment(themeManager)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary.green)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Advanced Settings")
                                ThemedText.caption("Per-prayer notifications & reminders")
                                    // Caption style already uses textTertiary - no additional opacity needed
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.tertiaryOpacity)
                        }
                    }
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1.0 : themeManager.currentTheme.disabledOpacity)
                }
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Language", icon: "globe")

            CardView {
                Button {
                    showLanguageAlert = true
                } label: {
                    settingRow(
                        icon: "text.bubble.fill",
                        title: "App Language",
                        value: "Coming Soon",
                        color: AppColors.primary.midnight
                    )
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "About", icon: "info.circle.fill")

            CardView {
                VStack(spacing: 16) {
                    Button { showVersionInfo = true } label: {
                        settingRow(
                            icon: "app.badge.fill",
                            title: "Version",
                            value: getAppVersion(),
                            color: AppColors.primary.green
                        )
                    }

                    IslamicDivider(style: .simple)

                    Button { showDeveloperInfo = true } label: {
                        settingRow(
                            icon: "person.2.fill",
                            title: "Developer",
                            value: "Qur'an Noor Team",
                            color: AppColors.primary.gold
                        )
                    }

                    IslamicDivider(style: .simple)

                    Button {
                        rateApp()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.featureAccent)
                                .frame(width: 32)

                            ThemedText.body("Rate This App")

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
    // MARK: - Developer Tools Section (Debug Only)

    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Developer Tools", icon: "hammer.fill")

            CardView {
                VStack(spacing: 16) {
                    // Notification Status Display
                    notificationStatusView

                    IslamicDivider(style: .simple)

                    // Test Notification Button
                    Button {
                        testNotification()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary.gold)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Test Notification")
                                ThemedText.caption("Sends a test notification in 5 seconds")
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }
                    }

                    IslamicDivider(style: .simple)

                    Button(role: .destructive) {
                        resetOnboarding()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                                .frame(width: 32)

                            ThemedText.body("Reset Onboarding")
                                .foregroundColor(.red)

                            Spacer()

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }

                    IslamicDivider(style: .simple)

                    Button {
                        testAudioPlayback()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.featureAccent)
                                .frame(width: 32)

                            ThemedText.body("Test Audio Playback")

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                                .opacity(themeManager.currentTheme.disabledOpacity)
                        }
                    }
                }
            }
        }
    }

    /// Shows current notification permission and enabled status
    private var notificationStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Permission Status
            HStack(spacing: 12) {
                Image(systemName: prayerVM.notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(prayerVM.notificationService.isAuthorized ? .green : .red)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    ThemedText.body("Permission")
                    ThemedText.caption(prayerVM.notificationService.isAuthorized ? "Granted" : "Denied")
                        .foregroundColor(prayerVM.notificationService.isAuthorized ? .green : .red)
                }

                Spacer()
            }

            // Enabled Status
            HStack(spacing: 12) {
                Image(systemName: prayerVM.notificationService.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(prayerVM.notificationService.notificationsEnabled ? .green : .orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    ThemedText.body("Notifications")
                    ThemedText.caption(prayerVM.notificationService.notificationsEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(prayerVM.notificationService.notificationsEnabled ? .green : .orange)
                }

                Spacer()
            }
        }
    }

    // MARK: - Developer Actions

    private func testNotification() {
        Task {
            await prayerVM.notificationService.sendTestNotification()
            AudioHapticCoordinator.shared.playSuccess()
        }
    }

    private func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        AudioHapticCoordinator.shared.playSuccess()

        // Show alert
        #if DEBUG
        print("✅ Onboarding reset! Restart the app to see onboarding again.")
        #endif
    }

    private func testAudioPlayback() {
        AudioHapticCoordinator.shared.playNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioHapticCoordinator.shared.playConfirm()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioHapticCoordinator.shared.playBack()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            AudioHapticCoordinator.shared.playStartup()
        }
    }
    #endif

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.primary.green)

            ThemedText(title, style: .heading)

            Spacer()
        }
    }

    private func settingRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)

            ThemedText.body(title)

            Spacer()

            ThemedText.body(value)
                .foregroundColor(color)
                .opacity(themeManager.currentTheme.secondaryOpacity)

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .opacity(themeManager.currentTheme.tertiaryOpacity)
        }
    }

    // MARK: - Helpers
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func getAppVersionDetails() -> String {
        let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "QuranNoor"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(name)\nVersion: \(version)\nBuild: \(build)"
    }

    private func rateApp() {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
            return
        }
        #endif
        // Fallback: Open App Store review page if App ID is known
        // Replace APP_ID below with your real App Store ID
        let appID = "APP_ID"
        if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #else
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(ThemeManager())
}

