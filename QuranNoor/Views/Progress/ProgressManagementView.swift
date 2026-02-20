//
//  ProgressManagementView.swift
//  QuranNoor
//
//  Sacred reading progress — hero stats, clean surah list, elegant management
//

import SwiftUI
import UniformTypeIdentifiers

struct ProgressManagementView: View {
    @State private var viewModel = ProgressManagementViewModel()
    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var showResetAllSheet = false
    @State private var resetConfirmationText = ""
    @State private var isStatsExpanded = false
    @State private var selectedSurah: Int?
    @State private var showingShareSheet = false
    @State private var showingFileImporter = false
    @State private var showImportStrategySheet = false
    @State private var selectedImportStrategy: ProgressManagementViewModel.ImportStrategy = .replace

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Reading Progress")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") { dismiss() }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                withAnimation { isStatsExpanded.toggle() }
                            } label: {
                                Label(
                                    isStatsExpanded ? "Collapse Stats" : "Expand Stats",
                                    systemImage: isStatsExpanded ? "chevron.up" : "chevron.down"
                                )
                            }

                            Divider()

                            Button {
                                viewModel.exportProgress()
                                if viewModel.exportURL != nil {
                                    showingShareSheet = true
                                }
                            } label: {
                                Label("Export Progress", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                showImportStrategySheet = true
                            } label: {
                                Label("Import Progress", systemImage: "square.and.arrow.down")
                            }

                            Divider()

                            Button {
                                viewModel.undoLastAction()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .disabled(!viewModel.canUndo)

                            Divider()

                            Button(role: .destructive) {
                                viewModel.resetAllProgress()
                            } label: {
                                Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .confirmationDialog(
                    "Reset Progress",
                    isPresented: Binding(
                        get: {
                            viewModel.showingResetConfirmation && viewModel.resetType != .all
                        },
                        set: { newValue in
                            if !newValue { viewModel.showingResetConfirmation = false }
                        }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) { viewModel.confirmReset() }
                    Button("Cancel", role: .cancel) { viewModel.cancelReset() }
                } message: {
                    Text(resetMessage)
                }
                .sheet(isPresented: Binding(
                    get: {
                        viewModel.showingResetConfirmation && viewModel.resetType == .all
                    },
                    set: { newValue in
                        if !newValue {
                            viewModel.showingResetConfirmation = false
                            resetConfirmationText = ""
                        }
                    }
                )) {
                    resetAllConfirmationSheet
                }
                .sheet(item: Binding(
                    get: { selectedSurah.map { SurahIdentifier(id: $0) } },
                    set: { selectedSurah = $0?.id }
                )) { identifier in
                    if let surah = viewModel.getSurah(forNumber: identifier.id) {
                        VerseProgressDetailView(surah: surah, viewModel: viewModel)
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let url = viewModel.exportURL {
                        ShareSheet(items: [url])
                    }
                }
                .sheet(isPresented: $showImportStrategySheet) {
                    importStrategySheet
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        viewModel.importProgress(from: url, strategy: selectedImportStrategy)
                    case .failure(let error):
                        viewModel.importError = "Failed to select file: \(error.localizedDescription)"
                    }
                }
                .toast(
                    message: viewModel.toastMessage,
                    style: viewModel.toastStyle,
                    isPresented: $viewModel.showToast,
                    showUndo: false,
                    onUndo: nil
                )
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    heroProgressSection

                    searchAndFilterSection

                    surahListSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.screenVertical)
            }
        }
    }

    // MARK: - Hero Progress Section

    private var heroProgressSection: some View {
        VStack(spacing: Spacing.md) {
            // Progress ring with key stats
            HStack(spacing: Spacing.md) {
                ProgressRing(
                    progress: viewModel.overallCompletionPercentage / 100,
                    lineWidth: 8,
                    size: 80,
                    showPercentage: true,
                    color: themeManager.currentTheme.accent
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(viewModel.totalVersesRead) of 6,236 verses")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(themeManager.currentTheme.textTertiary)

                    if viewModel.currentStreak > 0 {
                        HStack(spacing: Spacing.xxxs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: FontSizes.xs))
                            Text("\(viewModel.currentStreak) day streak")
                                .font(.system(size: FontSizes.sm))
                        }
                        .foregroundColor(themeManager.currentTheme.accent)
                    }

                    Text("Last read: \(viewModel.formatDate(viewModel.lastReadDate))")
                        .font(.system(size: FontSizes.xs))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()
            }

            // Expandable detailed stats
            if isStatsExpanded {
                IslamicDivider(style: .simple)

                HStack(spacing: 0) {
                    compactStat(
                        value: "\(viewModel.completedSurahsCount)",
                        label: "Completed",
                        color: themeManager.currentTheme.accent
                    )

                    compactStat(
                        value: "\(viewModel.startedSurahsCount)",
                        label: "In Progress",
                        color: themeManager.currentTheme.accentMuted
                    )

                    compactStat(
                        value: "\(viewModel.notStartedSurahsCount)",
                        label: "Not Started",
                        color: themeManager.currentTheme.textTertiary
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.md)
        .background(themeManager.currentTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    private func compactStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xxxs) {
            Text(value)
                .font(.system(size: FontSizes.lg, weight: .semibold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: FontSizes.xs))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search and Filter

    private var searchAndFilterSection: some View {
        VStack(spacing: Spacing.xs) {
            // Search bar
            HStack(spacing: Spacing.xxs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: FontSizes.sm))
                    .foregroundColor(themeManager.currentTheme.textTertiary)

                TextField("Search surahs...", text: $viewModel.searchQuery)
                    .font(.system(size: FontSizes.base))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: FontSizes.sm))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(themeManager.currentTheme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
            )

            // Filter and sort row
            HStack {
                // Filter segments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(ProgressManagementViewModel.SurahFilterType.allCases, id: \.self) { filter in
                            filterButton(filter)
                        }
                    }
                }

                Spacer()

                // Sort menu
                Menu {
                    ForEach(ProgressManagementViewModel.SurahSortOrder.allCases, id: \.self) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: FontSizes.xs))
                        .foregroundColor(themeManager.currentTheme.accentMuted)
                        .padding(Spacing.xxs)
                        .background(themeManager.currentTheme.accentTint)
                        .clipShape(RoundedRectangle(cornerRadius: BorderRadius.md))
                }
            }
        }
    }

    private func filterButton(_ filter: ProgressManagementViewModel.SurahFilterType) -> some View {
        let isSelected = viewModel.filterType == filter
        return Button {
            viewModel.filterType = filter
        } label: {
            Text(filter.rawValue)
                .font(.system(size: FontSizes.xs, weight: isSelected ? .semibold : .regular))
                .foregroundColor(
                    isSelected
                        ? themeManager.currentTheme.accent
                        : themeManager.currentTheme.textTertiary
                )
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxxs + 2)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accentTint
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: BorderRadius.md))
        }
    }

    // MARK: - Surah List

    private var surahListSection: some View {
        LazyVStack(spacing: Spacing.xxs) {
            ForEach(viewModel.filteredSurahStats) { stat in
                surahRow(stat)
                    .contextMenu {
                        if stat.readVerses > 0 {
                            Button(role: .destructive) {
                                viewModel.resetSurah(stat.surahNumber)
                            } label: {
                                Label("Reset Progress", systemImage: "arrow.counterclockwise")
                            }
                        }
                        Button {
                            selectedSurah = stat.surahNumber
                        } label: {
                            Label("View Details", systemImage: "eye")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if stat.readVerses > 0 {
                            Button(role: .destructive) {
                                viewModel.resetSurah(stat.surahNumber)
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                        }
                    }
            }
        }
    }

    private func surahRow(_ stat: SurahProgressStats) -> some View {
        Button {
            selectedSurah = stat.surahNumber
        } label: {
            HStack(spacing: Spacing.sm) {
                // Surah number
                ZStack {
                    Circle()
                        .fill(
                            stat.isCompleted
                                ? themeManager.currentTheme.accent.opacity(0.15)
                                : themeManager.currentTheme.accentTint
                        )
                        .frame(width: 36, height: 36)

                    if stat.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: FontSizes.xs, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.accent)
                    } else {
                        Text("\(stat.surahNumber)")
                            .font(.system(size: FontSizes.xs, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.accentMuted)
                    }
                }

                // Surah info
                if let surah = viewModel.getSurah(forNumber: stat.surahNumber) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(surah.englishName)
                            .font(.system(size: FontSizes.base, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        Text("\(stat.readVerses)/\(stat.totalVerses) verses")
                            .font(.system(size: FontSizes.xs))
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }

                Spacer()

                // Progress indicator
                if stat.readVerses > 0 {
                    Text("\(Int(stat.completionPercentage))%")
                        .font(.system(size: FontSizes.sm, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.accent)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: FontSizes.xs))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(themeManager.currentTheme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reset All Confirmation Sheet

    private var resetAllConfirmationSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.top, Spacing.lg)

                VStack(spacing: Spacing.xxs) {
                    Text("Reset All Progress?")
                        .font(.system(size: FontSizes.xl, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("This will permanently delete progress for all 114 surahs.")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Type RESET to confirm:")
                        .font(.system(size: FontSizes.sm))
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("", text: $resetConfirmationText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: FontSizes.lg, weight: .semibold))
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                VStack(spacing: Spacing.xs) {
                    Button {
                        viewModel.confirmReset()
                        viewModel.showingResetConfirmation = false
                        resetConfirmationText = ""
                    } label: {
                        Text("Reset All Progress")
                            .font(.system(size: FontSizes.base, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(resetConfirmationText == "RESET" ? Color.red : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg))
                    }
                    .disabled(resetConfirmationText != "RESET")

                    Button {
                        viewModel.cancelReset()
                        resetConfirmationText = ""
                    } label: {
                        Text("Cancel")
                            .font(.system(size: FontSizes.base))
                            .foregroundColor(themeManager.currentTheme.accentMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Confirm Reset")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var resetMessage: String {
        guard let resetType = viewModel.resetType else { return "Are you sure?" }
        switch resetType {
        case .all:
            return "This will reset all your reading progress. This action cannot be undone."
        case .surah(let number):
            let surah = viewModel.getSurah(forNumber: number)
            return "Reset progress for \(surah?.englishName ?? "this surah")?"
        case .verseRange:
            return "Reset progress for selected verses?"
        }
    }

    // MARK: - Import Strategy Sheet

    private var importStrategySheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                importStrategyButton(
                    strategy: .replace,
                    title: "Replace All",
                    description: "Delete existing progress and use imported data",
                    recommended: false
                )
                IslamicDivider(style: .simple)
                    .padding(.horizontal, Spacing.sm)

                importStrategyButton(
                    strategy: .merge,
                    title: "Merge (Smart)",
                    description: "Keep most recent timestamp for each verse",
                    recommended: true
                )
                IslamicDivider(style: .simple)
                    .padding(.horizontal, Spacing.sm)

                importStrategyButton(
                    strategy: .addOnly,
                    title: "Add Only",
                    description: "Only import verses not already read",
                    recommended: false
                )
            }
            .padding(.vertical, Spacing.xs)
            .navigationTitle("Import Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showImportStrategySheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func importStrategyButton(
        strategy: ProgressManagementViewModel.ImportStrategy,
        title: String,
        description: String,
        recommended: Bool
    ) -> some View {
        Button {
            selectedImportStrategy = strategy
            showImportStrategySheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingFileImporter = true
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    HStack(spacing: Spacing.xxs) {
                        Text(title)
                            .font(.system(size: FontSizes.base, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        if recommended {
                            Text("RECOMMENDED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.currentTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: BorderRadius.sm))
                        }
                    }

                    Text(description)
                        .font(.system(size: FontSizes.xs))
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()
            }
            .padding(Spacing.sm)
        }
    }
}

// MARK: - Helper

private struct SurahIdentifier: Identifiable {
    let id: Int
}

// MARK: - Preview

#Preview {
    ProgressManagementView()
        .environment(ThemeManager())
}
