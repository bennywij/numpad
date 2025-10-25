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
1. **FIX: iPad Layout Rendering Bug**
   - Removed GeometryReader complexity causing render issues
   - Simplified to use `horizontalSizeClass` environment variable
   - iPad now uses consistent 2-column layout (regular size class)
   - iPhone uses 1-column layout (compact size class)
   - Fixes Hidden section overlap rendering bug
   - File: `Numpad/Views/ContentView.swift:613-660`

2. **FIX: Divide by Zero Alert in Compound Quantities**
   - Issue: Error displayed when entering numerator before denominator (default 0)
   - Solution: Track `value2HasBeenEdited` state
   - Error only shows after denominator field is explicitly edited or loses focus
   - File: `Numpad/Views/Components/ValueInputView.swift:93-251`
   - Build verified: ✅ SUCCESS

---

## Next Steps

### Proceed With

1. **Implement Second App Intent Properly**
   - Add AddToQuantityIntent to build phase
   - Register in AppShortcuts with correct syntax
   - Test shortcuts appear in Shortcuts app

2. **Enhance Widget (When Ready)**
   - Implement cross-process data sync
   - Display actual quantity data
   - Keep widget and app data layers separate

3. **Review & Polish**
   - Run full test suite
   - Verify all shortcuts work
   - Clean up debug logging if added
