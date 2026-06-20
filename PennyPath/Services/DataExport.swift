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
    static let schemaVersion = "1.0.0"

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
    }
    struct BudgetDTO: Codable {
        var category: String, monthlyLimit: Double
    }
    struct UpcomingPaymentDTO: Codable {
        var name: String, amount: Double, category: String, nextDueDate: Date
        var createdAt: Date, isSubscription: Bool, cycleUnit: String
        var cycleInterval: Int, autoRenew: Bool, remindMe: Bool, note: String
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
                           dueDate: $0.dueDate)
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
                        savedAmount: $0.savedAmount, targetDate: $0.targetDate, createdAt: $0.createdAt)
            },
            budgets: all(CategoryBudget.self).map {
                BudgetDTO(category: $0.categoryRaw, monthlyLimit: $0.monthlyLimit)
            },
            upcomingPayments: all(UpcomingPayment.self).map {
                UpcomingPaymentDTO(name: $0.name, amount: $0.amount, category: $0.categoryRaw,
                                   nextDueDate: $0.nextDueDate, createdAt: $0.createdAt,
                                   isSubscription: $0.isSubscription, cycleUnit: $0.cycleUnitRaw,
                                   cycleInterval: $0.cycleInterval, autoRenew: $0.autoRenew,
                                   remindMe: $0.remindMe, note: $0.note)
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
}
