//
//  ValueInputView.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI

struct ValueInputView: View {
    let valueFormat: ValueFormat
    @Binding var value: Double
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(valueFormat.format(value))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)

            switch valueFormat {
            case .duration:
                DurationPicker(totalMinutes: $value)
            case .integer, .decimal:
                numberInputView
            }
        }
    }

    private var numberInputView: some View {
        VStack(spacing: 16) {
            TextField("Enter value", value: $value, format: .number)
                .keyboardType(valueFormat.keyboardType)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .focused($isFocused)

            // Quick add buttons
            HStack(spacing: 12) {
                ForEach([1, 5, 10, 50], id: \.self) { increment in
                    quickAddButton("+\(increment)", value: Double(increment))
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    private func quickAddButton(_ label: String, value addValue: Double) -> some View {
        Button(action: {
            value += addValue
        }) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}
