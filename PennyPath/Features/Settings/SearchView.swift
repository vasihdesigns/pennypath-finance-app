//
//  SearchView.swift
//  PennyPath
//
//  Settings → Search. One field that looks across everything the user has added —
//  accounts, investments, goals, logged spending, upcoming payments, and budgets —
//  and lists the matches grouped by kind. Tapping a result opens its real editor,
//  so search doubles as a fast way to jump straight to any item. Reached from
//  SettingsView.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    // Active items only — archived ones live in the Archived screen.
    @Query(filter: #Predicate<Account> { !$0.isArchived },
           sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query(sort: \Holding.cachedValueInBase, order: .reverse) private var holdings: [Holding]
    @Query(filter: #Predicate<Goal> { !$0.isArchived },
           sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \UpcomingPayment.nextDueDate, order: .forward) private var payments: [UpcomingPayment]
    @Query private var budgets: [CategoryBudget]

    @State private var query = ""

    // Each opens the item's real editor.
    @State private var editingAccount: Account?
    @State private var editingGoal: Goal?
    @State private var editingExpense: Expense?
    @State private var editingPayment: UpcomingPayment?
    @State private var editingHolding: Holding?

    private var q: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func hit(_ strings: String...) -> Bool {
        !q.isEmpty && strings.contains { $0.localizedCaseInsensitiveContains(q) }
    }

    // MARK: Matches

    private var matchedAccounts: [Account] {
        accounts.filter { hit($0.name, $0.institution, $0.counterparty, $0.notes, $0.category.title) }
    }
    private var matchedHoldings: [Holding] {
        holdings.filter { hit($0.symbol, $0.companyName) }
    }
    private var matchedGoals: [Goal] {
        goals.filter { hit($0.name) }
    }
    private var matchedExpenses: [Expense] {
        expenses.filter { hit($0.note, $0.category.title) }
    }
    private var matchedPayments: [UpcomingPayment] {
        payments.filter { hit($0.name, $0.note, $0.category?.title ?? "") }
    }
    private var matchedBudgets: [CategoryBudget] {
        budgets.filter { hit($0.category.title) }
    }

    private var hasAnyMatch: Bool {
        !matchedAccounts.isEmpty || !matchedHoldings.isEmpty || !matchedGoals.isEmpty
            || !matchedExpenses.isEmpty || !matchedPayments.isEmpty || !matchedBudgets.isEmpty
    }

    // MARK: Body

    var body: some View {
        List {
            if !matchedAccounts.isEmpty {
                Section("Accounts") { ForEach(matchedAccounts) { accountRow($0) } }
            }
            if !matchedHoldings.isEmpty {
                Section("Investments") { ForEach(matchedHoldings) { holdingRow($0) } }
            }
            if !matchedGoals.isEmpty {
                Section("Goals") { ForEach(matchedGoals) { goalRow($0) } }
            }
            if !matchedExpenses.isEmpty {
                Section("Spending") { ForEach(matchedExpenses) { expenseRow($0) } }
            }
            if !matchedPayments.isEmpty {
                Section("Upcoming") { ForEach(matchedPayments) { paymentRow($0) } }
            }
            if !matchedBudgets.isEmpty {
                Section("Budgets") { ForEach(matchedBudgets) { budgetRow($0) } }
            }
        }
        .searchable(text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search accounts, goals, spending…")
        .autocorrectionDisabled()
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.ink)
        .overlay { overlay }
        .sheet(item: $editingAccount) { SpectrumEditAccountView(account: $0) }
        .sheet(item: $editingGoal) { GoalFormView(goal: $0) }
        .sheet(item: $editingExpense) { SpectrumAddItemView(expense: $0) }
        .sheet(item: $editingPayment) { SpectrumAddItemView(payment: $0) }
        .sheet(item: $editingHolding) { holding in
            NavigationStack { HoldingFormView(holding: holding) }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if q.isEmpty {
            ContentUnavailableView("Find anything",
                                   systemImage: "magnifyingglass",
                                   description: Text("Search your accounts, investments, goals, spending, and upcoming payments by name."))
        } else if !hasAnyMatch {
            ContentUnavailableView.search(text: query)
        }
    }

    // MARK: Rows

    private func accountRow(_ a: Account) -> some View {
        resultRow(emoji: a.category.emoji, title: a.name,
                  subtitle: a.institution.isEmpty ? a.category.title : "\(a.category.title) · \(a.institution)",
                  trailing: money(a.balance, code: a.displayCurrencyCode),
                  trailingTint: a.category.isAsset ? Theme.ink : Theme.red) {
            editingAccount = a
        }
    }

    private func holdingRow(_ h: Holding) -> some View {
        resultRow(emoji: "📈", title: h.symbol,
                  subtitle: h.companyName.isEmpty ? "Investment" : h.companyName,
                  trailing: money(h.cachedValueInBase, code: currencyCode)) {
            editingHolding = h
        }
    }

    private func goalRow(_ g: Goal) -> some View {
        resultRow(emoji: g.emoji, title: g.name,
                  subtitle: g.isComplete ? "Goal · reached" : "Goal · \(percentText(g.progress)) saved",
                  trailing: money(g.targetAmount, code: currencyCode)) {
            editingGoal = g
        }
    }

    private func expenseRow(_ e: Expense) -> some View {
        resultRow(emoji: e.category.emoji, title: e.displayTitle,
                  subtitle: "\(e.category.title) · \(e.date.formatted(.dateTime.month(.abbreviated).day()))",
                  trailing: money(e.amount, code: currencyCode),
                  trailingTint: Theme.red) {
            editingExpense = e
        }
    }

    private func paymentRow(_ p: UpcomingPayment) -> some View {
        let cycle = p.isSubscription
            ? "every \(p.cycleInterval == 1 ? "" : "\(p.cycleInterval) ")\(CycleUnit(rawValue: p.cycleUnitRaw)?.title.lowercased() ?? "month")"
            : "due \(p.nextDueDate.formatted(.dateTime.month(.abbreviated).day()))"
        return resultRow(emoji: p.category?.emoji ?? "🔁", title: p.name,
                         subtitle: cycle,
                         trailing: money(p.amount, code: currencyCode)) {
            editingPayment = p
        }
    }

    private func budgetRow(_ b: CategoryBudget) -> some View {
        // Budgets are edited inline on the Budget tab, so this is informational.
        resultRow(emoji: b.category.emoji, title: "\(b.category.title) budget",
                  subtitle: "Monthly limit",
                  trailing: money(b.monthlyLimit, code: currencyCode))
    }

    /// One result row. With an `action` it's a tappable button that opens the
    /// item's editor; without one it's a plain informational row.
    private func resultRow(emoji: String, title: String, subtitle: String,
                           trailing: String, trailingTint: Color = Theme.ink,
                           action: (() -> Void)? = nil) -> some View {
        let content = HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: emoji, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Theme.ink).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(Theme.inkSecondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(trailing)
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(trailingTint)
                .lineLimit(1)
        }
        .contentShape(Rectangle())

        return Group {
            if let action {
                Button(action: action) { content }.buttonStyle(.plain)
            } else {
                content
            }
        }
    }
}
