//
//  WordByWordView.swift
//  QuranNoor
//
//  Tappable word-by-word display for a single Quran verse.
//  Words flow right-to-left and wrap naturally using a custom Layout.
//

import SwiftUI

// MARK: - RTL Flow Layout

/// A custom Layout that flows children right-to-left, wrapping onto new rows.
struct RTLFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        return layout(subviews: subviews, in: containerWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        let result = layout(subviews: subviews, in: containerWidth)

        for (index, frame) in result.frames.enumerated() {
            // Mirror X position for RTL: place from right edge
            let mirroredX = bounds.maxX - frame.maxX
            subviews[index].place(
                at: CGPoint(x: mirroredX + bounds.minX, y: frame.minY + bounds.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    // MARK: - Private Layout Engine

    private struct LayoutResult {
        let frames: [CGRect]
        let size: CGSize
    }

    private func layout(subviews: Subviews, in containerWidth: CGFloat) -> LayoutResult {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Wrap to next row if we exceed container width
            if currentX + size.width > containerWidth, currentX > 0 {
                currentY += rowHeight + verticalSpacing
                totalHeight = currentY
                currentX = 0
                rowHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + horizontalSpacing
        }

        totalHeight = currentY + rowHeight

        return LayoutResult(
            frames: frames,
            size: CGSize(width: containerWidth, height: totalHeight)
        )
    }
}

// MARK: - Word Chip

private struct WordChip: View {
    let word: QuranWord
    let fontSize: CGFloat
    let mushafType: MushafType
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(ThemeManager.self) private var theme

    private var arabicFont: Font {
        AppTypography.arabicFont(for: mushafType, size: fontSize)
    }

    var body: some View {
        if word.charType.isTappable {
            Button(action: onTap) {
                chipContent
            }
            .buttonStyle(WordChipButtonStyle(isSelected: isSelected, theme: theme))
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double-tap to see word details")
        } else {
            // Verse-end marker — not interactive
            Text("۝")
                .font(AppTypography.arabicScalable(size: fontSize * 0.8))
                .foregroundStyle(theme.textTertiary)
                .padding(.horizontal, Spacing.xxxs)
                .accessibilityHidden(true)
        }
    }

    private var chipContent: some View {
        VStack(spacing: 2) {
            Text(word.textUthmani)
                .font(arabicFont)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize()

            if let translation = word.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: max(10, fontSize * 0.45)))
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xxxs + 2)
        .padding(.vertical, Spacing.xxxs)
    }

    private var accessibilityLabel: String {
        var label = word.textUthmani
        if let translation = word.translation {
            label += ", meaning: \(translation)"
        }
        return label
    }
}

// MARK: - Word Chip Button Style

private struct WordChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    let theme: ThemeManager

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: BorderRadius.md, style: .continuous)
                    .fill(isSelected || configuration.isPressed
                          ? theme.accentTint
                          : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? theme.accent.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

// MARK: - Word By Word View

/// Displays a single verse's words as tappable chips in a right-to-left wrapping layout.
///
/// Usage:
/// ```swift
/// WordByWordView(words: verseWords, fontSize: 24, mushafType: .uthmani)
///     .sheet(item: $selectedWord) { word in
///         WordDetailSheet(word: word)
///     }
/// ```
struct WordByWordView: View {
    let words: [QuranWord]
    let fontSize: CGFloat
    let mushafType: MushafType

    @Environment(ThemeManager.self) private var theme
    @State private var selectedWord: QuranWord?

    var body: some View {
        RTLFlowLayout(horizontalSpacing: Spacing.xxxs, verticalSpacing: Spacing.xxs)  {
            ForEach(words) { word in
                WordChip(
                    word: word,
                    fontSize: fontSize,
                    mushafType: mushafType,
                    isSelected: selectedWord?.id == word.id
                ) {
                    if word.charType.isTappable {
                        selectedWord = word
                    }
                }
            }
        }
        .sheet(item: $selectedWord) { word in
            WordDetailSheet(word: word, mushafType: mushafType)
                .environment(theme)
        }
    }
}
