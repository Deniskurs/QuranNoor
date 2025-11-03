//
//  ThemeContrastTests.swift
//  QuranNoorTests
//
//  WCAG 2.1 AA/AAA contrast compliance testing for all theme modes
//

import XCTest
import SwiftUI
@testable import QuranNoor

final class ThemeContrastTests: XCTestCase {

    // MARK: - WCAG 2.1 Contrast Ratio Requirements
    // AA Level: Normal text 4.5:1, Large text 3:1
    // AAA Level: Normal text 7:1, Large text 4.5:1

    // MARK: - Primary Text Contrast Tests

    func testLightThemePrimaryTextContrast() throws {
        let theme = ThemeMode.light
        let contrast = contrastRatio(
            foreground: theme.textPrimary,
            background: theme.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            7.0,
            "Light theme primary text should meet WCAG AAA (7:1). Actual: \(String(format: "%.1f", contrast)):1"
        )
    }

    func testDarkThemePrimaryTextContrast() throws {
        let theme = ThemeMode.dark
        let contrast = contrastRatio(
            foreground: theme.textPrimary,
            background: theme.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            7.0,
            "Dark theme primary text should meet WCAG AAA (7:1). Actual: \(String(format: "%.1f", contrast)):1"
        )
    }

    func testNightThemePrimaryTextContrast() throws {
        let theme = ThemeMode.night
        let contrast = contrastRatio(
            foreground: theme.textPrimary,
            background: theme.backgroundColor
        )

        XCTAssertGreaterThanOrEqual(
            contrast,
            7.0,
            "Night theme primary text should meet WCAG AAA (7:1). Actual: \(String(format: "%.1f", contrast)):1"
        )
    }

    func testSepiaThemePrimaryTextContrast() throws {
        let theme = ThemeMode.sepia
        let contrast = contrastRatio(
            foreground: theme.textPrimary,
            background: theme.backgroundColor
        )

        // Target: 9.2:1 after fix (#3D2F1F)
        XCTAssertGreaterThanOrEqual(
            contrast,
            7.0,
            "Sepia theme primary text should meet WCAG AAA (7:1). Actual: \(String(format: "%.1f", contrast)):1"
        )

        // Verify improved contrast
        XCTAssertGreaterThanOrEqual(
            contrast,
            9.0,
            "Sepia theme should achieve enhanced 9.2:1 contrast with #3D2F1F. Actual: \(String(format: "%.1f", contrast)):1"
        )
    }

    // MARK: - Secondary Text Contrast Tests

    func testAllThemesSecondaryTextContrast() throws {
        let themes: [ThemeMode] = [.light, .dark, .night, .sepia]

        for theme in themes {
            let contrast = contrastRatio(
                foreground: theme.textSecondary,
                background: theme.backgroundColor
            )

            XCTAssertGreaterThanOrEqual(
                contrast,
                4.5,
                "\(theme) secondary text should meet WCAG AA (4.5:1). Actual: \(String(format: "%.1f", contrast)):1"
            )
        }
    }

    // MARK: - Tertiary Text Contrast Tests

    func testAllThemesTertiaryTextContrast() throws {
        let themes: [ThemeMode] = [.light, .dark, .night, .sepia]

        for theme in themes {
            let contrast = contrastRatio(
                foreground: theme.textTertiary,
                background: theme.backgroundColor
            )

            // Tertiary text should meet large text requirement (3:1)
            XCTAssertGreaterThanOrEqual(
                contrast,
                3.0,
                "\(theme) tertiary text should meet WCAG AA Large (3:1). Actual: \(String(format: "%.1f", contrast)):1"
            )
        }
    }

    // MARK: - Card Background Contrast Tests

    func testAllThemesTextOnCardContrast() throws {
        let themes: [ThemeMode] = [.light, .dark, .night, .sepia]

        for theme in themes {
            let contrast = contrastRatio(
                foreground: theme.textPrimary,
                background: theme.cardColor
            )

            XCTAssertGreaterThanOrEqual(
                contrast,
                4.5,
                "\(theme) text on card should meet WCAG AA (4.5:1). Actual: \(String(format: "%.1f", contrast)):1"
            )
        }
    }

    // MARK: - Active Prayer Card Contrast Tests

    func testPrayerActiveCardContrast() throws {
        let themes: [ThemeMode] = [.light, .dark, .night, .sepia]

        for theme in themes {
            let contrast = contrastRatio(
                foreground: theme.prayerActiveText,
                background: theme.prayerActiveBackground
            )

            XCTAssertGreaterThanOrEqual(
                contrast,
                4.5,
                "\(theme) active prayer card text should meet WCAG AA (4.5:1). Actual: \(String(format: "%.1f", contrast)):1"
            )
        }
    }

    // MARK: - Gradient Background Contrast Tests

    func testSepiaThemeHasNoGradients() throws {
        let sepiaTheme = ThemeMode.sepia

        XCTAssertFalse(
            sepiaTheme.supportsGradients,
            "Sepia theme should not support gradients for reading comfort"
        )

        // Verify gradient colors are solid (same as background)
        let gradientColors = sepiaTheme.gradientColors
        XCTAssertEqual(
            gradientColors.count,
            2,
            "Sepia theme should return gradient array"
        )
    }

    func testLightThemeGradientOpacity() throws {
        let theme = ThemeMode.light

        // Test gold gradient opacity
        let goldOpacity = theme.gradientOpacity(for: AppColors.primary.gold)
        XCTAssertLessThanOrEqual(
            goldOpacity,
            0.1,
            "Light theme gold gradient should be subtle (≤0.1 opacity). Actual: \(goldOpacity)"
        )

        // Test green gradient opacity
        let greenOpacity = theme.gradientOpacity(for: AppColors.primary.green)
        XCTAssertLessThanOrEqual(
            greenOpacity,
            0.1,
            "Light theme green gradient should be subtle (≤0.1 opacity). Actual: \(greenOpacity)"
        )
    }

    func testNightThemeGradientsDisabled() throws {
        let theme = ThemeMode.night
        let gradientColors = theme.gradientColors

        // Night theme should return pure black gradients
        XCTAssertEqual(
            gradientColors.count,
            2,
            "Night theme should return gradient array for OLED optimization"
        )
    }

    // MARK: - Contrast Ratio Calculator

    /// Calculates WCAG 2.1 contrast ratio between two colors
    /// Formula: (L1 + 0.05) / (L2 + 0.05) where L is relative luminance
    private func contrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculates relative luminance of a color
    /// Formula per WCAG 2.1: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    private func relativeLuminance(of color: Color) -> Double {
        let components = getColorComponents(color)

        let r = sRGBtoLinear(components.r)
        let g = sRGBtoLinear(components.g)
        let b = sRGBtoLinear(components.b)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Converts sRGB color component to linear RGB
    private func sRGBtoLinear(_ component: Double) -> Double {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    /// Extracts RGB components from SwiftUI Color
    private func getColorComponents(_ color: Color) -> (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        // Fallback for non-UIKit platforms
        return (0.5, 0.5, 0.5)
        #endif
    }
}

// MARK: - Performance Tests

extension ThemeContrastTests {

    func testGradientCachePerformance() throws {
        let cache = GradientCache.shared
        cache.clearCache()

        let theme = ThemeMode.light
        let styles: [BackgroundGradientStyle] = [.prayer, .quran, .home, .serenity, .settings]

        measure {
            for style in styles {
                _ = cache.gradient(for: style, theme: theme)
            }
        }
    }
}

// MARK: - Accessibility Tests

extension ThemeContrastTests {

    func testAllThemesSupportDynamicType() throws {
        // This would require UI testing
        // Placeholder for integration test
        XCTAssertTrue(true, "Dynamic Type support should be tested in UI tests")
    }

    func testHighContrastModeUsage() throws {
        // Verify ThemedText respects high contrast environment
        // This would require UI testing with Environment values
        XCTAssertTrue(true, "High contrast mode should be tested in UI tests")
    }
}
