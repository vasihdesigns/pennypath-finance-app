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
    var name: String
    var categoryRaw: String
    /// Always stored as a positive magnitude. The category decides the sign.
    var balance: Double
    var createdAt: Date
    /// True for the auto-managed account whose balance mirrors live investments.
    var isMarketLinked: Bool = false

    init(name: String, category: AccountCategory, balance: Double,
         createdAt: Date = .now, isMarketLinked: Bool = false) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.balance = abs(balance)
        self.createdAt = createdAt
        self.isMarketLinked = isMarketLinked
    }

    var category: AccountCategory {
        get { AccountCategory(rawValue: categoryRaw) ?? .cash }
        set { categoryRaw = newValue.rawValue }
    }

    /// Positive for assets, negative for debts. Sum these to get net worth.
    var signedBalance: Double { category.isAsset ? balance : -balance }
}
