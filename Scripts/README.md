# Numpad Scripts

## generate_app_icon.swift

Generates a complete set of app icons for the Numpad iOS app.

### Features
- Creates a numpad-style icon with a 3x4 grid pattern
- Blue gradient background (#007AFF to darker blue)
- White semi-transparent buttons with subtle borders
- Generates all required sizes for iPhone, iPad, and App Store

### Usage

```bash
cd Scripts
./generate_app_icon.swift
```

This will create an `AppIcon.appiconset` directory containing:
- 15 PNG files in various sizes (20pt to 1024pt)
- Contents.json for Xcode asset catalog

### Installing the Icons

1. Open `Numpad.xcodeproj` in Xcode
2. Navigate to `Numpad/Assets.xcassets`
3. Delete the existing `AppIcon` asset
4. Drag the generated `AppIcon.appiconset` folder into Assets.xcassets
5. Build and run the app to see the new icon

### Requirements
- macOS (uses AppKit and CoreGraphics)
- Swift 5.0+
- Xcode command line tools

### Icon Design
The icon features a simplified numpad grid design that:
- Represents the app's focus on number tracking
- Uses the app's primary blue color (#007AFF)
- Has a modern, clean aesthetic matching iOS design guidelines
- Shows a "1" in the first button for visual interest on larger sizes
