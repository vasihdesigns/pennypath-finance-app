//
//  DemoData.swift
//  PennyPath
//
//  A richer, "show-off" world used by Demo Mode — more accounts, several months
//  of spending, and a mix of goals so every screen looks full and alive.
//

import Foundation
import SwiftData

enum DemoData {
    static func fill(_ context: ModelContext) {
        let now = Date.now

        // Accounts — a healthy mix of things owned and owed.
        let accounts: [Account] = [
            Account(name: "Checking", category: .cash, balance: 2_450),
            Account(name: "Everyday Savings", category: .savings, balance: 8_900),
            Account(name: "Emergency Fund", category: .savings, balance: 6_000),
            Account(name: "Retirement", category: .investment, balance: 22_400),
            Account(name: "Car", category: .property, balance: 12_000),
            Account(name: "Credit Card", category: .creditCard, balance: 1_180),
            Account(name: "Car Loan", category: .loan, balance: 7_500),
            Account(name: "Student Loan", category: .loan, balance: 9_300)
        ]
        accounts.forEach { context.insert($0) }

        // Investments — real symbols; live prices replace these on first refresh.
        let holdings: [Holding] = [
            Holding(symbol: "AAPL", companyName: "Apple Inc.", shares: 20,
                    cachedPrice: 190, cachedChangePercent: 0.012, cachedValueInBase: 3_800),
            Holding(symbol: "MSFT", companyName: "Microsoft Corp.", shares: 10,
                    cachedPrice: 415, cachedChangePercent: 0.008, cachedValueInBase: 4_150),
            Holding(symbol: "NVDA", companyName: "NVIDIA Corp.", shares: 25,
                    cachedPrice: 120, cachedChangePercent: 0.021, cachedValueInBase: 3_000),
            Holding(symbol: "GOOGL", companyName: "Alphabet Inc.", shares: 15,
                    cachedPrice: 175, cachedChangePercent: -0.006, cachedValueInBase: 2_625),
            Holding(symbol: "AMZN", companyName: "Amazon.com Inc.", shares: 9,
                    cachedPrice: 185, cachedChangePercent: 0.004, cachedValueInBase: 1_665)
        ]
        holdings.forEach { context.insert($0) }
        Investments.rebuild(holdings: holdings, in: context)

        // Expenses across three months. This month is calmer than last month
        // so the coach has something cheerful to say. Dates are anchored to
        // month starts so the story holds on any install date.
        func thisMonth(_ amount: Double, _ category: ExpenseCategory, _ note: String, daysAgo: Int) {
            let date = max(now.adding(days: -daysAgo), now.startOfMonth)
            context.insert(Expense(amount: amount, category: category, note: note, date: date))
        }
        func monthAgo(_ amount: Double, _ category: ExpenseCategory, _ note: String, months: Int, day: Int) {
            let cal = Calendar.current
            let base = now.adding(months: -months).startOfMonth
            let maxDay = cal.range(of: .day, in: .month, for: base)?.count ?? 28
            let date = cal.date(byAdding: .day, value: min(day, maxDay) - 1, to: base) ?? base
            context.insert(Expense(amount: amount, category: category, note: note, date: date))
        }
        // This month
        thisMonth(16.00, .food, "Lunch", daysAgo: 0)
        thisMonth(9.50, .transport, "Bus pass", daysAgo: 1)
        thisMonth(24.99, .fun, "New game", daysAgo: 2)
        thisMonth(58.40, .food, "Groceries", daysAgo: 3)
        thisMonth(34.00, .health, "Pharmacy", daysAgo: 5)
        thisMonth(45.00, .shopping, "T-shirt", daysAgo: 6)
        thisMonth(72.00, .bills, "Phone + internet", daysAgo: 8)
        thisMonth(13.25, .food, "Smoothie", daysAgo: 9)
        thisMonth(28.00, .transport, "Gas", daysAgo: 11)
        // Last month
        monthAgo(62.00, .food, "Groceries", months: 1, day: 24)
        monthAgo(40.00, .transport, "Gas", months: 1, day: 20)
        monthAgo(55.00, .fun, "Concert ticket", months: 1, day: 16)
        monthAgo(120.00, .shopping, "Sneakers", months: 1, day: 12)
        monthAgo(72.00, .bills, "Phone + internet", months: 1, day: 8)
        monthAgo(48.00, .food, "Dinner out", months: 1, day: 5)
        monthAgo(95.00, .home, "Desk lamp", months: 1, day: 2)
        // Two months ago
        monthAgo(60.00, .food, "Groceries", months: 2, day: 22)
        monthAgo(38.00, .health, "Dentist", months: 2, day: 17)
        monthAgo(72.00, .bills, "Phone + internet", months: 2, day: 10)
        monthAgo(150.00, .fun, "Theme park", months: 2, day: 6)
        monthAgo(42.00, .transport, "Gas", months: 2, day: 2)

        // Goals — one finished, two in progress, one big and far off.
        let goals: [Goal] = [
            Goal(name: "New Bike", emoji: "🚲", targetAmount: 600, savedAmount: 420,
                 targetDate: now.adding(months: 3)),
            Goal(name: "Japan Trip", emoji: "✈️", targetAmount: 4_000, savedAmount: 1_250,
                 targetDate: now.adding(months: 10)),
            Goal(name: "New Laptop", emoji: "💻", targetAmount: 1_800, savedAmount: 1_800),
            Goal(name: "Rainy-Day Fund", emoji: "☂️", targetAmount: 10_000, savedAmount: 6_000)
        ]
        goals.forEach { context.insert($0) }

        // Budgets — comfortably set so the demo looks healthy and mostly green.
        let budgets: [CategoryBudget] = [
            CategoryBudget(category: .food, monthlyLimit: 100),
            CategoryBudget(category: .transport, monthlyLimit: 60),
            CategoryBudget(category: .fun, monthlyLimit: 50),
            CategoryBudget(category: .shopping, monthlyLimit: 120),
            CategoryBudget(category: .bills, monthlyLimit: 150),
            CategoryBudget(category: .health, monthlyLimit: 80)
        ]
        budgets.forEach { context.insert($0) }

        // Net-worth history for the Home sparkline (accounts + investments).
        let investmentsTotal = holdings.reduce(0) { $0 + $1.cachedValueInBase }
        let netNow = accounts.reduce(0) { $0 + $1.signedBalance } + investmentsTotal
        NetWorthSnapshot.seedHistory(current: netNow, into: context)
    }
}
