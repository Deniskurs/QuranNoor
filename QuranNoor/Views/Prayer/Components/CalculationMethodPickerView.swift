//
//  CalculationMethodPickerView.swift
//  QuranNoor
//
//  Created by Claude Code
//  Extracted from PrayerTimesView for better maintainability
//

import SwiftUI

/// Sheet view for selecting prayer calculation method
struct CalculationMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager: ThemeManager

    @Binding var selectedMethod: CalculationMethod
    let onMethodChanged: (CalculationMethod) async -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CalculationMethod.allCases) { method in
                            Button {
                                Task {
                                    await onMethodChanged(method)
                                    dismiss()
                                    AudioHapticCoordinator.shared.playButtonPress()
                                }
                            } label: {
                                methodRow(method)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calculation Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func methodRow(_ method: CalculationMethod) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(method.rawValue)
                    .font(.body)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)

                if let description = methodDescription(for: method) {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }

            Spacer()

            if method == selectedMethod {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(themeManager.currentTheme.accent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    method == selectedMethod
                        ? themeManager.currentTheme.accent.opacity(0.15)
                        : themeManager.currentTheme.cardColor
                )
        )
    }

    // MARK: - Helper Methods

    private func methodDescription(for method: CalculationMethod) -> String? {
        switch method {
        case .muslimWorldLeague:
            return "Used in Europe, Far East, parts of US"
        case .isna:
            return "Used in North America (US & Canada)"
        case .egyptian:
            return "Egyptian General Authority of Survey"
        case .ummAlQura:
            return "Used in Saudi Arabia"
        case .karachi:
            return "Used in Pakistan, Bangladesh, India, Afghanistan"
        case .dubai:
            return "Used in Dubai and UAE"
        case .moonsightingCommittee:
            return "Moonsighting Committee Worldwide"
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedMethod = CalculationMethod.muslimWorldLeague

    CalculationMethodPickerView(
        selectedMethod: $selectedMethod,
        onMethodChanged: { newMethod in
            #if DEBUG
            print("Method changed to: \(newMethod)")
            #endif
        }
    )
    .environment(ThemeManager())
}
