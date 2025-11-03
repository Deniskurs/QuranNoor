//
//  View+Transitions.swift
//  QuranNoor
//
//  Created on 2025-11-03
//  Custom view transitions for elegant UI flows
//

import SwiftUI

extension View {

    // MARK: - Scale Fade Transition

    /// Apply a scale and fade transition (onboarding → home screen)
    /// - Parameters:
    ///   - isPresented: Whether the view should be presented
    ///   - scaleFrom: Starting scale value (default 1.05 for appearing)
    ///   - scaleTo: Ending scale value (default 0.95 for disappearing)
    ///   - duration: Animation duration in seconds (default 0.6)
    /// - Returns: Modified view with transition
    func scaleFadeTransition(
        isPresented: Bool,
        scaleFrom: CGFloat = 1.05,
        scaleTo: CGFloat = 0.95,
        duration: Double = 0.6
    ) -> some View {
        self
            .scaleEffect(isPresented ? 1.0 : scaleFrom)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.easeInOut(duration: duration), value: isPresented)
    }

    // MARK: - Onboarding Transition

    /// Specialized transition for onboarding completion
    /// Onboarding: scales down and fades out
    /// Home: scales up and fades in
    /// - Parameter isOnboardingComplete: Whether onboarding is finished
    /// - Returns: Modified view with transition
    func onboardingCompleteTransition(isOnboardingComplete: Bool) -> some View {
        Group {
            if isOnboardingComplete {
                // Home screen: scale up from 1.05 and fade in
                self
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.05).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
            } else {
                // Onboarding: scale down to 0.95 and fade out
                self
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.05).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
            }
        }
    }

    // MARK: - Page Turn Transition

    /// Smooth page turn effect for onboarding pages
    /// - Parameters:
    ///   - isActive: Whether this page is active
    ///   - offset: Horizontal offset for slide effect (optional)
    /// - Returns: Modified view with transition
    func pageTransition(isActive: Bool, offset: CGFloat = 0) -> some View {
        self
            .offset(x: offset)
            .scaleEffect(isActive ? 1.0 : 0.95)
            .opacity(isActive ? 1.0 : 0.0)
            .animation(.smooth(duration: 0.3), value: isActive)
    }

    // MARK: - Spring Transition

    /// Bouncy spring transition for delightful interactions
    /// - Parameter isPresented: Whether the view is presented
    /// - Returns: Modified view with spring transition
    func springTransition(isPresented: Bool) -> some View {
        self
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }

    // MARK: - Slide Fade Transition

    /// Slide and fade transition (for modals, sheets)
    /// - Parameters:
    ///   - isPresented: Whether the view is presented
    ///   - edge: Edge to slide from (default .bottom)
    /// - Returns: Modified view with transition
    func slideFadeTransition(isPresented: Bool, from edge: Edge = .bottom) -> some View {
        self
            .transition(.move(edge: edge).combined(with: .opacity))
    }
}

// MARK: - Custom Transition Modifiers

/// Custom view modifier for onboarding dismissal
struct OnboardingDismissalModifier: ViewModifier {

    let isOnboardingComplete: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isOnboardingComplete ? 0.95 : 1.0)
            .opacity(isOnboardingComplete ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.6), value: isOnboardingComplete)
    }
}

/// Custom view modifier for home screen appearance
struct HomeAppearanceModifier: ViewModifier {

    let isOnboardingComplete: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isOnboardingComplete ? 1.0 : 1.05)
            .opacity(isOnboardingComplete ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.6), value: isOnboardingComplete)
    }
}

extension View {

    /// Apply onboarding dismissal transition
    func onboardingDismissal(isComplete: Bool) -> some View {
        modifier(OnboardingDismissalModifier(isOnboardingComplete: isComplete))
    }

    /// Apply home screen appearance transition
    func homeAppearance(isOnboardingComplete: Bool) -> some View {
        modifier(HomeAppearanceModifier(isOnboardingComplete: isOnboardingComplete))
    }
}

// MARK: - Animation Extensions

extension Animation {

    /// Smooth animation for iOS 26
    static var smooth: Animation {
        .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
    }

    /// Smooth animation with custom duration
    static func smooth(duration: Double) -> Animation {
        .timingCurve(0.4, 0.0, 0.2, 1.0, duration: duration)
    }

    /// Snappy animation for quick interactions
    static var snappy: Animation {
        .timingCurve(0.5, 0.0, 0.0, 1.0, duration: 0.2)
    }

    /// Elegant ease-in-out
    static var elegant: Animation {
        .easeInOut(duration: 0.4)
    }
}
