//
//  AddEntryView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let quantityType: QuantityType

    @State private var value: Double = 0
    @State private var notes: String = ""
    @State private var timestamp: Date = Date()
    @State private var isCustomTimestamp: Bool = false
    @StateObject private var viewModel: EntryViewModel

    init(quantityType: QuantityType, modelContext: ModelContext) {
        self.quantityType = quantityType
        self._viewModel = StateObject(wrappedValue: EntryViewModel(modelContext: modelContext))
    }

    private var isValidInput: Bool {
        // For compound inputs, allow any value (including 0 and negative)
        if quantityType.isCompound {
            // Just check for reasonable bounds
            return value > -1_000_000 && value < 1_000_000
        }

        // Validate based on value format for non-compound
        switch quantityType.valueFormat {
        case .integer, .decimal:
            // Must be positive and reasonable
            return value > 0 && value < 1_000_000
        case .duration:
            // Duration: 0 to 24 hours (1440 minutes, not 86400 seconds)
            return value >= 0 && value < 1440
        }
    }

    private var validationMessage: String? {
        // Skip "enter a value" check for compound inputs
        if !quantityType.isCompound && value == 0 {
            return "Enter a value"
        }
        if !isValidInput {
            if quantityType.isCompound {
                return "Value must be between -1,000,000 and 1,000,000"
            }
            switch quantityType.valueFormat {
            case .duration:
                return "Duration must be less than 24 hours"
            default:
                return "Value must be between 0 and 1,000,000"
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: quantityType.icon)
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: quantityType.colorHex))

                        Text(quantityType.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top)

                    // Value input
                    ValueInputView(
                        valueFormat: quantityType.valueFormat,
                        value: $value,
                        compoundConfig: quantityType.compoundConfig
                    )
                    .padding(.horizontal)

                    // Timestamp
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isCustomTimestamp) {
                            Text("Backdate entry")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if isCustomTimestamp {
                            DatePicker(
                                "Date & Time",
                                selection: $timestamp,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                        } else {
                            Text("Now: \(timestamp, style: .date) at \(timestamp, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: isCustomTimestamp) { _, newValue in
                        if !newValue {
                            timestamp = Date()
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                            .onChange(of: notes) { _, newValue in
                                // Limit notes to 500 characters
                                if newValue.count > 500 {
                                    notes = String(newValue.prefix(500))
                                }
                            }
                    }
                    .padding(.horizontal)

                    // Validation message
                    if let message = validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Satisfying haptic feedback on save
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        viewModel.addEntry(
                            value: value,
                            to: quantityType,
                            timestamp: timestamp,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(!isValidInput)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
