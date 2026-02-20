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

// MARK: - Corner Radius (Convenience Alias)
/// Standardized corner radius constants for consistent UI rounding.
/// Preferred over ad-hoc magic numbers throughout the codebase.
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
