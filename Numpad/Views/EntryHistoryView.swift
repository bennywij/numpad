//
//  EntryHistoryView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

struct EntryHistoryView: View {
    let quantityType: QuantityType
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: EntryViewModel
    @State private var entries: [NumpadEntry] = []
    @State private var editingEntry: NumpadEntry?
    @State private var showingEditSheet = false

    init(quantityType: QuantityType, modelContext: ModelContext) {
        self.quantityType = quantityType
        self._viewModel = StateObject(wrappedValue: EntryViewModel(modelContext: modelContext))
    }

    var body: some View {
        List {
            ForEach(entries) { entry in
                EntryRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingEntry = entry
                        showingEditSheet = true
                    }
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            if let entry = editingEntry {
                EditEntryView(entry: entry, modelContext: modelContext)
            }
        }
        .onAppear {
            loadEntries()
        }
    }

    private func loadEntries() {
        entries = viewModel.fetchEntries(for: quantityType)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteEntry(entries[index])
        }
        loadEntries()
    }
}

struct EntryRow: View {
    let entry: NumpadEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.formattedValue)
                    .font(.headline)

                Text(entry.timestamp, style: .date) + Text(" at ") + Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: NumpadEntry
    @State private var value: Double
    @State private var notes: String

    @StateObject private var viewModel: EntryViewModel

    init(entry: NumpadEntry, modelContext: ModelContext) {
        self.entry = entry
        self._value = State(initialValue: entry.value)
        self._notes = State(initialValue: entry.notes)
        self._viewModel = StateObject(wrappedValue: EntryViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let quantityType = entry.quantityType {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: quantityType.icon)
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: quantityType.colorHex))

                            Text(quantityType.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(entry.timestamp, style: .date) + Text(" at ") + Text(entry.timestamp, style: .time)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)

                        // Value input
                        ValueInputView(
                            valueFormat: quantityType.valueFormat,
                            value: $value
                        )
                        .padding(.horizontal)

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
                    }

                    Spacer()
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateEntry(entry, value: value, notes: notes)
                        dismiss()
                    }
                    .disabled(value == 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}