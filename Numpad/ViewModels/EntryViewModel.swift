//
//  EntryViewModel.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
class EntryViewModel: ObservableObject {
    private let modelContext: ModelContext
    private let repository: QuantityRepository
    @Published var lastError: Error?
    @Published var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.repository = QuantityRepository(modelContext: modelContext)
    }

    func addEntry(value: Double, to quantityType: QuantityType, timestamp: Date = Date(), notes: String = "") {
        let entry = NumpadEntry(
            value: value,
            timestamp: timestamp,
            notes: notes,
            quantityType: quantityType
        )
        modelContext.insert(entry)

        // Update last used timestamp
        quantityType.lastUsedAt = Date()

        saveContext()
    }

    func updateEntry(_ entry: NumpadEntry, value: Double, notes: String) {
        entry.value = value
        entry.notes = notes
        saveContext()
    }

    func deleteEntry(_ entry: NumpadEntry) {
        modelContext.delete(entry)
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
            // Clear any previous errors on success
            lastError = nil
            errorMessage = nil

            // Reload widget timelines to reflect changes
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            lastError = error
            errorMessage = "Failed to save data. Please try again."
            print("❌ SwiftData save failed: \(error.localizedDescription)")
        }
    }

    func fetchEntries(for quantityType: QuantityType) -> [NumpadEntry] {
        // Use repository for efficient database-level query with sorting
        return repository.fetchEntries(for: quantityType)
    }
}