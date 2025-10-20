//
//  SelectQuantityTypesIntent.swift
//  NumpadWidget
//
//  Created on 2025-10-17.
//

import AppIntents
import SwiftData

/// AppIntent for configuring which quantity types to display in the widget
struct SelectQuantityTypesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Quantity Types"
    static let description = IntentDescription("Choose which quantity types to display in your widget.")

    /// Selected quantity types (multi-select)
    @Parameter(title: "Quantity Types")
    var quantityTypes: [QuantityTypeEntity]?

    /// Fallback behavior when no selection is made
    var effectiveQuantityTypes: [String] {
        if let types = quantityTypes, !types.isEmpty {
            return types.map { $0.id }
        }
        // Default: empty array means "use top N by sort order" (current behavior)
        return []
    }
}

/// Entity representing a quantity type for widget configuration
struct QuantityTypeEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Quantity Type")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = QuantityTypeEntityQuery()
}

/// Query to fetch available quantity types for the widget configuration UI
struct QuantityTypeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [QuantityTypeEntity] {
        let allTypes = await fetchAllQuantityTypes()
        return allTypes.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [QuantityTypeEntity] {
        return await fetchAllQuantityTypes()
    }

    func defaultResult() async -> QuantityTypeEntity? {
        let allTypes = await fetchAllQuantityTypes()
        return allTypes.first
    }

    private func fetchAllQuantityTypes() async -> [QuantityTypeEntity] {
        // Access shared ModelContainer
        guard let container = try? ModelContainer(
            for: QuantityType.self, NumpadEntry.self,
            configurations: ModelConfiguration(
                groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
                cloudKitDatabase: .none
            )
        ) else {
            return []
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<QuantityType>(
            predicate: #Predicate { !$0.isHidden },
            sortBy: [SortDescriptor(\.name)]
        )

        guard let quantityTypes = try? context.fetch(descriptor) else {
            return []
        }

        return quantityTypes.map { qt in
            QuantityTypeEntity(
                id: qt.id.uuidString,
                name: qt.name
            )
        }
    }
}
