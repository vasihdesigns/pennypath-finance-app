//
//  QuickAddIntent.swift
//  PennyPath
//
//  An "Add Expense" App Shortcut. Once the app is installed, this shortcut shows
//  up in Siri, the Shortcuts app, and — most usefully — in
//  Settings → Accessibility → Touch → Back Tap, so a double-tap on the back of
//  the iPhone jumps straight to logging an expense.
//
//  iOS doesn't let an app set Back Tap itself; we just publish the shortcut and
//  guide the user to assign it (see SettingsView → "Quick add shortcut"). The
//  same AddExpenseIntent can also drive a Control Center / Lock Screen control
//  once a Widget Extension target is added (see RELEASE.md).
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

struct PennyPathShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "New expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "creditcard.fill"
        )
    }
}
