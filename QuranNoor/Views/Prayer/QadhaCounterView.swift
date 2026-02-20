//
//  QadhaCounterView.swift
//  QuranNoor
//
//  Created by Claude Code
//  View for tracking and managing qadha (missed) prayers
//

import SwiftUI

struct QadhaCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var qadhaService = QadhaTrackerService.shared
    @State private var showingHistory = false
    @State private var showingDuaSheet = false
    @State private var showingResetConfirmation = false
    @State private var selectedPrayer: PrayerName?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Total Qadha Header
                totalQadhaCard

                // Motivational Message
                if qadhaService.totalQadha > 0 {
                    motivationalMessageCard
                }

                // Individual Prayer Counters
                VStack(spacing: 16) {
                    ForEach(PrayerName.allCases, id: \.self) { prayer in
                        PrayerQadhaRow(
                            prayer: prayer,
                            count: qadhaService.getQadhaCount(for: prayer),
                            onIncrement: {
                                incrementWithFeedback(prayer: prayer)
                            },
                            onDecrement: {
                                decrementWithFeedback(prayer: prayer)
                            },
                            onLongPress: {
                                selectedPrayer = prayer
                            }
                        )
                    }
                }

                // Action Buttons
                actionButtons

                // Information Card
                infoCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Qadha Tracker")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingHistory) {
            QadhaHistoryView()
        }
        .sheet(isPresented: $showingDuaSheet) {
            DuaForQadhaView()
        }
        .sheet(item: $selectedPrayer) { prayer in
            CustomQadhaInputSheet(prayer: prayer)
        }
        .alert("Reset All Qadha?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllWithFeedback()
            }
        } message: {
            Text("This will reset all qadha counters to zero. This action cannot be undone.")
        }
    }

    // MARK: - Components

    private var totalQadhaCard: some View {
        CardView {
            VStack(spacing: 12) {
                Text("Total Qadha Prayers")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)

                Text("\(qadhaService.totalQadha)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        qadhaService.totalQadha == 0
                        ? themeManager.currentTheme.accent
                        : themeManager.currentTheme.textPrimary
                    )
                    .contentTransition(.numericText())
                    .accessibilityValue("\(qadhaService.totalQadha) missed prayers")

                if qadhaService.totalQadha == 0 {
                    Label("Alhamdulillah! No qadha prayers", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total qadha prayers")
            .accessibilityValue(qadhaService.totalQadha == 0 ? "None, all prayers completed" : "\(qadhaService.totalQadha) prayers to make up")
        }
    }

    private var motivationalMessageCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label("Keep Going", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text(getMotivationalMessage())
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingHistory = true
                AudioHapticCoordinator.shared.playButtonPress()
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.cardColor)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("View qadha history")
            .accessibilityHint("Shows timeline of your qadha prayer adjustments")

            Button {
                showingDuaSheet = true
                AudioHapticCoordinator.shared.playButtonPress()
            } label: {
                Label("Dua", systemImage: "book.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.cardColor)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("View duas for qadha prayers")
            .accessibilityHint("Opens supplications for making up missed prayers")

            if qadhaService.totalQadha > 0 {
                Button {
                    showingResetConfirmation = true
                    AudioHapticCoordinator.shared.playWarning()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Reset all qadha counters")
                .accessibilityHint("Resets all qadha prayer counts to zero. This cannot be undone.")
            }
        }
    }

    private var infoCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("About Qadha", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text("Qadha prayers are obligatory prayers that were missed. It is important to make them up as soon as possible.")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    infoRow(icon: "plus.circle.fill", text: "Tap + to add missed prayers")
                    infoRow(icon: "minus.circle.fill", text: "Tap - when you complete a qadha")
                    infoRow(icon: "hand.tap.fill", text: "Long press for custom numbers")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.accent)
                .frame(width: 20)

            Text(text)
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
    }

    // MARK: - Helper Methods

    private func incrementWithFeedback(prayer: PrayerName) {
        AudioHapticCoordinator.shared.playButtonPress()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            qadhaService.incrementQadha(for: prayer)
        }
    }

    private func decrementWithFeedback(prayer: PrayerName) {
        guard qadhaService.getQadhaCount(for: prayer) > 0 else { return }
        AudioHapticCoordinator.shared.playPrayerComplete()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            qadhaService.decrementQadha(for: prayer)
        }
    }

    private func resetAllWithFeedback() {
        AudioHapticCoordinator.shared.playSuccess()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            qadhaService.resetAllQadha()
        }
    }

    private func getMotivationalMessage() -> String {
        let total = qadhaService.totalQadha

        switch total {
        case 1...5:
            return "May Allah accept your efforts. You're almost there!"
        case 6...20:
            return "Every step counts. Keep making progress steadily."
        case 21...50:
            return "Allah loves those who are patient and consistent. You can do this!"
        default:
            return "The journey of a thousand miles begins with a single step. Start today, and Allah will ease your way."
        }
    }
}

// MARK: - PrayerQadhaRow

struct PrayerQadhaRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let prayer: PrayerName
    let count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        CardView {
            HStack(spacing: 16) {
                // Prayer Icon & Name
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: prayer.icon)
                            .font(.title3)
                            .foregroundStyle(themeManager.currentTheme.accent)
                            .accessibilityHidden(true)

                        Text(prayer.displayName)
                            .font(.headline)
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                    }

                    if count > 0 {
                        Text("\(count) prayer\(count != 1 ? "s" : "") to complete")
                            .font(.caption2)
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                    }
                }

                Spacer()

                // Count Display
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        count > 0
                        ? themeManager.currentTheme.textPrimary
                        : themeManager.currentTheme.textSecondary.opacity(0.5)
                    )
                    .contentTransition(.numericText())
                    .frame(minWidth: 50)
                    .accessibilityLabel("\(count) \(prayer.displayName) qadha prayers")
                    .accessibilityHint("Long press to set custom count")
                    .onLongPressGesture {
                        onLongPress()
                        AudioHapticCoordinator.shared.playButtonPress()
                    }

                // Stepper Buttons
                HStack(spacing: 8) {
                    Button {
                        onDecrement()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(count > 0 ? themeManager.currentTheme.accent : themeManager.currentTheme.textSecondary.opacity(0.3))
                    }
                    .disabled(count == 0)
                    .accessibilityLabel("Decrease \(prayer.displayName) qadha count")
                    .accessibilityHint(count > 0 ? "Decreases count by one" : "No qadha prayers to remove")

                    Button {
                        onIncrement()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeManager.currentTheme.accent)
                    }
                    .accessibilityLabel("Increase \(prayer.displayName) qadha count")
                    .accessibilityHint("Increases count by one")
                }
            }
            .padding(16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: count)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(prayer.displayName) qadha counter")
        .accessibilityValue("\(count) prayer\(count != 1 ? "s" : "")")
    }
}

// MARK: - CustomQadhaInputSheet

struct CustomQadhaInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let prayer: PrayerName
    @State private var customValue: String = ""
    @State private var qadhaService = QadhaTrackerService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Prayer Info
                VStack(spacing: 8) {
                    Image(systemName: prayer.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(themeManager.currentTheme.accent)

                    Text("\(prayer.displayName) Qadha")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    Text("Current count: \(qadhaService.getQadhaCount(for: prayer))")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
                .padding(.top, 32)

                // Custom Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set custom count")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    TextField("Enter number", text: $customValue)
                        .keyboardType(.numberPad)
                        .font(.title.weight(.bold))
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                // Quick Add Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick add")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach([1, 5, 10, 20, 30, 50], id: \.self) { value in
                            Button {
                                addValue(value)
                            } label: {
                                Text("+\(value)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(themeManager.currentTheme.cardColor)
                                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Save Button
                Button {
                    saveCustomValue()
                } label: {
                    Text("Set Count")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .disabled(customValue.isEmpty)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addValue(_ value: Int) {
        AudioHapticCoordinator.shared.playButtonPress()
        let current = qadhaService.getQadhaCount(for: prayer)
        customValue = "\(current + value)"
    }

    private func saveCustomValue() {
        guard let value = Int(customValue), value >= 0 else { return }
        AudioHapticCoordinator.shared.playSuccess()
        qadhaService.setQadha(for: prayer, to: value)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        QadhaCounterView()
            .environment(ThemeManager())
    }
}
