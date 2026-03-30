//
//  ShareStylePickerView.swift
//  QuranNoor
//
//  User-facing sheet for selecting a share style and exporting a verse image.
//

import SwiftUI

// MARK: - Share Style Picker View

struct ShareStylePickerView: View {
    // MARK: Input
    let arabicText: String
    let translationText: String?
    let surahName: String
    let verseReference: String

    // MARK: Environment
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    // MARK: State
    @State private var selectedStyle: ShareImageStyle = .emerald
    @State private var selectedSize: ShareImageSize   = .portrait
    @State private var includeTranslation: Bool       = true
    @State private var isGenerating: Bool             = false
    @State private var showShareSheet: Bool           = false
    @State private var generatedImage: UIImage?

    // MARK: Layout
    private let previewMaxHeight: CGFloat = 400

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Live preview
                    livePreview

                    // Style cards
                    styleSelector

                    // Options
                    optionsSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxl + 80)  // room for fixed button
            }
            .background(theme.backgroundColor)
            .navigationTitle("Share Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.accent)
                }
            }
            .overlay(alignment: .bottom) {
                shareButton
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.lg)
                    .background(
                        LinearGradient(
                            colors: [theme.backgroundColor.opacity(0), theme.backgroundColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false),
                        alignment: .top
                    )
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = generatedImage {
                    ShareSheet(items: [image, shareText])
                }
            }
        }
    }

    // MARK: - Subviews

    /// Scaled-down live preview that mirrors the final image.
    private var livePreview: some View {
        GeometryReader { geo in
            let aspectRatio = selectedSize.height / selectedSize.width
            let previewWidth = geo.size.width
            let previewHeight = min(previewWidth * aspectRatio, previewMaxHeight)
            let scale = previewHeight / selectedSize.height

            VerseShareImageView(
                arabicText: arabicText,
                translationText: includeTranslation ? translationText : nil,
                surahName: surahName,
                verseReference: verseReference,
                style: selectedStyle,
                size: selectedSize
            )
            .frame(width: selectedSize.width, height: selectedSize.height)
            .scaleEffect(scale)
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous))
            .shadow(color: theme.currentTheme.cardShadow, radius: theme.currentTheme.cardShadowRadius, x: 0, y: 4)
        }
        .frame(height: previewMaxHeight)
        .animation(AppAnimation.fast, value: selectedStyle)
        .animation(AppAnimation.fast, value: selectedSize)
        .animation(AppAnimation.fast,  value: includeTranslation)
    }

    /// Horizontal scroll of style thumbnail cards.
    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Style")
                .font(AppTypography.sectionHeader)
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ShareImageStyle.allCases) { style in
                        StyleThumbnailCard(
                            style: style,
                            isSelected: selectedStyle == style
                        )
                        .onTapGesture {
                            withAnimation(AppAnimation.fast) {
                                selectedStyle = style
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.xxxs)
            }
        }
    }

    /// Size toggle, translation toggle.
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Options")
                .font(AppTypography.sectionHeader)
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 0) {
                // Size picker
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Size")
                        .font(AppTypography.caption)
                        .foregroundColor(theme.textSecondary)

                    Picker("Size", selection: $selectedSize) {
                        ForEach(ShareImageSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, Spacing.sm)

                Divider()
                    .foregroundColor(theme.borderColor)

                // Translation toggle
                Toggle(isOn: $includeTranslation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Translation")
                            .font(AppTypography.body)
                            .foregroundColor(theme.textPrimary)
                        if translationText == nil {
                            Text("No translation available")
                                .font(AppTypography.caption)
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                }
                .tint(theme.accent)
                .disabled(translationText == nil)
                .padding(.vertical, Spacing.sm)
            }
            .padding(.horizontal, Spacing.sm)
            .background(theme.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous))
        }
    }

    /// Fixed "Share" button at bottom of screen.
    private var shareButton: some View {
        Button {
            generateAndShare()
        } label: {
            HStack(spacing: Spacing.xxs) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isGenerating ? "Generating..." : "Share")
                    .font(AppTypography.button)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.tapTarget)
            .background(theme.accent)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.xl, style: .continuous))
        }
        .disabled(isGenerating)
    }

    // MARK: - Helpers

    private var shareText: String {
        var parts = [arabicText]
        if includeTranslation, let translation = translationText {
            parts.append(translation)
        }
        parts.append("\(surahName) \u{00B7} \(verseReference)")
        parts.append("Shared via Quran Noor")
        return parts.joined(separator: "\n\n")
    }

    private func generateAndShare() {
        isGenerating = true
        Task {
            let image = VerseImageGenerator.generateImage(
                arabicText: arabicText,
                translationText: includeTranslation ? translationText : nil,
                surahName: surahName,
                verseReference: verseReference,
                style: selectedStyle,
                size: selectedSize
            )
            generatedImage = image
            isGenerating = false
            if image != nil {
                showShareSheet = true
            }
        }
    }
}

// MARK: - Style Thumbnail Card

private struct StyleThumbnailCard: View {
    let style: ShareImageStyle
    let isSelected: Bool

    private let cardSize: CGFloat = 80

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            // Mini gradient / solid swatch
            ZStack {
                if style.usesGradient {
                    LinearGradient(
                        colors: style.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    style.backgroundColor
                }

                // Tiny ornamental border hint
                RoundedRectangle(cornerRadius: BorderRadius.md - 2, style: .continuous)
                    .strokeBorder(style.borderColor.opacity(0.8), lineWidth: 1)
                    .padding(4)

                // Arabic letter hint
                Text("\u{0628}")  // ب  (Ba — compact stand-in)
                    .font(.custom("KFGQPCUthmanicScriptHAFS", size: 22))
                    .foregroundColor(style.arabicTextColor)
            }
            .frame(width: cardSize, height: cardSize)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.lg, style: .continuous)
                    .strokeBorder(
                        isSelected ? style.borderColor : Color.clear,
                        lineWidth: 2.5
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(AppAnimation.fast, value: isSelected)

            Text(style.displayName)
                .font(AppTypography.caption)
                .foregroundColor(isSelected ? style.borderColor : .secondary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
    }
}
