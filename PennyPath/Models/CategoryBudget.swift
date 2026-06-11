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
    var categoryRaw: String
    var monthlyLimit: Double

    init(category: ExpenseCategory, monthlyLimit: Double) {
        self.categoryRaw = category.rawValue
        self.monthlyLimit = max(0, monthlyLimit)
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
