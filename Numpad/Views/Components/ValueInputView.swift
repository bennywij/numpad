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
    let compoundConfig: CompoundConfig?
    @FocusState private var isFocused: Bool

    init(valueFormat: ValueFormat, value: Binding<Double>, compoundConfig: CompoundConfig? = nil) {
        self.valueFormat = valueFormat
        self._value = value
        self.compoundConfig = compoundConfig
    }

    var body: some View {
        VStack(spacing: 20) {
            // If compound config is provided, use CompoundInputView
            if let config = compoundConfig {
                CompoundInputView(config: config, calculatedValue: $value)
            } else {
                // Standard single-value input
                standardInputView
            }
        }
    }

    private var standardInputView: some View {
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

// MARK: - CompoundInputView

struct CompoundInputView: View {
    let config: CompoundConfig
    @Binding var calculatedValue: Double
    @FocusState private var focusedField: Field?

    @State private var value1: Double = 0
    @State private var value2: Double = 0
    @State private var date1: Date = Date()
    @State private var date2: Date = Date()
    @State private var hasUserInput: Bool = false
    @State private var value2HasBeenEdited: Bool = false

    enum Field {
        case input1
        case input2
    }

    var body: some View {
        VStack(spacing: 20) {
            // Display calculated result
            Text(formatResult())
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)

            // Input 1
            if config.operation == .timeDifference {
                timeInputField(
                    label: config.input1Label,
                    date: $date1,
                    focused: focusedField == .input1
                )
                .focused($focusedField, equals: .input1)
            } else {
                numberInputField(
                    label: config.input1Label,
                    value: $value1,
                    format: config.input1Format,
                    focused: focusedField == .input1
                )
                .focused($focusedField, equals: .input1)
            }

            // Input 2
            if config.operation == .timeDifference {
                timeInputField(
                    label: config.input2Label,
                    date: $date2,
                    focused: focusedField == .input2
                )
                .focused($focusedField, equals: .input2)
            } else {
                numberInputField(
                    label: config.input2Label,
                    value: $value2,
                    format: config.input2Format,
                    focused: focusedField == .input2
                )
                .focused($focusedField, equals: .input2)
            }
        }
        .onChange(of: value1) { _, _ in
            hasUserInput = true
            updateCalculation()
        }
        .onChange(of: value2) { _, _ in
            hasUserInput = true
            value2HasBeenEdited = true
            updateCalculation()
        }
        .onChange(of: date1) { _, _ in
            hasUserInput = true
            updateCalculation()
        }
        .onChange(of: date2) { _, _ in
            hasUserInput = true
            value2HasBeenEdited = true
            updateCalculation()
        }
        .onChange(of: focusedField) { _, newField in
            // Mark value2 as edited when user leaves the field
            if newField != .input2 && focusedField == .input2 {
                value2HasBeenEdited = true
            }
        }
        .onAppear {
            initializeDefaults()
            updateCalculation()
            focusedField = .input1
        }
    }

    private func numberInputField(label: String, value: Binding<Double>, format: ValueFormat, focused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)

            TextField("0", value: value, format: .number)
                .keyboardType(format.keyboardType)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func timeInputField(label: String, date: Binding<Date>, focused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)

            DatePicker(
                "",
                selection: date,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
        }
    }

    private func initializeDefaults() {
        if config.operation == .timeDifference {
            // Default: Start = 30 min ago, End = now
            date1 = Date().addingTimeInterval(-30 * 60)
            date2 = Date()
        }
    }

    private func updateCalculation() {
        if config.operation == .timeDifference {
            let timestamp1 = date1.timeIntervalSinceReferenceDate
            let timestamp2 = date2.timeIntervalSinceReferenceDate
            calculatedValue = config.operation.calculate(timestamp1, timestamp2) ?? 0
        } else {
            calculatedValue = config.operation.calculate(value1, value2) ?? 0
        }
    }

    private func formatResult() -> String {
        // Check for error states (only show after value2 has been explicitly edited)
        if config.operation == .divide && value2 == 0 && value2HasBeenEdited {
            return "Error: Divide by zero"
        }

        if config.operation == .timeDifference {
            // Format as duration (HH:MM or minutes)
            return ValueFormat.duration.format(calculatedValue)
        } else {
            // Use decimal format for calculations
            return String(format: "%.2f", calculatedValue)
        }
    }
}
