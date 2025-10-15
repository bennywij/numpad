//
//  AddQuantityTypeView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct AddQuantityTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var selectedFormat: ValueFormat = .integer
    @State private var selectedIcon: String = "number"
    @State private var selectedColorHex: String = "#007AFF"

    @StateObject private var viewModel: QuantityTypeViewModel

    init(modelContext: ModelContext) {
        self._viewModel = StateObject(wrappedValue: QuantityTypeViewModel(modelContext: modelContext))
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
            .navigationTitle("New Quantity Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createQuantityType(
                            name: name,
                            valueFormat: selectedFormat,
                            icon: selectedIcon,
                            colorHex: selectedColorHex
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
