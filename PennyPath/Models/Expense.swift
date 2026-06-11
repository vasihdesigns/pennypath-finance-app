//
//  Expense.swift
//  PennyPath
//
//  One thing you spent money on. Always a positive amount of money leaving.
//

import Foundation
import SwiftData

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable, Pickable {
    case food
    case transport
    case shopping
    case fun
    case bills
    case health
    case home
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .fun: return "Fun"
        case .bills: return "Bills"
        case .health: return "Health"
        case .home: return "Home"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .transport: return "🚗"
        case .shopping: return "🛍️"
        case .fun: return "🎮"
        case .bills: return "📲"
        case .health: return "💊"
        case .home: return "🛋️"
        case .other: return "✨"
        }
    }
}

@Model
final class Expense {
    var amount: Double
    var categoryRaw: String
    var note: String
    var date: Date

    init(amount: Double, category: ExpenseCategory, note: String = "", date: Date = .now) {
        self.amount = abs(amount)
        self.categoryRaw = category.rawValue
        self.note = note
        self.date = date
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// What to show as the title of the row: the note, or the category name.
    var displayTitle: String {
        note.trimmingCharacters(in: .whitespaces).isEmpty ? category.title : note
    }
}
