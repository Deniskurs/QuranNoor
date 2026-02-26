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
    var prayerVM: PrayerViewModel
    @Binding var selectedTab: Int

    /// Track view visibility to pause updates when not visible
    @State private var isViewVisible: Bool = true

    /// Completion service for tracking prayer completion (reactive observation)
    @State private var completionService = PrayerCompletionService.shared

    // MARK: - Body

    var body: some View {
        CardView(intensity: .prominent) {
            ZStack {
                // Subtle time-of-day gradient wash
                timeOfDayGradient
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))

                // Existing content
                VStack(spacing: Spacing.md) {
                    if let period = prayerVM.currentPrayerPeriod {
                        unifiedContent(for: period)
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
                    .font(.system(size: FontSizes.xl + 4, weight: .bold))
                    .foregroundColor(theme.textPrimary)
            }

            // HERO COUNTDOWN - Narrow TimelineView wraps ONLY the countdown text
            // so the rest of the card doesn't rebuild every second
            TimelineView(.periodic(from: .now, by: isViewVisible ? 1.0 : 60.0)) { context in
                let deadline = period.state.nextEventTime
                let interval = max(deadline.timeIntervalSince(context.date), 0)
                let hours = Int(interval) / 3600
                let minutes = (Int(interval) % 3600) / 60
                let seconds = Int(interval) % 60
                let liveCountdown = hours > 0
                    ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                    : String(format: "%02d:%02d", minutes, seconds)

                Text(liveCountdown)
                    .font(.system(size: FontSizes.xxxl + 8, weight: .light, design: .rounded))
                    .tracking(2)
                    .foregroundColor(urgency.countdownColor(for: theme))
                    .contentTransition(.numericText(countsDown: true))
                    .monospacedDigit()
                    .animation(.linear(duration: 0.3), value: liveCountdown)
                    .onChange(of: liveCountdown) { _, newValue in
                        // Only check for deadline crossing when countdown reaches zero
                        if newValue == "00:00" || newValue == "00:00:00" {
                            prayerVM.recalculatePeriod()
                        }
                    }
            }

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
        HStack(spacing: Spacing.xxxs + 2) {
            Image(systemName: stateIcon(for: period))
                .font(.system(size: FontSizes.sm, weight: .semibold))

            Text(statusBadgeText(for: period))
                .font(.system(size: FontSizes.xs - 1, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundColor(urgency.badgeForeground(for: theme))
        .padding(.horizontal, Spacing.xxs + 2)
        .padding(.vertical, Spacing.xxxs + 2)
        .background(
            RoundedRectangle(cornerRadius: BorderRadius.md)
                .fill(urgency.badgeBackground(for: theme))
        )
        .animation(.easeInOut(duration: 0.3), value: urgency)
    }

    // MARK: - Prayer Completion Row

    private func prayerCompletionRow(times: [PrayerTime], theme: ThemeMode) -> some View {
        // Read changeCounter to establish observation dependency for instant UI updates
        let _ = completionService.changeCounter

        return HStack(spacing: Spacing.sm) {
            ForEach(Array(times.prefix(5)), id: \.name) { time in
                let isCompleted = completionService.isCompleted(time.name)

                VStack(spacing: Spacing.xxxs) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? theme.accent : theme.textTertiary)
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
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(themeManager.currentTheme.accent)

            Text("Calculating prayer times...")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Time-of-Day Gradient

    /// Subtle atmospheric gradient wash based on time of day and theme.
    /// Returns Color.clear for sepia (no gradient overlay needed).
    @ViewBuilder
    private var timeOfDayGradient: some View {
        let period = TimeOfDayPeriod.current()
        let theme = themeManager.currentTheme

        if theme == .sepia {
            Color.clear
        } else {
            LinearGradient(
                colors: gradientColors(for: period, theme: theme),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.2)
        }
    }

    /// Returns 2-3 color stops at low opacity for the given period and theme.
    private func gradientColors(for period: TimeOfDayPeriod, theme: ThemeMode) -> [Color] {
        switch theme {
        case .light:
            switch period {
            case .preDawn, .night:
                return [
                    Color(hex: "#1A1A2E").opacity(0.8),
                    Color(hex: "#2C3E50").opacity(0.5),
                    Color.clear
                ]
            case .dawn:
                return [
                    Color(hex: "#E8C4A0").opacity(0.6),
                    Color(hex: "#FFD4A0").opacity(0.4),
                    Color.clear
                ]
            case .morning, .afternoon:
                return [
                    Color(hex: "#87CEEB").opacity(0.5),
                    Color(hex: "#E0F6FF").opacity(0.3),
                    Color.clear
                ]
            case .sunset:
                return [
                    Color(hex: "#5D4E6D").opacity(0.5),
                    Color(hex: "#C88B4A").opacity(0.4),
                    Color(hex: "#FFB366").opacity(0.3)
                ]
            }
        case .dark:
            switch period {
            case .preDawn, .night:
                return [
                    Color(hex: "#0D7377").opacity(0.3),
                    Color(hex: "#0D1419").opacity(0.5),
                    Color.clear
                ]
            case .dawn:
                return [
                    Color(hex: "#C7A566").opacity(0.25),
                    Color(hex: "#1A2332").opacity(0.4),
                    Color.clear
                ]
            case .morning, .afternoon:
                return [
                    Color(hex: "#14FFEC").opacity(0.15),
                    Color(hex: "#1A2332").opacity(0.3),
                    Color.clear
                ]
            case .sunset:
                return [
                    Color(hex: "#C7A566").opacity(0.2),
                    Color(hex: "#1A2332").opacity(0.4),
                    Color.clear
                ]
            }
        case .night:
            switch period {
            case .preDawn, .dawn:
                return [
                    Color(hex: "#FFD700").opacity(0.08),
                    Color.clear,
                    Color.clear
                ]
            case .morning, .afternoon:
                return [
                    Color(hex: "#14FFEC").opacity(0.06),
                    Color.clear,
                    Color.clear
                ]
            case .sunset:
                return [
                    Color(hex: "#FF6B6B").opacity(0.08),
                    Color.clear,
                    Color.clear
                ]
            case .night:
                return [Color.clear, Color.clear]
            }
        case .sepia:
            return [Color.clear]
        }
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
