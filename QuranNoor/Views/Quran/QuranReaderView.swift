//
//  QuranReaderView.swift
//  QuranNoor
//
//  Quran reader with surah list and progress tracking
//

import SwiftUI

struct QuranReaderView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = QuranViewModel()
    @State private var showingVerseReader = false
    @State private var showProgressManagement = false
    @State private var showingResetConfirmation = false
    @State private var selectedSurahForReset: Surah?
    @AppStorage("hideProgressBanner") private var hideProgressBanner = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Base theme background (ensures pure black in night mode for OLED)
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                // Gradient overlay (automatically suppressed in night mode)
                GradientBackground(style: .quran, opacity: 0.3)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Progress Banner (dismissible discovery hint)
                        if !hideProgressBanner && viewModel.getProgressPercentage() > 0 {
                            progressBanner
                        }

                        // Progress Card
                        progressCard

                        // Search Bar
                        searchBar

                        // Filter Buttons
                        filterButtons

                        // Surah List
                        surahList
                    }
                    .padding()
                }
            }
            .navigationTitle("Holy Quran")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProgressManagement = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            .foregroundColor(AppColors.primary.teal)
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("View reading progress")
                    .accessibilityHint("Shows your Quran reading statistics and progress management")
                }
            }
            .sheet(isPresented: $showingVerseReader) {
                if let surah = viewModel.selectedSurah {
                    VerseReaderView(surah: surah, viewModel: viewModel)
                }
                // Full screen presentation is appropriate for reading
            }
            .sheet(isPresented: $showProgressManagement) {
                ProgressManagementView()
                    .environmentObject(themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Reset Progress",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Progress", role: .destructive) {
                    if let surah = selectedSurahForReset {
                        resetSurahProgress(surah)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let surah = selectedSurahForReset {
                    Text("This will reset your progress for \(surah.englishName). You can track it again by reading.")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func resetSurahProgress(_ surah: Surah) {
        QuranService.shared.resetSurahProgress(surahNumber: surah.id)
        print("🔄 Reset progress for \(surah.englishName) from QuranReaderView")
        // Note: No need to call loadProgress() - observers will update automatically
    }

    // MARK: - Components

    private var progressBanner: some View {
        Button {
            showProgressManagement = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary.teal)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text("Your Progress: ")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textColor)
                        Text("\(Int(viewModel.getProgressPercentage()))%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary.green)
                    }

                    ThemedText.caption("Tap to manage →")
                        .foregroundColor(AppColors.primary.teal)
                        .opacity(themeManager.currentTheme.secondaryOpacity)
                }

                Spacer()

                Button {
                    hideProgressBanner = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .opacity(themeManager.currentTheme.disabledOpacity)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 2.5),
                        AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primary.teal.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.teal) * 5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary.gold)

            ThemedText("القرآن الكريم", style: .heading)
                .foregroundColor(AppColors.primary.gold)

            ThemedText.caption("Read and reflect upon the words of Allah")
                .multilineTextAlignment(.center)
                // Caption style already uses textTertiary - no additional opacity needed
        }
        .padding(.top, 8)
    }

    private var progressCard: some View {
        LiquidGlassCardView(showPattern: true, intensity: .moderate) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("READING PROGRESS")
                        ThemedText(viewModel.getProgressText(), style: .body)
                            .foregroundColor(AppColors.primary.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        ThemedText.caption("STREAK")
                        ThemedText(viewModel.getStreakText(), style: .body)
                            .foregroundColor(AppColors.primary.teal)
                    }
                }

                ProgressRing(
                    progress: viewModel.getProgressPercentage() / 100,
                    lineWidth: 8,
                    size: 80,
                    showPercentage: true,
                    color: AppColors.primary.green
                )

                IslamicDivider(style: .ornamental, color: AppColors.primary.gold.opacity(0.3))

                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(AppColors.primary.gold)
                    ThemedText.caption("Last read: \(viewModel.getLastReadSurahName())")
                        // Caption style already uses textTertiary - no additional opacity needed
                    Spacer()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search surahs...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                    viewModel.searchSurahs(newValue)
                }
        }
        .padding(12)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    private var filterButtons: some View {
        HStack(spacing: 12) {
            FilterButton(title: "All (\(viewModel.totalSurahs))", isSelected: viewModel.filteredSurahs.count == viewModel.surahs.count) {
                viewModel.filterByRevelationType(nil)
            }

            FilterButton(title: "Meccan (\(viewModel.meccanCount))", isSelected: false) {
                viewModel.filterByRevelationType(.meccan)
            }

            FilterButton(title: "Medinan (\(viewModel.medinanCount))", isSelected: false) {
                viewModel.filterByRevelationType(.medinan)
            }
        }
    }

    private var surahList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.filteredSurahs) { surah in
                let progress = viewModel.getSurahProgress(
                    surahNumber: surah.id,
                    totalVerses: surah.numberOfVerses
                )

                Button {
                    viewModel.selectSurah(surah)
                    showingVerseReader = true
                } label: {
                    SurahCard(
                        surah: surah,
                        progress: progress
                    )
                }
                .contextMenu {
                    Button {
                        // Open progress management filtered to this surah
                        viewModel.selectSurah(surah)
                        showProgressManagement = true
                    } label: {
                        Label("View Progress Details", systemImage: "chart.bar")
                    }

                    if progress > 0 {
                        Button(role: .destructive) {
                            selectedSurahForReset = surah
                            showingResetConfirmation = true
                        } label: {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Surah Card
struct SurahCard: View {
    let surah: Surah
    let progress: Double  // 0-100
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Surah number badge
                    ZStack {
                        Image(systemName: progress >= 100 ? "checkmark.seal.fill" : "star.fill")
                            .font(.system(size: 40))
                            .foregroundColor(
                                progress >= 100
                                    ? AppColors.primary.green
                                    : AppColors.primary.gold
                            )
                            .opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.gold) * 5)

                        if progress < 100 {
                            ThemedText("\(surah.id)", style: .body)
                                .foregroundColor(AppColors.primary.gold)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.primary.green)
                        }
                    }
                    .frame(width: 50)

                    // Surah info
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText(surah.englishName, style: .heading)
                            .foregroundColor(themeManager.currentTheme.textColor)

                        ThemedText.caption(surah.englishNameTranslation)
                            // Caption style already uses textTertiary - no additional opacity needed

                        HStack(spacing: 8) {
                            Label("\(surah.numberOfVerses) verses", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundColor(AppColors.primary.teal)

                            Text("•")
                                .foregroundColor(.secondary)

                            Text(surah.revelationType.rawValue)
                                .font(.caption)
                                .foregroundColor(AppColors.primary.green)
                        }
                    }

                    Spacer()

                    // Arabic name
                    VStack(alignment: .trailing, spacing: 4) {
                        ThemedText.arabic(surah.name)
                            .foregroundColor(AppColors.primary.gold)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress bar (if any progress)
                if progress > 0 {
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(themeManager.currentTheme.textTertiary.opacity(themeManager.currentTheme.disabledOpacity))
                                    .frame(height: 4)
                                    .cornerRadius(2)

                                // Progress fill
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColors.primary.green,
                                                AppColors.primary.teal
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * (progress / 100),
                                        height: 4
                                    )
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)

                        HStack {
                            ThemedText.caption("\(Int(progress))% complete")
                                .foregroundColor(AppColors.primary.teal)
                                .opacity(themeManager.currentTheme.secondaryOpacity)

                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AppColors.primary.green.opacity(themeManager.currentTheme.gradientOpacity(for: AppColors.primary.green) * 3)
                        : Color.clear
                )
                .foregroundColor(
                    isSelected
                        ? AppColors.primary.green
                        : themeManager.currentTheme.textSecondary
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                                ? AppColors.primary.green
                                : themeManager.currentTheme.textTertiary.opacity(themeManager.currentTheme.disabledOpacity),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Preview
#Preview {
    QuranReaderView()
        .environmentObject(ThemeManager())
}
