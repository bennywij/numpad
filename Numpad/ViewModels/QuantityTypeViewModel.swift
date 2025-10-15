//
//  QuantityTypeViewModel.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

@MainActor
class QuantityTypeViewModel: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createQuantityType(
        name: String,
        valueFormat: ValueFormat,
        aggregationType: AggregationType = .sum,
        icon: String = "number",
        colorHex: String = "#007AFF"
    ) -> QuantityType {
        let quantityType = QuantityType(
            name: name,
            valueFormat: valueFormat,
            aggregationType: aggregationType,
            icon: icon,
            colorHex: colorHex,
            sortOrder: fetchAllQuantityTypes().count
        )
        modelContext.insert(quantityType)
        try? modelContext.save()
        return quantityType
    }

    func updateQuantityType(
        _ quantityType: QuantityType,
        name: String,
        valueFormat: ValueFormat,
        icon: String,
        colorHex: String
    ) {
        quantityType.name = name
        quantityType.valueFormat = valueFormat
        quantityType.icon = icon
        quantityType.colorHex = colorHex
        try? modelContext.save()
    }

    func deleteQuantityType(_ quantityType: QuantityType) {
        modelContext.delete(quantityType)
        try? modelContext.save()
    }

    func fetchAllQuantityTypes() -> [QuantityType] {
        let descriptor = FetchDescriptor<QuantityType>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchMostRecentlyUsed() -> QuantityType? {
        let descriptor = FetchDescriptor<QuantityType>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    func seedDefaultQuantityTypes() {
        let existing = fetchAllQuantityTypes()
        guard existing.isEmpty else { return }

        let defaults: [(String, ValueFormat, String)] = [
            ("Minutes Read", .duration, "book.fill"),
            ("Steps", .integer, "figure.walk"),
            ("Calories", .integer, "flame.fill"),
            ("Water (oz)", .decimal, "drop.fill")
        ]

        for (index, (name, format, icon)) in defaults.enumerated() {
            let qt = QuantityType(
                name: name,
                valueFormat: format,
                icon: icon,
                sortOrder: index
            )
            modelContext.insert(qt)
        }

        try? modelContext.save()
    }
}
