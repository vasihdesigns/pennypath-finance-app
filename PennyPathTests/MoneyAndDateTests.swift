//
//  MoneyAndDateTests.swift
//  PennyPathTests
//
//  The formatting and calendar helpers everything else leans on.
//

import XCTest
@testable import PennyPath

final class MoneyTests: XCTestCase {
    func testPercentTextRounds() {
        XCTAssertEqual(percentText(0.62), "62%")
        XCTAssertEqual(percentText(0.625), "63%")
        XCTAssertEqual(percentText(0), "0%")
        XCTAssertEqual(percentText(1), "100%")
    }

    func testMoneyHidesCentsOnWholeAmounts() {
        let whole = money(1200, code: "USD")
        XCTAssertTrue(whole.contains("1"), whole)
        XCTAssertFalse(whole.contains(".00"), "whole amounts should not show .00 — got \(whole)")
    }

    func testMoneyShowsCentsOnFractionalAmounts() {
        let cents = money(12.5, code: "USD")
        XCTAssertTrue(cents.contains("50"), "fractional amounts keep two digits — got \(cents)")
    }

    func testSignedMoneyPrefixes() {
        XCTAssertTrue(signedMoney(5, code: "USD").hasPrefix("+"))
        XCTAssertTrue(signedMoney(-5, code: "USD").hasPrefix("−"))
    }

    func testNonFiniteInputsDegradeToDashInsteadOfTrapping() {
        // A 0/0 or x/0 ratio must never reach Int(...) and trap the app.
        XCTAssertEqual(percentText(.nan), "—")
        XCTAssertEqual(percentText(.infinity), "—")
        XCTAssertEqual(money(.nan, code: "USD"), "—")
        XCTAssertEqual(money(.infinity, code: "USD"), "—")
        XCTAssertEqual(signedMoney(.nan, code: "USD"), "—")
    }

    func testMoneyFormatsAcrossCurrencies() {
        // A zero-decimal currency shows no cents on a whole amount.
        XCTAssertFalse(money(1_200, code: "JPY").contains(".00"))
        // A standard currency keeps its cents when fractional.
        XCTAssertTrue(money(12.5, code: "EUR").contains("50"))
        // Every code — including 3-decimal (KWD) and exotic ones — formats to a
        // non-empty string and stays trap-safe on non-finite input.
        for code in ["USD", "EUR", "JPY", "INR", "GBP", "KWD", "CHF", "BRL", "ZAR", "NGN"] {
            XCTAssertFalse(money(1_234.5, code: code).isEmpty, "\(code) should format")
            XCTAssertEqual(money(.nan, code: code), "—")
        }
    }
}

final class DateHelperTests: XCTestCase {
    private let cal = Calendar.current

    func testStartOfMonthIsDayOne() {
        let start = Date.now.startOfMonth
        XCTAssertEqual(cal.component(.day, from: start), 1)
        XCTAssertTrue(start.isSameMonth(as: .now))
    }

    func testIsSameMonth() {
        XCTAssertTrue(Date.now.isSameMonth(as: .now))
        XCTAssertFalse(Date.now.isSameMonth(as: .now.adding(months: -1)))
    }

    func testMonthsUntilCountsWholeMonths() {
        let now = Date.now
        XCTAssertEqual(now.monthsUntil(now.adding(months: 5)), 5)
        XCTAssertEqual(now.monthsUntil(now), 0)
        // Past dates floor at zero rather than going negative.
        XCTAssertEqual(now.monthsUntil(now.adding(months: -3)), 0)
    }

    func testFriendlyDayLabels() {
        XCTAssertEqual(Date.now.friendlyDay, "Today")
        XCTAssertEqual(Date.now.adding(days: -1).friendlyDay, "Yesterday")
    }
}
