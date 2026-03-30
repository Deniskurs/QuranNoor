//
//  VerseShareImageView.swift
//  QuranNoor
//
//  Canvas view rendered to a shareable verse image.
//  Not intended to be displayed directly in the app UI —
//  it is passed to ImageRenderer inside VerseImageGenerator.
//

import SwiftUI

// MARK: - Ornamental Border

/// A thin horizontal decorative line with a small diamond motif at its centre.
/// Scales with the containing view width.
struct OrnamentalBorder: View {
    let color: Color
    var lineWidth: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let mid   = geo.size.width / 2
            let half  = geo.size.height / 2
            let dSize: CGFloat = 7   // half-size of the diamond

            Canvas { ctx, _ in
                // Left line
                var leftPath = Path()
                leftPath.move(to: CGPoint(x: 0, y: half))
                leftPath.addLine(to: CGPoint(x: mid - dSize - 6, y: half))
                ctx.stroke(leftPath, with: .color(color), lineWidth: lineWidth)

                // Right line
                var rightPath = Path()
                rightPath.move(to: CGPoint(x: mid + dSize + 6, y: half))
                rightPath.addLine(to: CGPoint(x: geo.size.width, y: half))
                ctx.stroke(rightPath, with: .color(color), lineWidth: lineWidth)

                // Diamond
                var diamond = Path()
                diamond.move(to:    CGPoint(x: mid,         y: half - dSize))
                diamond.addLine(to: CGPoint(x: mid + dSize, y: half))
                diamond.addLine(to: CGPoint(x: mid,         y: half + dSize))
                diamond.addLine(to: CGPoint(x: mid - dSize, y: half))
                diamond.closeSubpath()
                ctx.stroke(diamond, with: .color(color), lineWidth: lineWidth)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Verse Share Image View

/// Full-bleed canvas that is rendered to a UIImage by `VerseImageGenerator`.
/// Layout (top → bottom):
///   ornamental top border
///   Arabic verse text (centred, large)
///   decorative divider
///   English translation (centred, italic) — optional
///   Surah name · reference
///   "Quran Noor" branding (bottom-right)
///   ornamental bottom border
struct VerseShareImageView: View {
    let arabicText: String
    let translationText: String?
    let surahName: String
    let verseReference: String
    let style: ShareImageStyle
    let size: ShareImageSize

    // MARK: Computed layout constants (relative to canvas width)
    private var horizontalPadding: CGFloat { size.width * 0.10 }
    private var verticalPadding:   CGFloat { size.height * 0.07 }
    private var translationSize:   CGFloat { 20 }
    private var referenceSize:     CGFloat { 16 }
    private var brandingSize:      CGFloat { 14 }

    var body: some View {
        ZStack {
            // MARK: Background
            backgroundLayer

            // MARK: Content
            VStack(spacing: 0) {
                // Top ornamental border
                OrnamentalBorder(color: style.borderColor, lineWidth: 1.5)
                    .padding(.horizontal, horizontalPadding)

                Spacer(minLength: 0)

                // Arabic verse text
                Text(arabicText)
                    .font(.custom("KFGQPCUthmanicScriptHAFS", size: size.arabicFontSize))
                    .foregroundColor(style.arabicTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(size.arabicFontSize * 0.4)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, horizontalPadding)

                // Decorative divider
                decorativeDivider
                    .padding(.top, 32)
                    .padding(.horizontal, horizontalPadding)

                // Translation
                if let translation = translationText {
                    Text("\u{201C}\(translation)\u{201D}")
                        .font(.system(size: translationSize, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(style.translationTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 28)
                        .padding(.horizontal, horizontalPadding)
                }

                // Reference
                Text("\(surahName) \u{00B7} \(verseReference)")
                    .font(.system(size: referenceSize, weight: .medium, design: .default))
                    .foregroundColor(style.referenceTextColor)
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalPadding)

                Spacer(minLength: 0)

                // Branding row
                HStack {
                    Spacer()
                    Text("Quran Noor")
                        .font(.system(size: brandingSize, weight: .light, design: .default))
                        .foregroundColor(style.brandingColor)
                        .tracking(0.8)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 12)

                // Bottom ornamental border
                OrnamentalBorder(color: style.borderColor, lineWidth: 1.5)
                    .padding(.horizontal, horizontalPadding)
            }
            .padding(.vertical, verticalPadding)
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if style.usesGradient {
            LinearGradient(
                colors: style.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            style.backgroundColor
        }
    }

    // MARK: - Decorative Divider

    private var decorativeDivider: some View {
        HStack(spacing: 8) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(style.dividerColor)

            Image(systemName: "star.fill")
                .font(.system(size: 7))
                .foregroundColor(style.dividerColor)

            Image(systemName: "star.fill")
                .font(.system(size: 9))
                .foregroundColor(style.dividerColor)

            Image(systemName: "star.fill")
                .font(.system(size: 7))
                .foregroundColor(style.dividerColor)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(style.dividerColor)
        }
    }
}
