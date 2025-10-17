//
//  CSVExporter.swift
//  Numpad
//
//  Created on 2025-10-16.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Utility for exporting Numpad data to CSV format
struct CSVExporter {
    /// Generates a CSV string from all entries in the database
    /// - Parameter entries: Array of NumpadEntry objects to export
    /// - Returns: CSV-formatted string, or nil if no entries
    static func exportAllData(entries: [NumpadEntry]) -> String? {
        guard !entries.isEmpty else { return nil }

        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }
        var csv = "Timestamp,Quantity Name,Value,Formatted Value,Notes,Aggregation Type,Icon,Color\n"

        for entry in sortedEntries {
            guard let quantityType = entry.quantityType else { continue }

            let timestamp = formatTimestamp(entry.timestamp)
            let quantityName = escapeCSV(quantityType.name)
            let rawValue = String(entry.value)
            let formattedValue = escapeCSV(quantityType.valueFormat.format(entry.value))
            let notes = escapeCSV(entry.notes)
            let aggregationType = quantityType.aggregationType.displayName
            let icon = quantityType.icon
            let color = quantityType.colorHex

            csv += "\(timestamp),\(quantityName),\(rawValue),\(formattedValue),\(notes),\(aggregationType),\(icon),\(color)\n"
        }

        return csv
    }

    /// Formats a Date as ISO 8601 string for CSV
    private static func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    /// Escapes a string for CSV (handles commas, quotes, newlines)
    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Generates a filename for the CSV export with current date
    static func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "Numpad_Export_\(dateString).csv"
    }

    /// Creates a temporary file with the CSV content
    /// - Parameter csvContent: CSV-formatted string to write
    /// - Returns: URL to the temporary file, or nil if creation failed
    static func createTemporaryFile(csvContent: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(generateFilename())

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

            // Set file attributes to mark it as a CSV for proper iOS handling
            try? (fileURL as NSURL).setResourceValue(UTType.commaSeparatedText, forKey: .contentTypeKey)

            return fileURL
        } catch {
            print("❌ Failed to write CSV file: \(error)")
            return nil
        }
    }
}
