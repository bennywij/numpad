//
//  EditQuantityTypeView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct EditQuantityTypeView: View {
    @Environment(\.dismiss) private var dismiss

    let quantityType: QuantityType
    let modelContext: ModelContext

    @State private var name: String
    @State private var selectedFormat: ValueFormat
    @State private var selectedAggregationType: AggregationType
    @State private var selectedAggregationPeriod: AggregationPeriod
    @State private var selectedIcon: String
    @State private var selectedColorHex: String
    @State private var isHidden: Bool

    init(quantityType: QuantityType, modelContext: ModelContext) {
        self.quantityType = quantityType
        self.modelContext = modelContext

        // Initialize state from the existing quantity type
        _name = State(initialValue: quantityType.name)
        _selectedFormat = State(initialValue: quantityType.valueFormat)
        _selectedAggregationType = State(initialValue: quantityType.aggregationType)
        _selectedAggregationPeriod = State(initialValue: quantityType.aggregationPeriod)
        _selectedIcon = State(initialValue: quantityType.icon)
        _selectedColorHex = State(initialValue: quantityType.colorHex)
        _isHidden = State(initialValue: quantityType.isHidden)
    }

    let iconOptions = [
        "number", "book.fill", "figure.walk", "flame.fill",
        "drop.fill", "heart.fill", "moon.stars.fill", "cup.and.saucer.fill",
        "dumbbell.fill", "bicycle", "leaf.fill", "dollarsign.circle.fill"
    ]

    let colorOptions = [
        "#007AFF", "#FF3B30", "#34C759", "#FF9500",
        "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)

                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ValueFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }

                    Picker("Aggregation", selection: $selectedAggregationType) {
                        ForEach(AggregationType.allCases) { aggregation in
                            Text(aggregation.displayName).tag(aggregation)
                        }
                    }

                    Picker("Time Period", selection: $selectedAggregationPeriod) {
                        ForEach(AggregationPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Label {
                                Text(icon)
                            } icon: {
                                Image(systemName: icon)
                            }
                            .tag(icon)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                            ForEach(colorOptions, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColorHex = colorHex
                                    }
                            }
                        }
                    }
                }

                Section("Visibility") {
                    Toggle("Hide from main screen", isOn: $isHidden)
                }

                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundColor(Color(hex: selectedColorHex))

                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Preview" : name)
                                .font(.headline)

                            Text(selectedFormat.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Quantity Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        quantityType.name = name
        quantityType.valueFormat = selectedFormat
        quantityType.aggregationType = selectedAggregationType
        quantityType.aggregationPeriod = selectedAggregationPeriod
        quantityType.icon = selectedIcon
        quantityType.colorHex = selectedColorHex
        quantityType.isHidden = isHidden

        try? modelContext.save()
    }
}
