# Numpad Development Plan

## Session Recap (Oct 24 - Return to Baseline)

### Investigation: Widget Disappearance & App Intent Implementation

**What Happened:**
- Implemented second Siri App Intent (`AddToQuantityIntent` for selective quantity logging)
- Widget disappeared from iOS "Add Widgets" list after changes
- Spent entire session debugging the issue

**Root Cause (Identified with Gemini Code Review):**
The widget crashed due to CloudKit handler conflicts:
- Main app: `ModelContainer` with `cloudKitDatabase: .automatic`
- Widget: Tried to create its own `ModelContainer` for the same App Group store
- Both tried to register CloudKit handlers in the same process
- Error: "Illegal attempt to register a second handler for activity identifier"
- Result: Widget extension crashed and disappeared from Add Widgets list

**Key Finding: Architecture is Actually Correct**
- App Group (`group.com.bennywijatno.numpad.app`) already properly configured
- Widget data model duplication is NOT a mistake - it's a safety feature
- Widget needs separate data models to avoid CloudKit conflicts
- Swift modules don't allow sharing source files across targets anyway
- Current safe approach: Widget shows placeholder, doesn't access SwiftData

**Decision: Return to Baseline**
- Reset to commit `91af99e` (last known working state with functional widget)
- This baseline has working widget and limited app intent support
- Widget is safe and stable at this baseline

**Future Work on Second App Intent:**
- To implement `AddToQuantityIntent` properly requires:
  1. Ensure AddToQuantityIntent.swift is in project
  2. Add file to Numpad target's build phase
  3. Register intent in AppShortcuts.swift
  4. Update Info.plist NSUserActivityTypes
- Key insight: Registration in AppShortcuts.swift was the critical missing piece
- When implementing again, remember that result builder syntax requires NO commas between AppShortcut() expressions

**What to Remember for Next Time:**
- Widget must NOT access main app's SwiftData to avoid CloudKit conflicts
- Future widget data display should use cross-process sync (UserDefaults/File Sharing), not shared models
- When registering multiple AppShortcuts, use result builder syntax without commas
- Always verify build succeeds before considering work complete

## Session Learnings

### Swift/Xcode Lessons
1. **App Extensions & CloudKit**: Can't safely share SwiftData ModelContainers across process boundaries with CloudKit enabled
2. **Result Builder Syntax**: AppShortcuts provider uses result builder - multiple values need no commas, no brackets
3. **Module Boundaries**: Swift targets compile independently with their own module namespaces - can't share source files
4. **Project File Complexity**: Cherry-picking commits with project file changes requires careful attention to file reference IDs

### Architecture Insights
- Widget duplication is feature, not bug
- App Groups provide storage sharing, not code sharing
- Must keep data access layers separate between app and extension
- Cross-process communication should use lightweight mechanisms (UserDefaults, File Sharing, etc.)

---

## Session Progress (Oct 24 Evening)

### COMPLETED ✅

**Bugfixes & UX Improvements:**
1. **FIX: iPad Layout Rendering Bug**
   - Removed GeometryReader complexity causing render issues
   - Simplified to use `horizontalSizeClass` environment variable
   - iPad now uses consistent 2-column layout (regular size class)
   - iPhone uses 1-column layout (compact size class)
   - Fixes Hidden section overlap rendering bug
   - Reduced spacing from 16 to 8 for more compact iPad layout
   - Added SwiftUI #Preview macro for live testing
   - Commit: `052fa11`

2. **FIX: Divide by Zero Alert in Compound Quantities**
   - Issue: Error displayed when entering numerator before denominator (default 0)
   - Solution: Track `value2HasBeenEdited` state
   - Error only shows after denominator field is explicitly edited or loses focus
   - Commit: `92ddbdc`

**Core Features:**
3. **Improve Default Seeding Logic**
   - Added `hasSeededDefaultQuantities` @AppStorage flag
   - Seeding now happens only once on first app launch
   - Deleting all quantities won't trigger re-seeding (respects user intent)
   - Commit: `2930056`

4. **Improve Widget Display Sorting**
   - Changed widget default sort from `sortOrder` to `lastUsedAt`
   - Widget now shows most recently used quantities first
   - Better for quick reference in widget (most recent is most useful)
   - Commit: `2930056`

5. **Add Delete Quantity with Confirmation & Hide Context Menu**
   - Tap-and-hold context menu with Hide/Unhide toggle (shows current state)
   - Delete button at bottom of EditQuantityTypeView (harder to accidentally hit)
   - Confirmation dialog with comprehensive warning:
     - Permanent deletion notice
     - iCloud sync notice
     - Tip to export data before deletion
   - Cascades deletion to all related entries via SwiftData relationships
   - Tested: ✅ Working
   - Commit: `c3bc1f9`

---

## Session Progress (Oct 25 Evening - Second App Intent)

### COMPLETED ✅

**Second App Intent: "Log to a Specific Quantity"**
1. **Planned design carefully** - Parameter-based intent, user selects quantity before logging
2. **Followed safe pattern** - Exact same CloudKit-safe architecture as LogEntryIntent (cloudKitDatabase: .none)
3. **Created LogEntryForChosenQuantityIntent.swift**
   - Takes QuantityTypeEntity parameter for user selection
   - Creates entry for chosen quantity (not auto-selected)
   - Updates lastUsedAt and saves
   - Returns confirmation dialog
4. **Updated AppShortcuts.swift** - Registered new intent with correct result builder syntax
5. **Fixed build issues**:
   - Added files to Xcode project.pbxproj (critical for build)
   - Fixed Entry model name (NumpadEntry)
   - Fixed UUID predicate comparison
6. **Build succeeded** - Zero compiler errors ✅
7. **Testing passed** ✅:
   - Widget still appears in Add Widgets list
   - Both intents appear in Shortcuts app
   - Original LogEntryIntent still works
   - New intent allows choosing quantity before logging
   - Entries logged correctly with user-selected quantities
8. **Commit: [pending - this commit]**

### Why This Approach Was Safe
- No changes to main app UI or data models
- No widget code modifications
- Used existing QuantityTypeEntity for parameter
- Same CloudKit handler pattern as proven LogEntryIntent
- Minimal surface area (3 files): easy rollback if needed
- Extensive testing before committing

---

## Next Steps

### Recommended Priorities

1. **SortOrder/Drag-to-Reorder** (LOW PRIORITY - Optional Enhancement)
   - Decision: HOLD for now
   - Rationale: Non-standard UX in custom layout, risky to implement without clear value
   - Current behavior (most recently used sorting) appears sufficient
   - Can revisit in future refactor/feature push if needed

2. **App Polish & Testing** (MEDIUM PRIORITY)
   - Run full manual test suite
   - Verify all shortcuts in real Shortcuts app (not just simulator)
   - Test on physical device if available
   - Check for any regressions with new intent

3. **Future Enhancements** (LOW PRIORITY)
   - Voice control improvements (hard with quantity selection)
   - Widget data sync enhancements beyond current App Group
   - Additional app intents (e.g., view recent entries, export data)

### Architecture Notes
- App Group (`group.com.bennywijatno.numpad.app`) working correctly ✅
- Widget stable and properly isolated from CloudKit conflicts ✅
- App Intent pattern established and proven safe (cloudKitDatabase: .none) ✅
- Current two-intent setup covers: auto-log (fast) and selective-log (flexible)
