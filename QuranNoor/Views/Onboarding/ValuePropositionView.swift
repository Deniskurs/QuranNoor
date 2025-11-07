//
//  ValuePropositionView.swift
//  QuranNoor
//
//  Interactive value proposition with feature demos
//  Replaces static FeaturesOverviewView with engaging, tappable demos
//

import SwiftUI

struct ValuePropositionView: View {
    // MARK: - Properties
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ObservedObject private var accessibilityHelper = AccessibilityHelper.shared

    let coordinator: OnboardingCoordinator

    @State private var selectedDemo: DemoType = .quran
    @State private var accessibilityAnnouncement = ""

    enum DemoType: String, CaseIterable, Identifiable {
        case quran = "Quran"
        case prayer = "Prayer"
        case qibla = "Qibla"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .quran: return "book.closed.fill"
            case .prayer: return "clock.fill"
            case .qibla: return "location.north.circle.fill"
            }
        }

        var title: String {
            switch self {
            case .quran: return "Beautiful Quran Reader"
            case .prayer: return "Never Miss a Prayer"
            case .qibla: return "Find Qibla Anywhere"
            }
        }

        var subtitle: String {
            switch self {
            case .quran: return "Read, listen, and understand with translations and audio"
            case .prayer: return "Accurate prayer times with smart notifications"
            case .qibla: return "Precise direction to Makkah using your device"
            }
        }

        func color(for theme: ThemeMode) -> Color {
            switch self {
            case .quran: return theme.accentSecondary
            case .prayer: return theme.accentPrimary
            case .qibla: return theme.accentInteractive
            }
        }
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(selectedDemo.color(for: themeManager.currentTheme).opacity(accessibilityHelper.opacity(0.15)))
                            .frame(width: 80, height: 80)

                        Image(systemName: selectedDemo.icon)
                            .font(.system(size: 40))
                            .foregroundColor(selectedDemo.color(for: themeManager.currentTheme))
                            .symbolEffect(.bounce, value: selectedDemo)
                    }
                    .accessibilityHidden(true)  // Decorative

                    // Title
                    ThemedText(selectedDemo.title, style: .title)
                        .foregroundColor(themeManager.currentTheme.accentPrimary)
                        .multilineTextAlignment(.center)
                        .id(selectedDemo)
                        .transition(AccessibleTransition.slideAndFade)
                        .accessibilityAddTraits(.isHeader)

                    // Subtitle
                    ThemedText.body(selectedDemo.subtitle)
                        .multilineTextAlignment(.center)
                        .reducedTransparency(opacity: 0.8)
                        .padding(.horizontal, 32)
                        .id("\(selectedDemo)_subtitle")
                        .transition(AccessibleTransition.slideAndFade)
                }
                .padding(.top, 20)
                .accessibilityElement(children: .combine)
                .accessibleElement(
                    label: "\(selectedDemo.title). \(selectedDemo.subtitle)",
                    traits: .isHeader
                )

                // MARK: - Tab Picker
                Picker("Feature", selection: $selectedDemo) {
                    ForEach(DemoType.allCases) { demo in
                        Text(demo.rawValue)
                            .tag(demo)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .conditionalAnimation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDemo)
                .accessibleElement(
                    label: "Choose feature to preview",
                    hint: "Swipe right or left to switch between Quran reader, Prayer times, and Qibla compass demos",
                    traits: .isButton
                )
                .onChange(of: selectedDemo) { oldValue, newValue in
                    if accessibilityHelper.isVoiceOverRunning {
                        HapticManager.shared.trigger(.selection)
                        // Announce the new selection
                        accessibilityAnnouncement = "Showing \(newValue.title) demo. \(newValue.subtitle)"
                    } else {
                        HapticManager.shared.trigger(.selection)
                    }
                }

                // MARK: - Demo Area
                ZStack {
                    if selectedDemo == .quran {
                        QuranReaderDemo()
                            .transition(AccessibleTransition.slideAndFade)
                    } else if selectedDemo == .prayer {
                        PrayerTimesDemo()
                            .transition(AccessibleTransition.slideAndFade)
                    } else {
                        QiblaCompassDemo()
                            .transition(AccessibleTransition.slideAndFade)
                    }
                }
                .frame(height: selectedDemo == .qibla ? 700 : selectedDemo == .prayer ? 600 : 500)
                .padding(.horizontal, 16)
                .id(selectedDemo)
                .accessibilityElement(children: .contain)
                .accessibleElement(
                    label: "\(selectedDemo.title) interactive demo",
                    hint: "Explore this feature preview by swiping and tapping elements within",
                    traits: .allowsDirectInteraction
                )

                // MARK: - Feature Highlights
                VStack(spacing: 16) {
                    featureHighlight(
                        icon: "checkmark.seal.fill",
                        text: "100% Free - No ads, no subscriptions",
                        color: themeManager.currentTheme.accentPrimary
                    )

                    featureHighlight(
                        icon: "icloud.fill",
                        text: "Works offline - Download surahs for offline access",
                        color: themeManager.currentTheme.accentSecondary
                    )

                    featureHighlight(
                        icon: "moon.stars.fill",
                        text: "Beautiful themes - Light, dark, night, and sepia modes",
                        color: themeManager.currentTheme.accentInteractive
                    )
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .accessibilityElement(children: .combine)
                .accessibleElement(
                    label: "App benefits: 100% Free with no ads, Works offline, Beautiful themes available",
                    traits: .isStaticText
                )

                // MARK: - Call to Action
                VStack(spacing: 12) {
                    Text("Explore these features in the next steps")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(themeManager.currentTheme.accentPrimary)
                        Text("Swipe or tap Continue")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.accentPrimary)
                    }
                }
                .padding(.bottom, 20)
                .accessibilityElement(children: .combine)
                .accessibleElement(
                    label: "Swipe or tap Continue to proceed to the next onboarding step",
                    hint: "Double tap or swipe right to continue",
                    traits: .isStaticText
                )
            }
        }
        .accessibilityPageAnnouncement("App Features. Step 2 of 5. \(selectedDemo.title). \(selectedDemo.subtitle)")
        .accessibilityAnnounce(accessibilityAnnouncement)
    }

    // MARK: - Feature Highlight
    @ViewBuilder
    private func featureHighlight(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
                .accessibilityHidden(true)  // Icon is decorative, text conveys meaning

            ThemedText.body(text)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(AccessibilityHelper.shared.opacity(0.1)))
        )
    }
}

// MARK: - Preview
#Preview {
    ValuePropositionView(coordinator: OnboardingCoordinator())
        .environmentObject(ThemeManager())
}
