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
                             CategoryBudget.self, NetWorthSnapshot.self, Holding.self])
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
}
