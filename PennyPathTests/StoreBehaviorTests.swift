//
//  StoreBehaviorTests.swift
//  PennyPathTests
//
//  SwiftData-backed behavior: seeding guards and honest snapshot recording —
//  the audit's two data-integrity fixes, pinned by tests.
//

import XCTest
import SwiftData
@testable import PennyPath

@MainActor
final class StoreBehaviorTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var hadSeededFlag: Bool!

    override func setUp() async throws {
        let schema = Schema([Account.self, Expense.self, Goal.self,
                             CategoryBudget.self, NetWorthSnapshot.self, Holding.self,
                             UpcomingPayment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        hadSeededFlag = UserDefaults.standard.bool(forKey: SampleData.seededKey)
    }

    override func tearDown() async throws {
        UserDefaults.standard.set(hadSeededFlag, forKey: SampleData.seededKey)
        container = nil
    }

    private func count<T: PersistentModel>(_ type: T.Type) -> Int {
        (try? context.fetchCount(FetchDescriptor<T>())) ?? 0
    }

    // MARK: Seeding guard

    func testSeedIfNeededFillsAnEmptyStore() {
        UserDefaults.standard.removeObject(forKey: SampleData.seededKey)
        SampleData.seedIfNeeded(in: context)
        XCTAssertGreaterThan(count(Account.self), 0)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: SampleData.seededKey))
    }

    func testSeedIfNeededNeverPilesOntoExistingData() {
        context.insert(Account(name: "Mine", category: .cash, balance: 42))
        UserDefaults.standard.removeObject(forKey: SampleData.seededKey)

        SampleData.seedIfNeeded(in: context)

        XCTAssertEqual(count(Account.self), 1, "samples must not merge into real data")
        XCTAssertEqual(count(Goal.self), 0)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: SampleData.seededKey))
    }

    func testSeededExpensesRespectMonthBuckets() {
        UserDefaults.standard.removeObject(forKey: SampleData.seededKey)
        SampleData.seedIfNeeded(in: context)
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let thisMonth = expenses.filter { $0.date.isSameMonth(as: .now) }
        let lastMonth = expenses.filter { $0.date.isSameMonth(as: .now.adding(months: -1)) }
        XCTAssertEqual(thisMonth.count + lastMonth.count, expenses.count,
                       "every seeded expense lands cleanly in this month or last month")
        XCTAssertFalse(thisMonth.isEmpty)
        XCTAssertFalse(lastMonth.isEmpty)
        XCTAssertTrue(expenses.allSatisfy { $0.date <= .now }, "no future-dated seeds")
    }

    // MARK: Honest history

    func testRecordIsNoOpWithoutAccounts() {
        NetWorthHistory.record(in: context)
        XCTAssertEqual(count(NetWorthSnapshot.self), 0)
    }

    func testRecordUpsertsOnePointPerDay() {
        context.insert(Account(name: "Cash", category: .cash, balance: 100))
        NetWorthHistory.record(in: context)
        XCTAssertEqual(count(NetWorthSnapshot.self), 1, "no invented history — exactly today's point")

        // Balance changes the same day update the point instead of adding one.
        context.insert(Account(name: "Card", category: .creditCard, balance: 30))
        NetWorthHistory.record(in: context)
        let snapshots = (try? context.fetch(FetchDescriptor<NetWorthSnapshot>())) ?? []
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.value, 70)
    }

    func testSeedHistoryEndsAtCurrentValue() {
        NetWorthSnapshot.seedHistory(current: 1_000, into: context, weeks: 10)
        let snapshots = ((try? context.fetch(FetchDescriptor<NetWorthSnapshot>())) ?? [])
            .sorted { $0.date < $1.date }
        XCTAssertEqual(snapshots.count, 11)
        XCTAssertEqual(snapshots.last?.value, 1_000)
    }

    // MARK: Investments auto-account

    func testInvestmentsAccountIsRemovedWhenLastHoldingGoes() {
        let holding = Holding(symbol: "AAPL", shares: 1, cachedValueInBase: 100)
        context.insert(holding)
        Investments.rebuild(holdings: [holding], in: context)
        XCTAssertEqual(count(Account.self), 1, "a linked Investments account is created")

        // All holdings gone → the auto-account is removed, not left at $0.
        context.delete(holding)
        Investments.rebuild(holdings: [], in: context)
        XCTAssertEqual(count(Account.self), 0, "no stray $0 Investments account lingers")
    }

    // MARK: Demo Mode

    func testDemoContainerSeedsWithoutCrashing() {
        let (demo, health) = AppStore.makeContainer(isDemo: true)
        let ctx = ModelContext(demo)
        XCTAssertEqual(health, .healthy)
        XCTAssertGreaterThan((try? ctx.fetchCount(FetchDescriptor<Account>())) ?? 0, 0)
        XCTAssertGreaterThan((try? ctx.fetchCount(FetchDescriptor<UpcomingPayment>())) ?? 0, 0)
    }

    // MARK: Store recovery

    func testUnreadableStoreIsSetAsideAndReplacedWithAFreshOne() throws {
        UserDefaults.standard.set(true, forKey: SampleData.seededKey)
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pennypath-recovery-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // A garbage file where the database should be: opening must fail.
        let storeURL = dir.appendingPathComponent("test.store")
        try Data("not a database".utf8).write(to: storeURL)

        let (recovered, health) = AppStore.makeContainer(isDemo: false, storeURL: storeURL)

        XCTAssertEqual(health, .resetAfterFailure)

        // The garbage was kept on disk, not deleted.
        let siblings = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(siblings.contains { $0.contains(".unreadable-") },
                      "the unreadable file must be set aside, not destroyed")

        // The replacement store really persists: write, reopen, read back.
        let writeContext = ModelContext(recovered)
        writeContext.insert(Account(name: "Recovered", category: .cash, balance: 7))
        try writeContext.save()

        let (reopened, secondHealth) = AppStore.makeContainer(isDemo: false, storeURL: storeURL)
        XCTAssertEqual(secondHealth, .healthy)
        let fetched = try ModelContext(reopened).fetch(FetchDescriptor<Account>())
        XCTAssertEqual(fetched.map(\.name), ["Recovered"])
    }
}
