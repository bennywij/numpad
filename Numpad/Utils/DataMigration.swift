//
//  DataMigration.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import Foundation
import SwiftData

/// Handles migration of SwiftData database between different storage locations
/// to prevent data loss during app updates
struct DataMigration {

    /// Check if migration is needed from old location (app container) to new location (App Group)
    static func needsMigration() -> Bool {
        let oldLocation = getOldDatabaseURL()
        let newLocation = getNewDatabaseURL()

        // Migration needed if old database exists and new one doesn't
        let oldExists = FileManager.default.fileExists(atPath: oldLocation.path)
        let newExists = FileManager.default.fileExists(atPath: newLocation.path)

        print("🔍 Migration check: Old DB exists: \(oldExists), New DB exists: \(newExists)")

        return oldExists && !newExists
    }

    /// Migrate data from old location to new location
    static func migrateIfNeeded() {
        guard needsMigration() else {
            print("✅ No migration needed")
            return
        }

        print("🚀 Starting database migration...")

        do {
            let oldURL = getOldDatabaseURL()
            let newURL = getNewDatabaseURL()

            // Ensure the new directory exists
            let newDirectory = newURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: newDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            // Copy all SwiftData related files
            let oldDirectory = oldURL.deletingLastPathComponent()
            let fileManager = FileManager.default

            // Get all files in the old directory that are related to the database
            let files = try fileManager.contentsOfDirectory(
                at: oldDirectory,
                includingPropertiesForKeys: nil,
                options: []
            )

            for file in files {
                // Copy database files (default.store and related files)
                if file.lastPathComponent.hasPrefix("default.store") {
                    let destinationURL = newDirectory.appendingPathComponent(file.lastPathComponent)

                    // Copy the file if it doesn't exist at destination
                    if !fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.copyItem(at: file, to: destinationURL)
                        print("✅ Migrated: \(file.lastPathComponent)")
                    }
                }
            }

            print("✅ Database migration completed successfully")

        } catch {
            print("❌ Migration failed: \(error)")
            // Don't crash - let the app continue with empty database
            // User data is still in the old location and can be recovered
        }
    }

    /// Get the old database location (app container)
    private static func getOldDatabaseURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        return appSupport.appendingPathComponent("default.store")
    }

    /// Get the new database location (App Group container)
    private static func getNewDatabaseURL() -> URL {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.bennywijatno.numpad.app"
        ) else {
            fatalError("App Group container not available")
        }

        return groupURL.appendingPathComponent("default.store")
    }

    /// Create a backup of the current database (for safety)
    static func createBackup() {
        do {
            let newURL = getNewDatabaseURL()

            if FileManager.default.fileExists(atPath: newURL.path) {
                let backupURL = newURL.deletingLastPathComponent()
                    .appendingPathComponent("default.store.backup")

                // Remove old backup if exists
                if FileManager.default.fileExists(atPath: backupURL.path) {
                    try FileManager.default.removeItem(at: backupURL)
                }

                try FileManager.default.copyItem(at: newURL, to: backupURL)
                print("✅ Backup created at: \(backupURL.path)")
            }
        } catch {
            print("⚠️ Backup failed (non-critical): \(error)")
        }
    }
}
