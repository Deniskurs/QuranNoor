//
//  TasbihHistoryView.swift
//  QuranNoor
//
//  History view for tasbih sessions
//

import SwiftUI

struct TasbihHistoryView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var tasbihService = TasbihService.shared
    @State private var selectedFilter: HistoryFilter = .today

    @Environment(\.dismiss) private var dismiss

    enum HistoryFilter: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case all = "All Time"
    }

    private var filteredHistory: [TasbihHistoryEntry] {
        switch selectedFilter {
        case .today:
            return tasbihService.getTodayHistory()
        case .week:
            return tasbihService.getWeekHistory()
        case .all:
            return tasbihService.history
        }
    }

    private var totalCount: Int {
        filteredHistory.reduce(0) { $0 + $1.session.currentCount }
    }

    private var completedCount: Int {
        filteredHistory.filter { $0.session.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if filteredHistory.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Card
                            summaryCard

                            // History List
                            historyList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            clearHistory()
                        } label: {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(filteredHistory.count)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(completedCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(totalCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(themeManager.currentTheme.accent)

                Text("Total Count")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVStack(spacing: 12) {
                ForEach(filteredHistory) { entry in
                    HistoryCard(entry: entry)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No History")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your tasbih sessions will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func clearHistory() {
        tasbihService.clearHistory()
    }
}

// MARK: - History Card

struct HistoryCard: View {
    @Environment(ThemeManager.self) var themeManager
    let entry: TasbihHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Preset Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.session.preset.displayName)
                        .font(.headline)

                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion Badge
                if entry.session.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }

            Divider()

            // Stats
            HStack(spacing: 20) {
                // Count
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(themeManager.currentTheme.accent)
                    Text("\(entry.session.currentCount) / \(entry.session.targetCount)")
                        .font(.subheadline)
                }

                // Duration
                if let duration = entry.session.formattedDuration {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.orange)
                        Text(duration)
                            .font(.subheadline)
                    }
                }

                Spacer()

                // Progress
                Text("\(Int(entry.session.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.session.isCompleted ? .green : .secondary)
            }

            // Progress Bar
            ProgressView(value: entry.session.progress)
                .tint(entry.session.isCompleted ? .green : themeManager.currentTheme.accent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.session.isCompleted ? .green : .clear, lineWidth: 1)
        )
    }
}

#Preview {
    TasbihHistoryView()
}
