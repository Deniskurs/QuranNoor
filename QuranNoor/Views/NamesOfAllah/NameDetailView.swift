//
//  NameDetailView.swift
//  QuranNoor
//
//  Detail view for individual Name of Allah
//

import SwiftUI

struct NameDetailView: View {
    @Environment(ThemeManager.self) var themeManager
    let name: NameOfAllah
    @Bindable var namesService: NamesOfAllahService

    @Environment(\.dismiss) private var dismiss

    private var isFavorite: Bool {
        namesService.isFavorite(number: name.number)
    }

    private var isLearned: Bool {
        namesService.isLearned(number: name.number)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Number Badge
                    numberBadge

                    // Arabic Name
                    arabicNameSection

                    // Transliteration and Translation
                    namesSection

                    // Meaning
                    meaningSection

                    // Benefit
                    if let benefit = name.benefit {
                        benefitSection(benefit)
                    }

                    // Reference
                    if let reference = name.reference {
                        referenceSection(reference)
                    }

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Name of Allah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            namesService.toggleFavorite(number: name.number)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .primary)
                    }
                }
            }
        }
    }

    // MARK: - Number Badge

    private var numberBadge: some View {
        ZStack {
            Circle()
                .fill(
                    .linearGradient(
                        colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            VStack(spacing: 4) {
                Text("\(name.number)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)

                Text("of 99")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Arabic Name Section

    private var arabicNameSection: some View {
        VStack(spacing: 12) {
            Text(name.arabicName)
                .font(.system(size: 48, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    .linearGradient(
                        colors: [themeManager.currentTheme.featureAccent, themeManager.currentTheme.featureAccentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Names Section

    private var namesSection: some View {
        VStack(spacing: 12) {
            // Transliteration
            HStack {
                Text("Transliteration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(name.transliteration)
                .font(.title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Translation
            HStack {
                Text("Translation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(name.translation)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Meaning Section

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(themeManager.currentTheme.featureAccent)
                Text("Meaning")
                    .font(.headline)
                Spacer()
            }

            Text(name.meaning)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.featureBackgroundTint)
        )
    }

    // MARK: - Benefit Section

    private func benefitSection(_ benefit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Spiritual Benefit")
                    .font(.headline)
                Spacer()
            }

            Text(benefit)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.1))
        )
    }

    // MARK: - Reference Section

    private func referenceSection(_ reference: String) -> some View {
        HStack {
            Image(systemName: "text.book.closed.fill")
                .foregroundStyle(.secondary)
            Text(reference)
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

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Mark as Learned Button
            Button {
                withAnimation {
                    namesService.markAsLearned(number: name.number)
                }
            } label: {
                HStack {
                    Image(systemName: isLearned ? "checkmark.circle.fill" : "circle")
                    Text(isLearned ? "Learned" : "Mark as Learned")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isLearned ? themeManager.currentTheme.featureAccent : .primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isLearned ? themeManager.currentTheme.featureAccent.opacity(0.2) : Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            // Share Button
            Button {
                shareText()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
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

    private func shareText() {
        let text = """
        \(name.arabicName)
        \(name.transliteration) - \(name.translation)

        \(name.meaning)

        #99NamesOfAllah #AsmaUlHusna
        """

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    NameDetailView(
        name: NameOfAllah(
            number: 1,
            arabicName: "الرَّحْمَنُ",
            transliteration: "Ar-Rahman",
            translation: "The Most Merciful",
            meaning: "The One who has plenty of mercy for the believers and the disbelievers in this world and especially for the believers in the hereafter.",
            benefit: "Recite 100 times after Fajr prayer for opening the heart to Allah's mercy."
        ),
        namesService: NamesOfAllahService()
    )
    .environment(ThemeManager())
}
