//
//  EntryViewModel.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

@MainActor
class EntryViewModel: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addEntry(value: Double, to quantityType: QuantityType, notes: String = "") {
        let entry = Entry(
            value: value,
            timestamp: Date(),
            notes: notes,
            quantityType: quantityType
        )
        modelContext.insert(entry)

        // Update last used timestamp
        quantityType.lastUsedAt = Date()

        try? modelContext.save()
    }

    func updateEntry(_ entry: Entry, value: Double, notes: String) {
        entry.value = value
        entry.notes = notes
        try? modelContext.save()
    }

    func deleteEntry(_ entry: Entry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    func fetchEntries(for quantityType: QuantityType) -> [Entry] {
        let descriptor = FetchDescriptor<Entry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let allEntries = try? modelContext.fetch(descriptor) else {
            return []
        }

        return allEntries.filter { $0.quantityType?.id == quantityType.id }
    }
}
