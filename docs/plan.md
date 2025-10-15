# Numpad - Development Plan

## Project Overview
A frictionless iOS app for tracking quantities with timestamps, featuring CloudKit sync, SwiftUI, and SwiftData.

## Core Concept
Simulate a spreadsheet where users track different "columns" of values with automatic timestamps, then view totals and trends grouped by time periods (day/week/month/year).

---

## ✅ Completed Features

### Data Layer
- [x] SwiftData models with CloudKit sync (with fallback to local storage)
- [x] `QuantityType`: Name, format, icon, color, sort order, last used
- [x] `Entry`: Value, timestamp, notes, relationship to QuantityType
- [x] `ValueFormat`: Integer, Decimal, Duration (HH:MM)
- [x] Repository pattern with ViewModels (EntryViewModel, QuantityTypeViewModel, AnalyticsViewModel)

### UI - Main Screen
- [x] Quick-add section for most recently used quantity
- [x] Quantity type cards showing total
- [x] Tap card → Analytics view
- [x] Tap + button → Add entry modal
- [x] Edit mode with swipe-to-delete
- [x] Drag-and-drop reordering
- [x] Seed default quantity types on first launch

### UI - Add/Edit Entry
- [x] Adaptive input based on format type:
  - Integer: Number pad with quick-add buttons (+1, +5, +10, +50)
  - Decimal: Decimal pad with quick-add buttons
  - Duration: HH:MM sliders with quick-add (+15m, +30m, +1h)
- [x] Optional notes field
- [x] Optional backdating with toggle + datetime picker
- [x] Fixed race condition bug (blank sheet on first tap)

### UI - Analytics
- [x] Total display with quantity icon/color
- [x] Segmented control to group by: Day, Week, Month, Year, All Time
- [x] Grouped totals showing count and sum per period
- [x] Navigation to History from Analytics toolbar

### UI - History
- [x] List of all entries for a quantity type
- [x] Tap entry to edit (value, notes)
- [x] Swipe to delete entries
- [x] Shows formatted value, date/time, notes

### App Intents & Siri
- [x] `LogEntryIntent` for voice logging
- [x] Automatically logs to most recently used quantity
- [x] Siri shortcuts: "Log to Numpad"

### Edit & Manage Quantity Types
- [x] Long-press context menu to edit quantity types
- [x] EditQuantityTypeView with full editing capability
- [x] Edit name, icon, color, format, aggregation type
- [x] **Hide from main screen** toggle (isHidden field)
- [x] Filter hidden quantities from main screen
- [x] Show hidden quantities in dedicated "Hidden" section
- [x] Removed non-functional Edit button from toolbar

### Advanced Aggregations
- [x] `AggregationType` enum with 6 types: Sum, Average, Median, Min, Max, Count
- [x] Added `aggregationType` field to `QuantityType` model
- [x] Updated `AnalyticsViewModel.calculateTotal()` to respect aggregation type
- [x] Updated `AnalyticsViewModel.calculateGroupedTotals()` to respect aggregation type
- [x] UI shows aggregation type in analytics (e.g., "Avg", "Max", "Count")
- [x] Picker in add/edit quantity type to select aggregation
- [x] All aggregations work correctly across all grouping periods

### UI Improvements
- [x] Larger plus buttons on quantity type cards (better tap targets)
- [x] New app icon with numpad grid design

### Infrastructure
- [x] CloudKit entitlements with automatic fallback
- [x] Remote notifications for CloudKit push
- [x] Git repository initialized
- [x] README with setup instructions
- [x] Scripts directory with app icon generator

---

## 🚧 Next Steps (Priority Order)

### 1. Enhanced Siri App Intents
Improve the existing Siri integration to support specific quantity types and flexible duration inputs:
- [ ] Create `AddToQuantityIntent` that accepts quantity type and value parameters
- [ ] Support natural language like "add 90 minutes to reading time on Numpad"
- [ ] Parse flexible duration inputs: "90 minutes", "1.5 hours", "1 hour 30 minutes"
- [ ] Allow specifying any quantity type by name (not just most recent)
- [ ] Handle integer, decimal, and duration value types
- [ ] Provide confirmation feedback with the logged value
- [ ] Add App Shortcuts for common quantity types
- [ ] Test with various Siri phrasings

### 2. Home Screen Widget
Create widgets to display quantity totals at a glance:
- [ ] Create widget extension target
- [ ] Small widget: Single quantity type with icon, name, and total
- [ ] Medium widget: 2-3 quantity types in a grid
- [ ] Large widget: 4-6 quantity types with mini charts
- [ ] Widget configuration to select which quantity types to show
- [ ] Tap widget to open app to that quantity's analytics
- [ ] Auto-refresh widget data using Timeline
- [ ] Support for multiple widget instances with different configs
- [ ] Widget color matches quantity type color scheme

### 3. UI Polish
- [ ] Empty state improvements
- [ ] Loading states for CloudKit sync
- [ ] Error handling and user feedback
- [ ] Confirmation dialogs for destructive actions
- [ ] Accessibility improvements (VoiceOver, Dynamic Type)

### 4. Export/Backup
- [ ] CSV export of all data
- [ ] Per-quantity type export
- [ ] Share sheet integration

---

## Technical Debt & Known Issues

### Fixed Issues
- ✅ CloudKit requires all attributes to have default values (fixed)
- ✅ CloudKit doesn't support unique constraints (removed @Attribute(.unique))
- ✅ Enum storage in SwiftData (using raw value string)
- ✅ Sheet presentation race condition (using .sheet(item:))

### Monitoring
- Console logs from CloudKit/CoreData are verbose but harmless
- App works in simulator with local storage, CloudKit on device with iCloud

---

## Architecture Notes

### Navigation Flow
```
Main Screen
  ├─ Tap Card → Analytics
  │   └─ Tap History → Entry History
  │       └─ Tap Entry → Edit Entry
  └─ Tap + Button → Add Entry
```

### Data Flow
```
Models (SwiftData)
  ↓
ViewModels (@MainActor, ObservableObject)
  ↓
Views (SwiftUI)
```

### CloudKit Strategy
- Try CloudKit first with `.automatic` database
- Catch errors and fall back to local storage (`.none`)
- Works seamlessly in simulator and on device

---

## Future Ideas (Backlog)

- [ ] Charts/graphs for trends
- [ ] Reminders to log entries
- [ ] Custom time period groupings
- [ ] Tags for entries
- [ ] Multi-device sync testing
- [ ] iPad optimization
- [ ] Mac Catalyst version
- [ ] Shortcuts app integration beyond Siri
- [ ] Health app integration for relevant metrics
- [ ] Apple Watch complication

---

## Development Timeline

- **Day 1**: Initial scaffold, models, basic UI, CloudKit setup, navigation fixes, backdating feature
- **Day 2**: Edit quantity types, hiding, advanced aggregations (Sum/Avg/Median/Min/Max/Count), app icon
- **Next**: Enhanced Siri intents with flexible parsing, home screen widgets

---

## Notes

- Keep input frictionless - that's the core value prop
- Analytics should be insightful without being overwhelming
- Default to sensible behaviors (sum, recent sort, etc.)
- Make advanced features optional and discoverable
