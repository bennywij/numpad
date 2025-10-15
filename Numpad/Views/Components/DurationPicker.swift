//
//  DurationPicker.swift
//  Numpad
//
//  Created on 2025-10-15.
//

import SwiftUI

struct DurationPicker: View {
    @Binding var totalMinutes: Double
    @State private var hours: Int
    @State private var minutes: Int

    init(totalMinutes: Binding<Double>) {
        self._totalMinutes = totalMinutes
        let total = Int(totalMinutes.wrappedValue)
        self._hours = State(initialValue: total / 60)
        self._minutes = State(initialValue: total % 60)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                VStack {
                    Text("\(hours)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(":")
                    .font(.system(size: 48, weight: .bold))

                VStack {
                    Text(String(format: "%02d", minutes))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Slider(value: Binding(
                            get: { Double(hours) },
                            set: { newValue in
                                hours = Int(newValue)
                                updateTotalMinutes()
                            }
                        ), in: 0...23, step: 1)

                        Text("\(hours)")
                            .frame(width: 30)
                            .font(.headline)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Minutes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Slider(value: Binding(
                            get: { Double(minutes) },
                            set: { newValue in
                                minutes = Int(newValue)
                                updateTotalMinutes()
                            }
                        ), in: 0...59, step: 1)

                        Text("\(minutes)")
                            .frame(width: 30)
                            .font(.headline)
                    }
                }
            }
            .padding()

            // Quick add buttons
            HStack(spacing: 12) {
                quickAddButton("+15m", minutes: 15)
                quickAddButton("+30m", minutes: 30)
                quickAddButton("+1h", minutes: 60)
                quickAddButton("Reset", minutes: 0, isReset: true)
            }
        }
    }

    private func quickAddButton(_ label: String, minutes addMinutes: Int, isReset: Bool = false) -> some View {
        Button(action: {
            if isReset {
                hours = 0
                minutes = 0
            } else {
                let total = hours * 60 + minutes + addMinutes
                hours = total / 60
                minutes = total % 60
            }
            updateTotalMinutes()
        }) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isReset ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(isReset ? .red : .blue)
                .cornerRadius(8)
        }
    }

    private func updateTotalMinutes() {
        totalMinutes = Double(hours * 60 + minutes)
    }
}
