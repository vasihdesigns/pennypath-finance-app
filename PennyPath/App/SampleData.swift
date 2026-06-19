//
//  SampleData.swift
//  PennyPath
//
//  Fills a fresh install with friendly example data so the app feels alive
//  the moment it opens. Can be reloaded or cleared from Settings.
//

import Foundation
import SwiftData

enum SampleData {
    static let seededKey = "didSeedSampleData"

    /// Seed once on first launch — and only into an empty store, so samples
    /// can never pile on top of real data (e.g. after "Reset first-run state").
    static func seedIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        if isEmpty(context) { seed(in: context) }
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    static func isEmpty(_ context: ModelContext) -> Bool {
        func count<T: PersistentModel>(_ type: T.Type) -> Int {
            (try? context.fetchCount(FetchDescriptor<T>())) ?? 0
        }
        return count(Account.self) == 0 && count(Expense.self) == 0
            && count(Goal.self) == 0 && count(Holding.self) == 0
    }

    /// Wipe and reload examples (Settings → Load sample data).
    static func reset(in context: ModelContext) {
        deleteAll(in: context)
        seed(in: context)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Wipe everything and stay empty (Settings → Clear everything).
    static func clear(in context: ModelContext) {
        deleteAll(in: context)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    private static func deleteAll(in context: ModelContext) {
        try? context.delete(model: Account.self)
        try? context.delete(model: Expense.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: CategoryBudget.self)
        try? context.delete(model: NetWorthSnapshot.self)
        try? context.delete(model: Holding.self)
        try? context.delete(model: UpcomingPayment.self)
    }

    private static func seed(in context: ModelContext) {
        // Accounts — at least one of every money kind and a spread of sub-types,
        // so the deck and allocation grid show all categories from first launch.
        let accounts: [Account] = [
            // Cash Equivalents
            Account(name: "Checking", category: .cash, balance: 1_850),
            Account(name: "Apple Pay", category: .cash, balance: 180),        // digital wallet
            Account(name: "Savings", category: .savings, balance: 6_200),
            // Investment (live holdings added below)
            Account(name: "Retirement Fund", category: .investment, balance: 9_400), // fund
            Account(name: "Gold", category: .investment, balance: 2_100),            // precious metal
            // Property
            Account(name: "Car", category: .property, balance: 11_000),       // car
            // Receivable
            Account(name: "Loan to a friend", category: .otherAsset, balance: 800),   // money lent
            Account(name: "Rental Deposit", category: .otherAsset, balance: 1_500),   // deposit
            // Liability
            Account(name: "Credit Card", category: .creditCard, balance: 740),
            Account(name: "Student Loan", category: .loan, balance: 5_200),
            Account(name: "Phone Installment", category: .otherDebt, balance: 380)    // payable
        ]
        accounts.forEach { context.insert($0) }

        // Investments — real stock symbols plus crypto; live prices replace these
        // on first refresh.
        let holdings: [Holding] = [
            Holding(symbol: "AAPL", companyName: "Apple Inc.", shares: 6,
                    cachedPrice: 190, cachedChangePercent: 0.012, cachedValueInBase: 1_140),
            Holding(symbol: "MSFT", companyName: "Microsoft Corp.", shares: 3,
                    cachedPrice: 415, cachedChangePercent: 0.008, cachedValueInBase: 1_245),
            Holding(symbol: "TSLA", companyName: "Tesla Inc.", shares: 8,
                    cachedPrice: 240, cachedChangePercent: -0.015, cachedValueInBase: 1_920),
            Holding(symbol: "BTC-USD", companyName: "Bitcoin", shares: 0.05,
                    cachedPrice: 62_000, cachedChangePercent: 0.018, cachedValueInBase: 3_100)
        ]
        holdings.forEach { context.insert($0) }
        Investments.rebuild(holdings: holdings, in: context)

        // Expenses — this month is calmer than last month, so the coach can
        // cheer. Dates are anchored to month starts (not fixed day offsets) so
        // the "this month vs last month" story holds on any install date.
        let now = Date.now
        // Recent, but never spilling into the previous month.
        func thisMonth(_ amount: Double, _ category: ExpenseCategory, _ note: String, daysAgo: Int) {
            let date = max(now.adding(days: -daysAgo), now.startOfMonth)
            context.insert(Expense(amount: amount, category: category, note: note, date: date))
        }
        // A specific day of an earlier month (clamped to that month's length).
        func monthAgo(_ amount: Double, _ category: ExpenseCategory, _ note: String, months: Int, day: Int) {
            let cal = Calendar.current
            let base = now.adding(months: -months).startOfMonth
            let maxDay = cal.range(of: .day, in: .month, for: base)?.count ?? 28
            let date = cal.date(byAdding: .day, value: min(day, maxDay) - 1, to: base) ?? base
            context.insert(Expense(amount: amount, category: category, note: note, date: date))
        }
        // This month — one of every category.
        thisMonth(14.50, .food, "Lunch", daysAgo: 0)
        thisMonth(28.00, .transport, "Gas", daysAgo: 1)
        thisMonth(19.99, .fun, "New game", daysAgo: 2)
        thisMonth(46.30, .food, "Groceries", daysAgo: 3)
        thisMonth(22.00, .health, "Pharmacy", daysAgo: 4)
        thisMonth(54.00, .shopping, "Sneakers", daysAgo: 5)
        thisMonth(60.00, .subscriptions, "Phone bill", daysAgo: 6)
        thisMonth(15.00, .other, "Stationery", daysAgo: 7)
        thisMonth(700.00, .rent, "Monthly rent", daysAgo: 8)
        // Last month
        monthAgo(52.00, .food, "Groceries", months: 1, day: 25)
        monthAgo(40.00, .transport, "Gas", months: 1, day: 21)
        monthAgo(35.00, .fun, "Movie night", months: 1, day: 17)
        monthAgo(90.00, .shopping, "Jacket", months: 1, day: 11)
        monthAgo(60.00, .subscriptions, "Phone bill", months: 1, day: 6)
        monthAgo(38.00, .food, "Dinner out", months: 1, day: 3)
        monthAgo(70.00, .rent, "Monthly rent", months: 1, day: 1)

        // Goals — one finished, one in progress, one just started.
        let goals: [Goal] = [
            Goal(name: "New Bike", emoji: "🚲", targetAmount: 400, savedAmount: 260,
                 targetDate: now.adding(months: 4)),
            Goal(name: "Summer Trip", emoji: "✈️", targetAmount: 1_200, savedAmount: 350,
                 targetDate: now.adding(months: 8)),
            Goal(name: "Rainy-Day Fund", emoji: "☂️", targetAmount: 2_000, savedAmount: 2_000)
        ]
        goals.forEach { context.insert($0) }

        // Budgets — one per spending category. Food is set tight so it shows
        // an "over" bar.
        let budgets: [CategoryBudget] = [
            CategoryBudget(category: .food, monthlyLimit: 60),
            CategoryBudget(category: .transport, monthlyLimit: 120),
            CategoryBudget(category: .fun, monthlyLimit: 80),
            CategoryBudget(category: .shopping, monthlyLimit: 150),
            CategoryBudget(category: .subscriptions, monthlyLimit: 120),
            CategoryBudget(category: .health, monthlyLimit: 40),
            CategoryBudget(category: .rent, monthlyLimit: 800),
            CategoryBudget(category: .other, monthlyLimit: 50)
        ]
        budgets.forEach { context.insert($0) }

        // Upcoming — subscriptions spanning every payment category, plus a
        // scheduled one-off payment.
        let upcoming: [UpcomingPayment] = [
            UpcomingPayment(name: "Netflix", amount: 15.99, category: .fun, cycleUnit: .month,
                            nextDueDate: now.adding(days: 6)),
            UpcomingPayment(name: "Spotify", amount: 9.99, category: .fun, cycleUnit: .month,
                            nextDueDate: now.adding(days: 12)),
            UpcomingPayment(name: "iCloud+", amount: 2.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 14)),
            UpcomingPayment(name: "Gym", amount: 29.00, category: .health, cycleUnit: .month,
                            nextDueDate: now.adding(days: 18)),
            UpcomingPayment(name: "Wealthfront", amount: 8.00, category: .other, cycleUnit: .month,
                            nextDueDate: now.adding(days: 20)),
            UpcomingPayment(name: "LinkedIn Premium", amount: 29.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 24)),
            UpcomingPayment(name: "Coursera Plus", amount: 49.00, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 26)),
            UpcomingPayment(name: "Cloud Backup", amount: 6.99, category: .subscriptions, cycleUnit: .month,
                            nextDueDate: now.adding(days: 10)),
            UpcomingPayment(name: "Rent", amount: 450, category: .rent, cycleUnit: .month,
                            nextDueDate: now.adding(months: 1).startOfMonth),
            UpcomingPayment(name: "Car insurance", amount: 320, category: .transport, cycleUnit: .year,
                            nextDueDate: now.adding(days: 40)),
            UpcomingPayment(name: "Concert tickets", amount: 120, category: .fun,
                            isSubscription: false, remindMe: true,
                            nextDueDate: now.adding(days: 21))
        ]
        upcoming.forEach { context.insert($0) }

        // Net-worth history for the Home sparkline (accounts + investments).
        let investmentsTotal = holdings.reduce(0) { $0 + $1.cachedValueInBase }
        let netNow = accounts.reduce(0) { $0 + $1.signedBalance } + investmentsTotal
        NetWorthSnapshot.seedHistory(current: netNow, into: context)
    }
}
