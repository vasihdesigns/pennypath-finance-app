//
//  CategoryBudget.swift
//  PennyPath
//
//  A monthly spending limit for one category. The plan you compare your
//  real spending against.
//

import Foundation
import SwiftData

@Model
final class CategoryBudget {
    // Defaults keep the schema CloudKit-ready; `init` overwrites them.
    var categoryRaw: String = ExpenseCategory.other.rawValue
    var monthlyLimit: Double = 0

    init(category: ExpenseCategory, monthlyLimit: Double) {
        self.categoryRaw = category.rawValue
        self.monthlyLimit = max(0, monthlyLimit)
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
