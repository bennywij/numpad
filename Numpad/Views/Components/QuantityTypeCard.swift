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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: quantityType.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: quantityType.colorHex))
                    .accessibilityLabel("\(quantityType.name) icon")

                Spacer()

                Button(action: onPlusButtonTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Add entry to \(quantityType.name)")
                .accessibilityHint("Double tap to log a new entry")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(quantityType.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(quantityType.valueFormat.format(total))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .accessibilityLabel("Total: \(quantityType.valueFormat.format(total))")

                Text("Total • Tap for details")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quantityType.name), total: \(quantityType.valueFormat.format(total))")
        .accessibilityHint("Double tap to view analytics and history")
    }
}

// Color extension to parse hex strings
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
