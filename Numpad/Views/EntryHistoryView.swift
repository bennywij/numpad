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

    init(quantityType: QuantityType, modelContext: ModelContext) {
        self.quantityType = quantityType
        self._viewModel = StateObject(wrappedValue: EntryViewModel(modelContext: modelContext))
    }

    var body: some View {
        List {
            ForEach(entries) { entry in
                EntryRow(entry: entry)
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
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
        .padding(.vertical, 4)
    }
}