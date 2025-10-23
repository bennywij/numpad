//
//  FocusedValues.swift
//  Numpad
//
//  Created on 2025-10-21.
//

import SwiftUI

// MARK: - Focused Value Keys for Keyboard Commands

struct NewQuantityActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct AddEntryActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct NextQuantityActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct PreviousQuantityActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct DismissSheetActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct ShowKeyboardShortcutsActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var newQuantityAction: NewQuantityActionKey.Value? {
        get { self[NewQuantityActionKey.self] }
        set { self[NewQuantityActionKey.self] = newValue }
    }

    var addEntryAction: AddEntryActionKey.Value? {
        get { self[AddEntryActionKey.self] }
        set { self[AddEntryActionKey.self] = newValue }
    }

    var nextQuantityAction: NextQuantityActionKey.Value? {
        get { self[NextQuantityActionKey.self] }
        set { self[NextQuantityActionKey.self] = newValue }
    }

    var previousQuantityAction: PreviousQuantityActionKey.Value? {
        get { self[PreviousQuantityActionKey.self] }
        set { self[PreviousQuantityActionKey.self] = newValue }
    }

    var dismissSheetAction: DismissSheetActionKey.Value? {
        get { self[DismissSheetActionKey.self] }
        set { self[DismissSheetActionKey.self] = newValue }
    }

    var showKeyboardShortcutsAction: ShowKeyboardShortcutsActionKey.Value? {
        get { self[ShowKeyboardShortcutsActionKey.self] }
        set { self[ShowKeyboardShortcutsActionKey.self] = newValue }
    }
}
