//
//  ProgressManagementView.swift
//  QuranNoor
//
//  Comprehensive progress management with Overview, Surahs, and Management tabs
//

import SwiftUI
import UniformTypeIdentifiers

struct ProgressManagementView: View {
    @StateObject private var viewModel = ProgressManagementViewModel()
    @EnvironmentObject var themeManager: ThemeManager
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
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            withAnimation {
                                isStatsExpanded.toggle()
                            }
                        } label: {
                            Label(
                                isStatsExpanded ? "Collapse Stats" : "Expand Stats",
                                systemImage: isStatsExpanded ? "chevron.up" : "chevron.down"
                            )
                        }

                        Divider()

                        Button {
                            viewModel.undoLastAction()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
                        .disabled(!viewModel.canUndo)
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
                        if !newValue {
                            viewModel.showingResetConfirmation = false
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    viewModel.confirmReset()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelReset()
                }
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
                    VerseProgressDetailView(
                        surah: surah,
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showImportStrategySheet) {
                importStrategySelectionSheet
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
            GradientBackground(style: .quran, opacity: 0.2)

            ScrollView {
                VStack(spacing: 20) {
                    // Collapsible Stats Header
                    statsHeaderSection

                    // Filter and Search
                    filterAndSearchSection

                    // Surah List
                    surahListSection

                    Spacer(minLength: 80) // Bottom toolbar space
                }
                .padding()
            }
            .overlay(alignment: .bottom) {
                bottomToolbar
            }
        }
    }

    // MARK: - Reset All Confirmation Sheet

    private var resetAllConfirmationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 32)

                // Title
                VStack(spacing: 8) {
                    ThemedText("Reset All Progress?", style: .heading)
                        .foregroundColor(.red)

                    ThemedText.caption("This will permanently delete progress for ALL 114 surahs.")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                        .padding(.horizontal)
                }

                // TextField
                VStack(alignment: .leading, spacing: 8) {
                    ThemedText.caption("Type RESET to confirm:")
                        .foregroundColor(themeManager.currentTheme.textColor)

                    TextField("", text: $resetConfirmationText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.horizontal, 32)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.confirmReset()
                        viewModel.showingResetConfirmation = false
                        resetConfirmationText = ""
                    } label: {
                        Text("Reset All Progress")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(resetConfirmationText == "RESET" ? Color.red : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(resetConfirmationText != "RESET")

                    Button {
                        viewModel.cancelReset()
                        resetConfirmationText = ""
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.primary.teal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Confirm Reset")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var resetMessage: String {
        guard let resetType = viewModel.resetType else {
            return "Are you sure?"
        }

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

    // MARK: - Collapsible Stats Header

    private var statsHeaderSection: some View {
        CardView(showPattern: true) {
            VStack(spacing: 16) {
                // Header with expand/collapse button
                HStack {
                    ThemedText("Reading Progress", style: .heading)
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            isStatsExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isStatsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppColors.primary.teal)
                    }
                }

                // Always show summary
                HStack(spacing: 20) {
                    ProgressRing(
                        progress: viewModel.overallCompletionPercentage / 100,
                        lineWidth: 8,
                        size: 80,
                        showPercentage: true,
                        color: AppColors.primary.green
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                            ThemedText("\(viewModel.totalVersesRead) verses read", style: .body)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            ThemedText("\(viewModel.currentStreak) day streak", style: .caption)
                        }
                        .foregroundColor(AppColors.primary.gold)

                        ThemedText.caption("Last: \(viewModel.formatDate(viewModel.lastReadDate))")
                            .opacity(0.7)
                    }

                    Spacer()
                }

                // Expandable detailed stats
                if isStatsExpanded {
                    IslamicDivider(style: .simple)

                    HStack(spacing: 20) {
                        statItem(
                            icon: "checkmark.seal.fill",
                            value: "\(viewModel.completedSurahsCount)",
                            label: "Completed",
                            color: AppColors.primary.green
                        )

                        statItem(
                            icon: "book.fill",
                            value: "\(viewModel.startedSurahsCount)",
                            label: "In Progress",
                            color: AppColors.primary.teal
                        )

                        statItem(
                            icon: "circle",
                            value: "\(viewModel.notStartedSurahsCount)",
                            label: "Not Started",
                            color: .secondary
                        )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))

            ThemedText(value, style: .heading)
                .foregroundColor(color)

            ThemedText.caption(label)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter and Search Section

    private var filterAndSearchSection: some View {
        VStack(spacing: 12) {
            // Search bar
            searchBar

            // Filter pills
            filterPills

            // Sort picker
            sortPicker
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search surahs...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
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

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgressManagementViewModel.SurahFilterType.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        count: countForFilter(filter),
                        isSelected: viewModel.filterType == filter
                    ) {
                        viewModel.filterType = filter
                    }
                }
            }
        }
    }

    private func countForFilter(_ filter: ProgressManagementViewModel.SurahFilterType) -> Int {
        switch filter {
        case .all:
            return viewModel.surahStats.count
        case .started:
            return viewModel.startedSurahsCount
        case .completed:
            return viewModel.completedSurahsCount
        case .notStarted:
            return viewModel.notStartedSurahsCount
        }
    }

    private var sortPicker: some View {
        HStack {
            Image(systemName: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(ProgressManagementViewModel.SurahSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.menu)
            .accentColor(AppColors.primary.teal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.cardColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }

    // MARK: - Surah List Section

    private var surahListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredSurahStats) { stat in
                SurahProgressCard(
                    stat: stat,
                    surah: viewModel.getSurah(forNumber: stat.surahNumber),
                    onTap: {
                        selectedSurah = stat.surahNumber
                    },
                    onReset: {
                        viewModel.resetSurah(stat.surahNumber)
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if stat.readVerses > 0 {
                        Button(role: .destructive) {
                            viewModel.resetSurah(stat.surahNumber)
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
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
            }
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // Export button
            Button {
                viewModel.exportProgress()
                if viewModel.exportURL != nil {
                    showingShareSheet = true
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(AppColors.primary.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primary.green.opacity(0.1))
                    .cornerRadius(8)
            }

            // Import button
            Button {
                showImportStrategySheet = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
                    .font(.caption)
                    .foregroundColor(AppColors.primary.teal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primary.teal.opacity(0.1))
                    .cornerRadius(8)
            }

            // Reset All button
            Button {
                viewModel.resetAllProgress()
            } label: {
                Label("Reset All", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            themeManager.currentTheme.backgroundColor
                .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
        )
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Import Strategy Selection Sheet

    private var importStrategySelectionSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedImportStrategy = .replace
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Replace All")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                Text("Delete existing progress and use imported data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .replace {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        selectedImportStrategy = .merge
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Merge (Smart)")
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.textColor)

                                    Text("RECOMMENDED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppColors.primary.green)
                                        .cornerRadius(4)
                                }

                                Text("Keep most recent timestamp for each verse")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .merge {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        selectedImportStrategy = .addOnly
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Add Only")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                Text("Only import verses not already read")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .addOnly {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose Import Strategy")
                }
            }
            .navigationTitle("Import Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showImportStrategySheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var viewModel: ProgressManagementViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Progress Ring
                heroProgressSection

                // Stats Cards
                statsCardsSection

                // Streak and Velocity
                streakAndVelocitySection

                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
    }

    private var heroProgressSection: some View {
        CardView(showPattern: true) {
            VStack(spacing: 16) {
                ThemedText("Overall Progress", style: .heading)
                    .foregroundColor(themeManager.currentTheme.textColor)

                ProgressRing(
                    progress: viewModel.overallCompletionPercentage / 100,
                    lineWidth: 12,
                    size: 160,
                    showPercentage: true,
                    color: AppColors.primary.green
                )

                VStack(spacing: 8) {
                    ThemedText("\(viewModel.totalVersesRead) / \(viewModel.totalVersesInQuran) verses", style: .body)
                        .foregroundColor(AppColors.primary.teal)

                    ThemedText.caption("Last read: \(viewModel.formatDate(viewModel.lastReadDate))")
                        .opacity(0.7)
                }

                IslamicDivider(style: .ornamental, color: AppColors.primary.gold.opacity(0.3))

                HStack(spacing: 20) {
                    statItem(
                        icon: "checkmark.seal.fill",
                        value: "\(viewModel.completedSurahsCount)",
                        label: "Completed",
                        color: AppColors.primary.green
                    )

                    statItem(
                        icon: "book.fill",
                        value: "\(viewModel.startedSurahsCount)",
                        label: "In Progress",
                        color: AppColors.primary.teal
                    )

                    statItem(
                        icon: "circle",
                        value: "\(viewModel.notStartedSurahsCount)",
                        label: "Not Started",
                        color: .secondary
                    )
                }
            }
        }
    }

    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            // Streak Card
            MiniStatCard(
                icon: "flame.fill",
                title: "Streak",
                value: "\(viewModel.currentStreak)",
                subtitle: "day\(viewModel.currentStreak == 1 ? "" : "s")",
                color: AppColors.primary.gold
            )

            // Average Card
            MiniStatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Daily Average",
                value: String(format: "%.1f", viewModel.averageVersesPerDay),
                subtitle: "verses/day",
                color: AppColors.primary.teal
            )
        }
    }

    private var streakAndVelocitySection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .foregroundColor(AppColors.primary.green)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText("Reading Velocity", style: .body)
                            .foregroundColor(themeManager.currentTheme.textColor)

                        ThemedText.caption(viewModel.readingVelocity)
                            .foregroundColor(AppColors.primary.teal)
                    }

                    Spacer()
                }

                IslamicDivider(style: .simple)

                if viewModel.estimatedDaysToComplete > 0 {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(AppColors.primary.gold)

                        ThemedText.caption("At your current pace, you'll complete the Quran in ~\(viewModel.estimatedDaysToComplete) days")
                            .opacity(0.8)
                            .lineSpacing(4)
                    }
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Recent Activity", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                VStack(spacing: 0) {
                    let activities = viewModel.getRecentActivity(limit: 5)

                    if activities.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .opacity(0.5)

                            ThemedText.caption("No recent activity")
                                .opacity(0.5)
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 12)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                                    .font(.system(size: 16))

                                if let surah = viewModel.getSurah(forNumber: activity.surahNumber) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ThemedText.body("\(surah.englishName) - Verse \(activity.verseNumber)")

                                        ThemedText.caption(viewModel.formatDate(activity.timestamp))
                                            .foregroundColor(AppColors.primary.teal)
                                            .opacity(0.7)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                    }
                }
            }
        }
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))

            ThemedText(value, style: .heading)
                .foregroundColor(color)

            ThemedText.caption(label)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Surahs Tab

struct SurahsTab: View {
    @ObservedObject var viewModel: ProgressManagementViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedSurah: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding()

            // Filter Pills
            filterPills
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Sort Picker
            sortPicker
                .padding(.horizontal)
                .padding(.bottom, 12)

            // Surah List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSurahStats) { stat in
                        SurahProgressCard(
                            stat: stat,
                            surah: viewModel.getSurah(forNumber: stat.surahNumber),
                            onTap: {
                                selectedSurah = stat.surahNumber
                            },
                            onReset: {
                                viewModel.resetSurah(stat.surahNumber)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .sheet(item: Binding(
            get: { selectedSurah.map { SurahIdentifier(id: $0) } },
            set: { selectedSurah = $0?.id }
        )) { identifier in
            if let surah = viewModel.getSurah(forNumber: identifier.id) {
                VerseProgressDetailView(
                    surah: surah,
                    viewModel: viewModel
                )
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search surahs...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
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

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgressManagementViewModel.SurahFilterType.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        count: countForFilter(filter),
                        isSelected: viewModel.filterType == filter
                    ) {
                        viewModel.filterType = filter
                    }
                }
            }
        }
    }

    private var sortPicker: some View {
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
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                ThemedText.caption("Sort: \(viewModel.sortOrder.rawValue)")
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(AppColors.primary.teal)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.primary.teal.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private func countForFilter(_ filter: ProgressManagementViewModel.SurahFilterType) -> Int {
        switch filter {
        case .all:
            return viewModel.surahStats.count
        case .started:
            return viewModel.startedSurahsCount
        case .completed:
            return viewModel.completedSurahsCount
        case .notStarted:
            return viewModel.notStartedSurahsCount
        }
    }
}

// MARK: - Management Tab

struct ManagementTab: View {
    @ObservedObject var viewModel: ProgressManagementViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingShareSheet = false
    @State private var showingFileImporter = false
    @State private var showImportStrategySheet = false
    @State private var selectedImportStrategy: ProgressManagementViewModel.ImportStrategy = .replace

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Undo Section
                undoSection

                // Reset Options
                resetOptionsSection

                // Export/Import
                exportImportSection

                // Danger Zone
                dangerZoneSection
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
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
        .sheet(isPresented: $showImportStrategySheet) {
            importStrategySelectionSheet
        }
    }

    // MARK: - Import Strategy Selection Sheet

    private var importStrategySelectionSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedImportStrategy = .replace
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Replace All")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                Text("Delete existing progress and use imported data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .replace {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        selectedImportStrategy = .merge
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Merge (Smart)")
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.textColor)

                                    Text("RECOMMENDED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppColors.primary.green)
                                        .cornerRadius(4)
                                }

                                Text("Keep most recent timestamp for each verse")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .merge {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        selectedImportStrategy = .addOnly
                        showImportStrategySheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFileImporter = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Add Only")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                Text("Only import verses not already read")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedImportStrategy == .addOnly {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose Import Strategy")
                }
            }
            .navigationTitle("Import Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showImportStrategySheet = false
                    }
                }
            }
        }
    }

    private var undoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Undo History", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)

            CardView {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(AppColors.primary.teal)
                            .font(.system(size: 24))

                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText.body("Undo Last Action")

                            ThemedText.caption("\(viewModel.undoHistoryCount) action\(viewModel.undoHistoryCount == 1 ? "" : "s") in history")
                                .opacity(0.7)
                        }

                        Spacer()

                        Button {
                            viewModel.undoLastAction()
                        } label: {
                            Text("Undo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.primary.teal)
                                .cornerRadius(8)
                        }
                        .disabled(!viewModel.canUndo)
                        .opacity(viewModel.canUndo ? 1 : 0.5)
                    }

                    if viewModel.undoHistoryCount > 0 {
                        IslamicDivider(style: .simple)

                        Button {
                            viewModel.clearUndoHistory()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                ThemedText.caption("Clear Undo History")
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var resetOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Reset Options", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)

            CardView {
                VStack(spacing: 0) {
                    // Individual surah reset is handled in Surahs tab

                    ThemedText.caption("Reset options for individual surahs are available in the Surahs tab")
                        .multilineTextAlignment(.center)
                        .opacity(0.7)
                        .padding()
                }
            }
        }
    }

    private var exportImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Backup & Restore", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)

            CardView {
                VStack(spacing: 12) {
                    // Export
                    Button {
                        viewModel.exportProgress()
                        if viewModel.exportURL != nil {
                            showingShareSheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppColors.primary.green)
                            ThemedText.body("Export Progress")
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isExporting)

                    IslamicDivider(style: .simple)

                    // Import
                    Button {
                        showImportStrategySheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(AppColors.primary.teal)
                            ThemedText.body("Import Progress")
                            Spacer()
                            if viewModel.isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isImporting)

                    if let error = viewModel.importError {
                        ThemedText.caption(error)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Danger Zone", style: .heading)
                .foregroundColor(.red)

            CardView {
                Button {
                    viewModel.resetAllProgress()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            ThemedText.body("Reset All Progress")
                                .foregroundColor(.red)

                            ThemedText.caption("This will delete all your reading progress permanently")
                                .opacity(0.7)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Supporting Components

struct MiniStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        CardView {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24))

                ThemedText.caption(title)
                    .opacity(0.7)

                ThemedText(value, style: .heading)
                    .foregroundColor(color)

                ThemedText.caption(subtitle)
                    .opacity(0.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("(\(count))")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AppColors.primary.green.opacity(0.2)
                    : Color.clear
            )
            .foregroundColor(
                isSelected
                    ? AppColors.primary.green
                    : .secondary
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? AppColors.primary.green
                            : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct SurahProgressCard: View {
    let stat: SurahProgressStats
    let surah: Surah?
    let onTap: () -> Void
    let onReset: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingResetConfirmation = false

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        // Badge
                        ZStack {
                            Image(systemName: stat.isCompleted ? "checkmark.seal.fill" : "circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(
                                    stat.isCompleted
                                        ? AppColors.primary.green.opacity(0.3)
                                        : AppColors.primary.gold.opacity(0.3)
                                )

                            if stat.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.primary.green)
                            } else {
                                ThemedText("\(stat.surahNumber)", style: .body)
                                    .foregroundColor(AppColors.primary.gold)
                            }
                        }
                        .frame(width: 40)

                        // Surah info
                        VStack(alignment: .leading, spacing: 4) {
                            if let surah = surah {
                                ThemedText(surah.englishName, style: .body)
                                    .foregroundColor(themeManager.currentTheme.textColor)

                                ThemedText.caption(surah.englishNameTranslation)
                                    .opacity(0.7)
                            }

                            HStack(spacing: 4) {
                                ThemedText.caption("\(stat.readVerses)/\(stat.totalVerses) verses")
                                    .foregroundColor(AppColors.primary.teal)
                                Text("•")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                ThemedText.caption("\(Int(stat.completionPercentage))%")
                                    .foregroundColor(AppColors.primary.green)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                // Progress bar
                if stat.readVerses > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(themeManager.currentTheme.textColor.opacity(0.1))
                                .frame(height: 4)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary.green, AppColors.primary.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * (stat.completionPercentage / 100),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                    .cornerRadius(2)

                    // Reset button (only if started)
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                            ThemedText.caption("Reset Surah")
                        }
                        .foregroundColor(.red.opacity(0.7))
                    }
                    .confirmationDialog(
                        "Reset Surah",
                        isPresented: $showingResetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            onReset()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Reset all progress for \(surah?.englishName ?? "this surah")?")
                    }
                }
            }
        }
    }
}

// Helper struct for sheet presentation
struct SurahIdentifier: Identifiable {
    let id: Int
}

// MARK: - Preview

#Preview {
    ProgressManagementView()
        .environmentObject(ThemeManager())
}
