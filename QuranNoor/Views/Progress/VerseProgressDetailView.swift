//
//  VerseProgressDetailView.swift
//  QuranNoor
//
//  Detailed view of verse-level progress with grid layout and toggle functionality
//

import SwiftUI

struct VerseProgressDetailView: View {
    let surah: Surah
    @ObservedObject var viewModel: ProgressManagementViewModel

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var verseStates: [Int: Bool] = [:]  // Cached verse read states
    @State private var showingMarkAllConfirmation = false
    @State private var markAllAsRead = true
    @State private var selectedVerseToScroll: Int?  // Trigger for scrolling to verse

    private let quranService = QuranService.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .quran, opacity: 0.2)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        headerCard

                        // Progress Summary
                        progressSummaryCard

                        // Quick Actions
                        quickActionsCard

                        // Verse Grid
                        verseGridCard
                    }
                    .padding()
                }
            }
            .navigationTitle(surah.englishName)
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
                            goToFirstUnread()
                        } label: {
                            Label("Go to First Unread", systemImage: "arrow.forward.to.line")
                        }
                        .disabled(allVersesRead)

                        Button {
                            markAllAsRead = true
                            showingMarkAllConfirmation = true
                        } label: {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                        }

                        Button {
                            markAllAsRead = false
                            showingMarkAllConfirmation = true
                        } label: {
                            Label("Mark All Unread", systemImage: "circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadVerseStates()
            }
            .confirmationDialog(
                markAllAsRead ? "Mark All Read" : "Mark All Unread",
                isPresented: $showingMarkAllConfirmation,
                titleVisibility: .visible
            ) {
                Button(markAllAsRead ? "Mark All Read" : "Mark All Unread", role: markAllAsRead ? .none : .destructive) {
                    confirmMarkAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(markAllAsRead
                    ? "Mark all \(surah.numberOfVerses) verses as read?"
                    : "Mark all \(surah.numberOfVerses) verses as unread?")
            }
        }
    }

    // MARK: - Components

    private var headerCard: some View {
        LiquidGlassCardView(showPattern: true, intensity: .moderate) {
            VStack(spacing: 12) {
                // Arabic name
                ThemedText.arabic(surah.name)
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.currentTheme.accentInteractive)

                // English names
                VStack(spacing: 4) {
                    ThemedText(surah.englishName, style: .heading)
                        .foregroundColor(themeManager.currentTheme.textColor)

                    ThemedText.caption(surah.englishNameTranslation)
                        .opacity(0.7)
                }

                IslamicDivider(style: .ornamental, color: themeManager.currentTheme.accentInteractive.opacity(0.3))

                // Surah info
                HStack(spacing: 20) {
                    infoItem(icon: "doc.text", text: "\(surah.numberOfVerses) Verses")
                    infoItem(icon: "mappin.and.ellipse", text: surah.revelationType.rawValue)
                    infoItem(icon: "number", text: "Surah \(surah.id)")
                }
            }
        }
    }

    private func infoItem(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.accentSecondary)
                .font(.system(size: 14))

            ThemedText.caption(text)
                .opacity(0.8)
        }
    }

    private var progressSummaryCard: some View {
        let stats = getSurahStats()

        return CardView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        ThemedText.caption("PROGRESS")
                        ThemedText("\(stats.readVerses) / \(stats.totalVerses)", style: .heading)
                            .foregroundColor(themeManager.currentTheme.accentPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        ThemedText.caption("COMPLETION")
                        ThemedText("\(Int(stats.completionPercentage))%", style: .heading)
                            .foregroundColor(themeManager.currentTheme.accentSecondary)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.currentTheme.textColor.opacity(0.1))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.currentTheme.accentPrimary, themeManager.currentTheme.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (stats.completionPercentage / 100),
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)

                // Additional info
                HStack(spacing: 16) {
                    if let firstRead = stats.firstReadDate {
                        infoLabel(icon: "calendar.badge.clock", text: "Started: \(formatDate(firstRead))")
                    }

                    if let lastRead = stats.lastReadDate {
                        infoLabel(icon: "book.fill", text: "Last: \(formatDate(lastRead))")
                    }
                }
            }
        }
    }

    private func infoLabel(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            ThemedText.caption(text)
        }
        .foregroundColor(themeManager.currentTheme.accentSecondary)
        .opacity(0.8)
    }

    private var quickActionsCard: some View {
        CardView {
            VStack(spacing: 12) {
                ThemedText.caption("QUICK ACTIONS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(0.7)

                HStack(spacing: 12) {
                    // Go to First Unread
                    ActionButton(
                        icon: "arrow.forward.to.line",
                        title: "First Unread",
                        color: themeManager.currentTheme.accentSecondary,
                        disabled: allVersesRead
                    ) {
                        goToFirstUnread()
                    }

                    // Mark All Read
                    ActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Mark All Read",
                        color: themeManager.currentTheme.accentPrimary,
                        disabled: allVersesRead
                    ) {
                        markAllAsRead = true
                        showingMarkAllConfirmation = true
                    }

                    // Mark All Unread
                    ActionButton(
                        icon: "circle",
                        title: "Clear All",
                        color: .red,
                        disabled: verseStates.values.filter({ $0 }).isEmpty
                    ) {
                        markAllAsRead = false
                        showingMarkAllConfirmation = true
                    }
                }
            }
        }
    }

    private var verseGridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemedText("Verses", style: .heading)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 4)

            CardView {
                ScrollViewReader { proxy in
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(1...surah.numberOfVerses, id: \.self) { verseNumber in
                            VerseGridCell(
                                verseNumber: verseNumber,
                                isRead: verseStates[verseNumber] ?? false,
                                onToggle: {
                                    toggleVerse(verseNumber)
                                }
                            )
                            .id(verseNumber)  // Add ID for scrolling
                        }
                    }
                    .padding(8)
                    .onChange(of: selectedVerseToScroll) { _, newValue in
                        if let verse = newValue {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(verse, anchor: .center)
                            }
                            // Reset after scroll
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                selectedVerseToScroll = nil
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadVerseStates() {
        var states: [Int: Bool] = [:]

        for verseNumber in 1...surah.numberOfVerses {
            states[verseNumber] = quranService.isVerseRead(
                surahNumber: surah.id,
                verseNumber: verseNumber
            )
        }

        verseStates = states
    }

    private func toggleVerse(_ verseNumber: Int) {
        // Optimistic update
        verseStates[verseNumber]?.toggle()

        // Backend update
        quranService.toggleVerseReadStatus(
            surahNumber: surah.id,
            verseNumber: verseNumber
        )

        // Refresh ViewModel
        viewModel.loadProgress()
    }

    private func confirmMarkAll() {
        for verseNumber in 1...surah.numberOfVerses {
            if markAllAsRead {
                verseStates[verseNumber] = true
                quranService.markVerseAsRead(
                    surahNumber: surah.id,
                    verseNumber: verseNumber,
                    manual: true
                )
            } else {
                verseStates[verseNumber] = false
                quranService.markVerseAsUnread(
                    surahNumber: surah.id,
                    verseNumber: verseNumber
                )
            }
        }

        // Refresh ViewModel
        viewModel.loadProgress()
    }

    private func goToFirstUnread() {
        // Find first unread verse
        for verseNumber in 1...surah.numberOfVerses {
            if !(verseStates[verseNumber] ?? false) {
                // Scroll to this verse in the grid
                selectedVerseToScroll = verseNumber
                return
            }
        }
    }

    private var allVersesRead: Bool {
        return verseStates.values.filter({ !$0 }).isEmpty && !verseStates.isEmpty
    }

    private func getSurahStats() -> SurahProgressStats {
        return quranService.getSurahStatistics(
            surahNumber: surah.id,
            totalVerses: surah.numberOfVerses
        )
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Supporting Components

struct VerseGridCell: View {
    let verseNumber: Int
    let isRead: Bool
    let onToggle: () -> Void

    @Environment(ThemeManager.self) var themeManager: ThemeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isRead
                            ? LinearGradient(
                                colors: [themeManager.currentTheme.accentPrimary, themeManager.currentTheme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    themeManager.currentTheme.textColor.opacity(0.1),
                                    themeManager.currentTheme.textColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isRead
                                    ? themeManager.currentTheme.accentPrimary.opacity(0.5)
                                    : themeManager.currentTheme.borderColor,
                                lineWidth: 1
                            )
                    )

                VStack(spacing: 4) {
                    Text("\(verseNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(
                            isRead
                                ? .white
                                : themeManager.currentTheme.textColor
                        )

                    if isRead {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(disabled ? .secondary : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                (disabled ? Color.secondary : color).opacity(0.1)
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        (disabled ? Color.secondary : color).opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    VerseProgressDetailView(
        surah: Surah(
            id: 1,
            name: "الفاتحة",
            englishName: "Al-Fatihah",
            englishNameTranslation: "The Opening",
            numberOfVerses: 7,
            revelationType: .meccan
        ),
        viewModel: ProgressManagementViewModel()
    )
    .environment(ThemeManager())
}
