//
//  ExpensesView.swift
//  PennyPath
//
//  The RED pillar. What you spent this month, where it went, and a running list.
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var mode: SpendMode = .spent

    enum SpendMode: String, CaseIterable, Identifiable {
        case spent = "Spent"
        case budget = "Budget"
        var id: String { rawValue }
    }

    private func monthTotal(_ date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }
    private var thisMonth: Double { monthTotal(.now) }
    private var lastMonth: Double { monthTotal(.now.adding(months: -1)) }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let monthly = expenses.filter { $0.date.isSameMonth(as: .now) }
        let totals = Dictionary(grouping: monthly, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    private var dayGroups: [(day: Date, items: [Expense])] {
        let groups = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        return groups
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $mode) {
                ForEach(SpendMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Space.lg)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, Theme.Space.md)

            switch mode {
            case .spent: spendingTab
            case .budget: BudgetView()
            }
        }
        .background(Theme.background)
        .navigationTitle("Spending")
        .toolbar {
            if mode == .spent {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .tint(Theme.red)
    }

    private var spendingTab: some View {
        ScrollView {
            if expenses.isEmpty {
                EmptyState(
                    emoji: "🧾",
                    title: "Track your first expense",
                    message: "Every time you spend, jot it down. Soon you'll see exactly where your money goes.",
                    actionTitle: "Add an expense",
                    tint: Theme.red
                ) { showingAdd = true }
            } else {
                VStack(spacing: Theme.Space.lg) {
                    hero
                    if !breakdown.isEmpty { breakdownCard }
                    recentList
                }
                .padding(Theme.Space.lg)
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Theme.Space.md) {
            Text("SPENT THIS MONTH")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(1)
            Text(money(thisMonth))
                .font(.amount(46))
                .foregroundStyle(Theme.red)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            comparisonChip
        }
        .frame(maxWidth: .infinity)
        .card(padding: Theme.Space.xl)
    }

    @ViewBuilder private var comparisonChip: some View {
        if lastMonth > 0 {
            let change = (thisMonth - lastMonth) / lastMonth
            let down = change <= 0
            let color = down ? Theme.green : Theme.red
            HStack(spacing: 5) {
                Image(systemName: down ? "arrow.down.right" : "arrow.up.right")
                Text("\(percentText(abs(change))) vs last month")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(color.opacity(0.14), in: Capsule())
        } else {
            Text("Your first month — keep it up!")
                .font(.footnote)
                .foregroundStyle(Theme.inkTertiary)
        }
    }

    // MARK: Breakdown

    private var breakdownCard: some View {
        let maxValue = breakdown.first?.amount ?? 1
        return VStack(alignment: .leading, spacing: Theme.Space.md) {
            Text("Where it went")
                .font(.display(18))
                .foregroundStyle(Theme.ink)
            ForEach(breakdown, id: \.category) { item in
                HStack(spacing: Theme.Space.md) {
                    Text(item.category.emoji).font(.title3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.category.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.ink)
                        ProgressBar(value: item.amount / maxValue, tint: Theme.red, height: 8)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(money(item.amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(percentText(item.amount / thisMonth))
                            .font(.caption2)
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    .frame(width: 90, alignment: .trailing)
                }
            }
        }
        .card()
    }

    // MARK: Recent

    private var recentList: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Recent")
            ForEach(dayGroups, id: \.day) { group in
                let dayTotal = group.items.reduce(0) { $0 + $1.amount }
                VStack(alignment: .leading, spacing: Theme.Space.sm) {
                    HStack {
                        Text(group.day.friendlyDay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                        Spacer()
                        Text(money(dayTotal))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, expense in
                            Button { editing = expense } label: {
                                ExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") { editing = expense }
                                Button("Delete", role: .destructive) { context.delete(expense) }
                            }
                            if index < group.items.count - 1 {
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                    .card(padding: Theme.Space.md)
                }
            }
        }
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: expense.category.emoji, tint: Theme.red, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(expense.category.title)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: Theme.Space.sm)
            Text("−" + money(expense.amount))
                .font(.amount(17))
                .foregroundStyle(Theme.red)
        }
        .padding(.vertical, 8)
    }
}
