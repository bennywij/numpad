//
//  NumpadApp.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI
import SwiftData

@main
struct NumpadApp: App {
    var sharedModelContainer: ModelContainer = {
        // CRITICAL: Migrate data from old location SYNCHRONOUSLY before creating container
        // This prevents data loss when switching to App Group storage
        print("🔄 Starting app initialization...")
        let migrationResult = migrateDataIfNeeded()
        print("🔄 Migration completed: \(migrationResult ? "✅ Success" : "⏭️  Skipped")")

        let schema = Schema([
            QuantityType.self,
            NumpadEntry.self,
        ])

        // Try CloudKit first with App Group, fallback to local storage if unavailable
        // App Group enables data sharing with widget extension
        let cloudKitConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
            cloudKitDatabase: .automatic
        )

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.bennywijatno.numpad.app"),
            cloudKitDatabase: .none
        )

        let inMemoryConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            // Try with CloudKit first
            return try ModelContainer(for: schema, configurations: [cloudKitConfig])
        } catch {
            // Fallback to local storage
            print("⚠️ CloudKit unavailable, using local storage: \(error)")
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // Final fallback to in-memory storage (data won't persist, but app won't crash)
                print("⚠️ Local storage failed, using in-memory storage: \(error)")
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    // This should never happen with in-memory storage, but if it does,
                    // crash with a descriptive message
                    fatalError("❌ Critical: Could not create ModelContainer even with in-memory storage: \(error)")
                }
            }
        }
    }()

    init() {
        // Record app launch and version, and log startup info
        AppVersion.recordLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Data Migration Utilities

/// Migrate data from old location (app container) to new location (App Group)
/// Returns true if migration was performed, false if skipped
@discardableResult
private func migrateDataIfNeeded() -> Bool {
    let oldURL = getOldDatabaseURL()
    let newURL = getNewDatabaseURL()

    // Check if migration is needed
    let oldExists = FileManager.default.fileExists(atPath: oldURL.path)
    let newExists = FileManager.default.fileExists(atPath: newURL.path)

    print("🔍 Migration check:")
    print("   Old DB: \(oldURL.path) - Exists: \(oldExists)")
    print("   New DB: \(newURL.path) - Exists: \(newExists)")

    guard oldExists && !newExists else {
        if newExists {
            print("✅ Using existing App Group database")
        } else if !oldExists {
            print("✅ Fresh install - no migration needed")
        }
        return false
    }

    print("🚀 Starting database migration...")

    do {
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

        // Get all files in the old directory
        let files = try fileManager.contentsOfDirectory(
            at: oldDirectory,
            includingPropertiesForKeys: nil,
            options: []
        )

        var migratedFiles = 0
        // Copy database files (default.store and ALL related files like -wal, -shm)
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasPrefix("default.store") || filename.hasSuffix(".db") {
                let destinationURL = newDirectory.appendingPathComponent(filename)

                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: file, to: destinationURL)
                    print("✅ Migrated: \(filename) (\(try fileManager.attributesOfItem(atPath: file.path)[.size] as? Int ?? 0) bytes)")
                    migratedFiles += 1
                } else {
                    print("⚠️  Skipped (exists): \(filename)")
                }
            }
        }

        print("✅ Database migration completed: \(migratedFiles) file(s) migrated")
        return true
    } catch {
        print("❌ Migration failed: \(error.localizedDescription)")
        print("❌ Error details: \(error)")
        // Don't crash - data is still in old location and can be recovered
        return false
    }
}

/// Get the old database location (app container)
private func getOldDatabaseURL() -> URL {
    let appSupport = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    ).first!

    return appSupport.appendingPathComponent("default.store")
}

/// Get the new database location (App Group container)
private func getNewDatabaseURL() -> URL {
    guard let groupURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.bennywijatno.numpad.app"
    ) else {
        fatalError("App Group container not available")
    }

    return groupURL.appendingPathComponent("default.store")
}

// MARK: - App Version Tracking

/// Tracks app version to detect updates and trigger appropriate migrations
struct AppVersion {
    private static let versionKey = "AppVersion.currentVersion"
    private static let previousVersionKey = "AppVersion.previousVersion"

    /// Current app version from Info.plist
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Build number from Info.plist
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Check if this is a fresh install (no previous version)
    static var isFreshInstall: Bool {
        UserDefaults.standard.string(forKey: versionKey) == nil
    }

    /// Check if the app was just updated
    static var wasJustUpdated: Bool {
        let stored = UserDefaults.standard.string(forKey: versionKey)
        return stored != nil && stored != current
    }

    /// Get the previous version (before update)
    static var previousVersion: String? {
        UserDefaults.standard.string(forKey: previousVersionKey)
    }

    /// Record that the app has launched with current version
    static func recordLaunch() {
        let stored = UserDefaults.standard.string(forKey: versionKey)

        if stored != current {
            // Store previous version before updating
            if let stored = stored {
                UserDefaults.standard.set(stored, forKey: previousVersionKey)
                print("📱 App updated from \(stored) to \(current)")
            } else {
                print("📱 Fresh install: \(current)")
            }

            UserDefaults.standard.set(current, forKey: versionKey)
        }
    }

    /// Full version string (version + build)
    static var fullVersion: String {
        "\(current) (\(build))"
    }
}