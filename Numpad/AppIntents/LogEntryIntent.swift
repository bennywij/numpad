//
//  LogEntryIntent.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import AppIntents
import SwiftData

struct LogEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Log to Numpad"
    static var description = IntentDescription("Log a value to your most recently used quantity in Numpad")

    @Parameter(title: "Value")
    var value: Double

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

        // Fetch most recently used quantity type
        let descriptor = FetchDescriptor<QuantityType>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        guard let quantityType = try? modelContext.fetch(descriptor).first else {
            return .result(dialog: "No quantity types found. Please create one in the app first.")
        }

        // Create entry
        let entry = NumpadEntry(
            value: value,
            timestamp: Date(),
            notes: notes,
            quantityType: quantityType
        )
        modelContext.insert(entry)

        // Update last used
        quantityType.lastUsedAt = Date()

        try? modelContext.save()

        let formattedValue = quantityType.valueFormat.format(value)
        return .result(dialog: "Logged \(formattedValue) to \(quantityType.name)")
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$value) to Numpad") {
            \.$notes
        }
    }
}