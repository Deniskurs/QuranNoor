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
    @EnvironmentObject var themeManager: ThemeManager
    @State private var notificationsEnabled = true
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
                // Background gradient
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
                notificationsEnabled = prayerVM.notificationService.notificationsEnabled
            }
            .onChange(of: notificationsEnabled) { oldValue, newValue in
                // React to notification toggle changes
                Task {
                    do {
                        if newValue {
                            // User wants to enable notifications
                            if !prayerVM.notificationService.isAuthorized {
                                // Request permission first
                                let granted = try await prayerVM.notificationService.requestPermission()
                                if !granted {
                                    // Permission denied, revert toggle
                                    notificationsEnabled = false
                                    return
                                }
                            }
                        }

                        // Toggle notifications (schedules or cancels)
                        await prayerVM.toggleNotifications()

                    } catch {
                        // Error occurred, revert toggle
                        notificationsEnabled = oldValue
                        print("⚠️ Failed to toggle notifications: \(error.localizedDescription)")
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
                            .foregroundColor(AppColors.primary.teal)
                    }
                    .padding()
                }
                .navigationTitle("Prayer Time Rules")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { showPrayerCalcInfo = false } } }
            }
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
        }
        .sheet(isPresented: $showDeveloperInfo) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ThemedText.heading("About the Developer")
                        ThemedText.body("Qur'an Noor Team is dedicated to crafting a serene and accurate experience for prayer times, Qur'an reading, and spiritual tools.")
                        ThemedText.caption("Contact")
                            .foregroundColor(AppColors.primary.teal)
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
        }
        .sheet(isPresented: $showProgressManagement) {
            ProgressManagementView()
                .environmentObject(themeManager)
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
                .opacity(0.7)
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
                                        .opacity(0.6)
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
                                            .fill(Color.secondary.opacity(0.2))
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
                                .opacity(0.8)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .opacity(0.3)
                        }

                        IslamicDivider(style: .simple)

                        // Features Grid
                        HStack(spacing: 12) {
                            progressFeatureItem(
                                icon: "chart.bar.fill",
                                title: "Statistics",
                                color: AppColors.primary.teal
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
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
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
                        .opacity(0.7)
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
                            color: AppColors.primary.teal
                        )
                    }

                    // Subtitle for Madhab
                    ThemedText.caption("Affects Asr time: Shafi/Standard uses shadow length = 1x; Hanafi uses 2x.")
                        .opacity(0.7)
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
                                    .opacity(0.6)
                            }
                        }
                    }
                    .tint(AppColors.primary.green)

                    IslamicDivider(style: .simple)

                    Toggle(isOn: $soundEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary.teal)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                ThemedText.body("Sound Alerts")
                                ThemedText.caption("Play adhan when prayer time arrives")
                                    .opacity(0.6)
                            }
                        }
                    }
                    .tint(AppColors.primary.green)
                    .disabled(!notificationsEnabled)
                    .opacity(notificationsEnabled ? 1.0 : 0.5)
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
                                .foregroundColor(AppColors.primary.teal)
                                .frame(width: 32)

                            ThemedText.body("Rate This App")

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .opacity(0.5)
                        }
                    }
                }
            }
        }
    }

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
                .opacity(0.8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .opacity(0.3)
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
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                // Fallback for iOS < 18
                SKStoreReviewController.requestReview(in: scene)
            }
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
        .environmentObject(ThemeManager())
}

