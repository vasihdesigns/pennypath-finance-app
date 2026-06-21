//
//  NetWorthSnapshot.swift
//  PennyPath
//
//  A single point on the net-worth trend line: what you were worth on a given day.
//  The app records one per day (updating it as balances change) so the Home
//  sparkline can show how your worth is trending over time.
//

import Foundation
import SwiftData

@Model
final class NetWorthSnapshot {
    // Defaults keep the schema CloudKit-ready; `init` overwrites them.
    var date: Date = Date.now
    var value: Double = 0

    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

extension NetWorthSnapshot {
    /// Seed a gently rising weekly history that ends at `current` today.
    /// SAMPLE/DEMO DATA ONLY — this invents points that never happened, so it
    /// must never run against a real user's store. Real charts are built from
    /// daily `NetWorthHistory.record` points.
    static func seedHistory(current: Double, into context: ModelContext, now: Date = .now, weeks: Int = 26) {
        guard current != 0 else { return }
        let start = current * 0.8
        for i in 0...weeks {
            let t = Double(i) / Double(weeks)
            let trend = start + (current - start) * t
            let wiggle = sin(Double(i) * 1.3) * abs(current) * 0.02
            let value = (i == weeks) ? current : max(0, trend + wiggle)
            context.insert(NetWorthSnapshot(date: now.adding(days: -7 * (weeks - i)), value: value))
        }
    }
}
