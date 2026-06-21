//
//  DemoData.swift
//  PennyPath
//
//  A richer, "show-off" world used by Demo Mode — every money kind and its
//  sub-types, several months of spending across all categories, subscriptions in
//  every payment category, and a mix of goals so every screen looks full.
//

import Foundation
import SwiftData

enum DemoData {
    static func fill(_ context: ModelContext) {
        let now = Date.now

        // Accounts — one or more per sub-type, spanning all five money kinds
        // (Cash, Investment, Property, Receivable, Liability).
        let accounts: [Account] = [
            // Cash Equivalents
            Account(name: "Checking", category: .cash, balance: 2_450),
            Account(name: "Apple Pay", category: .cash, balance: 320),          // digital wallet
            Account(name: "Bank Debit Card", category: .cash, balance: 540),    // debit card
            Account(name: "Everyday Savings", category: .savings, balance: 8_900),
            Account(name: "Emergency Fund", category: .savings, balance: 6_000),
            // Investment (live holdings added below)
            Account(name: "Retirement Fund", category: .investment, balance: 22_400), // fund
            Account(name: "Gold", category: .investment, balance: 4_800),             // precious metal
            // Property
            Account(name: "Apartment", category: .property, balance: 85_000),   // house
            Account(name: "Car", category: .property, balance: 12_000),         // car
            // Receivable
            Account(name: "Loan to Alex", category: .otherAsset, balance: 1_500),   // money lent
            Account(name: "Rental Deposit", category: .otherAsset, balance: 2_200), // deposit
            // Liability
            Account(name: "Credit Card", category: .creditCard, balance: 1_180),
            Account(name: "Car Loan", category: .loan, balance: 7_500),
            Account(name: "Student Loan", category: .loan, balance: 9_300),
            Account(name: "Phone Installment", category: .otherDebt, balance: 640)  // payable
        ]
        accounts.forEach { context.insert($0) }

        // Investments — real stock symbols plus crypto; live prices replace these
        // on first refresh.
        let holdings: [Holding] = [
            Holding(symbol: "AAPL", companyName: "Apple Inc.", shares: 20,
                    cachedPrice: 190, cachedChangePercent: 0.012, cachedValueInBase: 3_800),
            Holding(symbol: "MSFT", companyName: "Microsoft Corp.", shares: 10,
                    cachedPrice: 415, cachedChangePercent: 0.008, cachedValueInBase: 4_150),
            Holding(symbol: "NVDA", companyName: "NVIDIA Corp.", shares: 25,
                    cachedPrice: 120, cachedChangePercent: 0.021, cachedValueInBase: 3_000),
            Holding(symbol: "GOOGL", companyName: "Alphabet Inc.", shares: 15,
                    cachedPrice: 175, cachedChangePercent: -0.006, cachedValueInBase: 2_625),
            Holding(symbol: "BTC-USD", companyName: "Bitcoin", shares: 0.15,
                    cachedPrice: 62_000, cachedChangePercent: 0.018, cachedValueInBase: 9_300),
            Holding(symbol: "ETH-USD", companyName: "Ethereum", shares: 2,
                    cachedPrice: 3_400, cachedChangePercent: -0.009, cachedValueInBase: 6_800)
        ]
        holdings.forEach { context.insert($0) }
        Investments.rebuild(holdings: holdings, in: context)

        // Expenses across three months, covering every category. This month is
        // calmer than last month so the coach has something cheerful to say.
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
        // This month — one of every category.
        thisMonth(16.00, .food, "Lunch", daysAgo: 0)
        thisMonth(9.50, .transport, "Bus pass", daysAgo: 1)
        thisMonth(24.99, .fun, "New game", daysAgo: 2)
        thisMonth(58.40, .food, "Groceries", daysAgo: 3)
        thisMonth(34.00, .health, "Pharmacy", daysAgo: 5)
        thisMonth(45.00, .shopping, "T-shirt", daysAgo: 6)
        thisMonth(72.00, .subscriptions, "Phone + internet", daysAgo: 8)
        thisMonth(19.00, .other, "Stationery", daysAgo: 9)
        thisMonth(28.00, .transport, "Gas", daysAgo: 11)
        thisMonth(1_200, .rent, "Monthly rent", daysAgo: 12)
        // Last month
        monthAgo(62.00, .food, "Groceries", months: 1, day: 24)
        monthAgo(40.00, .transport, "Gas", months: 1, day: 20)
        monthAgo(55.00, .fun, "Concert ticket", months: 1, day: 16)
        monthAgo(120.00, .shopping, "Sneakers", months: 1, day: 12)
        monthAgo(72.00, .subscriptions, "Phone + internet", months: 1, day: 8)
        monthAgo(30.00, .other, "Gift", months: 1, day: 7)
        monthAgo(48.00, .food, "Dinner out", months: 1, day: 5)
        monthAgo(1_200, .rent, "Monthly rent", months: 1, day: 2)
        // Two months ago
        monthAgo(60.00, .food, "Groceries", months: 2, day: 22)
        monthAgo(38.00, .health, "Dentist", months: 2, day: 17)
        monthAgo(72.00, .subscriptions, "Phone + internet", months: 2, day: 10)
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

        // Budgets — one per spending category.
        let budgets: [CategoryBudget] = [
            CategoryBudget(category: .food, monthlyLimit: 250),
            CategoryBudget(category: .transport, monthlyLimit: 60),
            CategoryBudget(category: .fun, monthlyLimit: 50),
            CategoryBudget(category: .shopping, monthlyLimit: 120),
            CategoryBudget(category: .subscriptions, monthlyLimit: 150),
            CategoryBudget(category: .health, monthlyLimit: 80),
            CategoryBudget(category: .rent, monthlyLimit: 1_300),
            CategoryBudget(category: .other, monthlyLimit: 60)
        ]
        budgets.forEach { context.insert($0) }

        // Upcoming — subscriptions across every payment category, plus a couple
        // of one-off future payments.
        let upcoming: [UpcomingPayment] = [
            UpcomingPayment(name: "Netflix", amount: 17.99, category: .fun, cycleUnit: .month,
                            nextDueDate: now.adding(days: 4)),
            UpcomingPayment(name: "Spotify", amount: 10.99, category: .fun, cycleUnit: .month,
                            nextDueDate: now.adding(days: 9)),
            UpcomingPayment(name: "iCloud+", amount: 2.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 15)),
            UpcomingPayment(name: "ChatGPT Plus", amount: 20.00, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 18)),
            UpcomingPayment(name: "Gym", amount: 39.00, category: .health, cycleUnit: .month,
                            nextDueDate: now.adding(days: 20)),
            UpcomingPayment(name: "Wealthfront", amount: 12.00, category: .other, cycleUnit: .month,
                            nextDueDate: now.adding(days: 22)),
            UpcomingPayment(name: "LinkedIn Premium", amount: 29.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 25)),
            UpcomingPayment(name: "Coursera Plus", amount: 49.00, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 27)),
            UpcomingPayment(name: "Cloud Backup", amount: 6.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 13)),
            UpcomingPayment(name: "Rent", amount: 1_200, category: .rent, cycleUnit: .month,
                            nextDueDate: now.adding(months: 1).startOfMonth),
            UpcomingPayment(name: "Car insurance", amount: 540, category: .transport, cycleUnit: .year,
                            nextDueDate: now.adding(days: 50)),
            UpcomingPayment(name: "Flight to NYC", amount: 480, category: .transport,
                            isSubscription: false, remindMe: true,
                            nextDueDate: now.adding(days: 16)),
            UpcomingPayment(name: "Dentist", amount: 150, category: .health,
                            isSubscription: false,
                            nextDueDate: now.adding(days: 9))
        ]
        upcoming.forEach { context.insert($0) }

        // Net-worth history for the sparkline (accounts + investments).
        let investmentsTotal = holdings.reduce(0) { $0 + $1.cachedValueInBase }
        let netNow = accounts.reduce(0) { $0 + $1.signedBalance } + investmentsTotal
        NetWorthSnapshot.seedHistory(current: netNow, into: context)
    }
}
