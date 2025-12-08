//
//  PrayerTimesView.swift
//  QuranNoor
//
//  Redesigned prayer times view with immersive hero section,
//  arc timeline, swipeable rows, and celebration effects.
//  Complete UI/UX overhaul for premium experience.
//

import SwiftUI

/// Redesigned Prayer Times view with premium visual experience
struct PrayerTimesView: View {
    // MARK: - Properties

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var viewModel = PrayerViewModel()
    @State private var transitionHandler: PrayerTransitionHandler?

    // Note: Access singletons directly - don't wrap in @State

    // UI State
    @State private var showMethodPicker: Bool = false
    @State private var showMadhabPicker: Bool = false
    @State private var showPrayerReminder: Bool = false
    @State private var hasShownReminderThisSession: Bool = false

    // Toast state for prayer completion
    @State private var showCompletionToast: Bool = false
    @State private var completedPrayerName: String = ""
    @State private var lastCompletedPrayer: PrayerName? = nil

    // View visibility tracking
    @State private var isViewVisible: Bool = true

    // Namespace for scroll animations
    @Namespace private var scrollNamespace

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Base background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Main content - Fixed 1s interval for reliable countdown updates
                TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                // Immersive Hero Section
                                if let period = viewModel.currentPrayerPeriod {
                                    PrayerHeroSection(
                                        period: period,
                                        currentTime: context.date,  // Live time for real-time countdown
                                        location: viewModel.userLocation,
                                        isLoadingLocation: viewModel.isLoadingLocation
                                    )
                                }

                                // Today's Prayers List
                                if let times = viewModel.todayPrayerTimes {
                                    prayerListSection(times, scrollProxy: scrollProxy)
                                }

                                // Completion Statistics with Celebration
                                CelebrationCompletionCard()

                                // Settings Section
                                settingsSection

                                // Mosque Finder
                                mosqueFinderButton

                                // Qadha Counter
                                qadhaCounterButton

                                // Bottom padding
                                Spacer()
                                    .frame(height: 20)
                            }
                            .padding(.horizontal, 16)
                        }
                        .refreshable {
                            await viewModel.refreshPrayerTimes()
                        }
                    }
                }

                // Loading overlay
                if viewModel.isLoadingPrayerTimes {
                    LoadingOverlay()
                }

                // Prayer reminder popup
                if showPrayerReminder,
                   let currentPrayer = viewModel.currentPrayer,
                   let times = viewModel.todayPrayerTimes,
                   let prayer = times.prayerTimes.first(where: { $0.name == currentPrayer }) {
                    PrayerReminderPopup(
                        prayer: prayer,
                        onComplete: {
                            PrayerCompletionService.shared.toggleCompletion(currentPrayer)
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
                await initializeView()
            }
            .onAppear {
                isViewVisible = true
            }
            .onDisappear {
                isViewVisible = false
                transitionHandler?.stop()
            }
            .onReceive(NotificationCenter.default.publisher(for: .prayerAdjustmentsChanged)) { _ in
                Task {
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
                    if let prayer = lastCompletedPrayer {
                        PrayerCompletionService.shared.toggleCompletion(prayer)
                        lastCompletedPrayer = nil
                    }
                }
            )
        }
    }

    // MARK: - View Initialization

    private func initializeView() async {
        await viewModel.initialize()

        // Start transition handler
        let handler = PrayerTransitionHandler(viewModel: viewModel)
        handler.start()
        transitionHandler = handler

        // Initial period calculation
        viewModel.recalculatePeriod()

        // Background cache cleanup
        Task.detached(priority: .background) {
            await PerformanceOptimizationService.shared.performAutomaticCacheCleanup()
        }

        // Show prayer reminder popup
        if !hasShownReminderThisSession,
           let currentPrayer = viewModel.currentPrayer,
           !PrayerCompletionService.shared.isCompleted(currentPrayer) {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showPrayerReminder = true
                hasShownReminderThisSession = true
            }
        }
    }

    // MARK: - Completed Prayers Set

    private var completedPrayersSet: Set<PrayerName> {
        let _ = PrayerCompletionService.shared.changeCounter
        return Set(PrayerName.allCases.filter { PrayerCompletionService.shared.isCompleted($0) })
    }

    // MARK: - Prayer List Section

    private func prayerListSection(_ times: DailyPrayerTimes, scrollProxy: ScrollViewProxy) -> some View {
        // Observe completion state at parent level - prevents gesture interference in child rows
        let _ = PrayerCompletionService.shared.changeCounter

        return VStack(spacing: 0) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S PRAYERS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .tracking(1.5)

                    Text(formattedDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                // Swipe hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 10, weight: .medium))
                    Text("Swipe to complete")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .opacity(0.7)
            }
            .padding(.bottom, 16)

            // Prayer rows - isCompleted passed from parent to avoid @Observable in gesture views
            VStack(spacing: 10) {
                ForEach(times.prayerTimes) { prayer in
                    let isCompleted = PrayerCompletionService.shared.isCompleted(prayer.name)

                    SwipeablePrayerRow(
                        prayer: prayer,
                        isCurrentPrayer: prayer.name == viewModel.currentPrayer,
                        isNextPrayer: prayer.name == viewModel.nextPrayer?.name,
                        relatedSpecialTimes: getRelatedSpecialTimes(for: prayer, from: times),
                        canCheckOff: prayer.hasStarted,
                        isCompleted: isCompleted,
                        onCompletionToggle: {
                            handlePrayerCompletion(prayer.name)
                        }
                    )
                    .id(prayer.name.rawValue)
                }
            }
        }
    }

    // MARK: - Prayer Completion Handler

    private func handlePrayerCompletion(_ prayer: PrayerName) {
        lastCompletedPrayer = prayer
        let isMarkingComplete = !PrayerCompletionService.shared.isCompleted(prayer)

        PrayerCompletionService.shared.toggleCompletion(prayer)

        if isMarkingComplete {
            completedPrayerName = prayer.displayName
            showCompletionToast = true
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("SETTINGS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .tracking(1.5)
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
                    title: "Madhab (Asr)",
                    value: viewModel.selectedMadhab.rawValue,
                    color: themeManager.currentTheme.accentSecondary
                )
            }
        }
    }

    private func settingRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeManager.currentTheme.cardColor)
        )
    }

    // MARK: - Mosque Finder Button

    private var mosqueFinderButton: some View {
        NavigationLink {
            MosqueFinderView()
                .environment(themeManager)
                .environmentObject(LocationService.shared)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.accentInteractive.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.accentInteractive)
                }

                Text("Find Nearby Mosques")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentTheme.cardColor)
            )
        }
        .accessibilityLabel("Find nearby mosques")
    }

    // MARK: - Qadha Counter Button

    private var qadhaCounterButton: some View {
        NavigationLink {
            QadhaCounterView()
                .environment(themeManager)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                }

                Text("Track Qadha Prayers")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                // Badge for pending qadha
                let totalQadha = QadhaTrackerService.shared.totalQadha
                if totalQadha > 0 {
                    Text("\(totalQadha)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentTheme.cardColor)
            )
        }
        .accessibilityLabel(qadhaAccessibilityLabel)
    }

    private var qadhaAccessibilityLabel: String {
        let totalQadha = QadhaTrackerService.shared.totalQadha
        if totalQadha > 0 {
            return "Track qadha prayers, \(totalQadha) pending"
        }
        return "Track qadha prayers"
    }

    // MARK: - Helper Methods

    private var formattedDate: String {
        Self.dayDateFormatter.string(from: Date())
    }

    // Cached DateFormatter for performance
    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private func getRelatedSpecialTimes(for prayer: PrayerTime, from times: DailyPrayerTimes) -> [SpecialTime] {
        var related: [SpecialTime] = []

        switch prayer.name {
        case .fajr:
            related.append(SpecialTime(type: .sunrise, time: times.sunrise))
        case .isha:
            if let midnight = times.midnight {
                related.append(SpecialTime(type: .midnight, time: midnight))
            }
            if let lastThird = times.lastThird {
                related.append(SpecialTime(type: .lastThird, time: lastThird))
            }
        default:
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
