//
//  QuantityTypeEntity.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import AppIntents
import SwiftData

struct QuantityTypeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Quantity Type")
    static var defaultQuery = QuantityTypeQuery()

    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    var name: String
    var valueFormatDisplay: String
}

struct QuantityTypeQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [QuantityTypeEntity] {
        let context = try getModelContext()
        let descriptor = FetchDescriptor<QuantityType>()
        guard let allQuantities = try? context.fetch(descriptor) else {
            return []
        }

        return allQuantities
            .filter { identifiers.contains($0.id.uuidString) }
            .map { QuantityTypeEntity(
                id: $0.id.uuidString,
                name: $0.name,
                valueFormatDisplay: $0.valueFormat.displayName
            )}
    }

    @MainActor
    func suggestedEntities() async throws -> [QuantityTypeEntity] {
        let context = try getModelContext()
        let descriptor = FetchDescriptor<QuantityType>(
            predicate: #Predicate { !$0.isHidden },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        guard let quantities = try? context.fetch(descriptor) else {
            return []
        }

        return quantities.map { QuantityTypeEntity(
            id: $0.id.uuidString,
            name: $0.name,
            valueFormatDisplay: $0.valueFormat.displayName
        )}
    }

    @MainActor
    private func getModelContext() throws -> ModelContext {
        let schema = Schema([
            QuantityType.self,
            NumpadEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            throw NSError(domain: "Numpad", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access data store"])
        }

        return ModelContext(modelContainer)
    }
}
