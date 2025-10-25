//
//  LogEntryForChosenQuantityIntent.swift
//  Numpad
//
//  Created on 2025-10-25.
//

import AppIntents
import SwiftData

struct LogEntryForChosenQuantityIntent: AppIntent {
    static var title: LocalizedStringResource = "Log to a specific quantity"
    static var description = IntentDescription("Log a value to a quantity you choose in Numpad")

    @Parameter(title: "Value")
    var value: Double

    @Parameter(title: "Quantity")
    var quantityType: QuantityTypeEntity

    @Parameter(title: "Notes", default: "")
    var notes: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get model context using App Group for shared data access
        let schema = Schema([
            QuantityType.self,
            NumpadEntry.self,
        ])

        // Use same App Group as main app to access shared data
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
            cloudKitDatabase: .none  // Use local storage for intents
        )

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return .result(dialog: "Failed to access data store")
        }

        let modelContext = ModelContext(modelContainer)

        // Fetch the chosen QuantityType using quantityType.id
        guard let selectedUUID = UUID(uuidString: quantityType.id) else {
            return .result(dialog: "Invalid quantity type ID.")
        }
        let descriptor = FetchDescriptor<QuantityType>(predicate: #Predicate { $0.id == selectedUUID })

        guard let chosenQuantityType = try? modelContext.fetch(descriptor).first else {
            return .result(dialog: "Could not find the selected quantity type.")
        }

        // Create entry
        let entry = NumpadEntry(
            value: value,
            timestamp: Date(),
            notes: notes,
            quantityType: chosenQuantityType
        )
        modelContext.insert(entry)

        // Update last used
        chosenQuantityType.lastUsedAt = Date()

        try? modelContext.save()

        let formattedValue = chosenQuantityType.valueFormat.format(value)
        return .result(dialog: "Logged \(formattedValue) to \(chosenQuantityType.name)")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$value) to \(\.$quantityType)") {
            \.$notes
        }
    }
}
