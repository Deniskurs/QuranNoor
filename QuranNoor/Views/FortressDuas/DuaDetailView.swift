//
//  DuaDetailView.swift
//  QuranNoor
//
//  Detail view for individual Fortress dua
//

import SwiftUI

struct DuaDetailView: View {
    @Environment(ThemeManager.self) var themeManager
    let dua: FortressDua
    @Bindable var duaService: FortressDuaService

    @Environment(\.dismiss) private var dismiss

    private var isFavorite: Bool {
        duaService.progress.isFavorite(duaId: dua.id)
    }

    private var usageCount: Int {
        duaService.progress.getUsageCount(duaId: dua.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Badge
                    categoryBadge

                    // Title and Occasion
                    titleSection

                    // Arabic Text
                    arabicSection

                    // Transliteration
                    transliterationSection

                    // Translation
                    translationSection

                    // Benefits (if available)
                    if let benefits = dua.benefits {
                        benefitsSection(benefits)
                    }

                    // Reference
                    referenceSection

                    // Usage Statistics
                    if usageCount > 0 {
                        usageSection
                    }

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Dua Details")
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
                            duaService.toggleFavorite(duaId: dua.id)
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .primary)
                    }
                }
            }
        }
    }

    // MARK: - Category Badge

    private var categoryBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: dua.category.icon)
                .foregroundStyle(categoryColor)

            Text(dua.category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(categoryColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(categoryColor.opacity(0.1))
        )
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(dua.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(dua.occasion)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Arabic Section

    private var arabicSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "character.textbox")
                    .foregroundStyle(.green)
                Text("Arabic Text")
                    .font(.headline)
                Spacer()
            }

            Text(dua.arabicText)
                .font(.system(size: 28))
                .lineSpacing(12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.05))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Transliteration Section

    private var transliterationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "text.word.spacing")
                    .foregroundStyle(themeManager.currentTheme.featureAccent)
                Text("Transliteration")
                    .font(.headline)
                Spacer()
            }

            Text(dua.transliteration)
                .font(.body)
                .italic()
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.featureBackgroundTint)
        )
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(.purple)
                Text("Translation")
                    .font(.headline)
                Spacer()
            }

            Text(dua.translation)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.purple.opacity(0.1))
        )
    }

    // MARK: - Benefits Section

    private func benefitsSection(_ benefits: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Benefits")
                    .font(.headline)
                Spacer()
            }

            Text(benefits)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.1))
        )
    }

    // MARK: - Reference Section

    private var referenceSection: some View {
        HStack {
            Image(systemName: "text.book.closed.fill")
                .foregroundStyle(.secondary)
            Text("Reference: \(dua.reference)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Usage Section

    private var usageSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green)
                Text("Usage Statistics")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Label("Recited \(usageCount) times", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: 12) {
            // Mark as Recited Button
            Button {
                withAnimation {
                    duaService.incrementUsage(duaId: dua.id)
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Recited")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            .linearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)

            // Share Button
            Button {
                shareText()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Properties

    private var categoryColor: Color {
        themeManager.currentTheme.categoryColor(for: dua.category.color)
    }

    // MARK: - Actions

    private func shareText() {
        var text = """
        \(dua.title)
        \(dua.occasion)

        \(dua.arabicText)

        \(dua.transliteration)

        \(dua.translation)
        """

        if let benefits = dua.benefits {
            text += "\n\nBenefits: \(benefits)"
        }

        text += "\n\nReference: \(dua.reference)"
        text += "\n\n#HisnAlMuslim #FortressOfTheMuslim #IslamicDuas"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    DuaDetailView(
        dua: FortressDua(
            category: .waking,
            title: "Upon Waking Up",
            arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
            transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur.",
            translation: "All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.",
            reference: "Bukhari 6312",
            occasion: "When waking up from sleep",
            benefits: "Expressing gratitude for being granted another day of life and remembering the resurrection.",
            order: 1
        ),
        duaService: FortressDuaService()
    )
}
