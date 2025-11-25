//
//  AdhkarView.swift
//  QuranNoor
//
//  Main view for adhkar (Islamic remembrances)
//

import SwiftUI

struct AdhkarView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var adhkarService = AdhkarService()
    @State private var selectedCategory: AdhkarCategory?
    @State private var showingTasbih = false
    @State private var showingNamesOfAllah = false
    @State private var showingFortressDuas = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Statistics Card
                    statisticsCard

                    // Quick Access Section
                    quickAccessSection

                    // Categories
                    categoriesSection
                }
                .padding()
            }
            .navigationTitle("Adhkar")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AdhkarCategory.self) { category in
                AdhkarCategoryView(category: category, adhkarService: adhkarService)
            }
            .sheet(isPresented: $showingTasbih) {
                TasbihCounterView()
            }
            .sheet(isPresented: $showingNamesOfAllah) {
                NamesOfAllahView()
            }
            .sheet(isPresented: $showingFortressDuas) {
                FortressDuasView()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.green, .teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Daily Remembrances")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Keep your tongue moist with the remembrance of Allah")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Current Streak",
                    value: "\(adhkarService.progress.streak)",
                    icon: "flame.fill",
                    color: .orange
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    title: "Total Completions",
                    value: "\(adhkarService.progress.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                // Digital Tasbih Button
                Button {
                    showingTasbih = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    .linearGradient(
                                        colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "hand.tap.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Digital Tasbih")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Count your dhikr")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)

                // 99 Names of Allah Button
                Button {
                    showingNamesOfAllah = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    .linearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Text("99")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("99 Names of Allah")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Asma ul Husna")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)

                // Fortress of the Muslim Button
                Button {
                    showingFortressDuas = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    .linearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "book.closed.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fortress of the Muslim")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Hisn al-Muslim duas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AdhkarCategory.allCases) { category in
                    NavigationLink(value: category) {
                        AdhkarCategoryCard(
                            category: category,
                            count: adhkarService.getAdhkar(for: category).count,
                            statistics: adhkarService.getStatistics(for: category)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AdhkarCategoryCard: View {
    @Environment(ThemeManager.self) var themeManager
    let category: AdhkarCategory
    let count: Int
    let statistics: AdhkarStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(category.recommendedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Progress Bar
            ProgressView(value: statistics.completionPercentage, total: 100)
                .tint(progressColor)

            HStack {
                Text("\(statistics.completedToday)/\(statistics.totalDhikr)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if statistics.isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
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
                .stroke(statistics.isFullyCompleted ? .green : .clear, lineWidth: 2)
        )
    }

    private var iconColor: Color {
        switch category {
        case .morning:
            return .orange
        case .evening:
            return .purple
        case .afterPrayer:
            return .green
        case .beforeSleep:
            return themeManager.currentTheme.featureAccent
        case .waking:
            return .yellow
        case .general:
            return .teal
        }
    }

    private var progressColor: Color {
        statistics.completionPercentage >= 100 ? .green : iconColor
    }
}

#Preview {
    AdhkarView()
}
