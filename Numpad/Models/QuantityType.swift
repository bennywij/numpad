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
    var id: UUID = UUID()
    var name: String = ""
    var valueFormatRawValue: String = ValueFormat.integer.rawValue
    var aggregationTypeRawValue: String = AggregationType.sum.rawValue
    var icon: String = "number"  // SF Symbol name
    var colorHex: String = "#007AFF"
    var lastUsedAt: Date = Date()
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var isHidden: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Entry.quantityType)
    var entries: [Entry]?

    var valueFormat: ValueFormat {
        get { ValueFormat(rawValue: valueFormatRawValue) ?? .integer }
        set { valueFormatRawValue = newValue.rawValue }
    }

    var aggregationType: AggregationType {
        get { AggregationType(rawValue: aggregationTypeRawValue) ?? .sum }
        set { aggregationTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        valueFormat: ValueFormat,
        aggregationType: AggregationType = .sum,
        icon: String = "number",
        colorHex: String = "#007AFF",
        lastUsedAt: Date = Date(),
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.valueFormatRawValue = valueFormat.rawValue
        self.aggregationTypeRawValue = aggregationType.rawValue
        self.icon = icon
        self.colorHex = colorHex
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.isHidden = isHidden
    }
}
