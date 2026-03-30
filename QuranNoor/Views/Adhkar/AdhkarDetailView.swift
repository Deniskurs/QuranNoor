//
//  AdhkarDetailView.swift
//  QuranNoor
//
//  Detail view for individual dhikr with counter
//

import SwiftUI

struct AdhkarDetailView: View {
    @Environment(ThemeManager.self) var themeManager
    let dhikr: Dhikr
    @Bindable var adhkarService: AdhkarService
    var allDhikrInCategory: [Dhikr]? = nil
    var initialIndex: Int? = nil

    @State private var currentCount: Int = 0
    @State private var currentDhikrIndex: Int = 0
    @State private var showTransliteration = true
    @State private var showTranslation = true
    @State private var showBenefits = false
    @State private var tapScale: CGFloat = 1.0
    @State private var showCompletionPulse = false
    @Environment(\.dismiss) private var dismiss

    private var activeDhikr: Dhikr {
        guard let allDhikr = allDhikrInCategory,
              currentDhikrIndex >= 0,
              currentDhikrIndex < allDhikr.count else {
            return dhikr
        }
        return allDhikr[currentDhikrIndex]
    }

    private var isCompleted: Bool {
        adhkarService.isCompleted(dhikrId: activeDhikr.id)
    }

    private var progress: Double {
        guard activeDhikr.repetitions > 0 else { return 0 }
        return min(Double(currentCount) / Double(activeDhikr.repetitions), 1.0)
    }

    private var hasNextDhikr: Bool {
        guard let allDhikr = allDhikrInCategory else { return false }
        return currentDhikrIndex < allDhikr.count - 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Ring
                    progressRing

                    // Arabic Text
                    arabicTextSection

                    // Transliteration
                    if showTransliteration {
                        transliterationSection
                    }

                    // Translation
                    if showTranslation {
                        translationSection
                    }

                    // Benefits
                    if let benefits = activeDhikr.benefits {
                        benefitsSection(benefits)
                    }

                    // Reference
                    referenceSection

                    // Counter Button
                    counterButton

                    // Display Options
                    displayOptions
                }
                .padding()
            }
            .navigationTitle("Dhikr")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                currentDhikrIndex = initialIndex ?? 0
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(.ultraThinMaterial, lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Milestone markers at 25%, 50%, 75%
                ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                    Circle()
                        .fill(progress >= milestone ? Color.white : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .offset(y: -60)
                        .rotationEffect(.degrees(milestone * 360 - 90))
                }

                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        .linearGradient(
                            colors: progress >= 1.0 ? [.green, .green] : [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: progress)

                // Completion pulse
                if showCompletionPulse {
                    Circle()
                        .fill(.green.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showCompletionPulse ? 1.3 : 1.0)
                        .opacity(showCompletionPulse ? 0 : 0.5)
                        .animation(.easeOut(duration: 0.8), value: showCompletionPulse)
                }

                // Count
                VStack(spacing: 4) {
                    Text("\(currentCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text("/ \(activeDhikr.repetitions)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if currentCount >= activeDhikr.repetitions && !isCompleted {
                Button {
                    markCompleted()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Completed")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.green)
                    )
                }
                .buttonStyle(.plain)
            }

            if isCompleted {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Completed Today")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if hasNextDhikr {
                        Button {
                            advanceToNextDhikr()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next Dhikr")
                                Image(systemName: "chevron.right")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.currentTheme.featureAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.featureAccent.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: - Arabic Text Section

    private var arabicTextSection: some View {
        VStack(spacing: 8) {
            Text(activeDhikr.arabicText)
                .font(.system(size: 28, weight: .medium))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Transliteration Section

    private var transliterationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transliteration")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(activeDhikr.transliteration)
                .font(.body)
                .italic()
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Translation")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(activeDhikr.translation)
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Benefits Section

    private func benefitsSection(_ benefits: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    showBenefits.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Benefits")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: showBenefits ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if showBenefits {
                Text(benefits)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.yellow.opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Reference Section

    private var referenceSection: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(.secondary)
            Text(activeDhikr.reference)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Counter Button

    private var counterButton: some View {
        Button {
            incrementCount()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        .linearGradient(
                            colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)

                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title)

                    Text("Tap to Count")
                        .font(.headline)
                }
                .foregroundStyle(.white)
            }
            .scaleEffect(tapScale)
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
        .opacity(isCompleted ? 0.5 : 1.0)
    }

    // MARK: - Display Options

    private var displayOptions: some View {
        VStack(spacing: 12) {
            Toggle("Show Transliteration", isOn: $showTransliteration)
            Toggle("Show Translation", isOn: $showTranslation)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Actions

    private func incrementCount() {
        guard !isCompleted else { return }

        // Bounce animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            tapScale = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapScale = 1.0
            }
        }

        withAnimation(.spring(duration: 0.3)) {
            if currentCount < activeDhikr.repetitions {
                currentCount += 1
            }
        }

        // Haptic feedback - varies by milestone
        let quarterTarget = activeDhikr.repetitions / 4
        if quarterTarget > 0 && currentCount % quarterTarget == 0 && currentCount < activeDhikr.repetitions {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } else {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        // Completion celebration
        if currentCount == activeDhikr.repetitions {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            // Stronger haptic on completion
            let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
            heavyImpact.impactOccurred()

            withAnimation {
                showCompletionPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showCompletionPulse = false
            }
        }
    }

    private func markCompleted() {
        adhkarService.markCompleted(dhikrId: activeDhikr.id)

        // Success feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    private func advanceToNextDhikr() {
        guard hasNextDhikr else { return }
        withAnimation(.spring(duration: 0.4)) {
            currentDhikrIndex += 1
            currentCount = 0
            showBenefits = false
            showCompletionPulse = false
        }
    }
}

#Preview {
    AdhkarDetailView(
        dhikr: Dhikr(
            arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa bihamdihi",
            translation: "Glory is to Allah and praise is to Him.",
            reference: "Bukhari 6405",
            repetitions: 100,
            benefits: "Whoever says this 100 times in the morning and evening, none will bring better than what he brought except one who does more than that.",
            category: .morning,
            order: 1
        ),
        adhkarService: AdhkarService()
    )
}
