//
//  VividSpendView.swift
//  PennyPath
//
//  Vivid reskin of Spending: a month toggle, the month's total as a split
//  hero inside a category donut, a color-coded legend, and the running list
//  of expenses. Budget mode and every form are the real ones.
//

import SwiftUI
import SwiftData

struct VividSpendView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var mode: Mode = .spent
    @State private var range: Range = .thisMonth

    enum Mode: String, CaseIterable { case spent = "Spent", budget = "Budget" }
    enum Range: CaseIterable { case thisMonth, lastMonth
        var title: String { self == .thisMonth ? "This month" : "Last month" }
    }

    // MARK: Numbers

    private var monthDate: Date { range == .thisMonth ? .now : .now.adding(months: -1) }
    private var monthExpenses: [Expense] {
        expenses.filter { $0.date.isSameMonth(as: monthDate) }
    }
    private var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }

    /// Compare this month against last month's pace at the same day.
    private var paceLine: (text: String, over: Bool)? {
        guard range == .thisMonth else { return nil }
        let lastMonth = expenses
            .filter { $0.date.isSameMonth(as: .now.adding(months: -1)) }
            .reduce(0) { $0 + $1.amount }
        guard lastMonth > 0 else { return nil }
        let cal = Calendar.current
        let day = cal.component(.day, from: .now)
        let daysInMonth = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        let usualPace = lastMonth * Double(day) / Double(daysInMonth)
        let diff = usualPace - monthTotal
        if abs(diff) < 1 { return ("Right on your usual pace", false) }
        return diff > 0
            ? ("\(money(diff)) under your usual pace", false)
            : ("\(money(-diff)) over your usual pace", true)
    }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let totals = Dictionary(grouping: monthExpenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        emptyCard
                    } else {
                        VividPills(items: Range.allCases, title: \.title, selection: $range)
                        donutCard
                        if monthExpenses.isEmpty {
                            quietNote("Nothing logged \(range == .thisMonth ? "yet this month" : "last month").")
                        } else {
                            recentCard
                        }
                    }
                case .budget:
                    BudgetView()
                        .padding(.horizontal, -20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Vivid.bg)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .tint(Vivid.violet)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                VividOverline(text: "Spending")
                Text(monthDate.formatted(.dateTime.month(.wide)))
                    .font(.vividDisplay(24))
                    .foregroundStyle(Vivid.ink)
            }
            Spacer()
            VividPills(items: Mode.allCases, title: \.rawValue, selection: $mode)
        }
    }

    // MARK: Donut + legend

    private struct Slice: Identifiable {
        let id = UUID()
        let color: Color
        let start: Double
        let end: Double
    }

    private var slices: [Slice] {
        let total = max(monthTotal, 0.0001)
        var acc = 0.0
        return breakdown.enumerated().map { index, item in
            let frac = item.amount / total
            let slice = Slice(color: Vivid.chartPalette[index % Vivid.chartPalette.count],
                              start: acc, end: acc + frac)
            acc += frac
            return slice
        }
    }

    private var donutCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(Vivid.well, lineWidth: 22)
                ForEach(slices) { slice in
                    Circle()
                        .trim(from: slice.start, to: max(slice.start, slice.end - 0.005))
                        .stroke(slice.color,
                                style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 3) {
                    VividOverline(text: "Spent")
                    VividAmount(value: monthTotal, size: 30)
                    if let pace = paceLine {
                        Text(pace.text)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(pace.over ? Vivid.coral : Vivid.inkSoft)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 130)
                    }
                }
            }
            .frame(width: 210, height: 210)
            .frame(maxWidth: .infinity)
            // The legend below names every category and amount; the ring is
            // decoration for VoiceOver.
            .accessibilityHidden(true)

            if !breakdown.isEmpty { legend }
        }
        .vividCard(padding: 22)
    }

    private var legend: some View {
        let columns = [GridItem(.adaptive(minimum: 140), alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Array(breakdown.enumerated()), id: \.element.category) { index, item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Vivid.chartPalette[index % Vivid.chartPalette.count])
                        .frame(width: 9, height: 9)
                    Text(item.category.title)
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundStyle(Vivid.ink)
                    Spacer(minLength: 4)
                    Text(money(item.amount))
                        .font(.vividAmount(13, weight: .semibold))
                        .foregroundStyle(Vivid.inkSoft)
                }
            }
        }
    }

    // MARK: Recent list (tap to edit, hold to delete — same as the real tab)

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VividOverline(text: "Transactions")
            VStack(spacing: 0) {
                let rows = Array(monthExpenses.prefix(30))
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, expense in
                    Button { editing = expense } label: {
                        expenseRow(expense)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = expense }
                        Button("Delete", role: .destructive) { context.delete(expense) }
                    }
                    if index < rows.count - 1 {
                        Vivid.hairline.frame(height: 1).padding(.leading, 64)
                    }
                }
            }
            .vividCard(padding: 8)
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.body)
                .frame(width: 42, height: 42)
                .background(Vivid.coral.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.displayTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Vivid.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption)
                    .foregroundStyle(Vivid.inkSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount))
                .font(.vividAmount(16, weight: .semibold))
                .foregroundStyle(Vivid.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func quietNote(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(Vivid.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    // MARK: Empty state

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Text("🧾").font(.system(size: 44))
            Text("Track your first expense")
                .font(.vividDisplay(22))
                .foregroundStyle(Vivid.ink)
            Text("Tap the + below whenever you spend. Soon you'll see exactly where your money goes.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Vivid.inkSoft)
                .multilineTextAlignment(.center)
            VividPrimaryButton(title: "Add an expense", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .vividCard(padding: 28)
        .padding(.top, 24)
    }
}
