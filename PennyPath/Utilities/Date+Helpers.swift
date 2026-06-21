//
//  Date+Helpers.swift
//  PennyPath
//
//  Small calendar helpers used by spending months and goal pacing.
//

import Foundation

extension Date {
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isSameYear(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .year)
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Whole months from this date to a later date (floored at 0).
    func monthsUntil(_ other: Date) -> Int {
        let months = Calendar.current
            .dateComponents([.month], from: startOfMonth, to: other.startOfMonth).month ?? 0
        return max(0, months)
    }

    /// "Jun 2026"
    var monthYear: String { formatted(.dateTime.month(.abbreviated).year()) }

    /// "Mon, Jun 8"
    var dayMonth: String { formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) }

    /// A relative-ish label for grouping: "Today", "Yesterday", or the date.
    var friendlyDay: String {
        if isSameDay(as: .now) { return "Today" }
        if isSameDay(as: Date.now.adding(days: -1)) { return "Yesterday" }
        return formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}
