//
//  PrismSpendView.swift
//  PennyPath
//
//  Prism reskin of Spending: the month's outflow up top, where it went as a
//  grid of hue-coded gradient tiles, then the transaction list. Budget mode
//  and every form are the real ones.
//

import SwiftUI
import SwiftData

struct PrismSpendView: View {
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

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

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
                        if !breakdown.isEmpty {
                            PrismOverline(text: "Where it went")
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(breakdown.prefix(6).enumerated()), id: \.element.category) { index, item in
                                    breakdownTile(index: index, category: item.category, amount: item.amount)
                                }
                            }
                        }
                        transactionsCard
                    }
                case .budget:
                    BudgetView().padding(.horizontal, -18)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Prism.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .tint(Prism.accent)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Spending")
                .font(.prismDisplay(24))
                .foregroundStyle(Prism.ink)
            Spacer()
            PrismPills(items: Mode.allCases, title: \.rawValue, selection: $mode)
                .frame(width: 160)
            PrismPlusButton { showingAdd = true }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            PrismOverline(text: Date.now.formatted(.dateTime.month(.wide)) + " spending")
            Text(money(monthTotal))
                .font(.prismAmount(38, weight: .heavy))
                .foregroundStyle(Prism.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func breakdownTile(index: Int, category: ExpenseCategory, amount: Double) -> some View {
        let share = monthTotal > 0 ? amount / monthTotal : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji).font(.system(size: 18))
                Spacer(minLength: 4)
                Text(percentText(share))
                    .font(.system(.caption).weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(money(amount))
                    .font(.prismAmount(17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismGradientCard(Prism.chartGradient(index), padding: 14)
    }

    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            PrismOverline(text: "Transactions", tint: Prism.inkSoft)
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
                        Prism.hairline.frame(height: 1).padding(.leading, 46)
                    }
                }
            }
        }
        .prismSurfaceCard(padding: 16)
    }

    private func transactionRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.footnote)
                .frame(width: 34, height: 34)
                .background(Prism.well, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.displayTitle)
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(Prism.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption).foregroundStyle(Prism.inkSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount))
                .font(.prismAmount(15, weight: .bold))
                .foregroundStyle(Prism.ink)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 38)).foregroundStyle(Prism.accent)
            Text("Track your spending")
                .font(.prismDisplay(21)).foregroundStyle(Prism.ink)
            Text("Log what you spend and watch it break down by category — each in its own colour.")
                .font(.subheadline).foregroundStyle(Prism.inkSoft)
                .multilineTextAlignment(.center)
            PrismPrimaryButton(title: "Add an expense", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .prismSurfaceCard(padding: 26)
        .padding(.top, 20)
    }
}
