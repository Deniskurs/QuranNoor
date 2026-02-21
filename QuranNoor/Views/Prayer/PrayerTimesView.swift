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
    @Bindable var viewModel: PrayerViewModel
    @State private var transitionHandler: PrayerTransitionHandler?

    // Note: Access singletons directly - don't wrap in @State
    private let hijriService = HijriCalendarService()
    @State private var islamicCalendarService = IslamicCalendarService()

    // UI State
    @State private var showMethodPicker: Bool = false
    @State private var showMadhabPicker: Bool = false
    @State private var showPrayerReminder: Bool = false
    @State private var hasShownReminderThisSession: Bool = false

    // Toast state for prayer completion
    @State private var showCompletionToast: Bool = false
    @State private var completedPrayerName: String = ""
    @State private var lastCompletedPrayer: PrayerName? = nil

    // Namespace for scroll animations
    @Namespace private var scrollNamespace

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Base background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay
                GradientBackground(style: .prayer, opacity: 0.3)

                // Main content
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: Spacing.sectionSpacing) {
                            // Arabic calligraphy header with Hijri date
                            prayerHeader

                            // Immersive Hero Section — only this needs per-second updates
                            if let period = viewModel.currentPrayerPeriod {
                                    PrayerHeroSection(
                                    period: period,
                                    location: viewModel.userLocation,
                                    isLoadingLocation: viewModel.isLoadingLocation
                                )
                            }

                            // Islamic divider after hero
                            IslamicDivider(style: .ornamental)

                            // Ramadan Suhoor/Iftar banner (shown only during Ramadan)
                            if islamicCalendarService.isRamadan(),
                               let times = viewModel.todayPrayerTimes {
                                ramadanBanner(times: times)
                            }

                            // Today's Prayers List (static — no per-second updates needed)
                            if viewModel.isLoadingPrayerTimes {
                                // Loading state
                                VStack(spacing: Spacing.sm) {
                                    LoadingView(size: .large, message: "Calculating prayer times...")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xl)
                            } else if let times = viewModel.todayPrayerTimes {
                                prayerListSection(times, scrollProxy: scrollProxy)
                            } else if !viewModel.isLoadingLocation {
                                // Empty state - no location available
                                emptyLocationState
                            }

                            // Completion Statistics with Celebration
                            CelebrationCompletionCard()

                            // Islamic divider before settings
                            IslamicDivider(style: .ornamental)

                            // Settings, Mosque Finder, and Qadha grouped in CardView
                            settingsActionsCard

                            // Bottom padding
                            Spacer()
                                .frame(height: Spacing.screenPadding)
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                    }
                    .refreshable {
                        await viewModel.refreshPrayerTimes()
                    }
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
                    Button {
                        Task { await viewModel.refreshPrayerTimes() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: FontSizes.lg, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.accentMuted)
                    }
                }
            }
            .task {
                await initializeView()
            }
            .onDisappear {
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

    // MARK: - Prayer Header

    private var prayerHeader: some View {
        VStack(spacing: 6) {
            Text("أوقات الصلاة")
                .font(.system(size: 34, weight: .regular, design: .default))
                .foregroundColor(themeManager.currentTheme.accent)

            Text("PRAYER TIMES")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)

            // Hijri date if available
            if let hijriDate = hijriService.getCachedHijriDate() {
                Text(hijriDate.formatted)
                    .font(.system(size: FontSizes.xs, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxs)
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

    // MARK: - Prayer List Section

    private func prayerListSection(_ times: DailyPrayerTimes, scrollProxy: ScrollViewProxy) -> some View {
        // Observe completion state at parent level - prevents gesture interference in child rows
        let _ = PrayerCompletionService.shared.changeCounter

        return VStack(spacing: 0) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S PRAYERS")
                        .sectionHeaderStyle()
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    // Date with Hijri inline
                    if let hijriDate = hijriService.getCachedHijriDate() {
                        Text("\(formattedDate) · \(hijriDate.formatted)")
                            .font(.system(size: FontSizes.sm, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .monospacedDigit()
                    } else {
                        Text(formattedDate)
                            .font(.system(size: FontSizes.sm, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                // Swipe hint
                HStack(spacing: Spacing.xxxs) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: FontSizes.xs, weight: .medium))
                    Text("Swipe")
                        .font(.system(size: FontSizes.xs, weight: .medium))
                }
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .opacity(0.5)
            }
            .padding(.bottom, Spacing.sm)

            // Prayer rows - isCompleted passed from parent to avoid @Observable in gesture views
            VStack(spacing: Spacing.xxs) {
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

    // MARK: - Settings & Actions Card

    private var settingsActionsCard: some View {
        CardView(intensity: .subtle) {
            VStack(spacing: 0) {
                // Settings section header
                HStack {
                    Text("SETTINGS")
                        .sectionHeaderStyle()
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                    Spacer()
                }
                .padding(.bottom, Spacing.xs)

                // Calculation Method
                Button {
                    showMethodPicker = true
                } label: {
                    settingRow(
                        icon: "function",
                        title: "Calculation Method",
                        value: viewModel.selectedCalculationMethod.rawValue,
                        color: themeManager.currentTheme.accent
                    )
                }

                IslamicDivider(style: .simple)
                    .padding(.vertical, Spacing.xs)

                // Madhab
                Button {
                    showMadhabPicker = true
                } label: {
                    settingRow(
                        icon: "globe",
                        title: "Madhab (Asr)",
                        value: viewModel.selectedMadhab.rawValue,
                        color: themeManager.currentTheme.accentMuted
                    )
                }

                IslamicDivider(style: .simple)
                    .padding(.vertical, Spacing.xs)

                // Mosque Finder
                NavigationLink {
                    MosqueFinderView()
                        .environment(themeManager)
                        .environment(LocationService.shared)
                } label: {
                    mosqueFinderRow
                }
                .accessibilityLabel("Find nearby mosques")

                IslamicDivider(style: .simple)
                    .padding(.vertical, Spacing.xs)

                // Qadha Counter
                NavigationLink {
                    QadhaCounterView()
                        .environment(themeManager)
                } label: {
                    qadhaCounterRow
                }
                .accessibilityLabel(qadhaAccessibilityLabel)
            }
        }
    }

    // MARK: - Settings Section

    private func settingRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: Spacing.xl, height: Spacing.xl)

                Image(systemName: icon)
                    .font(.system(size: FontSizes.base, weight: .medium))
                    .foregroundColor(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: FontSizes.sm, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(value)
                    .font(.system(size: FontSizes.xs, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    // MARK: - Mosque Finder Row

    private var mosqueFinderRow: some View {
        HStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.accent.opacity(0.15))
                    .frame(width: Spacing.xl, height: Spacing.xl)

                Image(systemName: "building.2.fill")
                    .font(.system(size: FontSizes.base, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accent)
            }

            Text("Find Nearby Mosques")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    // MARK: - Qadha Counter Row

    private var qadhaCounterRow: some View {
        HStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.accentMuted.opacity(0.15))
                    .frame(width: Spacing.xl, height: Spacing.xl)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: FontSizes.base, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.accentMuted)
            }

            Text("Track Qadha Prayers")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            // Badge for pending qadha
            let totalQadha = QadhaTrackerService.shared.totalQadha
            if totalQadha > 0 {
                Text("\(totalQadha)")
                    .font(.system(size: FontSizes.xs, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, Spacing.xxxs)
                    .background(Capsule().fill(themeManager.currentTheme.accentMuted))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }

    private var qadhaAccessibilityLabel: String {
        let totalQadha = QadhaTrackerService.shared.totalQadha
        if totalQadha > 0 {
            return "Track qadha prayers, \(totalQadha) pending"
        }
        return "Track qadha prayers"
    }

    // MARK: - Empty Location State

    private var emptyLocationState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(themeManager.currentTheme.textTertiary)
                .padding(.bottom, Spacing.xxs)

            Text("Location Required")
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text("We need your location to calculate accurate prayer times for your area.")
                .font(.system(size: FontSizes.sm))
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            PrimaryButton("Grant Location Permission", icon: "location.fill") {
                Task {
                    await viewModel.loadPrayerTimes()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Ramadan Banner

    private static let ramadanTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = Locale.autoupdatingCurrent
        return f
    }()

    private func ramadanBanner(times: DailyPrayerTimes) -> some View {
        HStack(spacing: Spacing.md) {
            // Suhoor
            HStack(spacing: Spacing.xxxs + 2) {
                Image(systemName: "moon.fill")
                    .font(.system(size: FontSizes.sm))
                    .foregroundStyle(themeManager.currentTheme.accentMuted)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Suhoor")
                        .font(.system(size: FontSizes.xs, weight: .medium))
                        .foregroundStyle(themeManager.currentTheme.textSecondary)

                    Text(Self.ramadanTimeFormatter.string(from: times.imsak ?? times.fajr))
                        .font(.system(size: FontSizes.base, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Iftar
            HStack(spacing: Spacing.xxxs + 2) {
                Image(systemName: "sunset.fill")
                    .font(.system(size: FontSizes.sm))
                    .foregroundStyle(themeManager.currentTheme.accentMuted)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Iftar")
                        .font(.system(size: FontSizes.xs, weight: .medium))
                        .foregroundStyle(themeManager.currentTheme.textSecondary)

                    Text(Self.ramadanTimeFormatter.string(from: times.maghrib))
                        .font(.system(size: FontSizes.base, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.md)
                .fill(themeManager.currentTheme.accent.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ramadan: Suhoor at \(Self.ramadanTimeFormatter.string(from: times.imsak ?? times.fajr)), Iftar at \(Self.ramadanTimeFormatter.string(from: times.maghrib))")
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
    PrayerTimesView(viewModel: PrayerViewModel())
        .environment(ThemeManager())
}
