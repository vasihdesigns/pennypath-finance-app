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

    /// The currency the whole app formats in. Defaults to USD until the user
    /// picks another in Settings.
    static var currencyCode: String {
        UserDefaults.standard.string(forKey: currencyKey) ?? "USD"
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

/// A short symbol like "$" or "€" for any currency code (locale-independent).
func currencySymbol(for code: String) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = code
    return f.currencySymbol ?? code
}

/// Friendly money string. Hides ".00" on whole amounts so it reads cleanly:
/// 1200 -> "$1,200", 12.5 -> "$12.50".
func money(_ amount: Double, code: String = AppSettings.currencyCode) -> String {
    guard amount.isFinite else { return "—" }
    let hasCents = amount.rounded() != amount
    return amount.formatted(
        .currency(code: code).precision(.fractionLength(hasCents ? 2 : 0))
    )
}

/// Money with an explicit leading + or − (used for spending and contributions).
func signedMoney(_ amount: Double, code: String = AppSettings.currencyCode) -> String {
    guard amount.isFinite else { return "—" }
    let sign = amount < 0 ? "−" : "+"
    return sign + money(abs(amount), code: code)
}

/// Compact percent like "62%". Non-finite input (a 0/0 ratio, say) yields "—"
/// instead of trapping in the `Int(...)` conversion.
func percentText(_ fraction: Double) -> String {
    guard fraction.isFinite else { return "—" }
    return "\(Int((fraction * 100).rounded()))%"
}
