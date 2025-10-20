# Numpad

A frictionless iOS app for tracking quantities with timestamps. Built with Claude Code.

## Features

- **Easy Quantity Tracking**: Track any quantity type (integers, decimals, or durations)
- **Smart Input**: Adaptive input UI based on data type (number pad, decimal pad, or HH:MM sliders)
- **CloudKit Sync**: Automatically sync your data across devices via iCloud
- **Analytics**: View totals grouped by day, week, month, year, or all time
- **Siri Integration**: Quick logging via App Intents ("Log to Numpad")
- **Editable Entries**: Easily edit or delete any logged entry
- **Custom Quantity Types**: Create unlimited "columns" with custom icons and colors

## Architecture

### Data Layer
- **SwiftData** with CloudKit integration for seamless iCloud sync
- **Models**:
  - `QuantityType`: Defines a trackable quantity (name, format, icon, color)
  - `Entry`: Individual logged values with timestamps
  - `ValueFormat`: Enum supporting integer, decimal, and duration formats

### UI Layer
- **SwiftUI** views with MVVM architecture
- **Components**:
  - `DurationPicker`: HH:MM slider input
  - `ValueInputView`: Adaptive input based on value format
  - `QuantityTypeCard`: Quick-add cards on home screen
  - `AnalyticsView`: Grouped totals and trends
  - `EntryHistoryView`: List of all entries with edit functionality

### App Intents
- `LogEntryIntent`: Siri shortcut for voice logging
- Automatically logs to most recently used quantity type

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.9+

## Setup

1. Open `Numpad.xcodeproj` in Xcode
2. Select your development team in signing settings
3. Enable iCloud capability and select or create a CloudKit container
4. Build and run on your device or simulator

## Usage

1. **Create Quantity Types**: Tap + to create your first quantity type (e.g., "Minutes Read", "Steps", "Calories")
2. **Log Entries**: Tap a quantity card to quickly add a new entry
3. **View History**: Tap on a quantity type card to see all entries and analytics
4. **Use Siri**: Say "Log to Numpad" and provide a value

## CloudKit Setup

To enable iCloud sync:
1. In Xcode, go to project settings → Signing & Capabilities
2. Add iCloud capability
3. Enable CloudKit
4. Select or create a CloudKit container

## License

MIT
