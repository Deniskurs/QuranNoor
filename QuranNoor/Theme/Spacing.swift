//
//  Spacing.swift
//  QuranNoor
//
//  Enhanced spacing system for premium visual hierarchy
//  Uses 4pt base unit system for consistent rhythm
//

import SwiftUI

// MARK: - Spacing
/// Unified spacing constants for consistent visual hierarchy throughout the app
/// Uses 4pt base unit system (4, 8, 12, 16, 24, 32, 40, 48)
struct Spacing {
    // MARK: - Core Spacing Scale

    /// 4pt - Minimal spacing for tightly related elements
    static let xxxs: CGFloat = 4

    /// 8pt - Very small spacing within components
    static let xxs: CGFloat = 8

    /// 12pt - Small spacing for related elements
    static let xs: CGFloat = 12

    /// 16pt - Standard spacing for component internals
    static let sm: CGFloat = 16

    /// 24pt - Primary component spacing (enhanced for breathing room)
    static let md: CGFloat = 24

    /// 32pt - Large section spacing for clear separation (enhanced)
    static let lg: CGFloat = 32

    /// 40pt - Extra large spacing for major visual breaks
    static let xl: CGFloat = 40

    /// 48pt - Maximum spacing for prominent separations
    static let xxl: CGFloat = 48

    // MARK: - Component-Specific

    /// Standard padding inside cards: 24pt (enhanced from 20pt)
    static let cardPadding: CGFloat = 24

    /// Spacing between cards in grids: 20pt
    static let cardSpacing: CGFloat = 20

    /// Spacing between major sections in scrollviews: 32pt (enhanced from 20pt)
    static let sectionSpacing: CGFloat = 32

    /// Screen edge padding (horizontal): 24pt (enhanced from 20pt)
    static let screenHorizontal: CGFloat = 24

    /// Screen edge padding (vertical): 20pt
    static let screenVertical: CGFloat = 20

    /// Standard screen padding (all edges): 20pt
    static let screenPadding: CGFloat = 20

    // MARK: - Grid Spacing

    /// Grid item spacing for 2-column layouts: 16pt (enhanced from 12pt)
    static let gridSpacing: CGFloat = 16

    /// Tight grid spacing for dense information: 12pt
    static let gridTight: CGFloat = 12

    // MARK: - Interactive Elements

    /// Minimum tap target size (Apple HIG): 44pt
    static let tapTarget: CGFloat = 44

    /// Button padding horizontal: 20pt
    static let buttonHorizontal: CGFloat = 20

    /// Button padding vertical: 12pt
    static let buttonVertical: CGFloat = 12
}

// MARK: - Border Radius
/// Corner radius values for consistent rounded corners
struct BorderRadius {
    /// 4pt - Minimal rounding
    static let sm: CGFloat = 4

    /// 8pt - Small rounding
    static let md: CGFloat = 8

    /// 12pt - Standard rounding
    static let lg: CGFloat = 12

    /// 16pt - Card rounding (enhanced for sleekness, reduced from 20pt)
    static let xl: CGFloat = 16

    /// 20pt - Large rounding for special elements
    static let xxl: CGFloat = 20

    /// Full pill shape
    static let full: CGFloat = 9999
}

// MARK: - Corner Radius (Deprecated — use BorderRadius instead)
/// Maps old CornerRadius values to BorderRadius for backward compatibility.
/// All new code should use BorderRadius directly.
enum CornerRadius {
    static let sm: CGFloat = BorderRadius.md    // was 8  -> 8
    static let md: CGFloat = BorderRadius.lg    // was 12 -> 12
    static let lg: CGFloat = BorderRadius.xl    // was 16 -> 16
    static let xl: CGFloat = BorderRadius.xxl   // was 20 -> 20
    static let xxl: CGFloat = 24                // kept as-is, no BorderRadius equivalent
}

// MARK: - App Animation Presets
/// Standardized animation curves for consistent motion throughout the app.
/// Use these instead of ad-hoc .easeInOut / .easeOut / .spring calls.
struct AppAnimation {
    /// Fast micro-interactions: toggles, button presses, highlights (0.25s)
    static let fast = Animation.spring(response: 0.25, dampingFraction: 0.85)

    /// Standard transitions: card reveals, filter changes, state updates (0.4s)
    static let standard = Animation.spring(response: 0.4, dampingFraction: 0.85)

    /// Slow, expressive transitions: onboarding, hero sections, celebrations (0.55s)
    static let expressive = Animation.spring(response: 0.55, dampingFraction: 0.8)

    /// Bouncy feedback: checkboxes, completion taps, interactive confirmations
    static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Gentle ease for content transitions where spring feels too physical
    static let gentle = Animation.easeInOut(duration: 0.3)

    /// Linear for progress bars and continuous value changes
    static let linear = Animation.linear(duration: 0.25)

    /// Continuous pulse for breathing/glow effects (default 1.5s cycle)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    /// Pulse with custom duration for urgency-based effects
    static func pulse(duration: Double) -> Animation {
        .easeInOut(duration: duration).repeatForever(autoreverses: true)
    }

    /// Smooth physics for compass/gyroscope rotation tracking
    static let compass = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Smooth Shape Helper
/// Creates a RoundedRectangle with .continuous style (Apple's superellipse).
/// Use this everywhere instead of plain RoundedRectangle(cornerRadius:).
func SmoothRoundedRectangle(cornerRadius: CGFloat) -> RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
}
