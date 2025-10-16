//
//  AnalyticsViewModel.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

enum GroupingPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }
}

struct GroupedTotal: Identifiable {
    let id = UUID()
    let periodLabel: String
    let total: Double
    let count: Int
    let startDate: Date
}

@MainActor
class AnalyticsViewModel: ObservableObject {
    private var modelContext: ModelContext?

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    /// Set or update the modelContext (needed for @StateObject initialization workaround)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func calculateTotal(for quantityType: QuantityType) -> Double {
        guard let modelContext = modelContext else { return 0 }

        // CRITICAL FIX: Don't rely on relationship loading - fetch entries explicitly
        let quantityTypeID = quantityType.id
        let descriptor = FetchDescriptor<NumpadEntry>(
            predicate: #Predicate<NumpadEntry> { entry in
                entry.quantityType?.id == quantityTypeID
            }
        )

        guard let entries = try? modelContext.fetch(descriptor) else {
            return 0
        }

        let values = entries.map { $0.value }
        return quantityType.aggregationType.aggregate(values)
    }

    func calculateGroupedTotals(
        for quantityType: QuantityType,
        groupedBy period: GroupingPeriod
    ) -> [GroupedTotal] {
        guard let modelContext = modelContext else { return [] }

        // CRITICAL FIX: Fetch entries explicitly instead of relying on relationship
        let quantityTypeID = quantityType.id
        let descriptor = FetchDescriptor<NumpadEntry>(
            predicate: #Predicate<NumpadEntry> { entry in
                entry.quantityType?.id == quantityTypeID
            }
        )

        guard let entries = try? modelContext.fetch(descriptor) else {
            return []
        }

        if period == .all {
            let values = entries.map { $0.value }
            let total = quantityType.aggregationType.aggregate(values)
            return [GroupedTotal(
                periodLabel: "All Time",
                total: total,
                count: entries.count,
                startDate: Date.distantPast
            )]
        }

        let calendar = Calendar.current
        var grouped: [Date: [Double]] = [:]

        for entry in entries {
            let periodStart = startOfPeriod(for: entry.timestamp, period: period, calendar: calendar)
            var values = grouped[periodStart] ?? []
            values.append(entry.value)
            grouped[periodStart] = values
        }

        return grouped.map { (date, values) in
            GroupedTotal(
                periodLabel: formatPeriodLabel(date, period: period),
                total: quantityType.aggregationType.aggregate(values),
                count: values.count,
                startDate: date
            )
        }.sorted { $0.startDate > $1.startDate }
    }

    private func startOfPeriod(for date: Date, period: GroupingPeriod, calendar: Calendar) -> Date {
        switch period {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start ?? date
        case .year:
            return calendar.dateInterval(of: .year, for: date)?.start ?? date
        case .all:
            return Date.distantPast
        }
    }

    private func formatPeriodLabel(_ date: Date, period: GroupingPeriod) -> String {
        let formatter = DateFormatter()

        switch period {
        case .day:
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        case .week:
            formatter.dateFormat = "MMM d"
            let calendar = Calendar.current
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: date) ?? date
            return "\(formatter.string(from: date)) - \(formatter.string(from: endOfWeek))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        case .all:
            return "All Time"
        }
    }
}
