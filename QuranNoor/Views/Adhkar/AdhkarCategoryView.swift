//
//  AdhkarCategoryView.swift
//  QuranNoor
//
//  Category view for adhkar
//

import SwiftUI

struct AdhkarCategoryView: View {
    @Environment(ThemeManager.self) var themeManager
    let category: AdhkarCategory
    @Bindable var adhkarService: AdhkarService

    @State private var selectedDhikr: Dhikr?

    private var adhkar: [Dhikr] {
        adhkarService.getAdhkar(for: category)
    }

    private var statistics: AdhkarStatistics {
        adhkarService.getStatistics(for: category)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with statistics
                headerSection

                // Dhikr List
                LazyVStack(spacing: 12) {
                    ForEach(adhkar) { dhikr in
                        DhikrCard(
                            dhikr: dhikr,
                            isCompleted: adhkarService.isCompleted(dhikrId: dhikr.id)
                        )
                        .onTapGesture {
                            selectedDhikr = dhikr
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDhikr) { dhikr in
            AdhkarDetailView(dhikr: dhikr, adhkarService: adhkarService)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 40))
                .foregroundStyle(categoryColor)

            Text(category.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(statistics.completedToday)/\(statistics.totalDhikr)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if statistics.isFullyCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                ProgressView(value: statistics.completionPercentage, total: 100)
                    .tint(statistics.isFullyCompleted ? .green : categoryColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)

            // Recommended Time
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.secondary)
                Text(category.recommendedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .morning:
            return .orange
        case .evening:
            return .purple
        case .afterPrayer:
            return .green
        case .beforeSleep:
            return themeManager.currentTheme.accent
        case .waking:
            return .yellow
        case .general:
            return .teal
        }
    }
}

// MARK: - Dhikr Card

struct DhikrCard: View {
    let dhikr: Dhikr
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Arabic Text
            Text(dhikr.arabicText)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 4)

            // Translation
            Text(dhikr.translation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            Divider()

            // Footer
            HStack {
                // Repetitions
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption)
                    Text("×\(dhikr.repetitions)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Reference
                Text(dhikr.reference)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                // Completed Indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? .green : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        AdhkarCategoryView(
            category: .morning,
            adhkarService: AdhkarService()
        )
    }
}
