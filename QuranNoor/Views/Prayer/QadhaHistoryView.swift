//
//  QadhaHistoryView.swift
//  QuranNoor
//
//  Created by Claude Code
//  History view for qadha prayer adjustments
//

import SwiftUI

struct QadhaHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @State private var qadhaService = QadhaTrackerService.shared
    @State private var showingClearConfirmation = false
    @State private var selectedPrayerFilter: PrayerName?

    private var filteredHistory: [QadhaHistoryEntry] {
        if let selected = selectedPrayerFilter {
            return qadhaService.getHistory(for: selected)
        }
        return qadhaService.getHistory()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                if filteredHistory.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("Qadha History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            selectedPrayerFilter = nil
                        } label: {
                            Label("All Prayers", systemImage: selectedPrayerFilter == nil ? "checkmark" : "")
                        }

                        Divider()

                        ForEach(PrayerName.allCases, id: \.self) { prayer in
                            Button {
                                selectedPrayerFilter = prayer
                            } label: {
                                Label(prayer.displayName, systemImage: selectedPrayerFilter == prayer ? "checkmark" : prayer.icon)
                            }
                        }

                        if !filteredHistory.isEmpty {
                            Divider()

                            Button(role: .destructive) {
                                showingClearConfirmation = true
                            } label: {
                                Label("Clear History", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .alert("Clear History?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    AudioHapticCoordinator.shared.playSuccess()
                    qadhaService.clearHistory()
                }
            } message: {
                Text("This will permanently delete all history entries. Your qadha counts will remain unchanged.")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(themeManager.secondaryTextColor.opacity(0.5))

            Text("No History Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(themeManager.primaryTextColor)

            Text("Your qadha prayer adjustments will appear here")
                .font(.subheadline)
                .foregroundStyle(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var historyList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Filter Info
                if selectedPrayerFilter != nil {
                    HStack {
                        Text("Showing \(selectedPrayerFilter!.displayName) only")
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)

                        Spacer()

                        Button("Clear Filter") {
                            selectedPrayerFilter = nil
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // History Entries
                LazyVStack(spacing: 10) {
                    ForEach(groupedByDate(), id: \.date) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                HistoryEntryRow(entry: entry)
                            }
                        } header: {
                            HStack {
                                Text(formatDate(group.date))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(themeManager.secondaryTextColor)
                                    .textCase(.uppercase)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, group.date == filteredHistory.first?.timestamp.startOfDay ? 0 : 16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    private func groupedByDate() -> [(date: Date, entries: [QadhaHistoryEntry])] {
        let grouped = Dictionary(grouping: filteredHistory) { entry in
            entry.timestamp.startOfDay
        }

        return grouped
            .sorted { $0.key > $1.key } // Most recent first
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - HistoryEntryRow

struct HistoryEntryRow: View {
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    let entry: QadhaHistoryEntry

    var body: some View {
        LiquidGlassCardView {
            HStack(spacing: 12) {
                // Prayer Icon
                Image(systemName: entry.prayer.icon)
                    .font(.title3)
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: 32)

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.description)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text(formatTime(entry.timestamp))
                        .font(.caption2)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }

                Spacer()

                // Change Indicator
                Text(entry.change >= 0 ? "+\(entry.change)" : "\(entry.change)")
                    .font(.headline)
                    .foregroundStyle(entry.change >= 0 ? Color.orange : themeManager.accentColor)
            }
            .padding(12)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Date Extension

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    QadhaHistoryView()
        .environment(ThemeManager())
}
