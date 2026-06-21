//
//  PennyPathWidgetBundle.swift
//  PennyPathWidgets
//
//  The widget extension's entry point. It hosts a single iOS 18 Control that
//  drops an "Add Expense" button into Control Center / the Lock Screen — the
//  easiest way to start logging, since (unlike Back Tap) the user can add it
//  with a long-press and a tap.
//
//  The control's action is `AddExpenseIntent`, shared from the app target
//  (QuickAddIntent.swift). It sets `openAppWhenRun`, so tapping the control
//  opens PennyPath straight to the Add Expense sheet.
//

import WidgetKit
import SwiftUI
import AppIntents

@main
struct PennyPathWidgetBundle: WidgetBundle {
    var body: some Widget {
        AddExpenseControl()
    }
}

struct AddExpenseControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.vasih.PennyPath.addExpense") {
            ControlWidgetButton(action: AddExpenseIntent()) {
                Label("Add Expense", systemImage: "creditcard.fill")
            }
        }
        .displayName("Add Expense")
        .description("Log a new expense in PennyPath.")
    }
}
