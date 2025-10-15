//
//  AggregationType.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation

enum AggregationType: String, Codable, CaseIterable, Identifiable {
    case sum
    case average
    case median
    case min
    case max
    case count

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sum:
            return "Sum"
        case .average:
            return "Average"
        case .median:
            return "Median"
        case .min:
            return "Minimum"
        case .max:
            return "Maximum"
        case .count:
            return "Count"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .sum:
            return "Sum"
        case .average:
            return "Avg"
        case .median:
            return "Median"
        case .min:
            return "Min"
        case .max:
            return "Max"
        case .count:
            return "Count"
        }
    }

    /// Calculate aggregated value from an array of values
    func aggregate(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        switch self {
        case .sum:
            return values.reduce(0, +)
        case .average:
            return values.reduce(0, +) / Double(values.count)
        case .median:
            let sorted = values.sorted()
            let count = sorted.count
            if count % 2 == 0 {
                return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
            } else {
                return sorted[count / 2]
            }
        case .min:
            return values.min() ?? 0
        case .max:
            return values.max() ?? 0
        case .count:
            return Double(values.count)
        }
    }
}
