#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// Configuration
let outputDirectory = "./AppIcon.appiconset"
let iconSizes: [(size: CGFloat, scale: Int, name: String)] = [
    // iPhone
    (20, 2, "Icon-20@2x"),
    (20, 3, "Icon-20@3x"),
    (29, 2, "Icon-29@2x"),
    (29, 3, "Icon-29@3x"),
    (40, 2, "Icon-40@2x"),
    (40, 3, "Icon-40@3x"),
    (60, 2, "Icon-60@2x"),
    (60, 3, "Icon-60@3x"),
    // iPad
    (20, 1, "Icon-20"),
    (29, 1, "Icon-29"),
    (40, 1, "Icon-40"),
    (76, 1, "Icon-76"),
    (76, 2, "Icon-76@2x"),
    (83.5, 2, "Icon-83.5@2x"),
    // App Store
    (1024, 1, "Icon-1024"),
]

// Create output directory
let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

// Function to create an app icon with a numpad-style design
func createAppIcon(size: CGFloat, scale: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Background gradient
    let context = NSGraphicsContext.current?.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Modern blue gradient background
    let startColor = NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor  // #007AFF
    let endColor = NSColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0).cgColor

    let colors = [startColor, endColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!

    context?.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )

    // Draw a 3x4 grid pattern resembling a numpad
    let padding = size * 0.15
    let gridWidth = size - (padding * 2)
    let gridHeight = size - (padding * 2)

    let buttonWidth = gridWidth / 3.2
    let buttonHeight = gridHeight / 4.5
    let horizontalSpacing = (gridWidth - (buttonWidth * 3)) / 2
    let verticalSpacing = (gridHeight - (buttonHeight * 4)) / 3

    // Draw numpad buttons (3x4 grid)
    for row in 0..<4 {
        for col in 0..<3 {
            let x = padding + CGFloat(col) * (buttonWidth + horizontalSpacing)
            let y = padding + CGFloat(row) * (buttonHeight + verticalSpacing)

            let buttonRect = NSRect(x: x, y: y, width: buttonWidth, height: buttonHeight)
            let buttonPath = NSBezierPath(roundedRect: buttonRect, xRadius: size * 0.06, yRadius: size * 0.06)

            // Button background - white with transparency
            NSColor.white.withAlphaComponent(0.25).setFill()
            buttonPath.fill()

            // Button border - subtle white outline
            NSColor.white.withAlphaComponent(0.4).setStroke()
            buttonPath.lineWidth = size * 0.01
            buttonPath.stroke()
        }
    }

    // Add a subtle highlight to suggest it's a calculator/numpad
    // Draw number "1" in the top-left button
    if size >= 60 {
        let fontSize = size * 0.12
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]

        // Position for "1" in first button
        let numberString = "1" as NSString
        let textSize = numberString.size(withAttributes: attributes)
        let x = padding + (buttonWidth - textSize.width) / 2
        let y = padding + gridHeight - buttonHeight + (buttonHeight - textSize.height) / 2

        numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
    }

    image.unlockFocus()
    return image
}

// Function to save NSImage as PNG
func savePNG(image: NSImage, path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Error saving PNG: \(error)")
    }
}

// Generate all icon sizes
print("Generating app icons...")

for (size, scale, name) in iconSizes {
    let image = createAppIcon(size: size, scale: scale)
    let filename = "\(outputDirectory)/\(name).png"
    savePNG(image: image, path: filename)
}

// Generate Contents.json
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "Icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = "\(outputDirectory)/Contents.json"
try? contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
print("Created: \(contentsPath)")

print("\nDone! Icon set created at: \(outputDirectory)")
print("\nTo use these icons:")
print("1. Open your Xcode project")
print("2. Navigate to Assets.xcassets")
print("3. Replace the AppIcon.appiconset folder with the generated one")
print("   Or drag the generated PNG files into the AppIcon asset")
