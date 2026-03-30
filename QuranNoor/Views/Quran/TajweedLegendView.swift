//
//  TajweedLegendView.swift
//  QuranNoor
//
//  Sheet view listing all tajweed rules with their colors and descriptions,
//  grouped by phonological category.
//

import SwiftUI

// MARK: - TajweedLegendView

/// A sheet that displays all tajweed color rules grouped by category,
/// helping users understand the color-coding used in the Quran reader.
struct TajweedLegendView: View {

    // MARK: - Environment

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        let theme = themeManager.currentTheme

        NavigationStack {
            List {
                ForEach(TajweedCategory.allCases, id: \.title) { category in
                    Section(header: sectionHeader(category.title, theme: theme)) {
                        ForEach(category.rules, id: \.rawValue) { rule in
                            RuleRow(rule: rule, theme: theme)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor)
            .navigationTitle("Tajweed Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.cardColor, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String, theme: ThemeMode) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(theme.textSecondary)
    }
}

// MARK: - RuleRow

private struct RuleRow: View {
    let rule: TajweedRule
    let theme: ThemeMode

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Colored indicator circle
            Circle()
                .fill(rule.color(for: theme))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .strokeBorder(rule.color(for: theme).opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.textPrimary)

                Text(ruleDescription(rule))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Arabic example in the rule's color
            Text(rule.arabicExample)
                .font(.custom("KFGQPCUthmanicScriptHAFS", size: 22))
                .foregroundStyle(rule.color(for: theme))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.cardColor)
    }

    // MARK: - Descriptions

    private func ruleDescription(_ rule: TajweedRule) -> String {
        switch rule {
        case .hamWasl:
            return "Connecting hamza; silent when preceded by a word"
        case .laamShamsiyah:
            return "Laam assimilated into the following sun letter"
        case .silent:
            return "Letter is written but not pronounced"
        case .maddaNormal:
            return "Natural elongation for 2 counts (harakah)"
        case .maddaPermissible:
            return "Optional elongation for 2, 4, or 6 counts"
        case .maddaObligatory:
            return "Obligatory elongation for exactly 6 counts"
        case .qalqalah:
            return "Echo or reverberating sound on sukoon letters: ق ط ب ج د"
        case .ikhfa:
            return "Concealment of noon saakin/tanween with partial nasalisation"
        case .ikhfaShafawi:
            return "Concealment of meem saakin before ب with nasal sound"
        case .idghamGhunnah:
            return "Merging noon saakin/tanween into ن م و ي with ghunnah"
        case .idghamWithoutGhunnah:
            return "Merging noon saakin/tanween into ل ر without ghunnah"
        case .iqlab:
            return "Changing noon saakin/tanween to م sound before ب"
        case .ghunnah:
            return "Nasal resonance held for 2 counts on shaddah noon or meem"
        }
    }
}

// MARK: - TajweedCategory

/// Logical groupings of tajweed rules for the legend list.
private enum TajweedCategory: CaseIterable {
    case silentReduced
    case elongation
    case nasalization
    case emphasis

    var title: String {
        switch self {
        case .silentReduced:  return "Silent / Reduced"
        case .elongation:     return "Elongation (Madd)"
        case .nasalization:   return "Nasalization (Ghunnah)"
        case .emphasis:       return "Emphasis"
        }
    }

    var rules: [TajweedRule] {
        switch self {
        case .silentReduced:
            return [.hamWasl, .laamShamsiyah, .silent]
        case .elongation:
            return [.maddaNormal, .maddaPermissible, .maddaObligatory]
        case .nasalization:
            return [.ikhfa, .ikhfaShafawi, .idghamGhunnah, .idghamWithoutGhunnah, .iqlab, .ghunnah]
        case .emphasis:
            return [.qalqalah]
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    TajweedLegendView()
        .environment(ThemeManager.shared)
}
#endif
