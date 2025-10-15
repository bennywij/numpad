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

### Infrastructure
- [x] CloudKit entitlements with automatic fallback
- [x] Remote notifications for CloudKit push
- [x] Git repository initialized
- [x] README with setup instructions

---

## 🚧 Next Steps (Priority Order)

### 1. Edit Quantity Types
- [ ] Add edit button/navigation from main screen or long-press
- [ ] Allow editing: name, icon, color, format type
- [ ] **Hide from main screen** toggle (add `isHidden: Bool` to model)
- [ ] Filter hidden quantities from main screen but keep in database
- [ ] Show hidden quantities in a separate section or settings

### 2. Advanced Aggregations
Currently only SUM is supported. Need to add:
- [ ] Add `aggregationType` enum to `QuantityType`:
  - Sum (default, current behavior)
  - Average
  - Median
  - Min
  - Max
  - Count
- [ ] Update `AnalyticsViewModel.calculateTotal()` to respect aggregation type
- [ ] Update `AnalyticsViewModel.calculateGroupedTotals()` to respect aggregation type
- [ ] Update UI to show aggregation type in analytics (e.g., "Avg: 120", "Max: 500")
- [ ] Add picker in edit quantity type to select aggregation

### 3. UI Polish
- [ ] Empty state improvements
- [ ] Loading states for CloudKit sync
- [ ] Error handling and user feedback
- [ ] Confirmation dialogs for destructive actions
- [ ] Accessibility improvements (VoiceOver, Dynamic Type)

### 4. Widget Support
- [ ] Create widget extension
- [ ] Quick-add widget for most recent quantity
- [ ] Summary widget showing totals

### 5. Export/Backup
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
- **Next**: Edit quantity types, hiding, aggregations

---

## Notes

- Keep input frictionless - that's the core value prop
- Analytics should be insightful without being overwhelming
- Default to sensible behaviors (sum, recent sort, etc.)
- Make advanced features optional and discoverable
