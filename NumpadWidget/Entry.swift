//
//  Entry.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

@Model
final class NumpadEntry {
    var id: UUID = UUID()
    var value: Double = 0

    // Timestamp used for date-based queries in analytics
    var timestamp: Date = Date()
    var notes: String = ""
    var quantityType: QuantityType?

    init(
        id: UUID = UUID(),
        value: Double,
        timestamp: Date = Date(),
        notes: String = "",
        quantityType: QuantityType? = nil
    ) {
        self.id = id
        self.value = value
        self.timestamp = timestamp
        self.notes = notes
        self.quantityType = quantityType
    }

    var formattedValue: String {
        quantityType?.valueFormat.format(value) ?? String(value)
    }
}
