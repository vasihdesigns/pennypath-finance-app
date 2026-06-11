//
//  ExpenseFormView.swift
//  PennyPath
//
//  Add or edit one expense.
//

import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var expense: Expense?

    @State private var amount: Double = 0
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var date = Date.now

    private var isEditing: Bool { expense != nil }
    private var canSave: Bool { amount > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.lg) {
                    AmountField(title: "How much?", amount: $amount, tint: Theme.red)
                        .card(padding: Theme.Space.xl)

                    FieldCard(label: "What was it for?") {
                        ChipGrid(items: ExpenseCategory.allCases, selection: $category, tint: Theme.red)
                    }

                    FieldCard(label: "Note (optional)") {
                        TextField("e.g. Lunch with friends", text: $note)
                            .textInputAutocapitalization(.sentences)
                    }

                    FieldCard(label: "When?") {
                        DatePicker("", selection: $date, in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                    }

                    if isEditing {
                        Button("Delete expense", role: .destructive) { deleteExpense() }
                            .buttonStyle(SoftButtonStyle(tint: Theme.red))
                    }
                }
                .padding(Theme.Space.lg)
            }
            .background(Theme.background)
            .navigationTitle(isEditing ? "Edit expense" : "New expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(Theme.red)
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let expense else { return }
        amount = expense.amount
        category = expense.category
        note = expense.note
        date = expense.date
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        if let expense {
            expense.amount = abs(amount)
            expense.category = category
            expense.note = trimmed
            expense.date = date
        } else {
            context.insert(Expense(amount: amount, category: category, note: trimmed, date: date))
        }
        dismiss()
    }

    private func deleteExpense() {
        if let expense { context.delete(expense) }
        dismiss()
    }
}
