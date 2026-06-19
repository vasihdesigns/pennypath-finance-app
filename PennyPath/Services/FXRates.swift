//
//  FXRates.swift
//  PennyPath
//
//  One shared, persisted table of exchange rates so every account and holding
//  converts into the app's base currency with the *same* number. Rates are
//  fetched once per refresh (see MarketService) and cached here; lookups are
//  in-memory and cheap, so they're safe to call inside net-worth sums.
//
//  Safety rule: a foreign currency with no known rate returns `nil` — callers
//  must treat that as "pending", never as 1:1. Assuming 1:1 would silently add
//  ₹100,000 as $100,000.
//

import Foundation

enum FXRates {
    private static let baseKey = "fxBaseCode"
    private static let ratesKey = "fxRatesByCode"

    // In-memory mirror of what's on disk, loaded lazily.
    private static var loaded = false
    private static var base: String?
    /// base → code rate, i.e. how many units of `code` equal one base unit.
    private static var perBase: [String: Double] = [:]

    /// Replace the table with a freshly fetched set (base → code rates).
    static func update(base: String, rates: [String: Double]) {
        self.base = base
        self.perBase = rates
        loaded = true
        let defaults = UserDefaults.standard
        defaults.set(base, forKey: baseKey)
        if let data = try? JSONEncoder().encode(rates) {
            defaults.set(data, forKey: ratesKey)
        }
    }

    private static func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        let defaults = UserDefaults.standard
        base = defaults.string(forKey: baseKey)
        if let data = defaults.data(forKey: ratesKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            perBase = decoded
        }
    }

    /// Multiplier that converts an amount in `code` into `base`, or nil if the
    /// rate isn't known for the current base. `base == code` (or empty) is 1.
    static func rateToBase(_ code: String, base: String = AppSettings.currencyCode) -> Double? {
        if code.isEmpty || code == base { return 1 }
        loadIfNeeded()
        guard self.base == base, let units = perBase[code], units > 0 else { return nil }
        return 1 / units
    }

    /// True when we have a usable rate (or none is needed) for `code` → base.
    static func isKnown(_ code: String, base: String = AppSettings.currencyCode) -> Bool {
        rateToBase(code, base: base) != nil
    }

    #if DEBUG
    /// Test hook: seed rates without hitting the network.
    static func _reset(base: String?, rates: [String: Double]) {
        self.loaded = true
        self.base = base
        self.perBase = rates
    }
    #endif
}
