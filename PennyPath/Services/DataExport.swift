//
//  DataExport.swift
//  PennyPath
//
//  Exports everything in the active store to a single JSON file the user can
//  save or send (via the share sheet). Because the app keeps all data on-device
//  with no automatic cloud copy, this is the user's portable backup and the way
//  their data is never trapped in the app.
//
//  The DTOs below are a plain, stable mirror of the SwiftData models. Keep them
//  in sync when a model gains a stored field, and bump `schemaVersion`.
//

import Foundation
import SwiftData

enum DataExport {
    static let schemaVersion = "1.1.0"

    // MARK: Snapshot

    struct Snapshot: Codable {
        var app = "PennyPath"
        var schemaVersion = DataExport.schemaVersion
        var exportedAt = Date()
        var accounts: [AccountDTO]
        var holdings: [HoldingDTO]
        var expenses: [ExpenseDTO]
        var goals: [GoalDTO]
        var budgets: [BudgetDTO]
        var upcomingPayments: [UpcomingPaymentDTO]
        var netWorthHistory: [SnapshotDTO]
    }

    struct AccountDTO: Codable {
        var name: String, category: String, balance: Double, createdAt: Date
        var isMarketLinked: Bool, currencyCode: String, notes: String
        var institution: String, counterparty: String
        var interestRate: Double, creditLimit: Double, dueDate: Date?
        // Archive state is real user data — a backup that drops it would silently
        // un-archive everything on restore. `isMarketLinked` above lets an importer
        // skip the auto-managed Investments account and rebuild it from holdings.
        var isArchived: Bool, archivedAt: Date?
    }
    struct HoldingDTO: Codable {
        var symbol: String, companyName: String, shares: Double, assetType: String
        var quoteCurrency: String, cachedPrice: Double, createdAt: Date
    }
    struct ExpenseDTO: Codable {
        var amount: Double, category: String, note: String, date: Date
    }
    struct GoalDTO: Codable {
        var name: String, emoji: String, targetAmount: Double, savedAmount: Double
        var targetDate: Date?, createdAt: Date
        var isArchived: Bool, archivedAt: Date?
    }
    struct BudgetDTO: Codable {
        var category: String, monthlyLimit: Double
    }
    struct UpcomingPaymentDTO: Codable {
        var name: String, amount: Double, category: String, nextDueDate: Date
        var createdAt: Date, isSubscription: Bool, cycleUnit: String
        var cycleInterval: Int, autoRenew: Bool, remindMe: Bool, note: String
        var iconURL: String
    }
    struct SnapshotDTO: Codable {
        var date: Date, value: Double
    }

    // MARK: Build

    static func snapshot(from context: ModelContext) -> Snapshot {
        func all<T: PersistentModel>(_ type: T.Type) -> [T] {
            (try? context.fetch(FetchDescriptor<T>())) ?? []
        }
        return Snapshot(
            accounts: all(Account.self).map {
                AccountDTO(name: $0.name, category: $0.categoryRaw, balance: $0.balance,
                           createdAt: $0.createdAt, isMarketLinked: $0.isMarketLinked,
                           currencyCode: $0.currencyCode, notes: $0.notes,
                           institution: $0.institution, counterparty: $0.counterparty,
                           interestRate: $0.interestRate, creditLimit: $0.creditLimit,
                           dueDate: $0.dueDate,
                           isArchived: $0.isArchived, archivedAt: $0.archivedAt)
            },
            holdings: all(Holding.self).map {
                HoldingDTO(symbol: $0.symbol, companyName: $0.companyName, shares: $0.shares,
                           assetType: $0.assetType, quoteCurrency: $0.quoteCurrency,
                           cachedPrice: $0.cachedPrice, createdAt: $0.createdAt)
            },
            expenses: all(Expense.self).map {
                ExpenseDTO(amount: $0.amount, category: $0.categoryRaw, note: $0.note, date: $0.date)
            },
            goals: all(Goal.self).map {
                GoalDTO(name: $0.name, emoji: $0.emoji, targetAmount: $0.targetAmount,
                        savedAmount: $0.savedAmount, targetDate: $0.targetDate, createdAt: $0.createdAt,
                        isArchived: $0.isArchived, archivedAt: $0.archivedAt)
            },
            budgets: all(CategoryBudget.self).map {
                BudgetDTO(category: $0.categoryRaw, monthlyLimit: $0.monthlyLimit)
            },
            upcomingPayments: all(UpcomingPayment.self).map {
                UpcomingPaymentDTO(name: $0.name, amount: $0.amount, category: $0.categoryRaw,
                                   nextDueDate: $0.nextDueDate, createdAt: $0.createdAt,
                                   isSubscription: $0.isSubscription, cycleUnit: $0.cycleUnitRaw,
                                   cycleInterval: $0.cycleInterval, autoRenew: $0.autoRenew,
                                   remindMe: $0.remindMe, note: $0.note, iconURL: $0.iconURL)
            },
            netWorthHistory: all(NetWorthSnapshot.self).map {
                SnapshotDTO(date: $0.date, value: $0.value)
            }
        )
    }

    static func jsonData(from context: ModelContext) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot(from: context))
    }

    /// Writes the export to a uniquely-named file in the temporary directory and
    /// returns its URL, ready to hand to a share sheet / `ShareLink`.
    static func writeTemporaryFile(from context: ModelContext, now: Date = .now) throws -> URL {
        let data = try jsonData(from: context)
        let stamp = Self.fileStamp.string(from: now)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PennyPath-Backup-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: Import (restore)

    struct ImportSummary {
        var accounts = 0, holdings = 0, expenses = 0, goals = 0
        var budgets = 0, payments = 0, snapshots = 0
    }

    enum ImportError: LocalizedError {
        case notPennyPath
        var errorDescription: String? {
            switch self {
            case .notPennyPath: return "That file isn't a PennyPath backup."
            }
        }
    }

    /// Restore a backup: REPLACES everything in the store with the snapshot's
    /// contents. The auto-managed Investments account is rebuilt from the imported
    /// holdings (not restored directly), so it never double-counts. Foreign-currency
    /// accounts come back with a neutral FX cache and re-convert on the next market
    /// refresh — until then they read as "pending" rather than wrong.
    @discardableResult
    static func importSnapshot(from data: Data, into context: ModelContext) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(Snapshot.self, from: data)
        guard snapshot.app == "PennyPath" else { throw ImportError.notPennyPath }

        deleteAll(in: context)
        var summary = ImportSummary()

        let holdings = snapshot.holdings.map { dto in
            Holding(symbol: dto.symbol, companyName: dto.companyName, shares: dto.shares,
                    assetType: dto.assetType, quoteCurrency: dto.quoteCurrency,
                    cachedPrice: dto.cachedPrice, createdAt: dto.createdAt)
        }
        holdings.forEach { context.insert($0); summary.holdings += 1 }

        for dto in snapshot.accounts where !dto.isMarketLinked {
            let account = Account(
                name: dto.name,
                category: AccountCategory(rawValue: dto.category) ?? .cash,
                balance: dto.balance, createdAt: dto.createdAt,
                currencyCode: dto.currencyCode, notes: dto.notes,
                institution: dto.institution, counterparty: dto.counterparty,
                interestRate: dto.interestRate, creditLimit: dto.creditLimit,
                dueDate: dto.dueDate)
            account.isArchived = dto.isArchived
            account.archivedAt = dto.archivedAt
            context.insert(account)
            summary.accounts += 1
        }

        // Rebuild the linked Investments account from the imported holdings.
        Investments.rebuild(holdings: holdings, in: context)

        for dto in snapshot.expenses {
            context.insert(Expense(amount: dto.amount,
                                   category: ExpenseCategory(rawValue: dto.category) ?? .other,
                                   note: dto.note, date: dto.date))
            summary.expenses += 1
        }
        for dto in snapshot.goals {
            let goal = Goal(name: dto.name, emoji: dto.emoji, targetAmount: dto.targetAmount,
                            savedAmount: dto.savedAmount, targetDate: dto.targetDate, createdAt: dto.createdAt)
            goal.isArchived = dto.isArchived
            goal.archivedAt = dto.archivedAt
            context.insert(goal)
            summary.goals += 1
        }
        for dto in snapshot.budgets {
            context.insert(CategoryBudget(category: ExpenseCategory(rawValue: dto.category) ?? .other,
                                          monthlyLimit: dto.monthlyLimit))
            summary.budgets += 1
        }
        for dto in snapshot.upcomingPayments {
            context.insert(UpcomingPayment(
                name: dto.name, amount: dto.amount,
                category: ExpenseCategory(rawValue: dto.category),
                isSubscription: dto.isSubscription,
                cycleUnit: CycleUnit(rawValue: dto.cycleUnit) ?? .month,
                cycleInterval: dto.cycleInterval, autoRenew: dto.autoRenew,
                remindMe: dto.remindMe, note: dto.note, iconURL: dto.iconURL,
                nextDueDate: dto.nextDueDate, createdAt: dto.createdAt))
            summary.payments += 1
        }
        for dto in snapshot.netWorthHistory {
            context.insert(NetWorthSnapshot(date: dto.date, value: dto.value))
            summary.snapshots += 1
        }

        if context.hasChanges { try context.save() }
        // The store is no longer empty, so first-run sample seeding must not fire.
        UserDefaults.standard.set(true, forKey: SampleData.seededKey)
        return summary
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
}
