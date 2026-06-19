//
//  ClaritySpendView.swift
//  PennyPath
//
//  Clarity's Spending screen. The decluttering move: spending and budget
//  are one list, not two modes — every category shows what went out and,
//  if a plan exists, a thin meter of how it's holding. The real expense
//  and budget forms do all the editing.
//

import SwiftUI
import SwiftData

struct ClaritySpendView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]

    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    @State private var showingAddBudget = false
    @State private var editingBudget: CategoryBudget?

    // MARK: Numbers

    private var thisMonth: Double { ClarityHealth.monthTotal(expenses, in: .now) }
    private var lastMonth: Double { ClarityHealth.monthTotal(expenses, in: .now.adding(months: -1)) }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }

    private func spent(_ category: ExpenseCategory, in date: Date = .now) -> Double {
        expenses
            .filter { $0.category == category && $0.date.isSameMonth(as: date) }
            .reduce(0) { $0 + $1.amount }
    }

    private func budget(for category: ExpenseCategory) -> CategoryBudget? {
        budgets.first { $0.category == category }
    }

    /// One row per category that has spending this month or a plan —
    /// biggest spending first, planned-but-quiet categories at the end.
    private var lines: [(category: ExpenseCategory, spent: Double, budget: CategoryBudget?)] {
        ExpenseCategory.allCases
            .map { (category: $0, spent: spent($0), budget: budget(for: $0)) }
            .filter { $0.spent > 0 || $0.budget != nil }
            .sorted { $0.spent > $1.spent }
    }

    private var paceLine: (text: String, over: Bool)? {
        guard lastMonth > 0 else { return nil }
        let cal = Calendar.current
        let day = cal.component(.day, from: .now)
        let daysInMonth = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        let usual = lastMonth * Double(day) / Double(daysInMonth)
        let diff = usual - thisMonth
        if abs(diff) < 1 { return (text: "Right on your usual pace", over: false) }
        return diff > 0
            ? (text: "\(money(diff)) under your usual pace", over: false)
            : (text: "\(money(-diff)) over your usual pace", over: true)
    }

    private var suggestableCategories: [ExpenseCategory] {
        let taken = Set(budgets.map { $0.categoryRaw })
        return ExpenseCategory.allCases
            .filter { !taken.contains($0.rawValue) }
            .filter { cat in (0..<3).contains { spent(cat, in: .now.adding(months: -$0)) > 0 } }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if expenses.isEmpty && budgets.isEmpty {
                    emptyState
                } else {
                    hero
                    categoryList
                    planButtons
                    recentList
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Clarity.paper)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddExpense) { ExpenseFormView() }
        .sheet(item: $editingExpense) { ExpenseFormView(expense: $0) }
        .sheet(isPresented: $showingAddBudget) {
            BudgetFormView(takenCategories: Set(budgets.map { $0.categoryRaw }))
        }
        .sheet(item: $editingBudget) { BudgetFormView(budget: $0) }
        .tint(Clarity.cobalt)
    }

    // MARK: Header & hero

    private var header: some View {
        HStack {
            ClarityOverline(text: Date.now.formatted(.dateTime.month(.wide).year()))
            Spacer()
            Button { showingAddExpense = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Clarity.inkSoft)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(money(thisMonth))
                .font(.clarityAmount(48))
                .foregroundStyle(Clarity.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let pace = paceLine {
                Text(pace.text)
                    .font(.subheadline)
                    .foregroundStyle(pace.over ? Clarity.rust : Clarity.inkSoft)
            } else if thisMonth > 0 {
                Text("Spent so far this month.")
                    .font(.subheadline)
                    .foregroundStyle(Clarity.inkSoft)
            }
        }
    }

    // MARK: Category list (spending and plan, together)

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                ClarityOverline(text: "Where it went")
                Spacer()
                if totalBudget > 0 {
                    Text("\(money(thisMonth)) of \(money(totalBudget)) plan")
                        .font(.caption)
                        .foregroundStyle(Clarity.inkFaint)
                }
            }
            .padding(.bottom, 6)

            ForEach(Array(lines.enumerated()), id: \.element.category) { index, line in
                categoryRow(line.category, spent: line.spent, budget: line.budget)
                if index < lines.count - 1 { ClarityRule() }
            }
        }
    }

    private func categoryRow(_ category: ExpenseCategory, spent: Double,
                             budget: CategoryBudget?) -> some View {
        let over = budget.map { spent > $0.monthlyLimit } ?? false
        let tint: Color = over ? Clarity.rust : Clarity.good

        return Button {
            if let budget { editingBudget = budget }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(category.emoji).font(.subheadline)
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Clarity.ink)
                    Spacer(minLength: 12)
                    Text(money(spent))
                        .font(.clarityAmount(16))
                        .foregroundStyle(Clarity.ink)
                }
                if let budget {
                    ClarityMeter(value: budget.monthlyLimit > 0
                                        ? spent / budget.monthlyLimit : 0,
                                 tint: tint)
                    Text(over ? "\(money(spent - budget.monthlyLimit)) over the \(money(budget.monthlyLimit)) plan"
                              : "\(money(budget.monthlyLimit - spent)) left of \(money(budget.monthlyLimit))")
                        .font(.caption)
                        .foregroundStyle(over ? Clarity.rust : Clarity.inkFaint)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let budget {
                Button("Edit plan") { editingBudget = budget }
                Button("Remove plan", role: .destructive) { context.delete(budget) }
            } else {
                Button("Set a plan for \(category.title)") { showingAddBudget = true }
            }
        }
    }

    @ViewBuilder private var planButtons: some View {
        let unbudgeted = ExpenseCategory.allCases.count - budgets.count
        HStack(spacing: 10) {
            if unbudgeted > 0 {
                ClarityGhostButton(title: budgets.isEmpty ? "Set a plan" : "Add to plan",
                                   systemImage: "plus", tint: Clarity.cobalt) {
                    showingAddBudget = true
                }
            }
            if !suggestableCategories.isEmpty {
                ClarityGhostButton(title: "Suggest from my spending",
                                   systemImage: "wand.and.stars") {
                    suggestBudgets()
                }
            }
        }
    }

    /// Same suggestion rule as the real Budget tab: average of the last
    /// three active months, rounded up to a friendly ten.
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

    // MARK: Recent expenses (tap to edit, hold to delete)

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClarityOverline(text: "Recent")
                .padding(.bottom, 6)
            ForEach(Array(expenses.prefix(30).enumerated()), id: \.element.id) { index, expense in
                Button { editingExpense = expense } label: {
                    expenseRow(expense)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit") { editingExpense = expense }
                    Button("Delete", role: .destructive) { context.delete(expense) }
                }
                if index < min(expenses.count, 30) - 1 { ClarityRule() }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(Clarity.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption)
                    .foregroundStyle(Clarity.inkFaint)
            }
            Spacer(minLength: 12)
            Text("−" + money(expense.amount))
                .font(.clarityAmount(15))
                .foregroundStyle(Clarity.ink)
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Where does\nit all go?")
                .font(.clarityDisplay(26))
                .foregroundStyle(Clarity.ink)
                .lineSpacing(3)
            Text("Note each expense as it happens. Within days the pattern shows itself — then a plan makes it a choice.")
                .font(.callout)
                .foregroundStyle(Clarity.inkSoft)
                .lineSpacing(3)
            ClarityButton(title: "+ Add an expense") { showingAddExpense = true }
                .padding(.top, 6)
        }
        .padding(.top, 16)
    }
}
