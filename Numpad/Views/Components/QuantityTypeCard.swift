//
//  QuantityTypeCard.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI

struct QuantityTypeCard: View {
    let quantityType: QuantityType
    let total: Double
    let onPlusButtonTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left: Icon and info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: quantityType.icon)
                        .font(.body)
                        .foregroundColor(Color(hex: quantityType.colorHex))
                        .frame(width: 20)
                        .accessibilityLabel("\(quantityType.name) icon")

                    Text(quantityType.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Text(quantityType.valueFormat.format(total))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
                    .accessibilityLabel("Total: \(quantityType.valueFormat.format(total))")
            }

            Spacer(minLength: 16)

            // Right: Plus button
            Button(action: onPlusButtonTap) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Add entry to \(quantityType.name)")
            .accessibilityHint("Double tap to log a new entry")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quantityType.name), total: \(quantityType.valueFormat.format(total))")
        .accessibilityHint("Double tap to view analytics and history")
    }
}

// MARK: - Color Hex Extension
// Note: This extension should ideally be in a shared file, but is included here
// until Color+Hex.swift is properly added to the Xcode project
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
