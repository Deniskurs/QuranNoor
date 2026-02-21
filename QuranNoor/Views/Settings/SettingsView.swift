//
//  SettingsView.swift
//  QuranNoor
//
//  App settings and preferences — orchestrator that composes section views
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    // MARK: - Properties
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var notificationsEnabled = false  // Start false, sync from service on appear
    @State private var hasInitializedNotifications = false  // Track initial sync
    @State private var notificationToggleTask: Task<Void, Never>?  // Debouncing task
    @State private var soundEnabled = true
    @State private var showPrayerCalcInfo = false
    @State private var showMethodSheet = false
    @State private var showMadhabSheet = false
    var prayerVM: PrayerViewModel
    @State private var showVersionInfo = false
    @State private var showDeveloperInfo = false
    @State private var showProgressManagement = false
    @State private var showDeleteConfirmation = false
    private let quranService = QuranService.shared

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .info

    // MARK: - Body
    var body: some View {
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
                        AppearanceSection()

                        // Reading Progress Section
                        ReadingProgressSection(
                            showProgressManagement: $showProgressManagement,
                            quranService: quranService
                        )

                        // Prayer Settings Section
                        PrayerSettingsSection(
                            prayerVM: prayerVM,
                            showMethodSheet: $showMethodSheet,
                            showMadhabSheet: $showMadhabSheet,
                            showPrayerCalcInfo: $showPrayerCalcInfo
                        )

                        // Notifications Section
                        NotificationSection(
                            notificationsEnabled: $notificationsEnabled,
                            soundEnabled: $soundEnabled
                        )

                        // About Section
                        AboutSection(
                            showVersionInfo: $showVersionInfo,
                            showDeveloperInfo: $showDeveloperInfo
                        )

                        // Data Management Section
                        dataManagementSection

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
                notificationsEnabled = prayerVM.notificationService.notificationsEnabled

                // Mark as initialized AFTER setting the value
                DispatchQueue.main.async {
                    hasInitializedNotifications = true
                }
            }
            .onDisappear {
                hasInitializedNotifications = false
            }
            .onChange(of: notificationsEnabled) { oldValue, newValue in
                guard hasInitializedNotifications else { return }

                // Cancel any pending task
                notificationToggleTask?.cancel()

                // Create a new debounced task
                notificationToggleTask = Task {
                    // Debounce delay
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                    guard !Task.isCancelled else { return }

                    await prayerVM.setNotificationsEnabled(newValue)

                    // Sync state back if service state differs
                    if notificationsEnabled != prayerVM.notificationService.notificationsEnabled {
                        notificationsEnabled = prayerVM.notificationService.notificationsEnabled
                    }

                    toastMessage = newValue ? "Notifications enabled" : "Notifications disabled"
                    toastStyle = .info
                    showToast = true
                }
            }
        .sheet(isPresented: $showPrayerCalcInfo) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ThemedText.heading("How Prayer Times Are Calculated")
                        ThemedText.body("The calculation method defines parameters like sun depression angles for Fajr and Isha, and other adjustments used by regional councils or organizations (e.g., ISNA, MWL, Umm al-Qura).")
                        ThemedText.heading("Madhab and Asr Time")
                        ThemedText.body("The chosen madhab affects only the Asr time: \n\u{2022} Shafi / Standard: Asr begins when an object's shadow equals its length (after noon).\n\u{2022} Hanafi: Asr begins when the shadow is twice the object's length.")
                        ThemedText.caption("Tip: If you are unsure, Shafi / Standard is commonly used in many regions.")
                            .foregroundColor(themeManager.currentTheme.accent)
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
                            toastMessage = "Calculation method changed"
                            toastStyle = .info
                            showToast = true
                        } label: {
                            HStack {
                                Text(method.rawValue)
                                Spacer()
                                if method == prayerVM.selectedCalculationMethod {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentTheme.semanticSuccess)
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
                            toastMessage = "Madhab updated"
                            toastStyle = .info
                            showToast = true
                        } label: {
                            HStack {
                                Text(madhab.rawValue)
                                Spacer()
                                if madhab == prayerVM.selectedMadhab {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentTheme.semanticSuccess)
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
                            .foregroundColor(themeManager.currentTheme.accent)
                        VStack(alignment: .leading, spacing: 8) {
                            Link("Website", destination: URL(string: "https://qurannoor.app")!)
                            Link("Support Email", destination: URL(string: "mailto:support@qurannoor.app")!)
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
        .alert("App Version", isPresented: $showVersionInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(getAppVersionDetails())
        }
        .toast(message: toastMessage, style: toastStyle, isPresented: $showToast)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.accent)

            ThemedText("Settings", style: .heading)
                .foregroundColor(themeManager.currentTheme.accent)

            ThemedText.caption("Customize your experience")
        }
        .padding(.top, 8)
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Data Management", icon: "externaldrive.fill")

            CardView {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            ThemedText.body("Delete All Data")
                                .foregroundColor(.red)
                            ThemedText.caption("Remove all bookmarks, progress, and settings")
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                }
                .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text("This will permanently delete all your bookmarks, reading progress, prayer history, and app settings. This action cannot be undone.")
                }
            }
        }
    }

    #if DEBUG
    // MARK: - Developer Tools Section (Debug Only)

    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader(title: "Developer Tools", icon: "hammer.fill")

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
                                .foregroundColor(themeManager.currentTheme.accentMuted)
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
                                .foregroundColor(themeManager.currentTheme.accent)
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

        #if DEBUG
        print("Onboarding reset! Restart the app to see onboarding again.")
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

    // MARK: - Helpers

    private func getAppVersionDetails() -> String {
        let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "QuranNoor"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(name)\nVersion: \(version)\nBuild: \(build)"
    }

    /// Delete all app data (GDPR compliance)
    private func deleteAllData() {
        // Clear UserDefaults (excluding system keys)
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        // Clear SwiftData container (bookmarks and reading progress)
        // Remove all bookmarks individually
        let bookmarks = quranService.getBookmarks()
        for bookmark in bookmarks {
            quranService.removeBookmark(id: bookmark.id)
        }

        // Reset reading progress
        quranService.resetAllProgress()

        // Clear spiritual bookmarks
        SpiritualBookmarkService.shared.clearAllBookmarks()

        // Reset prayer completion data
        PrayerCompletionService.shared.resetCompletions()

        // Clear cached files
        clearCachedFiles()

        // Show confirmation
        toastMessage = "All data deleted successfully"
        toastStyle = .success
        showToast = true

        AudioHapticCoordinator.shared.playSuccess()

        #if DEBUG
        print("All app data deleted")
        #endif
    }

    private func clearCachedFiles() {
        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    try? fileManager.removeItem(at: file)
                }
            } catch {
                #if DEBUG
                print("Failed to clear cache: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(prayerVM: PrayerViewModel())
        .environment(ThemeManager())
}
