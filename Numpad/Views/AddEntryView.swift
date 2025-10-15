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
                        value: $value
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
                    }
                    .padding(.horizontal)

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
                        viewModel.addEntry(
                            value: value,
                            to: quantityType,
                            timestamp: timestamp,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(value == 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
