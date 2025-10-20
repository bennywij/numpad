//
//  AggregationPeriod.swift
//  Numpad
//
//  Created on 2025-10-19.
//

import Foundation
import SwiftData

enum AggregationPeriod: String, Codable, CaseIterable, Identifiable {
    case allTime
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .allTime:
            return "All Time"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .allTime:
            return "All"
        case .daily:
            return "Day"
        case .weekly:
            return "Week"
        case .monthly:
            return "Month"
        }
    }

    /// Filter entries based on this aggregation period
    /// Returns entries that fall within the current period
    func filterEntries(_ entries: [NumpadEntry], relativeTo date: Date = Date()) -> [NumpadEntry] {
        let calendar = Calendar.current

        switch self {
        case .allTime:
            return entries

        case .daily:
            // Return entries from the start of today to now
            let startOfDay = calendar.startOfDay(for: date)
            return entries.filter { entry in
                entry.timestamp >= startOfDay
            }

        case .weekly:
            // Return entries from the start of this week to now
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return entries
            }
            return entries.filter { entry in
                entry.timestamp >= startOfWeek
            }

        case .monthly:
            // Return entries from the start of this month to now
            guard let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start else {
                return entries
            }
            return entries.filter { entry in
                entry.timestamp >= startOfMonth
            }
        }
    }

    /// Returns a SwiftData predicate for database-level filtering
    /// Returns nil for .allTime (no filtering needed)
    /// - Parameter date: The reference date for period calculation (defaults to now)
    /// - Returns: A Predicate for filtering NumpadEntry, or nil if no filtering needed
    func predicate(relativeTo date: Date = Date()) -> Predicate<NumpadEntry>? {
        let calendar = Calendar.current

        switch self {
        case .allTime:
            return nil // No filtering needed

        case .daily:
            let startOfDay = calendar.startOfDay(for: date)
            return #Predicate<NumpadEntry> { entry in
                entry.timestamp >= startOfDay
            }

        case .weekly:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return nil
            }
            return #Predicate<NumpadEntry> { entry in
                entry.timestamp >= startOfWeek
            }

        case .monthly:
            guard let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start else {
                return nil
            }
            return #Predicate<NumpadEntry> { entry in
                entry.timestamp >= startOfMonth
            }
        }
    }
}
