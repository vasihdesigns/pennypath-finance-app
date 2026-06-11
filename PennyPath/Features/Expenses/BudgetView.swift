//
//  BudgetView.swift
//  PennyPath
//
//  The "Budget" half of the Spending tab: a monthly plan you compare against
//  what you actually spent. Bars are green while you're under, red if you go over.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]

    @State private var editing: CategoryBudget?
    @State private var showingAdd = false

    // MARK: Numbers

    private func spent(_ category: ExpenseCategory, in date: Date = .now) -> Double {
        expenses
            .filter { $0.category == category && $0.date.isSameMonth(as: date) }
            .reduce(0) { $0 + $1.amount }
    }
    private var totalSpent: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    private var left: Double { totalBudget - totalSpent }
    private var over: Bool { left < 0 }

    private var sortedBudgets: [CategoryBudget] {
        budgets.sorted { $0.monthlyLimit > $1.monthlyLimit }
    }
    private var unbudgeted: [ExpenseCategory] {
        let taken = Set(budgets.map { $0.categoryRaw })
        return ExpenseCategory.allCases.filter { !taken.contains($0.rawValue) }
    }
    private var suggestableCategories: [ExpenseCategory] {
        unbudgeted.filter { cat in (0..<3).contains { spent(cat, in: .now.adding(months: -$0)) > 0 } }
    }
    private var canSuggest: Bool { !suggestableCategories.isEmpty }

    // MARK: Body

    var body: some View {
        ScrollView {
            if budgets.isEmpty {
                emptyState
            } else {
                VStack(spacing: Theme.Space.lg) {
                    headline
                    categoryList
                    footerButtons
                }
                .padding(Theme.Space.lg)
            }
        }
        .sheet(isPresented: $showingAdd) {
            BudgetFormView(takenCategories: Set(budgets.map { $0.categoryRaw }))
        }
        .sheet(item: $editing) { BudgetFormView(budget: $0) }
    }

    private var headline: some View {
        VStack(spacing: Theme.Space.md) {
            Text(over ? "OVER BUDGET THIS MONTH" : "LEFT TO SPEND THIS MONTH")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(1)
            Text(money(abs(left)))
                .font(.amount(46))
                .foregroundStyle(over ? Theme.red : Theme.green)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            ProgressBar(value: totalBudget > 0 ? min(1, totalSpent / totalBudget) : 0,
                        tint: over ? Theme.red : Theme.green, height: 12)
            Text("\(money(totalSpent)) of \(money(totalBudget)) budget")
                .font(.footnote)
                .foregroundStyle(Theme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: Theme.Space.xl)
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "By category")
            VStack(spacing: Theme.Space.sm) {
                ForEach(sortedBudgets) { budget in
                    Button { editing = budget } label: {
                        BudgetCategoryRow(category: budget.category,
                                          spent: spent(budget.category),
                                          limit: budget.monthlyLimit)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = budget }
                        Button("Delete", role: .destructive) { context.delete(budget) }
                    }
                }
            }
        }
    }

    @ViewBuilder private var footerButtons: some View {
        VStack(spacing: Theme.Space.md) {
            if !unbudgeted.isEmpty {
                Button { showingAdd = true } label: {
                    Label("Add a budget", systemImage: "plus")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.red))
            }
            if canSuggest {
                Button { suggestBudgets() } label: {
                    Label("Suggest from my spending", systemImage: "wand.and.stars")
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.ink))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Space.md) {
            Text("🧮").font(.system(size: 52))
            Text("Make a spending plan")
                .font(.display(20))
                .foregroundStyle(Theme.ink)
            Text("Set a monthly budget for the things you spend on. Each bar stays green while you're under and turns red if you go over.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            VStack(spacing: Theme.Space.sm) {
                if canSuggest {
                    Button("Suggest from my spending") { suggestBudgets() }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.red))
                    Button("Set one myself") { showingAdd = true }
                        .buttonStyle(SoftButtonStyle(tint: Theme.ink))
                } else {
                    Button("Set a budget") { showingAdd = true }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.red))
                }
            }
            .frame(maxWidth: 280)
            .padding(.top, Theme.Space.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.xxl)
        .padding(.horizontal, Theme.Space.lg)
    }

    private func suggestBudgets() {
        for category in suggestableCategories {
            let monthly = (0..<3)
                .map { spent(category, in: .now.adding(months: -$0)) }
                .filter { $0 > 0 }
            guard !monthly.isEmpty else { continue }
            let average = monthly.reduce(0, +) / Double(monthly.count)
            let rounded = max(10, (average / 10).rounded(.up) * 10)
            context.insert(CategoryBudget(category: category, monthlyLimit: rounded))
        }
        Haptics.success()
    }
}

private struct BudgetCategoryRow: View {
    let category: ExpenseCategory
    let spent: Double
    let limit: Double

    private var over: Bool { spent > limit }
    private var progress: Double { limit > 0 ? min(1, spent / limit) : 0 }
    private var tint: Color { over ? Theme.red : Theme.green }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack {
                Text(category.emoji)
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(over ? "\(money(spent - limit)) over" : "\(money(limit - spent)) left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            ProgressBar(value: progress, tint: tint, height: 10)
            Text("\(money(spent)) of \(money(limit))")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
        }
        .card()
    }
}
