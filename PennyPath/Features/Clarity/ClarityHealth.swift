//
//  ClarityHealth.swift
//  PennyPath
//
//  The "health check" on Clarity's Today screen: four honest signals
//  computed from the user's own data, on device. Based on the classic
//  personal-finance yardsticks — months of expenses saved (3–6 is
//  healthy), debt-to-asset ratio (under ~30% is comfortable), spending
//  pace, and budget adherence. A quick read, deliberately not a "score".
//

import SwiftUI

struct ClaritySignal: Identifiable {
    enum Status { case good, fair, poor, unknown }

    let id: String
    let title: String
    let reading: String     // the short verdict, e.g. "4.2 months saved"
    let detail: String      // one quiet line of why it matters
    let status: Status

    var tint: Color {
        switch status {
        case .good: return Clarity.good
        case .fair: return Clarity.amber
        case .poor: return Clarity.rust
        case .unknown: return Clarity.inkFaint
        }
    }
}

enum ClarityHealth {

    /// All four signals, in a stable order.
    static func signals(accounts: [Account],
                        expenses: [Expense],
                        budgets: [CategoryBudget],
                        now: Date = .now) -> [ClaritySignal] {
        [
            cushion(accounts: accounts, expenses: expenses, now: now),
            debtLoad(accounts: accounts),
            pace(expenses: expenses, now: now),
            plan(budgets: budgets, expenses: expenses, now: now)
        ]
    }

    // MARK: The four signals

    /// Liquid savings measured in months of typical spending. 3+ months
    /// is the classic emergency-fund comfort zone.
    private static func cushion(accounts: [Account], expenses: [Expense],
                                now: Date) -> ClaritySignal {
        let liquid = accounts
            .filter { $0.category == .cash || $0.category == .savings }
            .reduce(0) { $0 + $1.baseBalance }

        guard let typical = typicalMonthlySpend(expenses, now: now) else {
            return ClaritySignal(
                id: "cushion", title: "Cushion",
                reading: liquid > 0 ? "Savings in place" : "No reading yet",
                detail: "Track a month of spending to see how long your savings would carry you.",
                status: .unknown)
        }

        let months = liquid / typical
        let text = months >= 12 ? "Over a year saved"
                                : String(format: "%.1f months of expenses", months)
        let status: ClaritySignal.Status = months >= 3 ? .good : (months >= 1 ? .fair : .poor)
        return ClaritySignal(
            id: "cushion", title: "Cushion", reading: text,
            detail: "Cash and savings, measured against a typical month. Three months is a solid floor.",
            status: status)
    }

    /// What you owe against what you own. Under ~30% is comfortable.
    private static func debtLoad(accounts: [Account]) -> ClaritySignal {
        let assets = accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }
        let debts = accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }

        if debts == 0 {
            return ClaritySignal(
                id: "debt", title: "Debt load",
                reading: assets > 0 ? "Debt-free" : "No reading yet",
                detail: assets > 0 ? "Nothing owed against what you own."
                                   : "Add what you own and owe to see this.",
                status: assets > 0 ? .good : .unknown)
        }
        guard assets > 0 else {
            return ClaritySignal(
                id: "debt", title: "Debt load", reading: "Debts outweigh assets",
                detail: "What you owe currently has nothing to stand against.",
                status: .poor)
        }

        let ratio = debts / assets
        let status: ClaritySignal.Status = ratio < 0.3 ? .good : (ratio < 0.6 ? .fair : .poor)
        return ClaritySignal(
            id: "debt", title: "Debt load",
            reading: "\(percentText(ratio)) of what you own",
            detail: "All debts measured against all assets. Under 30% is comfortable.",
            status: status)
    }

    /// This month's spending against your usual pace at this point.
    private static func pace(expenses: [Expense], now: Date) -> ClaritySignal {
        let thisMonth = monthTotal(expenses, in: now)
        let lastMonth = monthTotal(expenses, in: now.adding(months: -1))
        guard lastMonth > 0 else {
            return ClaritySignal(
                id: "pace", title: "Pace",
                reading: thisMonth > 0 ? "First month of tracking" : "No reading yet",
                detail: "After a full month, spending is compared with your usual rhythm.",
                status: .unknown)
        }

        let cal = Calendar.current
        let day = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let usual = lastMonth * Double(day) / Double(daysInMonth)
        let diff = usual - thisMonth

        if abs(diff) < max(1, usual * 0.05) {
            return ClaritySignal(
                id: "pace", title: "Pace", reading: "On your usual pace",
                detail: "Spending this month is tracking right alongside last month.",
                status: .good)
        }
        return diff > 0
            ? ClaritySignal(id: "pace", title: "Pace",
                            reading: "\(money(diff)) under usual",
                            detail: "Spending slower than last month at this point.",
                            status: .good)
            : ClaritySignal(id: "pace", title: "Pace",
                            reading: "\(money(-diff)) over usual",
                            detail: "Spending faster than last month at this point.",
                            status: .fair)
    }

    /// Whether a plan exists and how many categories are holding it.
    private static func plan(budgets: [CategoryBudget], expenses: [Expense],
                             now: Date) -> ClaritySignal {
        guard !budgets.isEmpty else {
            return ClaritySignal(
                id: "plan", title: "Plan",
                reading: "No budget set",
                detail: "A monthly plan turns spending from a surprise into a choice.",
                status: .unknown)
        }
        let over = budgets.filter { budget in
            let spent = expenses
                .filter { $0.category == budget.category && $0.date.isSameMonth(as: now) }
                .reduce(0) { $0 + $1.amount }
            return spent > budget.monthlyLimit
        }.count

        if over == 0 {
            return ClaritySignal(
                id: "plan", title: "Plan",
                reading: "All \(budgets.count) categories on plan",
                detail: "Every budgeted category is still inside its monthly limit.",
                status: .good)
        }
        return ClaritySignal(
            id: "plan", title: "Plan",
            reading: "\(over) of \(budgets.count) over budget",
            detail: "A category over its limit this month deserves a look.",
            status: over > budgets.count / 2 ? .poor : .fair)
    }

    // MARK: Shared sums

    static func monthTotal(_ expenses: [Expense], in date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }

    /// Average of the last three non-empty full months; falls back to this
    /// month if history is thin. Nil when there's nothing to read.
    static func typicalMonthlySpend(_ expenses: [Expense], now: Date = .now) -> Double? {
        let past = (1...3)
            .map { monthTotal(expenses, in: now.adding(months: -$0)) }
            .filter { $0 > 0 }
        if !past.isEmpty { return past.reduce(0, +) / Double(past.count) }
        let current = monthTotal(expenses, in: now)
        return current > 0 ? current : nil
    }
}
