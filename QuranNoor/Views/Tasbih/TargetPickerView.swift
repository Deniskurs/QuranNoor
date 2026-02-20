//
//  TargetPickerView.swift
//  QuranNoor
//
//  Target count selector for tasbih counter
//

import SwiftUI

struct TargetPickerView: View {
    @Binding var selectedTarget: Int
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var customTarget: String = ""
    @State private var showingCustomInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Common targets
                    commonTargetsSection

                    // Custom target
                    customTargetSection
                }
                .padding()
            }
            .navigationTitle("Select Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Common Targets

    private var commonTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Targets")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TasbihTarget.allCases.filter { $0 != .custom }) { target in
                    TargetCard(
                        target: target,
                        isSelected: selectedTarget == target.rawValue
                    )
                    .onTapGesture {
                        selectedTarget = target.rawValue
                        onSelect()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Custom Target

    private var customTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Target")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if showingCustomInput {
                HStack(spacing: 12) {
                    TextField("Enter count", text: $customTarget)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )

                    Button {
                        if let count = Int(customTarget), count > 0 {
                            selectedTarget = count
                            onSelect()
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .disabled(Int(customTarget) == nil || Int(customTarget) ?? 0 <= 0)
                }
            } else {
                Button {
                    showingCustomInput = true
                } label: {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Count")
                                .font(.headline)

                            Text("Enter your own target")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TargetCard: View {
    let target: TasbihTarget
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(target.displayName)
                .font(.title)
                .fontWeight(.bold)

            Text(target.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .green : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    TargetPickerView(selectedTarget: .constant(33)) {
        #if DEBUG
        print("Selected")
        #endif
    }
}
