//
//  BudgetFormView.swift
//  PennyPath
//
//  Set or edit one category's monthly budget.
//

import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var budget: CategoryBudget?
    var takenCategories: Set<String> = []

    @State private var category: ExpenseCategory = .food
    @State private var amount: Double = 0

    private var isEditing: Bool { budget != nil }
    private var canSave: Bool { amount > 0 }
    private var available: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { !takenCategories.contains($0.rawValue) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.lg) {
                    AmountField(title: "Monthly budget", amount: $amount, tint: Theme.red)
                        .card(padding: Theme.Space.xl)

                    FieldCard(label: "Category") {
                        if isEditing {
                            HStack(spacing: Theme.Space.sm) {
                                Text(category.emoji)
                                Text(category.title).font(.body).foregroundStyle(Theme.ink)
                            }
                        } else {
                            ChipGrid(items: available, selection: $category, tint: Theme.red)
                        }
                    }

                    if isEditing {
                        Button("Remove budget", role: .destructive) { remove() }
                            .buttonStyle(SoftButtonStyle(tint: Theme.red))
                    }
                }
                .padding(Theme.Space.lg)
            }
            .background(Theme.background)
            .navigationTitle(isEditing ? "Edit budget" : "New budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(Theme.red)
        }
        .onAppear(perform: load)
    }

    private func load() {
        if let budget {
            category = budget.category
            amount = budget.monthlyLimit
        } else {
            category = available.first ?? .food
        }
    }

    private func save() {
        if let budget {
            budget.monthlyLimit = max(0, amount)
        } else {
            context.insert(CategoryBudget(category: category, monthlyLimit: amount))
        }
        dismiss()
    }

    private func remove() {
        if let budget { context.delete(budget) }
        dismiss()
    }
}
