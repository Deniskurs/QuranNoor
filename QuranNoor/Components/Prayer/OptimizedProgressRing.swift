//
//  OptimizedProgressRing.swift
//  QuranNoor
//
//  Created by Claude on 11/1/2025.
//  120fps optimized progress ring for ProMotion displays
//

import SwiftUI

/// High-performance progress ring optimized for 120fps ProMotion displays
/// Uses .drawingGroup() for Metal acceleration
struct OptimizedProgressRing: View {
    // MARK: - Properties

    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    let backgroundColor: Color
    let showPercentage: Bool

    // MARK: - Animation State

    @State private var animatedProgress: Double = 0

    // MARK: - Initializer

    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 100,
        color: Color = AppColors.primary.green,
        backgroundColor: Color = Color.gray.opacity(0.2),
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Percentage text (if enabled)
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .frame(width: size + lineWidth, height: size + lineWidth) // Prevent clipping
        .drawingGroup() // Metal acceleration for 120fps
        .onAppear {
            // Animate to initial progress
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            // Smooth animation for progress changes
            withAnimation(.linear(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Preview

#Preview("Progress Variations") {
    VStack(spacing: 40) {
        // 25% Progress
        OptimizedProgressRing(
            progress: 0.25,
            lineWidth: 8,
            size: 100,
            showPercentage: true
        )

        // 50% Progress
        OptimizedProgressRing(
            progress: 0.50,
            lineWidth: 10,
            size: 120,
            color: AppColors.primary.teal,
            showPercentage: true
        )

        // 75% Progress (Urgent)
        OptimizedProgressRing(
            progress: 0.75,
            lineWidth: 12,
            size: 140,
            color: .orange,
            showPercentage: true
        )

        // 100% Complete
        OptimizedProgressRing(
            progress: 1.0,
            lineWidth: 8,
            size: 80,
            color: AppColors.primary.green
        )
    }
    .padding()
    .background(Color(hex: "#1A2332"))
}
