//
//  PennyPathShortcuts.swift
//  PennyPath
//
//  Publishes the "Add Expense" App Shortcut so it appears in Siri, the Shortcuts
//  app, and the Back Tap picker. App target only — an AppShortcutsProvider must
//  live in the main app, not in the widget extension that shares the intent.
//

import AppIntents

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
