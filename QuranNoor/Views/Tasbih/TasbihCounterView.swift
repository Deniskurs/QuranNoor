//
//  TasbihCounterView.swift
//  QuranNoor
//
//  Digital tasbih counter with haptic feedback
//

import SwiftUI

struct TasbihCounterView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var tasbihService = TasbihService.shared
    @State private var selectedPreset: TasbihPreset = .subhanAllah
    @State private var selectedTarget: Int = 33
    @State private var showingPresetPicker = false
    @State private var showingTargetPicker = false
    @State private var showingHistory = false
    @State private var showingSettings = false

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .spiritual

    private var currentCount: Int {
        tasbihService.currentSession?.currentCount ?? 0
    }

    private var targetCount: Int {
        tasbihService.currentSession?.targetCount ?? selectedTarget
    }

    private var progress: Double {
        tasbihService.currentSession?.progress ?? 0
    }

    private var isCompleted: Bool {
        tasbihService.currentSession?.isCompleted ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [themeManager.currentTheme.accent.opacity(0.12), themeManager.currentTheme.accentMuted.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with statistics
                        statisticsHeader

                        // Preset and Target Selectors
                        selectorsSection

                        // Main Counter
                        mainCounterSection

                        // Dhikr Text
                        dhikrTextSection

                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Digital Tasbih")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingHistory = true
                        } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }

                        Divider()

                        Button(role: .destructive) {
                            resetCounter()
                        } label: {
                            Label("Reset All", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPresetPicker) {
                PresetPickerView(selectedPreset: $selectedPreset) {
                    startNewSession()
                }
            }
            .sheet(isPresented: $showingTargetPicker) {
                TargetPickerView(selectedTarget: $selectedTarget) {
                    startNewSession()
                }
            }
            .sheet(isPresented: $showingHistory) {
                TasbihHistoryView()
            }
            .sheet(isPresented: $showingSettings) {
                TasbihSettingsView()
            }
            .onAppear {
                if tasbihService.currentSession == nil {
                    startNewSession()
                }
            }
            .toast(message: toastMessage, style: toastStyle, isPresented: $showToast)
        }
    }

    // MARK: - Statistics Header

    private var statisticsHeader: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "calendar",
                title: "Today",
                value: "\(tasbihService.statistics.todayCount)",
                color: themeManager.currentTheme.accent
            )

            StatCard(
                icon: "flame.fill",
                title: "Streak",
                value: "\(tasbihService.statistics.currentStreak)",
                color: .orange
            )

            StatCard(
                icon: "chart.bar.fill",
                title: "Total",
                value: "\(tasbihService.statistics.totalCount)",
                color: .green
            )
        }
    }

    // MARK: - Selectors Section

    private var selectorsSection: some View {
        HStack(spacing: 12) {
            // Preset Selector
            Button {
                showingPresetPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dhikr")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(selectedPreset.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)

            // Target Selector
            Button {
                showingTargetPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(targetCount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    // MARK: - Main Counter Section

    private var mainCounterSection: some View {
        VStack(spacing: 20) {
            // Progress Ring with Counter
            ZStack {
                // Background Circle
                Circle()
                    .stroke(.ultraThinMaterial, lineWidth: 20)
                    .frame(width: 280, height: 280)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        .linearGradient(
                            colors: isCompleted ? [.green, .green] : [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: progress)

                // Counter Display
                VStack(spacing: 8) {
                    Text("\(currentCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .foregroundStyle(
                            .linearGradient(
                                colors: isCompleted ? [.green, .green] : [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("/ \(targetCount)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture {
                incrementCounter()
            }

            // Completion Badge
            if isCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Target Reached!")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.green.opacity(0.2))
                )
            }
        }
    }

    // MARK: - Dhikr Text Section

    private var dhikrTextSection: some View {
        VStack(spacing: 16) {
            if selectedPreset != .custom && tasbihService.showArabic {
                // Arabic Text
                Text(selectedPreset.arabicText)
                    .font(.system(size: 32, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            }

            if selectedPreset != .custom {
                VStack(spacing: 8) {
                    if tasbihService.showTransliteration {
                        Text(selectedPreset.transliteration)
                            .font(.title3)
                            .italic()
                            .foregroundStyle(.primary)
                    }

                    if tasbihService.showTranslation {
                        Text(selectedPreset.translation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Reset Button
            Button {
                resetCounter()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text("Reset")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)

            // Decrement Button
            Button {
                decrementCounter()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                    Text("Undo")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)
            .disabled(currentCount == 0)
            .opacity(currentCount == 0 ? 0.5 : 1.0)

            // New Session Button
            Button {
                startNewSession()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("New")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func incrementCounter() {
        let wasCompleted = isCompleted
        withAnimation(.spring(duration: 0.3)) {
            tasbihService.increment()
        }

        // Show toast when target is just reached
        if !wasCompleted && isCompleted {
            toastMessage = "Target reached! Subhan'Allah"
            toastStyle = .spiritual
            showToast = true
        }
    }

    private func decrementCounter() {
        withAnimation(.spring(duration: 0.3)) {
            tasbihService.decrement()
        }
    }

    private func resetCounter() {
        withAnimation {
            tasbihService.resetSession()
        }

        // Medium haptic
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func startNewSession() {
        tasbihService.startSession(preset: selectedPreset, target: selectedTarget)
    }
}

// Note: StatCard moved to Components/Cards/StatCard.swift

#Preview {
    TasbihCounterView()
        .environment(ThemeManager())
}
