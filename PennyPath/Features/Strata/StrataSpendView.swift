//
//  StrataSpendView.swift
//  PennyPath
//
//  Strata reskin of Spending ("Cash Flow"): the month's outflow up top, the
//  same proportional-band treatment for where it went, then the running list
//  of transactions. Budget mode and every form are the real ones.
//

import SwiftUI
import SwiftData

struct StrataSpendView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var mode: Mode = .spent

    enum Mode: String, CaseIterable { case spent = "Spent", budget = "Budget" }

    private var monthExpenses: [Expense] {
        expenses.filter { $0.date.isSameMonth(as: .now) }
    }
    private var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let totals = Dictionary(grouping: monthExpenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    private var bands: [StrataBand] {
        guard monthTotal > 0 else { return [] }
        return breakdown.enumerated().map { index, item in
            StrataBand(color: Strata.chartPalette[index % Strata.chartPalette.count],
                       label: item.category.title, value: item.amount,
                       share: item.amount / monthTotal, isLiability: false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        emptyCard
                    } else {
                        hero
                        if !bands.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                StrataOverline(text: "Where it went", tint: Strata.inkSoft)
                                StrataComposition(bands: bands, assetsHeight: 180)
                            }
                            .strataCard(padding: 16)
                        }
                        transactionsCard
                    }
                case .budget:
                    BudgetView().padding(.horizontal, -18)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Strata.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .tint(Strata.bg)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Cash Flow")
                .font(.strataDisplay(22))
                .foregroundStyle(Strata.onBrand)
            Spacer()
            StrataPills(items: Mode.allCases, title: \.rawValue, selection: $mode)
                .frame(width: 168)
            StrataPlusButton { showingAdd = true }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            StrataOverline(text: Date.now.formatted(.dateTime.month(.wide)) + " spending")
            Text(money(monthTotal))
                .font(.strataAmount(36, weight: .heavy))
                .foregroundStyle(Strata.onBrand)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            StrataOverline(text: "Transactions", tint: Strata.inkSoft)
            VStack(spacing: 0) {
                let rows = Array(monthExpenses.prefix(30))
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, expense in
                    Button { editing = expense } label: {
                        transactionRow(expense)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = expense }
                        Button("Delete", role: .destructive) { context.delete(expense) }
                    }
                    if index < rows.count - 1 {
                        Strata.hairline.frame(height: 1).padding(.leading, 46)
                    }
                }
            }
        }
        .strataCard(padding: 16)
    }

    private func transactionRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.footnote)
                .frame(width: 34, height: 34)
                .background(Strata.well, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.displayTitle)
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(Strata.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption).foregroundStyle(Strata.inkSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount))
                .font(.strataAmount(15, weight: .bold))
                .foregroundStyle(Strata.ink)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 38)).foregroundStyle(Strata.bg)
            Text("Track your cash flow")
                .font(.strataDisplay(21)).foregroundStyle(Strata.ink)
            Text("Log what comes in and goes out, and watch it break down by category — clean and clear.")
                .font(.subheadline).foregroundStyle(Strata.inkSoft)
                .multilineTextAlignment(.center)
            StrataPrimaryButton(title: "Add an expense", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .strataCard(padding: 26)
        .padding(.top, 20)
    }
}
