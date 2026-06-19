//
//  InsightsEngineTests.swift
//  PennyPathTests
//
//  The on-device coach: right tone, right facts, deterministic.
//

import XCTest
@testable import PennyPath

final class InsightsEngineTests: XCTestCase {

    func testEmptyWorldGetsOnboardingTips() {
        let out = InsightsEngine.generate(accounts: [], expenses: [], goals: [])
        XCTAssertEqual(out.count, 3)
        XCTAssertEqual(out.first?.emoji, "👋")
    }

    func testGreetingFollowsTheClock() {
        func at(hour: Int) -> Date {
            Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
        }
        XCTAssertEqual(InsightsEngine.greeting(date: at(hour: 9)), "Good morning")
        XCTAssertEqual(InsightsEngine.greeting(date: at(hour: 13)), "Good afternoon")
        XCTAssertEqual(InsightsEngine.greeting(date: at(hour: 19)), "Good evening")
        XCTAssertEqual(InsightsEngine.greeting(date: at(hour: 23)), "Hello")
    }

    func testOverBudgetProducesWarning() {
        let spent = Expense(amount: 150, category: .food, date: .now)
        let budget = CategoryBudget(category: .food, monthlyLimit: 100)
        let out = InsightsEngine.generate(accounts: [], expenses: [spent], goals: [], budgets: [budget])
        let alert = out.first { $0.title == "Over your budget" }
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.tone, .warning)
    }

    func testUnderBudgetStaysPositive() {
        let spent = Expense(amount: 20, category: .food, date: .now)
        let budget = CategoryBudget(category: .food, monthlyLimit: 100)
        let out = InsightsEngine.generate(accounts: [], expenses: [spent], goals: [], budgets: [budget])
        XCTAssertNotNil(out.first { $0.title == "Comfortably on budget" })
    }

    func testNegativeNetWorthIsEncouragingNotPanicked() {
        let loan = Account(name: "Loan", category: .loan, balance: 5_000)
        let cash = Account(name: "Cash", category: .cash, balance: 1_000)
        let out = InsightsEngine.generate(accounts: [loan, cash], expenses: [], goals: [])
        XCTAssertNotNil(out.first { $0.title == "Let's grow your net worth" })
    }

    func testCompletedGoalGetsCelebrated() {
        let done = Goal(name: "Laptop", targetAmount: 500, savedAmount: 500)
        let out = InsightsEngine.generate(accounts: [], expenses: [], goals: [done])
        XCTAssertNotNil(out.first { $0.title.contains("Goal reached") })
    }

    func testDailyWisdomIsStableWithinADay() {
        let a = InsightsEngine.dailyWisdom(now: .now)
        let b = InsightsEngine.dailyWisdom(now: .now)
        XCTAssertEqual(a.title, b.title)
    }

    func testHeadlineSurfacesTheMostUrgentThing() {
        // Over budget (urgent) coexists with a spending-is-down win; the headline
        // must be the urgent one, not whichever fired first.
        let now = Date.now
        let thisMonth = Expense(amount: 150, category: .food, date: now)
        let lastMonth = Expense(amount: 300, category: .food, date: now.adding(months: -1))
        let budget = CategoryBudget(category: .food, monthlyLimit: 100)
        let head = InsightsEngine.headline(accounts: [], expenses: [thisMonth, lastMonth],
                                           goals: [], budgets: [budget], now: now)
        XCTAssertEqual(head.title, "Over your budget")
        XCTAssertEqual(head.tone, .warning)
    }

    func testSubscriptionDueSoonSurfacesAsAttention() {
        let now = Date.now
        let sub = UpcomingPayment(name: "Netflix", amount: 16, category: .fun,
                                  isSubscription: true, cycleUnit: .month,
                                  nextDueDate: now.adding(days: 2))
        let out = InsightsEngine.generate(accounts: [], expenses: [Expense(amount: 100, category: .food, date: now)],
                                          goals: [], payments: [sub], now: now)
        let due = out.first { $0.topic == .subscriptions && $0.title.contains("due soon") }
        XCTAssertNotNil(due)
        XCTAssertEqual(due?.tone, .warning)
    }

    func testRisingHistoryProducesTrendInsight() {
        let now = Date.now
        let snapshots = [
            NetWorthSnapshot(date: now.adding(months: -4), value: 1_000),
            NetWorthSnapshot(date: now, value: 1_500),
        ]
        let out = InsightsEngine.generate(
            accounts: [Account(name: "Cash", category: .cash, balance: 1_500)],
            expenses: [], goals: [], snapshots: snapshots, now: now)
        XCTAssertNotNil(out.first { $0.title == "Net worth is trending up" })
    }
}
