//
//  PrayerTimesView.swift
//  QuranNoor
//
//  Redesigned prayer times view with TimelineView, sticky header, and completion tracking
//  Updated: 11/1/2025 - Complete UI/UX overhaul with 120fps optimizations
//

import SwiftUI

/// Redesigned Prayer Times view with 120fps optimizations
struct PrayerTimesView: View {
    // MARK: - Properties

    @EnvironmentObject var themeManager: ThemeManager
    @State private var viewModel = PrayerViewModel()
    @State private var transitionHandler: PrayerTransitionHandler?

    // Completion tracking
    private let completionService = PrayerCompletionService.shared

    // UI State
    @State private var showMosqueList: Bool = false
    @State private var showMethodPicker: Bool = false
    @State private var showMadhabPicker: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showPrayerReminder: Bool = false
    @State private var hasShownReminderThisSession: Bool = false

    // Toast state for prayer completion
    @State private var showCompletionToast: Bool = false
    @State private var completedPrayerName: String = ""
    @State private var lastCompletedPrayer: PrayerName? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Base theme background (ensures pure black in night mode for OLED)
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay (automatically suppressed in night mode)
                GradientBackground(style: .prayer, opacity: 0.3)

                // Main content with TimelineView for automatic updates
                TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                    ScrollView {
                        VStack(spacing: 20) {
                            // Location header
                            locationHeader

                            // Current Prayer Period Header (Sticky concept)
                            if let period = viewModel.currentPrayerPeriod {
                                CurrentPrayerHeader(
                                    state: period.state,
                                    progress: period.periodProgress,
                                    countdownString: period.countdownString,
                                    isUrgent: period.isUrgent
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }

                            // Today's Prayers with Smart Rows
                            if let times = viewModel.todayPrayerTimes {
                                todayPrayersSection(times)
                            }

                            // Completion Statistics
                            completionStatisticsCard

                            // Settings Section
                            settingsSection

                            // Mosque Finder
                            mosqueFinderButton
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshPrayerTimes()
                    }
                }

                // Loading overlay
                if viewModel.isLoadingPrayerTimes {
                    LoadingOverlay()
                }

                // Prayer reminder popup (shows on app launch)
                if showPrayerReminder,
                   let currentPrayer = viewModel.currentPrayer,
                   let times = viewModel.todayPrayerTimes,
                   let prayer = times.prayerTimes.first(where: { $0.name == currentPrayer }) {
                    PrayerReminderPopup(
                        prayer: prayer,
                        onComplete: {
                            completionService.toggleCompletion(currentPrayer)
                        },
                        onDismiss: {
                            showPrayerReminder = false
                        }
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle("Prayer Times")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    IconButton(icon: "arrow.clockwise", size: 36) {
                        Task {
                            await viewModel.refreshPrayerTimes()
                        }
                    }
                }
            }
            .task {
                await viewModel.initialize()

                // Start transition handler
                let handler = PrayerTransitionHandler(viewModel: viewModel)
                handler.start()
                transitionHandler = handler

                // Initial period calculation
                viewModel.recalculatePeriod()

                // Show prayer reminder popup if there's a current prayer not yet completed
                if !hasShownReminderThisSession,
                   let currentPrayer = viewModel.currentPrayer,
                   !completionService.isCompleted(currentPrayer) {
                    // Delay to let the view settle
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showPrayerReminder = true
                        hasShownReminderThisSession = true
                    }
                }
            }
            .onDisappear {
                transitionHandler?.stop()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showMosqueList) {
                mosqueListSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMethodPicker) {
                methodPickerSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMadhabPicker) {
                madhabPickerSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .toast(
                message: EncouragingMessages.prayerComplete(prayerName: completedPrayerName),
                style: .spiritual,
                isPresented: $showCompletionToast,
                showUndo: true,
                onUndo: {
                    // Play back sound for undo action
                    AudioHapticCoordinator.shared.playBack()

                    // Undo the completion
                    if let prayer = lastCompletedPrayer {
                        completionService.toggleCompletion(prayer)
                        lastCompletedPrayer = nil
                    }
                }
            )
        }
    }

    // MARK: - Components

    private var locationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                ThemedText.caption("YOUR LOCATION")
                ThemedText.body(viewModel.userLocation)
                    .foregroundColor(AppColors.primary.green)
            }

            Spacer()

            if viewModel.isLoadingLocation {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
    }

    private func todayPrayersSection(_ times: DailyPrayerTimes) -> some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                ThemedText("Today's Prayers", style: .heading)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .padding(.bottom, 12)

            // Smart Prayer Rows
            VStack(spacing: 12) {
                ForEach(times.prayerTimes) { prayer in
                    SmartPrayerRow(
                        prayer: prayer,
                        isCurrentPrayer: prayer.name == viewModel.currentPrayer,
                        isNextPrayer: prayer.name == viewModel.nextPrayer?.name,
                        isCompleted: completionService.isCompleted(prayer.name),
                        relatedSpecialTimes: getRelatedSpecialTimes(for: prayer, from: times),
                        canCheckOff: prayer.hasStarted, // Only allow checking off past/current prayers
                        onCompletionToggle: {
                            // Store prayer for undo
                            lastCompletedPrayer = prayer.name

                            // Check if marking complete or incomplete
                            let isMarkingComplete = !completionService.isCompleted(prayer.name)

                            // Toggle completion
                            completionService.toggleCompletion(prayer.name)

                            // Show encouraging toast only when marking complete
                            if isMarkingComplete {
                                completedPrayerName = prayer.name.displayName
                                showCompletionToast = true

                                // Play toast notification sound
                                AudioHapticCoordinator.shared.playToast()
                            }
                        }
                    )
                    .id(prayer.name.rawValue) // For smooth animations
                }
            }
        }
    }

    private var completionStatisticsCard: some View {
        let stats = completionService.getTodayStatistics()

        return CardView(showPattern: false) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("TODAY'S PROGRESS")
                        ThemedText("Prayer Completion", style: .heading)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    // Completion ring
                    OptimizedProgressRing(
                        progress: Double(stats.completedCount) / Double(stats.totalCount),
                        lineWidth: 6,
                        size: 60,
                        color: stats.isAllCompleted ? AppColors.primary.green : AppColors.primary.teal,
                        showPercentage: true
                    )
                }

                IslamicDivider(style: .simple)

                // Stats row
                HStack(spacing: 20) {
                    statItem(
                        icon: "checkmark.circle.fill",
                        value: "\(stats.completedCount)",
                        label: "Completed",
                        color: AppColors.primary.green
                    )

                    statItem(
                        icon: "circle.dashed",
                        value: "\(stats.totalCount - stats.completedCount)",
                        label: "Remaining",
                        color: AppColors.primary.gold
                    )

                    statItem(
                        icon: "percent",
                        value: "\(stats.percentage)",
                        label: "Progress",
                        color: AppColors.primary.teal
                    )
                }

                // All completed celebration
                if stats.isAllCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColors.primary.gold)
                        Text("All prayers completed! ✨")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primary.gold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppColors.primary.gold.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.gold) * 2.5))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stats.completedCount)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(spacing: 12) {
            HStack {
                ThemedText("Settings", style: .heading)
                Spacer()
            }

            // Calculation Method
            Button {
                showMethodPicker = true
            } label: {
                settingRow(
                    icon: "function",
                    title: "Calculation Method",
                    value: viewModel.selectedCalculationMethod.rawValue,
                    color: AppColors.primary.green
                )
            }

            // Madhab
            Button {
                showMadhabPicker = true
            } label: {
                settingRow(
                    icon: "globe",
                    title: "Madhab (Asr Calculation)",
                    value: viewModel.selectedMadhab.rawValue,
                    color: AppColors.primary.teal
                )
            }
        }
    }

    private func settingRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                ThemedText.body(title)
                ThemedText.caption(value)
                    .foregroundColor(color)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .opacity(themeManager.currentTheme.tertiaryOpacity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardColor)
        )
    }

    private var mosqueFinderButton: some View {
        PrimaryButton("Find Nearby Mosques", icon: "location.fill") {
            Task {
                await viewModel.findNearbyMosques()
                showMosqueList = true
            }
        }
    }

    // MARK: - Sheets

    private var mosqueListSheet: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                if viewModel.isLoadingMosques {
                    LoadingView(size: .large, message: "Finding mosques...")
                } else if viewModel.nearbyMosques.isEmpty {
                    emptyMosquesView
                } else {
                    mosquesList
                }
            }
            .navigationTitle("Nearby Mosques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMosqueList = false
                    }
                }
            }
        }
    }

    private var emptyMosquesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            ThemedText.heading("No Mosques Found")
            ThemedText.body("Try adjusting your location or search radius")
                .multilineTextAlignment(.center)
                // Body style already uses textSecondary - no additional opacity needed
        }
        .padding()
    }

    private var mosquesList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.nearbyMosques) { mosque in
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ThemedText(mosque.name, style: .heading)
                                Spacer()
                                Text(mosque.formattedDistance)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.primary.teal)
                            }

                            ThemedText.caption(mosque.address)
                                // Caption style already uses textTertiary - no additional opacity needed

                            if let phone = mosque.phoneNumber {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 12))
                                    ThemedText.caption(phone)
                                }
                                .foregroundColor(AppColors.primary.green)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var methodPickerSheet: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CalculationMethod.allCases) { method in
                            Button {
                                Task {
                                    await viewModel.changeCalculationMethod(method)
                                    showMethodPicker = false
                                }
                            } label: {
                                HStack {
                                    ThemedText.body(method.rawValue)
                                        .foregroundColor(themeManager.currentTheme.textColor)

                                    Spacer()

                                    if method == viewModel.selectedCalculationMethod {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primary.green)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            method == viewModel.selectedCalculationMethod
                                                ? AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green) * 2)
                                                : themeManager.currentTheme.cardColor
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calculation Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMethodPicker = false
                    }
                }
            }
        }
    }

    private var madhabPickerSheet: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Informational note
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary.gold)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("About Madhab Options")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                Text("Only Asr calculation time is affected. Standard covers Shafi, Maliki, and Hanbali schools (shadow = object). Hanafi uses different calculation (shadow = 2× object).")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary.gold.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.gold) * 2))
                        )

                        // Madhab options
                        ForEach(Madhab.allCases) { madhab in
                            Button {
                                Task {
                                    await viewModel.changeMadhab(madhab)
                                    showMadhabPicker = false
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ThemedText.body(madhab.rawValue)
                                                .foregroundColor(themeManager.currentTheme.textColor)

                                            Text(madhab.technicalNote)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(AppColors.primary.teal)
                                                .opacity(themeManager.currentTheme.secondaryOpacity)
                                        }

                                        Spacer()

                                        if madhab == viewModel.selectedMadhab {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppColors.primary.teal)
                                        }
                                    }

                                    // Explanation
                                    Text(madhab.explanation)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(themeManager.currentTheme.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            madhab == viewModel.selectedMadhab
                                                ? AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2)
                                                : themeManager.currentTheme.cardColor
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Madhab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMadhabPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Get special times related to a specific prayer
    private func getRelatedSpecialTimes(for prayer: PrayerTime, from times: DailyPrayerTimes) -> [SpecialTime] {
        var related: [SpecialTime] = []

        switch prayer.name {
        case .fajr:
            // Sunrise ends Fajr
            related.append(SpecialTime(type: .sunrise, time: times.sunrise))

        case .isha:
            // Midnight and last third for night prayers
            if let midnight = times.midnight {
                related.append(SpecialTime(type: .midnight, time: midnight))
            }
            if let lastThird = times.lastThird {
                related.append(SpecialTime(type: .lastThird, time: lastThird))
            }

        default:
            // No special times for other prayers
            break
        }

        return related
    }
}

// MARK: - Preview

#Preview {
    PrayerTimesView()
        .environmentObject(ThemeManager())
}
