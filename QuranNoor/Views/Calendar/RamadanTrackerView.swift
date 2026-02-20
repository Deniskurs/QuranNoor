//
//  RamadanTrackerView.swift
//  QuranNoor
//
//  Immersive Ramadan journey tracker — fasting, Qiyam, and spiritual goals
//

import SwiftUI

struct RamadanTrackerView: View {
    @Environment(ThemeManager.self) var themeManager
    @Bindable var calendarService: IslamicCalendarService

    @Environment(\.dismiss) private var dismiss

    @State private var currentTracker: RamadanTracker

    /// Computed from service so they react to moon sighting offset changes
    private var currentYear: Int { calendarService.convertToHijri().year }
    private var currentDay: Int { calendarService.convertToHijri().day }

    init(calendarService: IslamicCalendarService) {
        self.calendarService = calendarService
        self._currentTracker = State(initialValue: calendarService.getCurrentRamadanTracker())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                GradientBackground(style: .home, opacity: 0.15)

                ScrollView {
                    VStack(spacing: Spacing.sectionSpacing) {
                        // Hero header
                        heroHeader

                        // Moon sighting adjustment
                        moonSightingAdjustment

                        // Journey progress
                        journeyProgressCard

                        // Fasting grid
                        fastingSection

                        // Last 10 Nights
                        qiyamSection

                        // Spiritual goals
                        spiritualGoalsSection
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("Ramadan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }
                }
            }
        }
        .presentationBackground(themeManager.currentTheme.backgroundColor)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: Spacing.xs) {
            // Crescent icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: FontSizes.xxxl))
                .foregroundStyle(.linearGradient(
                    colors: [themeManager.currentTheme.accentMuted, themeManager.currentTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: themeManager.currentTheme.accent.opacity(0.3), radius: 12)

            Text("رَمَضَان مُبَارَك")
                .font(.custom("KFGQPCHAFSUthmanicScript-Regular", size: 28, relativeTo: .title))
                .foregroundStyle(themeManager.currentTheme.textPrimary)

            Text("Ramadan \(currentYear) AH")
                .font(.system(size: FontSizes.lg, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textPrimary)

            Text("Day \(currentDay) of 30")
                .font(.system(size: FontSizes.sm, weight: .medium))
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Moon Sighting Adjustment

    private var moonSightingAdjustment: some View {
        CardView(intensity: .subtle) {
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "moon.haze.fill")
                        .font(.system(size: FontSizes.lg))
                        .foregroundStyle(themeManager.currentTheme.accentMuted)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Moon Sighting Adjustment")
                            .font(.system(size: FontSizes.sm, weight: .semibold))
                            .foregroundStyle(themeManager.currentTheme.textPrimary)

                        Text("Align with your local sighting")
                            .font(.system(size: FontSizes.xs))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }

                    Spacer()
                }

                // Stepper row
                HStack {
                    Button {
                        guard calendarService.hijriDayOffset > -3 else { return }
                        calendarService.setHijriDayOffset(calendarService.hijriDayOffset - 1)
                        HapticManager.shared.trigger(.light)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: FontSizes.xl))
                            .foregroundStyle(
                                calendarService.hijriDayOffset > -3
                                    ? themeManager.currentTheme.accent
                                    : themeManager.currentTheme.textTertiary.opacity(0.3)
                            )
                    }
                    .disabled(calendarService.hijriDayOffset <= -3)

                    Spacer()

                    VStack(spacing: 2) {
                        Text(offsetLabel)
                            .font(.system(size: FontSizes.lg, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                            .contentTransition(.numericText())

                        Text("days")
                            .font(.system(size: FontSizes.xs))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }

                    Spacer()

                    Button {
                        guard calendarService.hijriDayOffset < 3 else { return }
                        calendarService.setHijriDayOffset(calendarService.hijriDayOffset + 1)
                        HapticManager.shared.trigger(.light)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: FontSizes.xl))
                            .foregroundStyle(
                                calendarService.hijriDayOffset < 3
                                    ? themeManager.currentTheme.accent
                                    : themeManager.currentTheme.textTertiary.opacity(0.3)
                            )
                    }
                    .disabled(calendarService.hijriDayOffset >= 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.sm)
            }
        }
    }

    private var offsetLabel: String {
        let offset = calendarService.hijriDayOffset
        if offset == 0 { return "0" }
        return offset > 0 ? "+\(offset)" : "\(offset)"
    }

    // MARK: - Journey Progress Card

    private var journeyProgressCard: some View {
        CardView(intensity: .prominent) {
            VStack(spacing: Spacing.sm) {
                // Stats row
                HStack(spacing: Spacing.sm) {
                    progressStat(
                        value: currentTracker.totalFastingDays,
                        total: 30,
                        label: "Fasts",
                        icon: "sun.max.fill"
                    )

                    // Divider
                    Rectangle()
                        .fill(themeManager.currentTheme.textTertiary.opacity(0.3))
                        .frame(width: 1, height: 48)

                    progressStat(
                        value: currentTracker.lastTenNightsCount,
                        total: 10,
                        label: "Qiyam",
                        icon: "moon.stars.fill"
                    )

                    // Divider
                    Rectangle()
                        .fill(themeManager.currentTheme.textTertiary.opacity(0.3))
                        .frame(width: 1, height: 48)

                    progressStat(
                        value: checklistCompleteCount,
                        total: 2,
                        label: "Goals",
                        icon: "checkmark.seal.fill"
                    )
                }

                // Overall progress bar
                VStack(spacing: Spacing.xxxs) {
                    ProgressView(value: overallProgress, total: 1.0)
                        .tint(themeManager.currentTheme.accent)

                    HStack {
                        Text("Overall Journey")
                            .font(.system(size: FontSizes.xs, weight: .medium))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)

                        Spacer()

                        Text("\(Int(overallProgress * 100))%")
                            .font(.system(size: FontSizes.xs, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.currentTheme.accent)
                    }
                }
            }
        }
    }

    private func progressStat(value: Int, total: Int, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Image(systemName: icon)
                .font(.system(size: FontSizes.lg))
                .foregroundStyle(themeManager.currentTheme.accentMuted)

            Text("\(value)/\(total)")
                .font(.system(size: FontSizes.lg, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textPrimary)

            Text(label)
                .font(.system(size: FontSizes.xs, weight: .medium))
                .foregroundStyle(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fasting Section

    private var fastingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(themeManager.currentTheme.accent)
                Text("Daily Fasting")
                    .font(.system(size: FontSizes.lg, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                Spacer()
                Text("\(currentTracker.totalFastingDays)/30")
                    .font(.system(size: FontSizes.sm, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.accent)
            }

            CardView(intensity: .subtle) {
                VStack(spacing: Spacing.xs) {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xxs), count: 7)

                    // Day labels
                    LazyVGrid(columns: columns, spacing: Spacing.xxs) {
                        ForEach(1...30, id: \.self) { day in
                            fastingDayCell(day: day)
                        }
                    }

                    // Hint
                    Text("Tap today or past days to log your fast")
                        .font(.system(size: FontSizes.xs))
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func fastingDayCell(day: Int) -> some View {
        let isCompleted = currentTracker.isFastingCompleted(day: day)
        let isToday = day == currentDay
        let isPast = day < currentDay
        let isFuture = day > currentDay

        return Button {
            guard !isFuture else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentTracker.toggleFasting(day: day)
                calendarService.updateRamadanTracker(currentTracker)
            }
            HapticManager.shared.trigger(isCompleted ? .light : .medium)
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: BorderRadius.md, style: .continuous)
                    .fill(dayBackground(isCompleted: isCompleted, isToday: isToday, isPast: isPast, isFuture: isFuture))
                    .frame(width: 40, height: 40)

                // Today ring
                if isToday {
                    RoundedRectangle(cornerRadius: BorderRadius.md, style: .continuous)
                        .strokeBorder(themeManager.currentTheme.accent, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }

                // Content
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: FontSizes.xs, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(day)")
                        .font(.system(size: FontSizes.sm, weight: isToday ? .bold : .medium, design: .rounded))
                        .foregroundStyle(
                            isFuture
                                ? themeManager.currentTheme.textTertiary.opacity(0.4)
                                : isToday
                                    ? themeManager.currentTheme.accent
                                    : themeManager.currentTheme.textSecondary
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel("Day \(day)\(isCompleted ? ", fasted" : "")\(isToday ? ", today" : "")\(isFuture ? ", upcoming" : "")")
    }

    private func dayBackground(isCompleted: Bool, isToday: Bool, isPast: Bool, isFuture: Bool) -> Color {
        if isCompleted {
            return themeManager.currentTheme.accent
        } else if isFuture {
            return themeManager.currentTheme.textTertiary.opacity(0.04)
        } else if isPast {
            return themeManager.currentTheme.textTertiary.opacity(0.08)
        } else {
            return .clear
        }
    }

    // MARK: - Qiyam Section (Last 10 Nights)

    private var qiyamSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(themeManager.currentTheme.accentMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last 10 Nights")
                        .font(.system(size: FontSizes.lg, weight: .semibold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                    Text("Seek Laylat al-Qadr")
                        .font(.system(size: FontSizes.xs))
                        .foregroundStyle(themeManager.currentTheme.textTertiary)
                }
                Spacer()
                Text("\(currentTracker.lastTenNightsCount)/10")
                    .font(.system(size: FontSizes.sm, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.accentMuted)
            }

            CardView(showPattern: true, intensity: .moderate) {
                VStack(spacing: Spacing.sm) {
                    // Nights grid (2 rows of 5)
                    let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 5)

                    LazyVGrid(columns: columns, spacing: Spacing.xs) {
                        ForEach(21...30, id: \.self) { night in
                            qiyamNightCell(night: night)
                        }
                    }

                    // Legend
                    HStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xxxs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(themeManager.currentTheme.accent)
                            Text("Odd nights — most blessed")
                                .font(.system(size: FontSizes.xs))
                                .foregroundStyle(themeManager.currentTheme.textTertiary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func qiyamNightCell(night: Int) -> some View {
        let isCompleted = currentTracker.isQiyamCompleted(night: night)
        let isOdd = night % 2 != 0
        let isFuture = night > currentDay

        return Button {
            guard !isFuture else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentTracker.toggleQiyam(night: night)
                calendarService.updateRamadanTracker(currentTracker)
            }
            HapticManager.shared.trigger(isCompleted ? .light : .medium)
        } label: {
            VStack(spacing: Spacing.xxxs) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isCompleted ? themeManager.currentTheme.accent : themeManager.currentTheme.accentTint)
                        .frame(width: 50, height: 50)

                    // Odd night indicator ring
                    if isOdd && !isCompleted {
                        Circle()
                            .strokeBorder(
                                themeManager.currentTheme.accent.opacity(0.4),
                                lineWidth: 1.5
                            )
                            .frame(width: 50, height: 50)
                    }

                    // Content
                    VStack(spacing: 1) {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: FontSizes.sm, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Text("\(night)")
                            .font(.system(size: isCompleted ? FontSizes.xs : FontSizes.sm, weight: .semibold, design: .rounded))
                            .foregroundStyle(isCompleted ? .white : themeManager.currentTheme.textPrimary)
                    }

                    // Star for odd nights
                    if isOdd && !isCompleted {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(themeManager.currentTheme.accent)
                                    .offset(x: -2, y: 2)
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.35 : 1.0)
        .accessibilityLabel("Night \(night)\(isCompleted ? ", Qiyam completed" : "")\(isOdd ? ", blessed odd night" : "")\(isFuture ? ", upcoming" : "")")
    }

    // MARK: - Spiritual Goals Section

    private var spiritualGoalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(themeManager.currentTheme.accent)
                Text("Spiritual Goals")
                    .font(.system(size: FontSizes.lg, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                Spacer()
            }

            // Quran completion
            goalRow(
                icon: "book.fill",
                title: "Complete Quran Recitation",
                subtitle: "Read the entire Quran during this blessed month",
                isCompleted: currentTracker.quranCompleted
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentTracker.quranCompleted.toggle()
                    calendarService.updateRamadanTracker(currentTracker)
                }
                HapticManager.shared.trigger(currentTracker.quranCompleted ? .success : .light)
            }

            // Zakat al-Fitr
            goalRow(
                icon: "heart.fill",
                title: "Pay Zakat al-Fitr",
                subtitle: "Obligatory charity before Eid prayer",
                isCompleted: currentTracker.zakahPaid
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentTracker.zakahPaid.toggle()
                    calendarService.updateRamadanTracker(currentTracker)
                }
                HapticManager.shared.trigger(currentTracker.zakahPaid ? .success : .light)
            }
        }
    }

    private func goalRow(
        icon: String,
        title: String,
        subtitle: String,
        isCompleted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CardView(intensity: .subtle) {
                HStack(spacing: Spacing.sm) {
                    // Checkbox
                    ZStack {
                        Circle()
                            .fill(isCompleted ? themeManager.currentTheme.accent : .clear)
                            .frame(width: 28, height: 28)

                        Circle()
                            .strokeBorder(
                                isCompleted ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: FontSizes.xs, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: FontSizes.base, weight: .semibold))
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                            .strikethrough(isCompleted, color: themeManager.currentTheme.textTertiary)

                        Text(subtitle)
                            .font(.system(size: FontSizes.xs))
                            .foregroundStyle(themeManager.currentTheme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: icon)
                        .font(.system(size: FontSizes.lg))
                        .foregroundStyle(isCompleted ? themeManager.currentTheme.accent : themeManager.currentTheme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(isCompleted ? "completed" : "not completed")")
    }

    // MARK: - Computed Properties

    private var checklistCompleteCount: Int {
        var count = 0
        if currentTracker.quranCompleted { count += 1 }
        if currentTracker.zakahPaid { count += 1 }
        return count
    }

    private var overallProgress: Double {
        let fastingWeight = 0.6
        let qiyamWeight = 0.25
        let goalsWeight = 0.15

        let fastingProgress = Double(currentTracker.totalFastingDays) / 30.0
        let qiyamProgress = Double(currentTracker.lastTenNightsCount) / 10.0
        let goalsProgress = Double(checklistCompleteCount) / 2.0

        return (fastingProgress * fastingWeight) + (qiyamProgress * qiyamWeight) + (goalsProgress * goalsWeight)
    }
}

// MARK: - Preview

#Preview {
    RamadanTrackerView(calendarService: IslamicCalendarService())
        .environment(ThemeManager())
}
