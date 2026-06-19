//
//  CurrencyConversionTests.swift
//  PennyPathTests
//
//  Pins the multi-currency net-worth maths: a foreign account or holding must
//  convert into the base currency, and an unknown rate must count as pending
//  (0) — never silently as 1:1 (which once added ₹100,000 as $100,000).
//

import XCTest
import SwiftData
@testable import PennyPath

/// A deterministic stand-in for the live market — no network.
private struct MockProvider: MarketDataProvider {
    var quotes: [String: Quote] = [:]
    var rates: [String: Double] = [:]   // base → code (e.g. USD→INR = 90)

    func quote(_ symbol: String) async throws -> Quote {
        guard let q = quotes[symbol] else { throw MarketError.noData }
        return q
    }
    func search(_ query: String) async throws -> [SymbolMatch] { [] }
    func fxRates(base: String) async throws -> [String: Double] { rates }
    func fxRate(from: String, to: String) async throws -> Double {
        if from == to { return 1 }
        guard let units = rates[from], units > 0 else { throw MarketError.noData }
        return 1 / units
    }
}

@MainActor
final class CurrencyConversionTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var savedCurrency: String?

    override func setUp() async throws {
        let schema = Schema([Account.self, Expense.self, Goal.self,
                             CategoryBudget.self, NetWorthSnapshot.self, Holding.self,
                             UpcomingPayment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)

        savedCurrency = UserDefaults.standard.string(forKey: AppSettings.currencyKey)
        UserDefaults.standard.set("USD", forKey: AppSettings.currencyKey)
        FXRates._reset(base: nil, rates: [:])   // start with no known rates
    }

    override func tearDown() async throws {
        UserDefaults.standard.set(savedCurrency, forKey: AppSettings.currencyKey)
        FXRates._reset(base: nil, rates: [:])
        container = nil
    }

    private func service(_ mock: MockProvider) -> MarketService {
        let s = MarketService(); s.provider = mock; return s
    }

    // MARK: The bug

    func testForeignAccountConvertsIntoBaseAfterRefresh() async {
        // 1 USD = 90 INR, so ₹90,000 is $1,000 — not $90,000.
        let mock = MockProvider(rates: ["INR": 90])
        let account = Account(name: "Mutual fund", category: .investment,
                              balance: 90_000, currencyCode: "INR", cachedFXRate: 1)
        context.insert(account)

        await service(mock).refresh(holdings: [], displayCurrency: "USD", in: context)

        XCTAssertEqual(account.baseBalance, 1_000, accuracy: 0.01,
                       "₹90,000 must convert to $1,000, not be summed as $90,000")
        XCTAssertEqual(account.signedBalance, 1_000, accuracy: 0.01)
    }

    func testUnknownForeignRateCountsAsPendingNotRaw() {
        // No rates known at all — the dangerous case.
        let account = Account(name: "Cash", category: .cash,
                              balance: 100_000, currencyCode: "INR", cachedFXRate: 1)
        XCTAssertTrue(account.hasPendingRate)
        XCTAssertEqual(account.baseBalance, 0,
                       "an unknown foreign rate must contribute 0, never the raw foreign amount")
    }

    func testBaseAndEmptyCurrencyAccountsAreUntouched() {
        FXRates._reset(base: "USD", rates: ["INR": 90])
        let legacy = Account(name: "Old", category: .cash, balance: 500)          // currencyCode ""
        let usd = Account(name: "Checking", category: .cash, balance: 250, currencyCode: "USD")
        XCTAssertEqual(legacy.baseBalance, 500)
        XCTAssertEqual(usd.baseBalance, 250)
        XCTAssertFalse(legacy.hasPendingRate)
        XCTAssertFalse(usd.hasPendingRate)
    }

    func testCachedRateForCurrentBaseStillConvertsWithoutLiveTable() {
        // base USD, no live rate table, but the account cached a USD-based rate.
        let account = Account(name: "Euro savings", category: .savings,
                              balance: 100, currencyCode: "EUR",
                              cachedFXRate: 1.08, cachedFXBase: "USD")
        FXRates._reset(base: nil, rates: [:])
        XCTAssertFalse(account.hasPendingRate)
        XCTAssertEqual(account.baseBalance, 108, accuracy: 0.01)
    }

    func testCachedRateFromAnotherBaseIsNotReused() {
        // €100 cached at 1.08 (EUR→USD). Switch base to GBP with no GBP rate
        // known: the old USD-based rate must NOT be applied to GBP — that would
        // show a wrong number with no hint it's stale. It counts as pending.
        let account = Account(name: "Euro savings", category: .savings,
                              balance: 100, currencyCode: "EUR",
                              cachedFXRate: 1.08, cachedFXBase: "USD")
        UserDefaults.standard.set("GBP", forKey: AppSettings.currencyKey)
        FXRates._reset(base: nil, rates: [:])
        XCTAssertTrue(account.hasPendingRate)
        XCTAssertEqual(account.baseBalance, 0,
                       "a rate cached for a different base must count as pending, not convert wrongly")
    }

    func testForeignHoldingConvertsIntoBase() async {
        // An Indian stock quoted in INR at ₹1,000; 10 shares = ₹10,000 = $111.11.
        let mock = MockProvider(
            quotes: ["RELIANCE.NS": Quote(symbol: "RELIANCE.NS", name: "Reliance",
                                          price: 1_000, previousClose: 990, currency: "INR")],
            rates: ["INR": 90])
        let holding = Holding(symbol: "RELIANCE.NS", shares: 10, assetType: "EQUITY")
        context.insert(holding)

        await service(mock).refresh(holdings: [holding], displayCurrency: "USD", in: context)

        XCTAssertEqual(holding.cachedValueInBase, 10_000.0 / 90.0, accuracy: 0.01)
    }

    func testNetWorthSumsConvertedValuesAcrossCurrencies() async {
        let mock = MockProvider(rates: ["INR": 90, "EUR": 0.9])
        context.insert(Account(name: "USD cash", category: .cash, balance: 1_000, currencyCode: "USD"))
        context.insert(Account(name: "INR fund", category: .investment, balance: 90_000, currencyCode: "INR"))
        context.insert(Account(name: "EUR card", category: .creditCard, balance: 90, currencyCode: "EUR"))

        await service(mock).refresh(holdings: [], displayCurrency: "USD", in: context)

        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let netWorth = accounts.reduce(0) { $0 + $1.signedBalance }
        // 1000 (USD) + 1000 (₹90k) − 100 (€90) = 1900.
        XCTAssertEqual(netWorth, 1_900, accuracy: 0.01)
    }
}
