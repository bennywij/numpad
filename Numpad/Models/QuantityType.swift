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
    var aggregationPeriodRawValue: String = AggregationPeriod.allTime.rawValue
    var icon: String = "number"  // SF Symbol name
    var colorHex: String = "#007AFF"

    // Frequently queried fields (predicates will use these efficiently)
    var lastUsedAt: Date = Date()
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var isHidden: Bool = false

    // Compound input configuration (optional)
    var isCompound: Bool = false
    var compoundConfigJSON: String = ""

    @Relationship(deleteRule: .cascade, inverse: \NumpadEntry.quantityType)
    var entries: [NumpadEntry]?

    var valueFormat: ValueFormat {
        get { ValueFormat(rawValue: valueFormatRawValue) ?? .integer }
        set { valueFormatRawValue = newValue.rawValue }
    }

    var aggregationType: AggregationType {
        get { AggregationType(rawValue: aggregationTypeRawValue) ?? .sum }
        set { aggregationTypeRawValue = newValue.rawValue }
    }

    var aggregationPeriod: AggregationPeriod {
        get { AggregationPeriod(rawValue: aggregationPeriodRawValue) ?? .allTime }
        set { aggregationPeriodRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        valueFormat: ValueFormat,
        aggregationType: AggregationType = .sum,
        aggregationPeriod: AggregationPeriod = .allTime,
        icon: String = "number",
        colorHex: String = "#007AFF",
        lastUsedAt: Date = Date(),
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        isHidden: Bool = false,
        isCompound: Bool = false,
        compoundConfigJSON: String = ""
    ) {
        self.id = id
        self.name = name
        self.valueFormatRawValue = valueFormat.rawValue
        self.aggregationTypeRawValue = aggregationType.rawValue
        self.aggregationPeriodRawValue = aggregationPeriod.rawValue
        self.icon = icon
        self.colorHex = colorHex
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.isCompound = isCompound
        self.compoundConfigJSON = compoundConfigJSON
    }

    // MARK: - Total Calculation

    /// **DEPRECATED**: Use QuantityRepository.calculateTotal(for:) instead for efficient database-level filtering.
    ///
    /// This method loads ALL entries into memory before filtering - very inefficient for large datasets.
    /// The repository pattern uses database predicates for optimal performance.
    @available(*, deprecated, message: "Use QuantityRepository.calculateTotal(for:) for efficient database-level queries")
    func calculateTotal(from allEntries: [NumpadEntry]) -> Double {
        // Filter entries for this quantity type
        let myEntries = allEntries.filter { $0.quantityType?.id == self.id }

        // Filter by aggregation period
        let filteredEntries = aggregationPeriod.filterEntries(myEntries)

        // Extract values and aggregate
        let values = filteredEntries.map { $0.value }
        return aggregationType.aggregate(values)
    }

    // MARK: - Compound Configuration Helpers

    var compoundConfig: CompoundConfig? {
        get {
            guard isCompound, !compoundConfigJSON.isEmpty else { return nil }
            guard let data = compoundConfigJSON.data(using: .utf8) else {
                print("⚠️ Failed to convert compoundConfigJSON to Data for quantity: \(name)")
                return nil
            }
            do {
                return try JSONDecoder().decode(CompoundConfig.self, from: data)
            } catch {
                print("⚠️ Failed to decode CompoundConfig for quantity: \(name), error: \(error)")
                return nil
            }
        }
        set {
            guard let config = newValue else {
                compoundConfigJSON = ""
                return
            }
            do {
                let data = try JSONEncoder().encode(config)
                guard let json = String(data: data, encoding: .utf8) else {
                    print("⚠️ Failed to convert encoded data to string for quantity: \(name)")
                    compoundConfigJSON = ""
                    return
                }
                compoundConfigJSON = json
            } catch {
                print("⚠️ Failed to encode CompoundConfig for quantity: \(name), error: \(error)")
                compoundConfigJSON = ""
            }
        }
    }
}

// MARK: - Hashable Conformance

extension QuantityType: Hashable {
    static func == (lhs: QuantityType, rhs: QuantityType) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Compound Configuration

struct CompoundConfig: Codable, Equatable {
    var input1Label: String
    var input1Format: ValueFormat
    var input2Label: String
    var input2Format: ValueFormat
    var operation: CompoundOperation

    enum CompoundOperation: String, Codable, CaseIterable {
        case divide = "/"
        case multiply = "*"
        case add = "+"
        case subtract = "-"
        case timeDifference = "time_diff"  // Special: Date - Date → minutes

        var displayName: String {
            switch self {
            case .divide: return "Divide (A ÷ B)"
            case .multiply: return "Multiply (A × B)"
            case .add: return "Add (A + B)"
            case .subtract: return "Subtract (A - B)"
            case .timeDifference: return "Time Range (End - Start)"
            }
        }

        func calculate(_ value1: Double, _ value2: Double) -> Double? {
            switch self {
            case .divide:
                guard value2 != 0 else { return nil }  // Return nil instead of 0
                return value1 / value2
            case .multiply:
                return value1 * value2
            case .add:
                return value1 + value2
            case .subtract:
                return value1 - value2
            case .timeDifference:
                // Assumes values are timestamps in seconds since reference
                // No abs() - maintains sign to indicate direction
                return (value2 - value1) / 60  // Convert to minutes
            }
        }
    }
}
