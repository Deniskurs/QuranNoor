//
//  NextPrayerCardView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Unified prayer countdown card with consistent layout across all states
//  Uses adaptive colors for urgency indication (psychologically-informed)
//

import SwiftUI

struct NextPrayerCardView: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var prayerVM: PrayerViewModel
    @Binding var selectedTab: Int

    /// Tracks the last state to detect when deadline is crossed
    @State private var lastStateDescription: String = ""

    /// Dynamic update interval based on prayer state (Performance: reduce updates when not urgent)
    @State private var updateInterval: TimeInterval = 1.0

    /// Track view visibility to pause updates when not visible
    @State private var isViewVisible: Bool = true

    /// Completion service for tracking prayer completion (reactive observation)
    @State private var completionService = PrayerCompletionService.shared

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: isViewVisible ? updateInterval : 60.0)) { context in
            LiquidGlassCardView(intensity: .prominent) {
                VStack(spacing: Spacing.md) {
                    if let period = prayerVM.currentPrayerPeriod {
                        unifiedContent(for: period)
                            .onAppear {
                                checkForDeadlineCrossing(period: period, date: context.date)
                                // Update interval based on current state
                                updateInterval = PerformanceOptimizationService.shared.getOptimalUpdateInterval(for: period.state)
                            }
                            .onChange(of: context.date) { _, newDate in
                                checkForDeadlineCrossing(period: period, date: newDate)
                            }
                            .onChange(of: period.state) { _, newState in
                                // Dynamically adjust update frequency based on urgency
                                updateInterval = PerformanceOptimizationService.shared.getOptimalUpdateInterval(for: newState)
                            }
                    } else {
                        loadingContent
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = 2 // Navigate to Prayer tab
            AudioHapticCoordinator.shared.playToast()
        }
        .onAppear {
            isViewVisible = true
        }
        .onDisappear {
            isViewVisible = false
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to open Prayer Times")
    }

    // MARK: - Unified Content (Single Consistent Layout)

    /// The unified layout that adapts via colors, not structure
    /// Layout stays constant - only colors and indicators change based on urgency
    @ViewBuilder
    private func unifiedContent(for period: PrayerPeriod) -> some View {
        let urgency = UrgencyLevel.from(period: period)
        let theme = themeManager.currentTheme

        VStack(spacing: Spacing.md) {
            // Header row - status badge + depleting progress ring
            headerRow(period: period, urgency: urgency, theme: theme)

            // Prayer name
            if let nextPrayer = period.nextPrayer {
                Text(nextPrayer.name.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }

            // HERO COUNTDOWN - Always 56pt, never changes size
            Text(period.countdownString)
                .font(.system(size: 56, weight: .light, design: .rounded))
                .tracking(2)
                .foregroundColor(urgency.countdownColor(for: theme))
                .contentTransition(.numericText())
                .monospacedDigit()
                .animation(.easeInOut(duration: 0.5), value: urgency)

            // Context label
            Text(contextLabel(for: period))
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            // Divider + Prayer completion row (ALWAYS visible)
            if let times = prayerVM.todayPrayerTimes {
                Divider()
                    .padding(.vertical, Spacing.xxxs)

                prayerCompletionRow(times: times.prayerTimes, theme: theme)
            }
        }
    }

    // MARK: - Header Row

    @ViewBuilder
    private func headerRow(period: PrayerPeriod, urgency: UrgencyLevel, theme: ThemeMode) -> some View {
        HStack {
            // Status badge
            statusBadge(period: period, urgency: urgency, theme: theme)

            Spacer()

            // Depleting progress ring (ALWAYS visible)
            DepletingProgressRing(
                period: period,
                theme: theme,
                size: 44,
                lineWidth: 4
            )
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge(period: PrayerPeriod, urgency: UrgencyLevel, theme: ThemeMode) -> some View {
        HStack(spacing: 6) {
            Image(systemName: stateIcon(for: period))
                .font(.system(size: 14, weight: .semibold))

            Text(statusBadgeText(for: period))
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(urgency.badgeForeground(for: theme))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(urgency.badgeBackground(for: theme))
        )
        .animation(.easeInOut(duration: 0.3), value: urgency)
    }

    // MARK: - Prayer Completion Row

    private func prayerCompletionRow(times: [PrayerTime], theme: ThemeMode) -> some View {
        // Read changeCounter to establish observation dependency for instant UI updates
        let _ = completionService.changeCounter

        return HStack(spacing: 16) {
            ForEach(Array(times.prefix(5)), id: \.name) { time in
                let isCompleted = completionService.isCompleted(time.name)

                VStack(spacing: 4) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? theme.accentPrimary : theme.textTertiary)
                        .symbolEffect(.bounce, options: .speed(0.5), value: isCompleted)

                    Text(String(time.name.displayName.prefix(3)))
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(themeManager.currentTheme.accentInteractive)

            Text("Calculating prayer times...")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(40)
    }

    // MARK: - Computed Properties

    /// Icon for the current state
    private func stateIcon(for period: PrayerPeriod) -> String {
        switch period.state {
        case .beforeFajr:
            return "moon.stars.fill"
        case .inProgress:
            return "clock.fill"
        case .betweenPrayers:
            return "clock.fill"
        case .afterIsha:
            return "moon.fill"
        }
    }

    /// Badge text for the current state
    private func statusBadgeText(for period: PrayerPeriod) -> String {
        switch period.state {
        case .beforeFajr:
            return "Before Fajr"
        case .inProgress(let prayer, _):
            return "\(prayer.displayName) Period"
        case .betweenPrayers(_, let next, _):
            return "Until \(next.displayName)"
        case .afterIsha:
            return "After Isha"
        }
    }

    /// Context label below countdown
    private func contextLabel(for period: PrayerPeriod) -> String {
        switch period.state {
        case .beforeFajr:
            return "until Fajr"
        case .inProgress:
            if let next = period.nextPrayer {
                return "until \(next.name.displayName)"
            }
            return "remaining"
        case .betweenPrayers(_, let next, _):
            return "until \(next.displayName)"
        case .afterIsha:
            return "until Fajr"
        }
    }

    /// Accessibility label for VoiceOver
    private var accessibilityLabel: String {
        guard let period = prayerVM.currentPrayerPeriod else {
            return "Loading prayer times"
        }

        let urgency = UrgencyLevel.from(period: period)
        let prayerName = period.nextPrayer?.name.displayName ?? "Prayer"
        let timeRemaining = period.formattedTimeRemaining

        return "\(prayerName) in \(timeRemaining). \(urgency.accessibilityDescription)"
    }

    // MARK: - Deadline Crossing Detection

    /// Checks if the deadline has been crossed and triggers recalculation
    /// This fixes the issue where countdown shows 00:00 but state doesn't update
    private func checkForDeadlineCrossing(period: PrayerPeriod, date: Date) {
        // If countdown has reached or passed 0, recalculate immediately
        if period.timeUntilNextEvent <= 0 {
            // Only recalculate if state hasn't already changed (prevents duplicate calls)
            let currentDescription = period.state.description
            if lastStateDescription != currentDescription || lastStateDescription.isEmpty {
                lastStateDescription = currentDescription
                prayerVM.recalculatePeriod()
            }
        } else {
            // Update tracked state when not at deadline
            let currentDescription = period.state.description
            if lastStateDescription != currentDescription {
                lastStateDescription = currentDescription
            }
        }
    }
}

// MARK: - Preview

#Preview("Light Theme - Normal") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environment(ThemeManager())
        .padding()
        .background(Color(hex: "#F8F4EA"))
        .task {
            await prayerVM.initialize()
        }
}

#Preview("Dark Theme") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.dark)
            return manager
        }())
        .padding()
        .background(Color(hex: "#1A2332"))
        .task {
            await prayerVM.initialize()
        }
}

#Preview("Night Theme") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.night)
            return manager
        }())
        .padding()
        .background(Color.black)
        .task {
            await prayerVM.initialize()
        }
}

#Preview("Sepia Theme") {
    @Previewable @State var prayerVM = PrayerViewModel()
    @Previewable @State var selectedTab = 0

    NextPrayerCardView(prayerVM: prayerVM, selectedTab: $selectedTab)
        .environment({
            let manager = ThemeManager()
            manager.setTheme(.sepia)
            return manager
        }())
        .padding()
        .background(Color(hex: "#F4E8D0"))
        .task {
            await prayerVM.initialize()
        }
}
