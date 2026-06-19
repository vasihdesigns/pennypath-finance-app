//
//  EmberExpensesView.swift
//  PennyPath
//
//  Ember's Expenses screen on real data: what you spent this month, where it
//  went, and a running day-by-day list. A Budget toggle drops in the real
//  Budget editor. Every form is the real one.
//

import SwiftUI
import SwiftData

struct EmberExpensesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var showingSettings = false
    @State private var mode: Mode = .spent
    /// Flipped by the floating + when on the Upcoming tab, handled inside it.
    @State private var upcomingAddRequested = false

    enum Mode: String, CaseIterable, Identifiable {
        case spent = "Spending", upcoming = "Upcoming", budget = "Budget"
        var id: String { rawValue }
    }

    private func monthTotal(_ date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }
    private var thisMonth: Double { monthTotal(.now) }
    private var lastMonth: Double { monthTotal(.now.adding(months: -1)) }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let monthly = expenses.filter { $0.date.isSameMonth(as: .now) }
        return Dictionary(grouping: monthly, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    private var dayGroups: [(day: Date, items: [Expense])] {
        Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EmberHeader(title: "Expenses") { showingSettings = true }
                EmberSegmented(items: Mode.allCases, title: \.rawValue, selection: $mode)

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        emptyCard
                    } else {
                        heroCard
                        if !breakdown.isEmpty { breakdownCard }
                        recentList
                    }
                case .upcoming:
                    EmberUpcomingView(addRequested: $upcomingAddRequested)
                case .budget:
                    EmberBudgetView()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Ember.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            if mode != .budget {
                EmberPlusButton {
                    if mode == .upcoming { upcomingAddRequested = true }
                    else { showingAdd = true }
                }
                .padding(.trailing, 22)
                .padding(.bottom, 58)   // sit just above the floating tab bar
            }
        }
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SPENT THIS MONTH")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Ember.onCanvasSoft)
            Text(money(thisMonth, code: currencyCode))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Ember.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            comparisonChip
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .emberPanel(padding: 20)
    }

    @ViewBuilder private var comparisonChip: some View {
        if lastMonth > 0 {
            let change = (thisMonth - lastMonth) / lastMonth
            let down = change <= 0
            let color = down ? Ember.good : Ember.spend
            HStack(spacing: 5) {
                Image(systemName: down ? "arrow.down.right" : "arrow.up.right")
                Text("\(percentText(abs(change))) vs last month")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(color.opacity(0.16), in: Capsule())
        } else {
            Text("Your first month — keep it up!")
                .font(.system(size: 13))
                .foregroundStyle(Ember.onCanvasSoft)
        }
    }

    // MARK: Breakdown

    private var breakdownCard: some View {
        let maxValue = breakdown.first?.amount ?? 1
        return VStack(alignment: .leading, spacing: 14) {
            Text("Where it went")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            ForEach(breakdown, id: \.category) { item in
                HStack(spacing: 12) {
                    Text(item.category.emoji).font(.title3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.category.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Ember.onCanvas)
                        EmberBar(value: item.amount / maxValue)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(money(item.amount, code: currencyCode))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Ember.onCanvas)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(percentText(thisMonth > 0 ? item.amount / thisMonth : 0))
                            .font(.system(size: 11))
                            .foregroundStyle(Ember.onCanvasSoft)
                    }
                    .frame(width: 84, alignment: .trailing)
                }
            }
        }
        .emberPanel()
    }

    // MARK: Recent

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            ForEach(dayGroups, id: \.day) { group in
                let dayTotal = group.items.reduce(0) { $0 + $1.amount }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.day.friendlyDay)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Ember.onCanvasSoft)
                        Spacer()
                        Text(money(dayTotal, code: currencyCode))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Ember.onCanvasSoft)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, expense in
                            Button { editing = expense } label: { row(expense) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Edit") { editing = expense }
                                    Button("Delete", role: .destructive) { context.delete(expense) }
                                }
                            if index < group.items.count - 1 {
                                Rectangle()
                                    .fill(Ember.onCanvasSoft.opacity(0.18))
                                    .frame(height: 1)
                                    .padding(.leading, 46)
                            }
                        }
                    }
                    .emberPanel(padding: 6)
                }
            }
        }
    }

    private func row(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category.emoji)
                .font(.system(size: 16))
                .frame(width: 34, height: 34)
                .background(Ember.onCanvasSoft.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Ember.onCanvas)
                    .lineLimit(1)
                Text(expense.category.title)
                    .font(.system(size: 12))
                    .foregroundStyle(Ember.onCanvasSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount, code: currencyCode))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Ember.spend)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }

    // MARK: Empty

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Ember.accentSoft)
            Text("Track your first expense")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            Text("Every time you spend, jot it down. Soon you'll see exactly where your money goes.")
                .font(.system(size: 14))
                .foregroundStyle(Ember.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add an expense")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Ember.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Ember.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .emberPanel(padding: 28)
        .padding(.top, 8)
    }
}

// MARK: - Small shared pieces

/// A thin progress bar in the Ember palette.
private struct EmberBar: View {
    var value: Double                  // 0…1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Ember.onCanvasSoft.opacity(0.22))
                Capsule().fill(Ember.accentSoft)
                    .frame(width: max(6, min(1, max(0, value)) * geo.size.width))
            }
        }
        .frame(height: 8)
    }
}

/// Segmented pill control in the Ember palette (active = taupe).
struct EmberSegmented<T: Hashable>: View {
    let items: [T]
    let title: (T) -> String
    @Binding var selection: T
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 3) {
            ForEach(items, id: \.self) { item in
                let on = item == selection
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(on ? Ember.plusInk : Ember.onCanvasSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background { if on { Capsule().fill(Ember.accentSoft) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Ember.glassFill(dark: scheme == .dark), in: Capsule())
    }
}
