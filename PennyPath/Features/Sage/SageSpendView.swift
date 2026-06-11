//
//  SageSpendView.swift
//  PennyPath
//
//  Sage reskin of Spending: the month's total up top, how it compares to
//  your usual pace, one stacked bar of where it went, and the running
//  list of expenses. Budget mode and all the forms are the real ones.
//

import SwiftUI
import SwiftData

struct SageSpendView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var mode: Mode = .spent

    enum Mode: String, CaseIterable { case spent = "Spent", budget = "Budget" }

    // MARK: Numbers

    private func monthTotal(_ date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }
    private var thisMonth: Double { monthTotal(.now) }
    private var lastMonth: Double { monthTotal(.now.adding(months: -1)) }

    /// Compare against last month's pace at the same point in the month.
    private var paceLine: (text: String, over: Bool)? {
        guard lastMonth > 0 else { return nil }
        let cal = Calendar.current
        let day = cal.component(.day, from: .now)
        let daysInMonth = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        let usualPace = lastMonth * Double(day) / Double(daysInMonth)
        let diff = usualPace - thisMonth
        if abs(diff) < 1 { return (text: "Right on your usual pace", over: false) }
        return diff > 0
            ? (text: "\(money(diff)) under your usual pace", over: false)
            : (text: "\(money(-diff)) over your usual pace", over: true)
    }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let monthly = expenses.filter { $0.date.isSameMonth(as: .now) }
        let totals = Dictionary(grouping: monthly, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        emptyCard
                    } else {
                        hero
                        if !breakdown.isEmpty { stackedBar }
                        recentCard
                    }
                case .budget:
                    BudgetView()
                        .padding(.horizontal, -22)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Sage.bg)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .tint(Sage.green)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            SageOverline(text: Date.now.formatted(.dateTime.month(.wide)) + " spending")
            Spacer()
            modePills
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Sage.inkSoft)
            }
            .padding(.leading, 6)
        }
    }

    private var modePills: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy) { mode = item }
                } label: {
                    Text(item.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(mode == item ? Sage.green : Sage.inkSoft)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background {
                            if mode == item {
                                Capsule().stroke(Sage.green.opacity(0.45), lineWidth: 1.2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(money(thisMonth))
                .font(.sageAmount(44))
                .foregroundStyle(Sage.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let pace = paceLine {
                Text(pace.text)
                    .font(.subheadline)
                    .foregroundStyle(pace.over ? Sage.terracotta : Sage.inkSoft)
            } else {
                Text("Your first month — keep it up!")
                    .font(.subheadline)
                    .foregroundStyle(Sage.inkSoft)
            }
        }
    }

    // MARK: Stacked category bar + legend

    private var stackedBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                let total = max(thisMonth, 0.0001)
                let gap: CGFloat = 5
                let usable = geo.size.width - gap * CGFloat(max(breakdown.count - 1, 0))
                HStack(spacing: gap) {
                    ForEach(Array(breakdown.enumerated()), id: \.element.category) { index, item in
                        Capsule()
                            .fill(Sage.chartPalette[index % Sage.chartPalette.count])
                            .frame(width: max(usable * item.amount / total, 8))
                    }
                }
            }
            .frame(height: 14)

            legend
        }
    }

    private var legend: some View {
        let columns = [GridItem(.adaptive(minimum: 130), alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(breakdown.enumerated()), id: \.element.category) { index, item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Sage.chartPalette[index % Sage.chartPalette.count])
                        .frame(width: 7, height: 7)
                    Text(item.category.title)
                        .font(.caption)
                        .foregroundStyle(Sage.ink)
                    Text(money(item.amount))
                        .font(.caption)
                        .foregroundStyle(Sage.inkSoft)
                }
            }
        }
    }

    // MARK: Recent list (tap to edit, hold to delete — same as the real tab)

    private var recentCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(expenses.prefix(30).enumerated()), id: \.element.id) { index, expense in
                Button { editing = expense } label: {
                    expenseRow(expense)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit") { editing = expense }
                    Button("Delete", role: .destructive) { context.delete(expense) }
                }
                if index < min(expenses.count, 30) - 1 {
                    Sage.hairline.frame(height: 1)
                }
            }
        }
        .sageCard(padding: 8)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Sage.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption)
                    .foregroundStyle(Sage.inkSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount))
                .font(.sageAmount(16))
                .foregroundStyle(Sage.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    // MARK: Empty state

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Text("🧾").font(.system(size: 40))
            Text("Track your first expense")
                .font(.sageDisplay(20))
                .foregroundStyle(Sage.ink)
            Text("Every time you spend, jot it down. Soon you'll see exactly where your money goes.")
                .font(.subheadline)
                .foregroundStyle(Sage.inkSoft)
                .multilineTextAlignment(.center)
            Button { showingAdd = true } label: {
                Text("Add an expense")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Sage.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .sageCard(padding: 28)
        .padding(.top, 30)
    }
}
