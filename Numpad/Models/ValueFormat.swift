//
//  ValueFormat.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation

enum ValueFormat: String, Codable, CaseIterable, Identifiable {
    case integer
    case decimal
    case duration  // Stored as minutes, displayed as HH:MM or MM

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .integer:
            return "Integer"
        case .decimal:
            return "Decimal"
        case .duration:
            return "Duration (HH:MM)"
        }
    }

    /// Format a raw double value for display
    func format(_ value: Double) -> String {
        switch self {
        case .integer:
            return String(format: "%.0f", value)
        case .decimal:
            return String(format: "%.2f", value)
        case .duration:
            return formatDuration(minutes: value)
        }
    }

    private func formatDuration(minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60

        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        } else {
            return String(format: "%d min", mins)
        }
    }

    /// Parse a string input to a double value
    func parse(_ input: String) -> Double? {
        switch self {
        case .integer:
            return Double(input.trimmingCharacters(in: .whitespaces))
        case .decimal:
            return Double(input.trimmingCharacters(in: .whitespaces))
        case .duration:
            return parseDuration(input)
        }
    }

    private func parseDuration(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Handle HH:MM format
        if trimmed.contains(":") {
            let components = trimmed.split(separator: ":")
            guard components.count == 2,
                  let hours = Int(components[0]),
                  let minutes = Int(components[1]) else {
                return nil
            }
            return Double(hours * 60 + minutes)
        }

        // Handle plain number as minutes
        if let minutes = Double(trimmed) {
            return minutes
        }

        return nil
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .integer:
            return .numberPad
        case .decimal:
            return .decimalPad
        case .duration:
            return .numberPad
        }
    }
}
