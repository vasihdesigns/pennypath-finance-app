//
//  ModelTests.swift
//  PennyPathTests
//
//  Sign conventions and goal math — the rules the money numbers live by.
//

import XCTest
@testable import PennyPath

final class AccountTests: XCTestCase {
    func testBalanceIsStoredAsMagnitude() {
        let debt = Account(name: "Card", category: .creditCard, balance: -740)
        XCTAssertEqual(debt.balance, 740)
        XCTAssertEqual(debt.signedBalance, -740)
    }

    func testSignedBalanceFollowsCategory() {
        let cash = Account(name: "Checking", category: .cash, balance: 100)
        XCTAssertEqual(cash.signedBalance, 100)
        XCTAssertTrue(AccountCategory.assetCases.allSatisfy(\.isAsset))
        XCTAssertTrue(AccountCategory.debtCases.allSatisfy { !$0.isAsset })
    }
}

final class ExpenseTests: XCTestCase {
    func testAmountIsAlwaysPositive() {
        XCTAssertEqual(Expense(amount: -12.5, category: .food).amount, 12.5)
    }

    func testDisplayTitleFallsBackToCategory() {
        XCTAssertEqual(Expense(amount: 1, category: .food, note: "  ").displayTitle, "Food")
        XCTAssertEqual(Expense(amount: 1, category: .food, note: "Lunch").displayTitle, "Lunch")
    }
}

final class GoalTests: XCTestCase {
    func testProgressClampsToOne() {
        let goal = Goal(name: "Bike", targetAmount: 100, savedAmount: 150)
        XCTAssertEqual(goal.progress, 1)
        XCTAssertTrue(goal.isComplete)
        XCTAssertEqual(goal.remaining, 0)
    }

    func testZeroTargetNeverDividesByZero() {
        let goal = Goal(name: "Empty", targetAmount: 0)
        XCTAssertEqual(goal.progress, 0)
        XCTAssertFalse(goal.isComplete)
    }

    func testSuggestedMonthlySpreadsRemainingOverMonths() throws {
        let goal = Goal(name: "Trip", targetAmount: 600, savedAmount: 100,
                        targetDate: Date.now.adding(months: 5))
        let monthly = try XCTUnwrap(goal.suggestedMonthly)
        XCTAssertEqual(monthly, 100, accuracy: 0.01)   // 500 left over 5 months
    }

    func testSuggestedMonthlyIsRemainingWhenOverdue() throws {
        let goal = Goal(name: "Late", targetAmount: 300, savedAmount: 100,
                        targetDate: Date.now.adding(months: -1))
        XCTAssertEqual(try XCTUnwrap(goal.suggestedMonthly), 200)
    }

    func testSuggestedMonthlyNilWithoutDateOrWhenDone() {
        XCTAssertNil(Goal(name: "NoDate", targetAmount: 100).suggestedMonthly)
        XCTAssertNil(Goal(name: "Done", targetAmount: 100, savedAmount: 100,
                          targetDate: Date.now.adding(months: 2)).suggestedMonthly)
    }
}
