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

    @State private var currentCount: Int = 0
    @State private var showTransliteration = true
    @State private var showTranslation = true
    @State private var showBenefits = false
    @Environment(\.dismiss) private var dismiss

    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .spiritual

    private var isCompleted: Bool {
        adhkarService.isCompleted(dhikrId: dhikr.id)
    }

    private var progress: Double {
        guard dhikr.repetitions > 0 else { return 0 }
        return min(Double(currentCount) / Double(dhikr.repetitions), 1.0)
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
                    if let benefits = dhikr.benefits {
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
            .toast(message: toastMessage, style: toastStyle, isPresented: $showToast)
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

                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        .linearGradient(
                            colors: progress >= 1.0 ? [.green, .green] : [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.5), value: progress)

                // Count
                VStack(spacing: 4) {
                    Text("\(currentCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text("/ \(dhikr.repetitions)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if currentCount >= dhikr.repetitions && !isCompleted {
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
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Completed Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Arabic Text Section

    private var arabicTextSection: some View {
        VStack(spacing: 8) {
            Text(dhikr.arabicText)
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

            Text(dhikr.transliteration)
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

            Text(dhikr.translation)
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
            Text(dhikr.reference)
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
                            colors: [themeManager.currentTheme.accent, themeManager.currentTheme.accentMuted],
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

        withAnimation(.spring(duration: 0.3)) {
            if currentCount < dhikr.repetitions {
                currentCount += 1
            }
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Special feedback on completion
        if currentCount == dhikr.repetitions {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            toastMessage = "Target reached! Alhamdulillah"
            toastStyle = .spiritual
            showToast = true
        }
    }

    private func markCompleted() {
        adhkarService.markCompleted(dhikrId: dhikr.id)

        // Success feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        toastMessage = "Dhikr completed! Masha'Allah"
        toastStyle = .spiritual
        showToast = true
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
