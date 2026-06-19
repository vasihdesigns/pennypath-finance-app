//
//  UpcomingPayment.swift
//  PennyPath
//
//  A planned future outflow: a recurring subscription (Netflix, rent, gym) or a
//  one-off scheduled "future payment". Distinct from `Expense`, which records
//  money that has ALREADY left. Marking one paid logs a real Expense and rolls
//  the due date forward (auto-renewing subscriptions) or clears it.
//

import Foundation
import SwiftData

/// The unit a subscription repeats on. Paired with an interval ("every N").
enum CycleUnit: String, CaseIterable, Codable, Identifiable {
    case day, week, month, year
    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    /// Short suffix for amounts, e.g. "/ mo".
    var short: String {
        switch self {
        case .day: return "day"
        case .week: return "wk"
        case .month: return "mo"
        case .year: return "yr"
        }
    }
    var component: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
    /// Approximate length of one unit, in days, for monthly-equivalent maths.
    var approxDays: Double {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30.44
        case .year: return 365.25
        }
    }
}

@Model
final class UpcomingPayment {
    var name: String = ""
    /// Always stored as a positive magnitude.
    var amount: Double = 0
    /// Empty string means no category ("None").
    var categoryRaw: String = ""
    var nextDueDate: Date = Date.now
    var createdAt: Date = Date.now

    /// true = recurring subscription; false = one-off future payment.
    var isSubscription: Bool = true

    // Subscription cycle ("every <interval> <unit>").
    var cycleUnitRaw: String = CycleUnit.month.rawValue
    var cycleInterval: Int = 1
    var autoRenew: Bool = true

    // Future payment
    var remindMe: Bool = false

    // Shared
    var note: String = ""
    /// Remote icon for the matched app/service (from App Store search); empty = none.
    var iconURL: String = ""

    init(name: String,
         amount: Double,
         category: ExpenseCategory? = nil,
         isSubscription: Bool = true,
         cycleUnit: CycleUnit = .month,
         cycleInterval: Int = 1,
         autoRenew: Bool = true,
         remindMe: Bool = false,
         note: String = "",
         iconURL: String = "",
         nextDueDate: Date = .now,
         createdAt: Date = .now) {
        self.name = name
        self.amount = abs(amount)
        self.categoryRaw = category?.rawValue ?? ""
        self.isSubscription = isSubscription
        self.cycleUnitRaw = cycleUnit.rawValue
        self.cycleInterval = max(1, cycleInterval)
        self.autoRenew = autoRenew
        self.remindMe = remindMe
        self.note = note
        self.iconURL = iconURL
        self.nextDueDate = nextDueDate
        self.createdAt = createdAt
    }

    /// Spending category — the *same* taxonomy as logged expenses, so a
    /// subscription and the expense it becomes when paid speak one language.
    /// nil = "None".
    var category: ExpenseCategory? {
        get { categoryRaw.isEmpty ? nil : ExpenseCategory(rawValue: categoryRaw) }
        set { categoryRaw = newValue?.rawValue ?? "" }
    }

    /// Where this lands in the spending breakdown when marked paid.
    var paidCategory: ExpenseCategory { category ?? .subscriptions }
    var cycleUnit: CycleUnit {
        get { CycleUnit(rawValue: cycleUnitRaw) ?? .month }
        set { cycleUnitRaw = newValue.rawValue }
    }

    /// Recurring cost normalised to a month (subscriptions only), so they can be
    /// summed into one "monthly commitments" figure.
    var monthlyEquivalent: Double {
        guard isSubscription else { return 0 }
        let perOccurrenceDays = Double(max(1, cycleInterval)) * cycleUnit.approxDays
        return amount * (30.44 / perOccurrenceDays)
    }

    var isOverdue: Bool { nextDueDate < Calendar.current.startOfDay(for: .now) }
    var isDueThisMonth: Bool { nextDueDate.isSameMonth(as: .now) }

    /// The due date after a recurring, auto-renewing subscription is paid once;
    /// nil for one-offs or subscriptions that don't auto-renew (they're done).
    var dueDateAfterPaying: Date? {
        guard isSubscription, autoRenew else { return nil }
        return Calendar.current.date(byAdding: cycleUnit.component,
                                     value: max(1, cycleInterval), to: nextDueDate)
    }

    /// "Monthly", "Yearly", "Every 2 weeks", "One-off"…
    var cycleLabel: String {
        guard isSubscription else { return "One-off" }
        if cycleInterval == 1 {
            switch cycleUnit {
            case .day: return "Daily"
            case .week: return "Weekly"
            case .month: return "Monthly"
            case .year: return "Yearly"
            }
        }
        return "Every \(cycleInterval) \(cycleUnit.title.lowercased())s"
    }
}
