//
//  QuantityRepository.swift
//  Numpad
//
//  Created on 2025-10-20.
//  Phase 2: Repository Layer for efficient database queries
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
@MainActor
class QuantityRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Calculate total for a quantity type using database-level filtering
    /// - Parameter quantityType: The quantity type to calculate total for
    /// - Returns: Aggregated total based on quantity type's aggregation type and period
    func calculateTotal(for quantityType: QuantityType) -> Double {
        let quantityTypeID = quantityType.id
        let aggregationPeriod = quantityType.aggregationPeriod

        // Build a single predicate combining both conditions
        // This approach works in iOS 17.0+ (doesn't require .evaluate() from 17.4+)
        let descriptor: FetchDescriptor<NumpadEntry>

        // Get the time filter if needed (capture as Date? to use in predicate)
        let periodStartDate: Date? = {
            let calendar = Calendar.current
            let now = Date()

            switch aggregationPeriod {
            case .allTime:
                return nil
            case .daily:
                return calendar.startOfDay(for: now)
            case .weekly:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.start
            case .monthly:
                return calendar.dateInterval(of: .month, for: now)?.start
            }
        }()

        // Build single predicate combining quantity type filter and optional time filter
        if let startDate = periodStartDate {
            descriptor = FetchDescriptor<NumpadEntry>(
                predicate: #Predicate<NumpadEntry> { entry in
                    entry.quantityType?.id == quantityTypeID && entry.timestamp >= startDate
                }
            )
        } else {
            descriptor = FetchDescriptor<NumpadEntry>(
                predicate: #Predicate<NumpadEntry> { entry in
                    entry.quantityType?.id == quantityTypeID
                }
            )
        }

        do {
            let entries = try modelContext.fetch(descriptor)
            let values = entries.map { $0.value }
            return quantityType.aggregationType.aggregate(values)
        } catch {
            #if DEBUG
            print("❌ QuantityRepository.calculateTotal: Failed to fetch entries for \(quantityType.name) - \(error.localizedDescription)")
            #endif
            return 0
        }
    }

    /// Fetch entries for a quantity type with optional limit
    /// - Parameters:
    ///   - quantityType: The quantity type to fetch entries for
    ///   - limit: Maximum number of entries to return (nil = no limit)
    /// - Returns: Array of entries, sorted by timestamp descending (most recent first)
    func fetchEntries(for quantityType: QuantityType, limit: Int? = nil) -> [NumpadEntry] {
        let quantityTypeID = quantityType.id

        var descriptor = FetchDescriptor<NumpadEntry>(
            predicate: #Predicate<NumpadEntry> { $0.quantityType?.id == quantityTypeID },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            print("❌ QuantityRepository.fetchEntries: Failed to fetch entries for \(quantityType.name) - \(error.localizedDescription)")
            #endif
            return []
        }
    }
}
