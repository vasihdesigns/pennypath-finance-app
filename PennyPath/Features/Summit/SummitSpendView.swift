//
//  SummitSpendView.swift
//  PennyPath
//
//  Summit's Expenses screen: step through any month's outflow, see a quiet
//  breakdown of where it went, and the full list of that month's transactions
//  (no silent cap). A Budget toggle drops in the real Budget view. Every form
//  is the real one.
//

import SwiftUI
import SwiftData

struct SummitSpendView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @AppStorage("summitHideAmounts") private var hideAmounts = false

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var showingSettings = false
    @State private var mode: Mode = .spent
    /// The month being viewed (first day of that month). Defaults to now.
    @State private var monthAnchor: Date = Date.now.startOfMonth

    enum Mode: String, CaseIterable { case spent = "Spending", budget = "Budget" }

    private var monthExpenses: [Expense] {
        expenses.filter { $0.date.isSameMonth(as: monthAnchor) }
    }
    private var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }
    private var isCurrentMonth: Bool { monthAnchor.isSameMonth(as: .now) }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        Dictionary(grouping: monthExpenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    private var segments: [SummitSegment] {
        breakdown.enumerated().map { index, item in
            SummitSegment(color: Summit.spendPalette[index % Summit.spendPalette.count],
                          value: item.amount, label: item.category.title)
        }
    }

    private func mask(_ value: Double) -> String {
        hideAmounts ? "••••••" : money(value, code: currencyCode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SummitSegmented(items: Mode.allCases, title: \.rawValue, selection: $mode)

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        firstRunEmpty
                    } else {
                        monthStepper
                        if monthExpenses.isEmpty {
                            monthEmpty
                        } else {
                            heroCard
                            if !breakdown.isEmpty { breakdownCard }
                            transactionsCard
                        }
                    }
                case .budget:
                    BudgetView().padding(.horizontal, -20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Summit.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            SummitTopBar(title: "Expenses",
                         privacy: $hideAmounts,
                         onAdd: { showingAdd = true },
                         onSettings: { showingSettings = true })
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .background(Summit.canvas)
        }
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .tint(Summit.accent)
    }

    // MARK: Month stepper

    private var monthStepper: some View {
        HStack {
            stepButton(symbol: "chevron.left", label: "Previous month") {
                withAnimation(.snappy) { monthAnchor = monthAnchor.adding(months: -1).startOfMonth }
            }
            Spacer()
            Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                .font(.summitText(15, weight: .semibold))
                .foregroundStyle(Summit.ink)
                .contentTransition(.numericText())
            Spacer()
            stepButton(symbol: "chevron.right", label: "Next month") {
                withAnimation(.snappy) { monthAnchor = monthAnchor.adding(months: 1).startOfMonth }
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.25 : 1)
        }
        .padding(6)
        .background(Summit.well, in: Capsule())
    }

    private func stepButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Summit.ink)
                .frame(width: 36, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Spending content

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SummitOverline(text: monthAnchor.formatted(.dateTime.month(.wide)) + " spending", tint: Summit.inkSoft)
            Text(mask(monthTotal))
                .font(.summitNumber(36, weight: .heavy))
                .foregroundStyle(Summit.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(monthExpenses.count) transaction\(monthExpenses.count == 1 ? "" : "s")")
                .font(.summitText(13))
                .foregroundStyle(Summit.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .summitCard(padding: 20)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SummitOverline(text: "Where it went", tint: Summit.inkSoft)
            SummitCompositionBar(segments: segments)
            VStack(spacing: 12) {
                ForEach(Array(breakdown.prefix(5).enumerated()), id: \.element.category) { index, item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Summit.spendPalette[index % Summit.spendPalette.count])
                            .frame(width: 9, height: 9)
                        Text(item.category.title)
                            .font(.summitText(14, weight: .medium))
                            .foregroundStyle(Summit.ink)
                        Spacer(minLength: 8)
                        Text(percentText(monthTotal > 0 ? item.amount / monthTotal : 0))
                            .font(.summitNumber(12, weight: .medium))
                            .foregroundStyle(Summit.inkFaint)
                        Text(mask(item.amount))
                            .font(.summitNumber(14, weight: .semibold))
                            .foregroundStyle(Summit.ink)
                            .frame(minWidth: 64, alignment: .trailing)
                    }
                }
            }
        }
        .summitCard(padding: 18)
    }

    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SummitOverline(text: "Transactions", tint: Summit.inkSoft)
            VStack(spacing: 0) {
                let rows = monthExpenses
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, expense in
                    SummitDeletableRow(
                        confirmTitle: "Delete this expense?",
                        confirmMessage: "“\(expense.displayTitle)” (\(money(expense.amount, code: currencyCode))) will be removed. This can't be undone.",
                        onEdit: { editing = expense },
                        onDelete: { context.delete(expense) }
                    ) {
                        transactionRow(expense)
                    }
                    if index < rows.count - 1 {
                        Summit.hairline.frame(height: 1).padding(.leading, 44)
                    }
                }
            }
        }
        .summitCard(padding: 18)
    }

    private func transactionRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.system(size: 15))
                .frame(width: 32, height: 32)
                .background(Summit.well, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.displayTitle)
                    .font(.summitText(15, weight: .medium))
                    .foregroundStyle(Summit.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.summitText(12))
                    .foregroundStyle(Summit.inkFaint)
            }
            Spacer(minLength: 8)
            Text("−" + mask(expense.amount))
                .font(.summitNumber(15, weight: .semibold))
                .foregroundStyle(Summit.ink)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: Empty states

    private var monthEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Summit.inkFaint)
            Text("No spending recorded in \(monthAnchor.formatted(.dateTime.month(.wide))).")
                .font(.summitText(14))
                .foregroundStyle(Summit.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .summitCard(padding: 26)
    }

    private var firstRunEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Summit.accent)
            Text("Track what you spend")
                .font(.summitSerif(22, weight: .semibold))
                .foregroundStyle(Summit.ink)
            Text("Log an expense to see where your money goes — clarity is the first step to keeping more of it.")
                .font(.summitText(14))
                .foregroundStyle(Summit.inkSoft)
                .multilineTextAlignment(.center)
            SummitPrimaryButton(title: "Add an expense", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .summitCard(padding: 28)
        .padding(.top, 8)
    }
}
