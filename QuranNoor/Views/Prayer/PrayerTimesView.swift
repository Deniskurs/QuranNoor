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

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var viewModel = PrayerViewModel()
    @State private var transitionHandler: PrayerTransitionHandler?

    // Completion tracking
    private let completionService = PrayerCompletionService.shared

    // Performance optimization
    @State private var performanceService = PerformanceOptimizationService.shared
    @State private var updateInterval: TimeInterval = 1.0

    // UI State
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

                // Main content with dynamic TimelineView for optimal performance
                TimelineView(.periodic(from: Date(), by: updateInterval)) { context in
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
                                .onChange(of: period.state) { _, newState in
                                    // Update timeline frequency based on prayer state
                                    updateInterval = performanceService.getOptimalUpdateInterval(for: newState)
                                }
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

                            // Qadha Counter
                            qadhaCounterButton
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

                // Perform automatic cache cleanup (runs in background)
                Task.detached(priority: .background) {
                    await performanceService.performAutomaticCacheCleanup()
                }

                // Set initial update interval based on current state
                updateInterval = performanceService.getOptimalUpdateInterval(for: viewModel.currentPrayerPeriod?.state)

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
            .onReceive(NotificationCenter.default.publisher(for: .prayerAdjustmentsChanged)) { _ in
                // Prayer time adjustments changed - refresh prayer times
                Task {
                    print("🔄 Adjustments changed, refreshing prayer times...")
                    await viewModel.refreshPrayerTimes()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showMethodPicker) {
                CalculationMethodPickerView(
                    selectedMethod: $viewModel.selectedCalculationMethod,
                    onMethodChanged: { method in
                        await viewModel.changeCalculationMethod(method)
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMadhabPicker) {
                MadhabPickerView(
                    selectedMadhab: $viewModel.selectedMadhab,
                    onMadhabChanged: { madhab in
                        await viewModel.changeMadhab(madhab)
                    }
                )
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
                    // AudioHapticCoordinator.shared.playBack() // Removed: button press sound

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
                    .foregroundColor(themeManager.currentTheme.accentPrimary)
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
                            // Note: Sound is already played by SmartPrayerRow
                            if isMarkingComplete {
                                completedPrayerName = prayer.name.displayName
                                showCompletionToast = true
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

        return LiquidGlassCardView(intensity: .moderate) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("TODAY'S PROGRESS")
                        ThemedText("Prayer Completion", style: .heading)
                            .foregroundColor(themeManager.currentTheme.accentPrimary)
                    }

                    Spacer()

                    // Completion ring
                    OptimizedProgressRing(
                        progress: Double(stats.completedCount) / Double(stats.totalCount),
                        lineWidth: 6,
                        size: 60,
                        color: stats.isAllCompleted ? themeManager.currentTheme.accentPrimary : themeManager.currentTheme.accentSecondary,
                        showPercentage: true
                    )
                    .accessibilityLabel("Prayer completion progress")
                    .accessibilityValue("\(stats.percentage) percent complete")
                }

                IslamicDivider(style: .simple)

                // Stats row
                HStack(spacing: 20) {
                    statItem(
                        icon: "checkmark.circle.fill",
                        value: "\(stats.completedCount)",
                        label: "Completed",
                        color: themeManager.currentTheme.accentPrimary
                    )

                    statItem(
                        icon: "circle.dashed",
                        value: "\(stats.totalCount - stats.completedCount)",
                        label: "Remaining",
                        color: themeManager.currentTheme.accentInteractive
                    )

                    statItem(
                        icon: "percent",
                        value: "\(stats.percentage)",
                        label: "Progress",
                        color: themeManager.currentTheme.accentSecondary
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Prayer statistics")
                .accessibilityValue("\(stats.completedCount) completed, \(stats.totalCount - stats.completedCount) remaining, \(stats.percentage) percent progress")

                // All completed celebration
                if stats.isAllCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(themeManager.currentTheme.accentInteractive)
                            .accessibilityHidden(true)
                        Text("All prayers completed! ✨")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.accentInteractive)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.accentInteractive.opacity(0.15))
                    )
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Celebration: All today's prayers completed")
                }
            }
            .accessibilityElement(children: .contain)
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
                    color: themeManager.currentTheme.accentPrimary
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
                    color: themeManager.currentTheme.accentSecondary
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
        NavigationLink {
            MosqueFinderView()
                .environment(themeManager)
        } label: {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityHidden(true)
                Text("Find Nearby Mosques")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .accessibilityHidden(true)
            }
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
            )
        }
        .accessibilityLabel("Find nearby mosques")
        .accessibilityHint("Opens map showing mosques near your location")
    }

    private var qadhaCounterButton: some View {
        NavigationLink {
            QadhaCounterView()
                .environment(themeManager)
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityHidden(true)
                Text("Track Qadha Prayers")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()

                // Show total count badge if any qadha prayers exist
                let totalQadha = QadhaTrackerService.shared.totalQadha
                if totalQadha > 0 {
                    Text("\(totalQadha)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .accessibilityLabel("\(totalQadha) qadha prayers pending")
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .accessibilityHidden(true)
            }
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardColor)
            )
        }
        .accessibilityLabel(totalQadhaAccessibilityLabel)
        .accessibilityHint("Opens qadha prayer tracker to manage missed prayers")
    }

    private var totalQadhaAccessibilityLabel: String {
        let totalQadha = QadhaTrackerService.shared.totalQadha
        if totalQadha > 0 {
            return "Track qadha prayers, \(totalQadha) pending"
        } else {
            return "Track qadha prayers"
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
        .environment(ThemeManager())
}
