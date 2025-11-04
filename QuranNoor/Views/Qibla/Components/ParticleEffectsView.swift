//
//  ParticleEffectsView.swift
//  QuranNoor
//
//  Particle effects for Qibla alignment celebration
//

import SwiftUI

// MARK: - Particle Model

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var opacity: Double
    var scale: Double
    var rotation: Double
    var color: Color
}

// MARK: - Star Particle Emitter

struct ParticleEmitterView: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    let isEmitting: Bool
    let center: CGPoint

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                var contextCopy = context
                contextCopy.opacity = particle.opacity
                contextCopy.translateBy(x: particle.position.x, y: particle.position.y)
                contextCopy.scaleBy(x: particle.scale, y: particle.scale)
                contextCopy.rotate(by: .degrees(particle.rotation))

                let star = createStarPath()

                contextCopy.fill(
                    star,
                    with: .color(particle.color)
                )
            }
        }
        .onAppear {
            if isEmitting {
                startEmitting()
            }
        }
        .onChange(of: isEmitting) { oldValue, newValue in
            if newValue {
                startEmitting()
            } else {
                stopEmitting()
            }
        }
        .accessibilityHidden(true)
    }

    private func createStarPath() -> Path {
        var path = Path()
        let points: [CGPoint] = [
            CGPoint(x: 0, y: -10),
            CGPoint(x: 2.5, y: -2.5),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 2.5, y: 2.5),
            CGPoint(x: 0, y: 10),
            CGPoint(x: -2.5, y: 2.5),
            CGPoint(x: -10, y: 0),
            CGPoint(x: -2.5, y: -2.5)
        ]

        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()

        return path
    }

    private func startEmitting() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            emitParticles()
            updateParticles()
        }
    }

    private func stopEmitting() {
        timer?.invalidate()
        timer = nil
        particles.removeAll()
    }

    private func emitParticles() {
        // Emit 3 particles per frame
        for _ in 0..<3 {
            let angle = Double.random(in: 0...360) * .pi / 180
            let speed = Double.random(in: 2...5)
            let particle = Particle(
                position: center,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                opacity: 1.0,
                scale: Double.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                color: [AppColors.primary.gold, AppColors.primary.teal].randomElement()!
            )
            particles.append(particle)
        }
    }

    private func updateParticles() {
        particles = particles.compactMap { particle in
            var updated = particle
            updated.position.x += particle.velocity.dx
            updated.position.y += particle.velocity.dy
            updated.opacity -= 0.02
            updated.rotation += 5

            return updated.opacity > 0 ? updated : nil
        }
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.6),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: geometry.size.width * phase - geometry.size.width * 0.15)
                        .blendMode(.overlay)
                    }
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                if isActive {
                    animateShimmer()
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    phase = 0
                    animateShimmer()
                } else {
                    phase = 0
                }
            }
    }

    private func animateShimmer() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            phase = 1.2
        }
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Confetti Celebration

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var opacity: Double
    var rotation: Double
    var color: Color
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    let show: Bool

    var body: some View {
        Canvas { context, size in
            for piece in pieces {
                var contextCopy = context
                contextCopy.opacity = piece.opacity
                contextCopy.translateBy(x: piece.position.x, y: piece.position.y)
                contextCopy.rotate(by: .degrees(piece.rotation))

                let rect = CGRect(
                    x: -5,
                    y: -5,
                    width: 10,
                    height: 10
                )

                contextCopy.fill(
                    Path(roundedRect: rect, cornerRadius: 2),
                    with: .color(piece.color)
                )
            }
        }
        .onChange(of: show) { oldValue, newValue in
            if newValue {
                generateConfetti()
            }
        }
        .accessibilityHidden(true)
    }

    private func generateConfetti() {
        pieces.removeAll()

        let screenWidth = UIScreen.main.bounds.width
        let startY: CGFloat = 0

        // Create 50 confetti pieces
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                position: CGPoint(x: screenWidth / 2, y: startY),
                velocity: CGVector(
                    dx: Double.random(in: -5...5),
                    dy: Double.random(in: 3...8)
                ),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                color: [
                    AppColors.primary.gold,
                    AppColors.primary.teal,
                    AppColors.primary.green,
                    .red,
                    .blue,
                    .purple,
                    .pink,
                    .orange
                ].randomElement()!
            )
            pieces.append(piece)
        }

        updateConfetti()
    }

    private func updateConfetti() {
        withAnimation(.linear(duration: 3.0)) {
            pieces = pieces.map { piece in
                var updated = piece
                updated.position.x += piece.velocity.dx * 30
                updated.position.y += piece.velocity.dy * 30
                updated.opacity = 0
                updated.rotation += 360
                return updated
            }
        }

        // Clean up after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            pieces.removeAll()
        }
    }
}

// MARK: - Preview

#Preview("Star Particles") {
    ZStack {
        Color.black.ignoresSafeArea()

        ParticleEmitterView(
            isEmitting: true,
            center: CGPoint(x: 140, y: 140)
        )
        .frame(width: 280, height: 280)
    }
}

#Preview("Shimmer Effect") {
    ZStack {
        Color.black.ignoresSafeArea()

        Image(systemName: "house.fill")
            .font(.system(size: 64))
            .foregroundColor(AppColors.primary.gold)
            .shimmer(isActive: true)
    }
}

#Preview("Confetti") {
    ZStack {
        Color.black.ignoresSafeArea()

        ConfettiView(show: true)
            .ignoresSafeArea()
    }
}
