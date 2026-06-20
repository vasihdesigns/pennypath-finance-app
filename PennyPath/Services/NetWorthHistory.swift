//
//  NetWorthHistory.swift
//  PennyPath
//
//  The one place that records the net-worth trend: one snapshot per day,
//  updated as balances change. Real charts only ever show real points —
//  invented history is reserved for sample/demo seeds.
//

import Foundation
import SwiftData

enum NetWorthHistory {
    /// Save (or update) today's net-worth point from current account balances.
    /// No-op while there are no accounts yet.
    static func record(in context: ModelContext) {
        // Mirror the screen: archived accounts are hidden, so they must not move
        // the recorded net-worth point either.
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { !$0.isArchived })
        let accounts = (try? context.fetch(descriptor)) ?? []
        guard !accounts.isEmpty else { return }
        let net = accounts.reduce(0) { $0 + $1.signedBalance }

        let snapshots = (try? context.fetch(
            FetchDescriptor<NetWorthSnapshot>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )) ?? []
        if let today = snapshots.first(where: { $0.date.isSameDay(as: .now) }) {
            if today.value != net { today.value = net }
        } else {
            context.insert(NetWorthSnapshot(date: .now, value: net))
        }
    }
}
