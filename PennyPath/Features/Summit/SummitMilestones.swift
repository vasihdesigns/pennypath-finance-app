//
//  SummitMilestones.swift
//  PennyPath
//
//  The motivating heart of Summit: a ladder of net-worth milestones to climb.
//  Pure value logic (no storage) computed from the live net-worth number, plus
//  a compact money formatter for tidy rung labels like "$10K" and "$1M".
//

import Foundation

enum SummitMilestones {

    /// The rungs of the climb, in the app's currency units. Round, meaningful
    /// targets that keep mattering as someone's wealth grows.
    static let ladder: [Double] = [
        1_000, 5_000, 10_000, 25_000, 50_000,
        100_000, 250_000, 500_000, 1_000_000,
        2_500_000, 5_000_000, 10_000_000
    ]

    /// The next rung strictly above `netWorth`, or nil once the top is passed.
    static func next(after netWorth: Double) -> Double? {
        ladder.first { $0 > netWorth }
    }

    /// The highest rung already reached, or nil if none yet.
    static func lastReached(_ netWorth: Double) -> Double? {
        ladder.last { netWorth >= $0 }
    }

    /// How far along the current rung you are, 0…1 (1 once the top is passed).
    static func progress(_ netWorth: Double) -> Double {
        guard let next = next(after: netWorth) else { return 1 }
        let floorValue = lastReached(netWorth) ?? 0
        let span = next - floorValue
        guard span > 0 else { return 0 }
        return min(1, max(0, (netWorth - floorValue) / span))
    }

    static func reachedCount(_ netWorth: Double) -> Int {
        ladder.filter { netWorth >= $0 }.count
    }
}

/// Compact money like "$10K" or "$1.5M", using the app's chosen currency
/// symbol. Used for milestone rung labels where full numbers would be noisy.
func summitCompact(_ amount: Double) -> String {
    let symbol = AppSettings.currencySymbol
    let value = abs(amount)

    func trimmed(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    if value >= 1_000_000 { return symbol + trimmed(value / 1_000_000) + "M" }
    if value >= 1_000 { return symbol + trimmed(value / 1_000) + "K" }
    return symbol + String(Int(value))
}
