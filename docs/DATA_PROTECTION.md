# Data Protection Strategy

## Overview

This document explains how Numpad protects user data during app updates and prevents data loss.

## The Problem: Data Loss on Storage Location Changes

SwiftData (and Core Data) stores its database files in specific locations. When you change the storage configuration (e.g., switching from app container to App Group container), SwiftData creates a **new** empty database at the new location, leaving the old data behind.

### What Causes Data Loss

1. **Changing storage location**: Moving from app container to App Group
2. **Changing database name**: Renaming the ModelConfiguration
3. **Schema changes without migration**: Adding/removing required fields

## Our Protection Strategy

### 1. Automatic Migration (`DataMigration.swift`)

Before creating the ModelContainer, we check if migration is needed:

```swift
// In NumpadApp.swift
DataMigration.migrateIfNeeded()
```

This utility:
- Detects if data exists in the old location
- Checks if the new location is empty
- Copies all database files to the new location
- Logs the migration process for debugging

**Files copied:**
- `default.store` - Main database file
- `default.store-shm` - Shared memory file (SQLite)
- `default.store-wal` - Write-ahead log (SQLite)

### 2. Version Tracking (`AppVersion.swift`)

We track app versions to detect updates:

```swift
if AppVersion.wasJustUpdated {
    print("Updated from \(AppVersion.previousVersion ?? "unknown")")
}
```

This helps us:
- Know when migrations might be needed
- Debug data loss issues
- Log update events

### 3. Graceful Degradation (In-Memory Fallback)

If storage fails completely, we fall back to in-memory storage:

```swift
// Try CloudKit → Local Storage → In-Memory
// App stays functional, even if data doesn't persist
```

This prevents crashes while allowing users to recover.

### 4. Consistent App Group Usage

All parts of the app use the same storage location:
- **Main App**: `group.com.bennywijatno.numpad.app`
- **Widget Extension**: `group.com.bennywijatno.numpad.app`
- **App Intents (Siri)**: `group.com.bennywijatno.numpad.app`

This ensures:
- Data is shared across all components
- No conflicting databases
- Widgets and Shortcuts see real-time data

## Storage Locations

### Before App Groups (OLD)
```
~/Library/Application Support/[App Bundle ID]/default.store
```

### After App Groups (NEW)
```
~/Library/Group Containers/group.com.bennywijatno.numpad.app/default.store
```

## What Happened in Your Case

**Most likely cause**: When we added App Groups to the main app's ModelContainer, it created a new database in the App Group location, leaving your test data in the old location.

**Solution**: The migration code now handles this automatically on the next update.

## Testing Migration

To test that migration works:

1. **Simulate old data**:
   ```bash
   # Install version WITHOUT App Group
   # Create test data
   ```

2. **Update to new version**:
   ```bash
   # Install version WITH App Group
   # App should migrate data automatically
   ```

3. **Check logs**:
   Look for these console messages:
   - `🔍 Migration check: Old DB exists: true, New DB exists: false`
   - `🚀 Starting database migration...`
   - `✅ Migrated: default.store`
   - `✅ Database migration completed successfully`

## Future-Proofing

### DO NOT Change These Without Migration:
- ❌ ModelConfiguration `groupContainer` identifier
- ❌ Schema model names (`Entry`, `QuantityType`)
- ❌ Required fields without defaults
- ❌ Database file name

### Safe to Change:
- ✅ Add optional fields with defaults
- ✅ Rename variables (computed properties)
- ✅ Add new models to schema
- ✅ Change UI/Views

### When Making Schema Changes:

1. **Add fields with defaults**:
   ```swift
   var newField: String = ""  // ✅ Has default
   ```

2. **Make new fields optional**:
   ```swift
   var newField: String?  // ✅ Optional
   ```

3. **Don't remove required fields immediately**:
   ```swift
   // ❌ Bad: Remove field
   // ✅ Good: Deprecate, then remove in next version
   ```

4. **Use SwiftData VersionedSchema for major changes**:
   ```swift
   enum SchemaV1: VersionedSchema {
       static var models: [any PersistentModel.Type] {
           [QuantityType.self, Entry.self]
       }
   }
   ```

## Backup Strategy

The migration utility can create backups:

```swift
DataMigration.createBackup()
```

This creates `default.store.backup` before any risky operations.

## Recovery Plan

If users report data loss:

1. **Check old location**:
   - Data might still be in the old app container
   - Can be recovered with migration code

2. **Check iCloud**:
   - If CloudKit was enabled, data might be in iCloud
   - Re-syncing might restore data

3. **Export feature** (future):
   - Allow users to export data regularly
   - Makes recovery easier

## Debugging Data Loss

Add these to your testing checklist:

```swift
// In NumpadApp init():
print("🔍 Database location: \(getDatabaseURL())")
print("🔍 Files in database directory:")
try? FileManager.default.contentsOfDirectory(at: dir)
    .forEach { print("  - \(file.lastPathComponent)") }
```

## Console Logs to Watch For

### Good Signs ✅
- `✅ No migration needed`
- `✅ Database migration completed successfully`
- `🚀 Numpad started: version X.Y.Z (build)`

### Warning Signs ⚠️
- `⚠️ CloudKit unavailable, using local storage`
- `⚠️ Local storage failed, using in-memory storage`
- `🔍 Migration check: Old DB exists: true, New DB exists: false`

### Critical Issues ❌
- `❌ Migration failed: [error]`
- `❌ Critical: Could not create ModelContainer`
- `❌ Widget: Failed to create ModelContainer`

## Recommendations

1. **Always test updates** on a test device first
2. **Never change storage location** without migration code
3. **Use version tracking** to know when migrations happen
4. **Log everything** during development
5. **Test with real data** before releasing updates

## Related Files

- `Numpad/NumpadApp.swift` - App entry point with migration trigger
- `Numpad/Utils/DataMigration.swift` - Migration logic
- `Numpad/Utils/AppVersion.swift` - Version tracking
- `Numpad/Models/*.swift` - Data models (schema)

## Questions?

If you see data loss:
1. Check Console logs for migration messages
2. Check old database location exists
3. Check new database location for files
4. Verify App Group identifier matches everywhere
5. Test migration code with debug breakpoints
