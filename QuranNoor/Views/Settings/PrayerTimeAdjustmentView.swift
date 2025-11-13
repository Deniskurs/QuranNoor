//
//  PrayerTimeAdjustmentView.swift
//  QuranNoor
//
//  Created by Claude Code
//  View for manually adjusting prayer times to sync with local mosque
//

import SwiftUI

struct PrayerTimeAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var adjustmentService = PrayerTimeAdjustmentService.shared
    @State private var showResetAllConfirmation = false
    @State private var showInfoSheet = false
    @State private var adjustmentsChanged = false

    // Callback to notify parent when adjustments change (for prayer time refresh)
    var onAdjustmentsChanged: (() -> Void)?

    // Local state for smooth slider animation
    @State private var localAdjustments: [PrayerName: Double] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    if adjustmentService.hasAdjustments {
                        summaryCard
                    }

                    // Information Banner
                    infoBanner

                    // Individual Prayer Adjustments
                    VStack(spacing: 16) {
                        ForEach(PrayerName.allCases, id: \.self) { prayer in
                            PrayerAdjustmentRow(
                                prayer: prayer,
                                adjustment: Binding(
                                    get: { localAdjustments[prayer] ?? Double(adjustmentService.getAdjustment(for: prayer)) },
                                    set: { newValue in
                                        localAdjustments[prayer] = newValue
                                        adjustmentService.setAdjustment(for: prayer, minutes: Int(newValue))
                                        adjustmentsChanged = true
                                    }
                                ),
                                onReset: {
                                    resetPrayerWithFeedback(prayer)
                                    adjustmentsChanged = true
                                }
                            )
                        }
                    }

                    // Action Buttons
                    actionButtons

                    // Detailed Information Card
                    detailedInfoCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Adjust Prayer Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .alert("Reset All Adjustments?", isPresented: $showResetAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset All", role: .destructive) {
                    resetAllWithFeedback()
                }
            } message: {
                Text("This will reset all prayer time adjustments to 0. Your local mosque sync will be lost.")
            }
            .sheet(isPresented: $showInfoSheet) {
                AdjustmentInfoSheet()
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                // Initialize local adjustments
                for prayer in PrayerName.allCases {
                    localAdjustments[prayer] = Double(adjustmentService.getAdjustment(for: prayer))
                }
            }
            .onDisappear {
                // Notify parent if adjustments were changed
                if adjustmentsChanged {
                    onAdjustmentsChanged?()
                }
            }
        }
    }

    // MARK: - Components

    private var summaryCard: some View {
        LiquidGlassCardView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Times Active")
                            .font(.headline)
                            .foregroundStyle(themeManager.primaryTextColor)

                        Text("\(adjustmentService.adjustedPrayerCount) prayer\(adjustmentService.adjustedPrayerCount != 1 ? "s" : "") adjusted")
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }

                    Spacer()
                }

                Divider()

                VStack(spacing: 6) {
                    ForEach(PrayerName.allCases.filter { adjustmentService.isAdjusted($0) }, id: \.self) { prayer in
                        HStack {
                            Text(prayer.displayName)
                                .font(.subheadline)
                                .foregroundStyle(themeManager.primaryTextColor)

                            Spacer()

                            Text(adjustmentService.formatAdjustment(adjustmentService.getAdjustment(for: prayer)))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(
                                    adjustmentService.getAdjustment(for: prayer) > 0
                                    ? Color.orange
                                    : themeManager.accentColor
                                )
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var infoBanner: some View {
        LiquidGlassCardView {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync with Your Mosque")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text("Adjust times to match your local mosque's schedule")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(14)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if adjustmentService.hasAdjustments {
                Button {
                    showResetAllConfirmation = true
                    AudioHapticCoordinator.shared.playWarning()
                } label: {
                    Label("Reset All", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var detailedInfoCard: some View {
        LiquidGlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("When to Use Adjustments", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.accentColor)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Your mosque announces prayer times slightly different from calculated times")
                    bulletPoint("You want to pray a few minutes earlier for safety margin")
                    bulletPoint("Local community follows specific timing conventions")
                    bulletPoint("Accounting for call-to-prayer (adhan) vs. iqamah time")
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("How It Works")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text("Adjustments are applied after calculating prayer times. Negative values make prayers earlier, positive values make them later. All notifications and reminders will use the adjusted times.")
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(themeManager.accentColor)

            Text(text)
                .font(.caption)
                .foregroundStyle(themeManager.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helper Methods

    private func resetPrayerWithFeedback(_ prayer: PrayerName) {
        AudioHapticCoordinator.shared.playButtonPress()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            localAdjustments[prayer] = 0
            adjustmentService.resetAdjustment(for: prayer)
        }
    }

    private func resetAllWithFeedback() {
        AudioHapticCoordinator.shared.playSuccess()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            adjustmentService.resetAllAdjustments()
            for prayer in PrayerName.allCases {
                localAdjustments[prayer] = 0
            }
            adjustmentsChanged = true
        }
    }
}

// MARK: - PrayerAdjustmentRow

struct PrayerAdjustmentRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let prayer: PrayerName
    @Binding var adjustment: Double
    let onReset: () -> Void

    private var adjustmentInt: Int {
        Int(adjustment)
    }

    private var isAdjusted: Bool {
        adjustmentInt != 0
    }

    var body: some View {
        LiquidGlassCardView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: prayer.icon)
                            .font(.title3)
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(prayer.displayName)
                                .font(.headline)
                                .foregroundStyle(themeManager.primaryTextColor)

                            if isAdjusted {
                                Text(formatDescription())
                                    .font(.caption2)
                                    .foregroundStyle(themeManager.secondaryTextColor)
                            }
                        }
                    }

                    Spacer()

                    // Adjustment Value Display
                    VStack(spacing: 2) {
                        Text(formatAdjustment())
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                adjustmentInt == 0
                                ? themeManager.secondaryTextColor
                                : (adjustmentInt > 0 ? Color.orange : themeManager.accentColor)
                            )
                            .contentTransition(.numericText())

                        if isAdjusted {
                            Text(adjustmentInt > 0 ? "later" : "earlier")
                                .font(.caption2)
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                    }
                    .frame(minWidth: 70)
                }

                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $adjustment,
                        in: Double(PrayerTimeAdjustmentService.minAdjustment)...Double(PrayerTimeAdjustmentService.maxAdjustment),
                        step: 1
                    ) {
                        Text("Adjustment")
                    } minimumValueLabel: {
                        Text("\(PrayerTimeAdjustmentService.minAdjustment)")
                            .font(.caption2)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    } maximumValueLabel: {
                        Text("+\(PrayerTimeAdjustmentService.maxAdjustment)")
                            .font(.caption2)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                    .tint(adjustmentInt == 0 ? themeManager.secondaryTextColor : themeManager.accentColor)
                    .onChange(of: adjustment) { _, _ in
                        AudioHapticCoordinator.shared.playHapticOnly(.light)
                    }

                    // Slider markers
                    HStack {
                        ForEach([PrayerTimeAdjustmentService.minAdjustment, -15, 0, 15, PrayerTimeAdjustmentService.maxAdjustment], id: \.self) { value in
                            if value == 0 {
                                Spacer()
                                Text("0")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(themeManager.accentColor)
                                Spacer()
                            } else {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }

                // Reset Button
                if isAdjusted {
                    Button {
                        onReset()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to 0")
                            Spacer()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(.vertical, 8)
                        .background(themeManager.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(16)
        }
    }

    private func formatAdjustment() -> String {
        if adjustmentInt == 0 {
            return "0 min"
        } else if adjustmentInt > 0 {
            return "+\(adjustmentInt) min"
        } else {
            return "\(adjustmentInt) min"
        }
    }

    private func formatDescription() -> String {
        let absValue = abs(adjustmentInt)
        if adjustmentInt > 0 {
            return "\(absValue) min later than calculated"
        } else {
            return "\(absValue) min earlier than calculated"
        }
    }
}

// MARK: - AdjustmentInfoSheet

struct AdjustmentInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(themeManager.accentColor)

                        Text("Prayer Time Adjustments")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(themeManager.primaryTextColor)

                        Text("Fine-tune prayer times to match your local mosque or personal preferences")
                            .font(.subheadline)
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    // Use Cases
                    infoSection(
                        title: "Common Use Cases",
                        icon: "star.fill",
                        items: [
                            "Your mosque follows slightly different times than calculated",
                            "You want to pray a few minutes early for safety margin (precaution)",
                            "Accounting for adhan vs. iqamah difference",
                            "Local community conventions or scholarly opinions"
                        ]
                    )

                    // How It Works
                    infoSection(
                        title: "How Adjustments Work",
                        icon: "gearshape.fill",
                        items: [
                            "Adjustments are applied after calculating prayer times",
                            "Range: 30 minutes earlier to 30 minutes later",
                            "All notifications use adjusted times automatically",
                            "Adjustments are saved and persist across app restarts"
                        ]
                    )

                    // Examples
                    infoSection(
                        title: "Examples",
                        icon: "lightbulb.fill",
                        items: [
                            "Set Fajr -5 min to pray before calculated time",
                            "Set Isha +10 min to match your mosque's later iqamah",
                            "Set all prayers +3 min for comfortable preparation time",
                            "Set Asr -2 min to pray in the preferred early period"
                        ]
                    )

                    // Important Notes
                    LiquidGlassCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Important Notes", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(Color.orange)

                            VStack(alignment: .leading, spacing: 8) {
                                noteItem("Adjustments don't change the calculation method")
                                noteItem("Always verify times with your local mosque")
                                noteItem("Large adjustments (>15 min) should be used carefully")
                                noteItem("Consider using a more suitable calculation method instead of large adjustments")
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("About Adjustments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func infoSection(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(themeManager.primaryTextColor)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(themeManager.accentColor)

                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func noteItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.orange)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundStyle(themeManager.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrayerTimeAdjustmentView()
        .environment(ThemeManager())
}
