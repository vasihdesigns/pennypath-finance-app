//
//  Holding.swift
//  PennyPath
//
//  One investment position: a number of shares of a symbol (e.g. 4 × AAPL).
//  Its value is fetched from live market data and converted into the app's
//  currency, then it rolls up into Net Worth.
//

import Foundation
import SwiftData

@Model
final class Holding {
    // Defaults keep the schema CloudKit-ready; `init` overwrites them.
    var symbol: String = ""      // e.g. "AAPL", "BMW.DE", "RELIANCE.NS"
    var companyName: String = ""
    var shares: Double = 0
    var assetType: String = ""   // raw Yahoo quoteType, e.g. "EQUITY", "MUTUALFUND"

    // Cached market data so values survive offline and between refreshes.
    var quoteCurrency: String = "USD"  // currency the price is quoted in
    var cachedPrice: Double = 0  // last known price in quoteCurrency
    var cachedChangePercent: Double = 0  // today's move, as a fraction
    var cachedFXRate: Double = 1 // quoteCurrency -> app currency at last refresh
    var cachedValueInBase: Double = 0  // shares * price * fx, in the app's currency
    var lastUpdated: Date?
    var createdAt: Date = Date.now

    init(symbol: String,
         companyName: String = "",
         shares: Double,
         assetType: String = "",
         quoteCurrency: String = "USD",
         cachedPrice: Double = 0,
         cachedChangePercent: Double = 0,
         cachedFXRate: Double = 1,
         cachedValueInBase: Double = 0,
         lastUpdated: Date? = nil,
         createdAt: Date = .now) {
        self.symbol = symbol.uppercased()
        self.companyName = companyName
        self.shares = max(0, shares)
        self.assetType = assetType
        self.quoteCurrency = quoteCurrency
        self.cachedPrice = cachedPrice
        self.cachedChangePercent = cachedChangePercent
        self.cachedFXRate = cachedFXRate
        self.cachedValueInBase = cachedValueInBase
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }

    /// Value in the security's own currency.
    var nativeValue: Double { shares * cachedPrice }
}
