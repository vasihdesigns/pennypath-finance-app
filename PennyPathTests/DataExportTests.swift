//
//  DataExportTests.swift
//  PennyPathTests
//
//  The JSON backup is the user's only portable copy of their data, so the export
//  DTOs must mirror every STORED field on the models. These tests export real
//  records, decode the JSON straight back, and assert nothing was dropped on the
//  way out — the guard that would have caught archive state and subscription
//  icons silently going missing from a backup.
//

import XCTest
import SwiftData
@testable import PennyPath

@MainActor
final class DataExportTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    // Whole-second timestamps so they survive the ISO-8601 (second-resolution)
    // round-trip exactly, keeping date assertions precise.
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() async throws {
        let schema = Schema([Account.self, Expense.self, Goal.self,
                             CategoryBudget.self, NetWorthSnapshot.self, Holding.self,
                             UpcomingPayment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    /// Export the current store and decode the JSON back into a Snapshot, exactly
    /// as a future importer would have to.
    private func roundTrip() throws -> DataExport.Snapshot {
        let data = try DataExport.jsonData(from: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DataExport.Snapshot.self, from: data)
    }

    // MARK: Envelope

    func testSnapshotCarriesAppAndSchemaStamp() throws {
        let snapshot = try roundTrip()
        XCTAssertEqual(snapshot.app, "PennyPath")
        XCTAssertEqual(snapshot.schemaVersion, DataExport.schemaVersion)
    }

    // MARK: Account — every stored field, including the once-dropped archive state

    func testArchivedAccountRoundTripsEveryField() throws {
        let due = t0.addingTimeInterval(86_400)
        let archivedAt = t0.addingTimeInterval(120)
        context.insert(Account(
            name: "Amex Gold", category: .creditCard, balance: 742.50,
            createdAt: t0, currencyCode: "EUR", cachedFXRate: 1.08, cachedFXBase: "USD",
            notes: "travel card", institution: "Amex", counterparty: "",
            interestRate: 19.9, creditLimit: 5_000, dueDate: due))
        if let account = try context.fetch(FetchDescriptor<Account>()).first {
            account.isArchived = true
            account.archivedAt = archivedAt
        }

        let snapshot = try roundTrip()
        let dto = try XCTUnwrap(snapshot.accounts.first)

        XCTAssertEqual(dto.name, "Amex Gold")
        XCTAssertEqual(dto.category, AccountCategory.creditCard.rawValue)
        XCTAssertEqual(dto.balance, 742.50, accuracy: 0.001)
        XCTAssertEqual(dto.currencyCode, "EUR")
        XCTAssertEqual(dto.notes, "travel card")
        XCTAssertEqual(dto.institution, "Amex")
        XCTAssertEqual(dto.interestRate, 19.9, accuracy: 0.001)
        XCTAssertEqual(dto.creditLimit, 5_000, accuracy: 0.001)
        XCTAssertEqual(dto.createdAt, t0)
        XCTAssertEqual(try XCTUnwrap(dto.dueDate), due)
        // The fields that previously fell off a backup.
        XCTAssertTrue(dto.isArchived, "archive state must survive a backup")
        XCTAssertEqual(try XCTUnwrap(dto.archivedAt), archivedAt)
    }

    func testActiveAccountExportsUnarchived() throws {
        context.insert(Account(name: "Checking", category: .cash, balance: 100, createdAt: t0))
        let dto = try XCTUnwrap(try roundTrip().accounts.first)
        XCTAssertFalse(dto.isArchived)
        XCTAssertNil(dto.archivedAt)
    }

    // MARK: Goal — including archive state

    func testArchivedGoalRoundTripsArchiveState() throws {
        let target = t0.addingTimeInterval(2_000_000)
        let archivedAt = t0.addingTimeInterval(300)
        context.insert(Goal(name: "New Bike", emoji: "🚲", targetAmount: 400,
                            savedAmount: 260, targetDate: target, createdAt: t0))
        if let goal = try context.fetch(FetchDescriptor<Goal>()).first {
            goal.isArchived = true
            goal.archivedAt = archivedAt
        }

        let dto = try XCTUnwrap(try roundTrip().goals.first)
        XCTAssertEqual(dto.name, "New Bike")
        XCTAssertEqual(dto.emoji, "🚲")
        XCTAssertEqual(dto.targetAmount, 400, accuracy: 0.001)
        XCTAssertEqual(dto.savedAmount, 260, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(dto.targetDate), target)
        XCTAssertEqual(dto.createdAt, t0)
        XCTAssertTrue(dto.isArchived, "a goal's archive state must survive a backup")
        XCTAssertEqual(try XCTUnwrap(dto.archivedAt), archivedAt)
    }

    // MARK: UpcomingPayment — including the subscription icon URL

    func testSubscriptionRoundTripsIconURL() throws {
        context.insert(UpcomingPayment(
            name: "Netflix", amount: 15.99, category: .fun,
            isSubscription: true, cycleUnit: .month, cycleInterval: 1,
            autoRenew: true, remindMe: false, note: "family plan",
            iconURL: "https://example.com/netflix.png", nextDueDate: t0, createdAt: t0))

        let dto = try XCTUnwrap(try roundTrip().upcomingPayments.first)
        XCTAssertEqual(dto.name, "Netflix")
        XCTAssertEqual(dto.amount, 15.99, accuracy: 0.001)
        XCTAssertEqual(dto.category, ExpenseCategory.fun.rawValue)
        XCTAssertTrue(dto.isSubscription)
        XCTAssertEqual(dto.cycleUnit, CycleUnit.month.rawValue)
        XCTAssertEqual(dto.cycleInterval, 1)
        XCTAssertTrue(dto.autoRenew)
        XCTAssertEqual(dto.note, "family plan")
        XCTAssertEqual(dto.iconURL, "https://example.com/netflix.png",
                       "a subscription's matched icon must survive a backup")
    }

    // MARK: Everything together — counts line up across all seven models

    func testFullStoreExportsEveryRecord() throws {
        context.insert(Account(name: "Cash", category: .cash, balance: 50, createdAt: t0))
        context.insert(Expense(amount: 12.5, category: .food, note: "Lunch", date: t0))
        context.insert(Goal(name: "Trip", targetAmount: 1_000, createdAt: t0))
        context.insert(CategoryBudget(category: .food, monthlyLimit: 300))
        context.insert(UpcomingPayment(name: "Gym", amount: 29, nextDueDate: t0, createdAt: t0))
        context.insert(Holding(symbol: "AAPL", companyName: "Apple", shares: 3, createdAt: t0))
        context.insert(NetWorthSnapshot(date: t0, value: 1_234))

        let snapshot = try roundTrip()
        XCTAssertEqual(snapshot.accounts.count, 1)
        XCTAssertEqual(snapshot.expenses.count, 1)
        XCTAssertEqual(snapshot.goals.count, 1)
        XCTAssertEqual(snapshot.budgets.count, 1)
        XCTAssertEqual(snapshot.upcomingPayments.count, 1)
        XCTAssertEqual(snapshot.holdings.count, 1)
        XCTAssertEqual(snapshot.netWorthHistory.count, 1)

        XCTAssertEqual(snapshot.holdings.first?.symbol, "AAPL")
        XCTAssertEqual(snapshot.expenses.first?.note, "Lunch")
        XCTAssertEqual(snapshot.netWorthHistory.first?.value, 1_234)
    }

    // MARK: Import (restore) — export then read it back into a fresh store

    func testImportReplacesStoreAndRestoresEverything() throws {
        let savedSeeded = UserDefaults.standard.bool(forKey: SampleData.seededKey)
        defer { UserDefaults.standard.set(savedSeeded, forKey: SampleData.seededKey) }

        // Populate the source store, including archive state, an icon URL, and a
        // holding (which seeds an auto-managed, market-linked Investments account).
        context.insert(Account(name: "Cash", category: .cash, balance: 50, createdAt: t0))
        let card = Account(name: "Old Card", category: .creditCard, balance: 100, createdAt: t0,
                           currencyCode: "EUR", institution: "Amex",
                           interestRate: 19.9, creditLimit: 5_000)
        card.isArchived = true
        card.archivedAt = t0
        context.insert(card)
        context.insert(Expense(amount: 12.5, category: .food, note: "Lunch", date: t0))
        let goal = Goal(name: "Trip", targetAmount: 1_000, createdAt: t0)
        goal.isArchived = true
        goal.archivedAt = t0
        context.insert(goal)
        context.insert(CategoryBudget(category: .food, monthlyLimit: 300))
        context.insert(UpcomingPayment(name: "Netflix", amount: 15.99, category: .fun,
                                       iconURL: "https://example.com/n.png",
                                       nextDueDate: t0, createdAt: t0))
        context.insert(Holding(symbol: "AAPL", companyName: "Apple", shares: 3, createdAt: t0))
        Investments.rebuild(holdings: Investments.allHoldings(in: context), in: context)
        context.insert(NetWorthSnapshot(date: t0, value: 1_234))

        let data = try DataExport.jsonData(from: context)

        // A different, non-empty store: the replace-import must wipe it first.
        let schema = Schema([Account.self, Expense.self, Goal.self,
                             CategoryBudget.self, NetWorthSnapshot.self, Holding.self,
                             UpcomingPayment.self])
        let other = ModelContext(try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]))
        other.insert(Account(name: "Junk", category: .cash, balance: 999))
        // Save so it's persisted — matching the app, which always imports over an
        // autosaved store (the bulk delete clears persisted rows).
        try other.save()

        let summary = try DataExport.importSnapshot(from: data, into: other)

        // The exported market-linked Investments account is skipped on import and
        // rebuilt from the holdings — so the summary counts only the two real ones.
        XCTAssertEqual(summary.accounts, 2)
        let accounts = try other.fetch(FetchDescriptor<Account>())
        XCTAssertFalse(accounts.contains { $0.name == "Junk" }, "import must replace, not merge")
        XCTAssertTrue(accounts.contains { $0.name == "Old Card" && $0.isArchived },
                      "an archived account restores as archived")
        XCTAssertEqual(accounts.filter { $0.isMarketLinked }.count, 1,
                       "exactly one Investments account is rebuilt from the holdings")

        let goals = try other.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 1)
        XCTAssertTrue(goals.first?.isArchived ?? false)

        let payments = try other.fetch(FetchDescriptor<UpcomingPayment>())
        XCTAssertEqual(payments.first?.iconURL, "https://example.com/n.png")

        XCTAssertEqual(try other.fetchCount(FetchDescriptor<Expense>()), 1)
        XCTAssertEqual(try other.fetchCount(FetchDescriptor<Holding>()), 1)
        XCTAssertEqual(try other.fetchCount(FetchDescriptor<NetWorthSnapshot>()), 1)
    }

    func testImportRejectsNonPennyPathJSON() throws {
        // A well-formed but foreign snapshot must be refused by the app-name guard.
        let json = """
        {"app":"SomethingElse","schemaVersion":"1.1.0","exportedAt":"2023-11-14T22:13:20Z",\
        "accounts":[],"holdings":[],"expenses":[],"goals":[],"budgets":[],\
        "upcomingPayments":[],"netWorthHistory":[]}
        """
        XCTAssertThrowsError(try DataExport.importSnapshot(from: Data(json.utf8), into: context))
    }
}
