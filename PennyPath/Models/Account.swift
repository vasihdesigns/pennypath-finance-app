//
//  Account.swift
//  PennyPath
//
//  An "account" is anything that holds value (an asset) or that you owe (a debt).
//  Net worth = everything you OWN minus everything you OWE.
//

import Foundation
import SwiftData

enum AccountCategory: String, CaseIterable, Codable, Identifiable, Pickable {
    // Things you OWN (assets)
    case cash
    case savings
    case investment
    case property
    case otherAsset
    // Things you OWE (debts)
    case creditCard
    case loan
    case otherDebt

    var id: String { rawValue }

    /// True for assets (money you own), false for debts (money you owe).
    var isAsset: Bool {
        switch self {
        case .cash, .savings, .investment, .property, .otherAsset: return true
        case .creditCard, .loan, .otherDebt: return false
        }
    }

    var title: String {
        switch self {
        case .cash: return "Cash"
        case .savings: return "Savings"
        case .investment: return "Investments"
        case .property: return "Property"
        case .otherAsset: return "Other"
        case .creditCard: return "Credit Card"
        case .loan: return "Loan"
        case .otherDebt: return "Other Debt"
        }
    }

    var emoji: String {
        switch self {
        case .cash: return "💵"
        case .savings: return "🏦"
        case .investment: return "📈"
        case .property: return "🏠"
        case .otherAsset: return "💎"
        case .creditCard: return "💳"
        case .loan: return "🧾"
        case .otherDebt: return "📉"
        }
    }

    static var assetCases: [AccountCategory] { allCases.filter(\.isAsset) }
    static var debtCases: [AccountCategory] { allCases.filter { !$0.isAsset } }
}

@Model
final class Account {
    // Non-optional fields carry default values so the schema is CloudKit-ready
    // (CloudKit requires every attribute to be optional or have a default). The
    // initializer always overwrites them with real values.
    var name: String = ""
    var categoryRaw: String = AccountCategory.cash.rawValue
    /// Always stored as a positive magnitude, in `currencyCode`. The category
    /// decides the sign.
    var balance: Double = 0
    var createdAt: Date = Date.now
    /// True for the auto-managed account whose balance mirrors live investments.
    var isMarketLinked: Bool = false

    /// ISO code this account's `balance` is denominated in. Empty means "the
    /// app's base currency" (the default for older accounts and same-currency ones).
    var currencyCode: String = ""
    /// `currencyCode` → app base currency at the last refresh. 1 when the account
    /// is already in the base currency; kept fresh by `MarketService.refresh`.
    var cachedFXRate: Double = 1
    /// The app base currency `cachedFXRate` was computed against. Lets a stale
    /// rate be rejected after the user switches base currency (until a refresh
    /// re-pins it), so a foreign balance is never converted with the wrong base.
    /// Empty for legacy accounts — treated as unknown (pending) rather than trusted.
    var cachedFXBase: String = ""
    /// Optional free-text note.
    var notes: String = ""

    // Optional, type-specific details captured when adding the account. Each is
    // relevant to only some kinds (e.g. `creditLimit`/`interestRate` for cards
    // and loans, `counterparty` for money lent or owed). Empty/zero/nil = unset.
    /// Bank, card issuer, lender, wallet provider, or brokerage.
    var institution: String = ""
    /// The person/party on the other side (who owes you, or who you owe).
    var counterparty: String = ""
    /// Annual interest rate as a percentage, e.g. 19.9 for a credit card.
    var interestRate: Double = 0
    /// Credit limit for a card, in the account's own currency.
    var creditLimit: Double = 0
    /// Payment due / money-back / payoff date, depending on the kind.
    var dueDate: Date? = nil

    // Archiving — a soft hide. Archived accounts drop out of net worth, the deck,
    // insights, and history, but the record is kept so it can be restored later
    // (or deleted for good) from Settings → Archived. Defaulted so the additive
    // field migrates in lightweight, and older accounts read as "not archived".
    var isArchived: Bool = false
    /// When the account was archived (nil while active). Used to sort the
    /// Archived list newest-first.
    var archivedAt: Date? = nil

    init(name: String, category: AccountCategory, balance: Double,
         createdAt: Date = .now, isMarketLinked: Bool = false,
         currencyCode: String = "", cachedFXRate: Double = 1, cachedFXBase: String = "",
         notes: String = "", institution: String = "", counterparty: String = "",
         interestRate: Double = 0, creditLimit: Double = 0, dueDate: Date? = nil) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.balance = abs(balance)
        self.createdAt = createdAt
        self.isMarketLinked = isMarketLinked
        self.currencyCode = currencyCode
        self.cachedFXRate = cachedFXRate
        self.cachedFXBase = cachedFXBase
        self.notes = notes
        self.institution = institution
        self.counterparty = counterparty
        self.interestRate = interestRate
        self.creditLimit = creditLimit
        self.dueDate = dueDate
    }

    var category: AccountCategory {
        get { AccountCategory(rawValue: categoryRaw) ?? .cash }
        set { categoryRaw = newValue.rawValue }
    }

    /// The currency to *display* this account in (its own, falling back to base).
    var displayCurrencyCode: String {
        currencyCode.isEmpty ? AppSettings.currencyCode : currencyCode
    }

    /// The balance converted into the app's base currency, for net-worth totals.
    /// Prefers the shared live rate table; never assumes 1:1 for a foreign
    /// currency — an unknown rate yields 0 (pending), not a wildly wrong total.
    var baseBalance: Double {
        let base = AppSettings.currencyCode
        if currencyCode.isEmpty || currencyCode == base { return balance }
        if let rate = FXRates.rateToBase(currencyCode, base: base) { return balance * rate }
        if let cached = cachedRate(for: base) { return balance * cached }
        return 0
    }

    /// True when a foreign account is still waiting on an exchange rate, so its
    /// `baseBalance` is 0 for now (rather than silently mis-added at 1:1).
    var hasPendingRate: Bool {
        let base = AppSettings.currencyCode
        guard !currencyCode.isEmpty, currencyCode != base else { return false }
        return FXRates.rateToBase(currencyCode, base: base) == nil
            && cachedRate(for: base) == nil
    }

    /// The last-known per-account rate, but only when it's a real conversion (a
    /// foreign currency is essentially never exactly 1.0) *and* it was cached
    /// against the current base — a rate from a previous base would convert with
    /// the wrong number, so it counts as pending until the next refresh re-pins it.
    private func cachedRate(for base: String) -> Double? {
        guard cachedFXBase == base, cachedFXRate > 0, cachedFXRate != 1 else { return nil }
        return cachedFXRate
    }

    /// Positive for assets, negative for debts, in the base currency. Sum these
    /// to get net worth.
    var signedBalance: Double { category.isAsset ? baseBalance : -baseBalance }
}
