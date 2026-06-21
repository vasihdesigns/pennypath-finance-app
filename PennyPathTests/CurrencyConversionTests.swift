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

    // MARK: Many currencies, mixed, exact

    func testManyForeignAccountsEachConvertExactlyAndSum() {
        // base USD. Rates are "units of foreign per 1 USD". Each balance is chosen
        // to be exactly $100 so the math is easy to verify by hand.
        FXRates._reset(base: "USD", rates: ["EUR": 0.90, "INR": 80, "JPY": 150,
                                            "GBP": 0.80, "CAD": 1.25, "AUD": 1.50,
                                            "CHF": 0.88, "BRL": 5.00])
        let cases: [(code: String, balance: Double)] = [
            ("EUR", 90), ("INR", 8_000), ("JPY", 15_000), ("GBP", 80),
            ("CAD", 125), ("AUD", 150), ("CHF", 88), ("BRL", 500),
        ]
        var total = 0.0
        for c in cases {
            let account = Account(name: c.code, category: .cash, balance: c.balance, currencyCode: c.code)
            XCTAssertEqual(account.baseBalance, 100, accuracy: 0.0001, "\(c.code) must convert to exactly $100")
            XCTAssertFalse(account.hasPendingRate, "\(c.code) has a known rate")
            total += account.signedBalance
        }
        XCTAssertEqual(total, 800, accuracy: 0.0001, "eight currencies, each $100, sum to $800")
    }

    func testNonUSDBaseConvertsEveryForeignCurrency() {
        UserDefaults.standard.set("EUR", forKey: AppSettings.currencyKey)
        FXRates._reset(base: "EUR", rates: ["USD": 1.10, "INR": 90, "JPY": 160])
        // 1 EUR = 1.10 USD → $110 = €100, etc.
        XCTAssertEqual(Account(name: "u", category: .cash, balance: 110, currencyCode: "USD").baseBalance,
                       100, accuracy: 0.0001)
        XCTAssertEqual(Account(name: "i", category: .savings, balance: 9_000, currencyCode: "INR").baseBalance,
                       100, accuracy: 0.0001)
        XCTAssertEqual(Account(name: "j", category: .cash, balance: 16_000, currencyCode: "JPY").baseBalance,
                       100, accuracy: 0.0001)
        // An account already in the base currency is never converted.
        XCTAssertEqual(Account(name: "e", category: .cash, balance: 50, currencyCode: "EUR").baseBalance, 50)
    }

    func testZeroDecimalBaseCurrencyConvertsAccurately() {
        // A zero-decimal base (JPY) must convert just like any other.
        UserDefaults.standard.set("JPY", forKey: AppSettings.currencyKey)
        FXRates._reset(base: "JPY", rates: ["USD": 0.01, "EUR": 0.009])
        // 1 JPY = 0.01 USD → $100 = ¥10,000.
        XCTAssertEqual(Account(name: "u", category: .cash, balance: 100, currencyCode: "USD").baseBalance,
                       10_000, accuracy: 0.01)
        // ¥ amounts display with no forced decimals.
        XCTAssertFalse(money(10_000, code: "JPY").contains(".00"))
    }

    // MARK: Minor-unit quote currencies (pence / agorot / cents)

    func testPenceQuotedHoldingConvertsViaPounds() async {
        // Vodafone on the LSE quotes in pence (GBp): 2500p = £25.
        let mock = MockProvider(
            quotes: ["VOD.L": Quote(symbol: "VOD.L", name: "Vodafone",
                                    price: 2_500, previousClose: 2_480, currency: "GBp")],
            rates: ["GBP": 0.80])              // 1 USD = 0.80 GBP → £25 = $31.25
        let holding = Holding(symbol: "VOD.L", shares: 10, assetType: "EQUITY")
        context.insert(holding)

        await service(mock).refresh(holdings: [holding], displayCurrency: "USD", in: context)

        XCTAssertEqual(holding.quoteCurrency, "GBP", "pence is normalised to pounds")
        XCTAssertEqual(holding.cachedPrice, 25, accuracy: 0.0001, "2500p becomes £25")
        // 10 × £25 = £250; £250 ÷ 0.80 = $312.50.
        XCTAssertEqual(holding.cachedValueInBase, 312.50, accuracy: 0.01)
    }

    func testAgorotAndCentsQuoteUnitsNormalise() {
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("GBp").code, "GBP")
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("GBp").priceFactor, 0.01)
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("ILA").code, "ILS")
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("ZAc").code, "ZAR")
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("USD").code, "USD")
        XCTAssertEqual(MarketService.normalizedQuoteCurrency("USD").priceFactor, 1)
    }

    // MARK: Never 1:1 for an unknown foreign rate (the holdings regression)

    func testNewForeignHoldingWithUnknownRateIsPendingNotOneToOne() async {
        // The dangerous case: a fresh holding (cachedFXRate defaults to 1) in a
        // currency the FX table doesn't list must NOT be valued at 1:1.
        let mock = MockProvider(
            quotes: ["ZZZZ": Quote(symbol: "ZZZZ", name: "Exotic",
                                   price: 100, previousClose: 99, currency: "XYZ")],
            rates: ["EUR": 0.9])              // table loads, but has no "XYZ"
        let holding = Holding(symbol: "ZZZZ", shares: 5, assetType: "EQUITY")
        context.insert(holding)

        await service(mock).refresh(holdings: [holding], displayCurrency: "USD", in: context)

        XCTAssertEqual(holding.cachedValueInBase, 0,
                       "an unknown foreign rate must be pending, never counted at 1:1")
    }

    // MARK: Mixed accounts + holdings, exact net worth

    func testMixedAccountsAndHoldingsNetWorthIsExact() async {
        let mock = MockProvider(
            quotes: ["RELIANCE.NS": Quote(symbol: "RELIANCE.NS", name: "Reliance",
                                          price: 1_000, previousClose: 990, currency: "INR")],
            rates: ["INR": 80, "EUR": 0.9])
        context.insert(Account(name: "USD cash", category: .cash, balance: 1_000, currencyCode: "USD"))
        context.insert(Account(name: "EUR savings", category: .savings, balance: 90, currencyCode: "EUR")) // €90 → $100
        context.insert(Account(name: "INR loan", category: .loan, balance: 8_000, currencyCode: "INR"))    // ₹8000 → $100 owed
        let holding = Holding(symbol: "RELIANCE.NS", shares: 8, assetType: "EQUITY")
        context.insert(holding)

        await service(mock).refresh(holdings: [holding], displayCurrency: "USD", in: context)

        // Holding: 8 × ₹1000 = ₹8000 → $100, rolled into the auto Investments account.
        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let net = accounts.reduce(0) { $0 + $1.signedBalance }
        // 1000 (USD) + 100 (EUR) − 100 (INR debt) + 100 (investments) = 1100.
        XCTAssertEqual(net, 1_100, accuracy: 0.01)
    }
}
