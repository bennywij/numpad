//
//  QuantityType.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

@Model
final class QuantityType {
    var id: UUID
    var name: String
    var valueFormat: ValueFormat
    var icon: String  // SF Symbol name
    var colorHex: String
    var lastUsedAt: Date
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Entry.quantityType)
    var entries: [Entry]?

    init(
        id: UUID = UUID(),
        name: String,
        valueFormat: ValueFormat,
        icon: String = "number",
        colorHex: String = "#007AFF",
        lastUsedAt: Date = Date(),
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.valueFormat = valueFormat
        self.icon = icon
        self.colorHex = colorHex
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
