//
//  QuickAddIntent.swift
//  PennyPath
//
//  The "Add Expense" App Intent and the coordinator that bridges it into the
//  SwiftUI app. Firing the intent flips a flag and the root presents the Add
//  Expense sheet. Reached from Siri, the Shortcuts app, Back Tap, and the
//  Control Center / Lock Screen control.
//
//  This file is shared with the PennyPathWidgets extension target (so the
//  Control can reference AddExpenseIntent). Keep it free of app-only types —
//  the AppShortcutsProvider lives in PennyPathShortcuts.swift (app target only).
//

import AppIntents
import SwiftUI

/// Bridges an intent firing into the SwiftUI app: flip the flag and the root
/// presents the Add Expense sheet.
@MainActor
@Observable
final class QuickAddCoordinator {
    static let shared = QuickAddCoordinator()
    var showAddExpense = false
    private init() {}
}

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Open PennyPath and start logging a new expense.")

    /// Bring the app to the front so the quick-add sheet can appear.
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickAddCoordinator.shared.showAddExpense = true
        return .result()
    }
}
