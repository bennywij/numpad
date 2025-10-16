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
- [x] New app icon with numpad grid design showing "4" and "2" in correct numpad positions
- [x] Fixed all app icon sizes to match iOS 2025 standards (verified via web search)
- [x] App icon generator script updated to use scale factors correctly
- [x] Icon composer integration (glass effect icon available as alternative)

### Infrastructure
- [x] CloudKit entitlements with automatic fallback
- [x] Remote notifications for CloudKit push
- [x] Git repository initialized
- [x] README with setup instructions
- [x] Scripts directory with app icon generator
- [x] Widget extension with App Groups for data sharing
- [x] Scheme configuration (Numpad as default, widget extension hidden)

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

### 2. Home Screen Widget ✅
Create widgets to display quantity totals at a glance:
- [x] Create widget extension target with proper configuration
- [x] Small widget: Single quantity type with icon, name, and total
- [x] Medium widget: 3 quantity types in a grid
- [x] Large widget: 6 quantity types in a list
- [x] Auto-refresh widget data using Timeline (15 min intervals)
- [x] Widget color matches quantity type color scheme
- [x] SwiftData integration via App Groups for shared data access
- [x] Respects aggregation type (Sum/Avg/Median/Min/Max/Count)
- [x] Fixed iOS deployment target to 17.0 (was incorrectly set to 26.0)
- [x] Created manual Info.plist with NSExtension dictionary (required for widget installation)
- [x] Resolved "Invalid placeholder attributes" error via fresh target creation
- [x] Widget builds and installs successfully on simulator
- [ ] Widget configuration to select which quantity types to show (currently shows top by sort order)
- [ ] Tap widget to open app to that quantity's analytics

### 3. App Store Preparation 🎯
Performance, stability, and distribution readiness:
- [ ] Comprehensive code review for performance optimization
- [ ] Memory leak detection and optimization
- [ ] SwiftData query optimization and indexing
- [ ] CloudKit error handling improvements
- [ ] Repository cleanup (unused files, optimized assets)
- [ ] Privacy policy and data handling documentation
- [ ] App Store metadata (screenshots, description, keywords)
- [ ] App versioning and build configuration
- [ ] Accessibility audit (VoiceOver, Dynamic Type, contrast)
- [ ] Testing across device sizes and iOS versions
- [ ] Empty state improvements
- [ ] Loading states for CloudKit sync
- [ ] Confirmation dialogs for destructive actions

### 4. UI Polish
- [ ] Error handling and user feedback improvements
- [ ] Haptic feedback for key interactions
- [ ] Animation polish and transitions
- [ ] Dark mode optimization

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

### High Value Features
- [ ] **Multi-dimensional quantities**: Track related values (e.g., miles + gallons → MPG, weight + reps for exercise)
- [ ] **Simple trend charts**: Visual sparklines or mini-charts in analytics cards
- [ ] **CSV data export**: Export to Files app or share via share sheet
- [ ] Charts/graphs for trends (full-featured)
- [ ] Reminders to log entries

### Testing & Quality
- [ ] **CloudKit multi-device sync testing**: Verify data syncs correctly across devices
- [ ] Multi-device conflict resolution testing

### Platform & Integration
- [ ] iPad optimization
- [ ] Mac Catalyst version
- [ ] Shortcuts app integration beyond Siri
- [ ] Health app integration for relevant metrics
- [ ] Apple Watch complication

### Advanced Features
- [ ] Custom time period groupings
- [ ] Tags for entries
- [ ] Derived/calculated quantities (formulas between quantity types)

---

## Development Timeline

- **Day 1**: Initial scaffold, models, basic UI, CloudKit setup, navigation fixes, backdating feature
- **Day 2**: Edit quantity types, hiding, advanced aggregations (Sum/Avg/Median/Min/Max/Count), app icon
- **Day 3**: Home screen widgets (Small/Medium/Large variants), SwiftData integration via App Groups
- **Next**: Enhanced Siri intents with flexible parsing, widget deep linking, widget configuration

---

## Notes

- Keep input frictionless - that's the core value prop
- Analytics should be insightful without being overwhelming
- Default to sensible behaviors (sum, recent sort, etc.)
- Make advanced features optional and discoverable
