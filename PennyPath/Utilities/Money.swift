//
//  Money.swift
//  PennyPath
//
//  One place that knows how to turn a number into friendly money text,
//  and where the app's chosen currency lives.
//

import Foundation

enum AppSettings {
    static let currencyKey = "currencyCode"

    /// The currency the whole app formats in. Defaults to the device's currency.
    static var currencyCode: String {
        UserDefaults.standard.string(forKey: currencyKey)
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    /// A short symbol like "$" or "€" for the current currency.
    static var currencySymbol: String {
        let id = Locale.current.currency?.identifier
        if id == currencyCode {
            return Locale.current.currencySymbol ?? "$"
        }
        // Build a locale-independent symbol for the chosen code.
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }
}

/// Friendly money string. Hides ".00" on whole amounts so it reads cleanly:
/// 1200 -> "$1,200", 12.5 -> "$12.50".
func money(_ amount: Double, code: String = AppSettings.currencyCode) -> String {
    let hasCents = amount.rounded() != amount
    return amount.formatted(
        .currency(code: code).precision(.fractionLength(hasCents ? 2 : 0))
    )
}

/// Money with an explicit leading + or − (used for spending and contributions).
func signedMoney(_ amount: Double, code: String = AppSettings.currencyCode) -> String {
    let sign = amount < 0 ? "−" : "+"
    return sign + money(abs(amount), code: code)
}

/// Compact percent like "62%".
func percentText(_ fraction: Double) -> String {
    "\(Int((fraction * 100).rounded()))%"
}
