//
//  AddToQuantityIntent.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import AppIntents
import SwiftData

struct AddToQuantityIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Quantity"
    static var description = IntentDescription("Log a value to a specific quantity type in Numpad")

    @Parameter(
        title: "Quantity Type",
        description: "The name of the quantity to track (e.g., Steps, Water, Reading Time)",
        requestValueDialog: "Which quantity would you like to log to?"
    )
    var quantityTypeName: String

    @Parameter(
        title: "Value",
        description: "Amount to log. For durations: '90 minutes', '1.5 hours', '2:30'. For numbers: '100', '5.5'",
        requestValueDialog: "What value would you like to log?"
    )
    var valueInput: String

    @Parameter(
        title: "Notes",
        description: "Optional notes about this entry",
        default: ""
    )
    var notes: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$valueInput) to \(\.$quantityTypeName)") {
            \.$notes
        }
    }

    static var openAppWhenRun: Bool { false }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get model context
        let schema = Schema([
            QuantityType.self,
            Entry.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            return .result(dialog: "Failed to access data store")
        }

        let modelContext = ModelContext(modelContainer)

        // Find quantity type by name (case-insensitive)
        let descriptor = FetchDescriptor<QuantityType>()
        guard let allQuantities = try? modelContext.fetch(descriptor) else {
            return .result(dialog: "Failed to fetch quantity types")
        }

        guard let quantityType = allQuantities.first(where: {
            $0.name.lowercased() == quantityTypeName.lowercased()
        }) else {
            return .result(dialog: "Could not find quantity type named '\(quantityTypeName)'")
        }

        // Parse the value based on the quantity type's format
        let parsedValue = parseValue(valueInput, format: quantityType.valueFormat)

        guard let value = parsedValue else {
            return .result(dialog: "Could not understand value '\(valueInput)'")
        }

        // Create entry
        let entry = Entry(
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

    /// Parse flexible value input based on format type
    private func parseValue(_ input: String, format: ValueFormat) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()

        switch format {
        case .integer:
            return parseInteger(trimmed)
        case .decimal:
            return parseDecimal(trimmed)
        case .duration:
            return parseDuration(trimmed)
        }
    }

    private func parseInteger(_ input: String) -> Double? {
        // Remove common separators
        let cleaned = input.replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private func parseDecimal(_ input: String) -> Double? {
        // Remove common separators
        let cleaned = input.replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private func parseDuration(_ input: String) -> Double? {
        // Parse various duration formats and return total minutes

        // Pattern 1: "X hours Y minutes" or "X hour Y minutes"
        let hoursMinutesPattern = #"(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)(?:\s+(?:and\s+)?(\d+(?:\.\d+)?)\s*(?:minutes?|mins?|m))?"#
        if let result = parseWithRegex(input, pattern: hoursMinutesPattern) {
            let hours = result.0
            let minutes = result.1 ?? 0
            return hours * 60 + minutes
        }

        // Pattern 2: "X minutes Y seconds" or just "X minutes"
        let minutesPattern = #"(\d+(?:\.\d+)?)\s*(?:minutes?|mins?|m)"#
        if let result = parseWithRegex(input, pattern: minutesPattern) {
            return result.0
        }

        // Pattern 3: "X seconds"
        let secondsPattern = #"(\d+(?:\.\d+)?)\s*(?:seconds?|secs?|s)"#
        if let result = parseWithRegex(input, pattern: secondsPattern) {
            return result.0 / 60  // Convert to minutes
        }

        // Pattern 4: HH:MM format
        if input.contains(":") {
            let components = input.split(separator: ":")
            if components.count == 2,
               let hours = Double(components[0]),
               let minutes = Double(components[1]) {
                return hours * 60 + minutes
            }
        }

        // Pattern 5: Plain number (assume minutes)
        if let minutes = Double(input) {
            return minutes
        }

        return nil
    }

    /// Helper to parse with regex and extract numbers
    private func parseWithRegex(_ input: String, pattern: String) -> (Double, Double?)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = input as NSString
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))

        guard let match = matches.first else {
            return nil
        }

        if match.numberOfRanges >= 2 {
            let firstRange = match.range(at: 1)
            if firstRange.location != NSNotFound {
                let firstValue = nsString.substring(with: firstRange)
                if let first = Double(firstValue) {
                    if match.numberOfRanges >= 3 {
                        let secondRange = match.range(at: 2)
                        if secondRange.location != NSNotFound {
                            let secondValue = nsString.substring(with: secondRange)
                            return (first, Double(secondValue))
                        }
                    }
                    return (first, nil)
                }
            }
        }

        return nil
    }
}
