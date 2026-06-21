//
//  Goal.swift
//  PennyPath
//
//  Something you are saving toward, like a bike, a trip, or a rainy-day fund.
//

import Foundation
import SwiftData

@Model
final class Goal {
    // Defaults keep the schema CloudKit-ready; `init` overwrites them.
    var name: String = ""
    var emoji: String = "⭐️"
    var targetAmount: Double = 0
    var savedAmount: Double = 0
    var targetDate: Date?
    var createdAt: Date = Date.now

    // Archiving — a soft hide, mirroring Account. Archived goals drop out of the
    // Goals list, the saved-so-far summary, and insights, but the record is kept
    // so it can be restored (or deleted) from Settings → Archived. Defaulted so
    // the additive field migrates in lightweight.
    var isArchived: Bool = false
    /// When the goal was archived (nil while active). Sorts the Archived list.
    var archivedAt: Date? = nil

    init(
        name: String,
        emoji: String = "⭐️",
        targetAmount: Double,
        savedAmount: Double = 0,
        targetDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.emoji = emoji
        self.targetAmount = max(0, targetAmount)
        self.savedAmount = max(0, savedAmount)
        self.targetDate = targetDate
        self.createdAt = createdAt
    }

    /// 0...1 how far along this goal is.
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, max(0, savedAmount / targetAmount))
    }

    var isComplete: Bool { savedAmount >= targetAmount && targetAmount > 0 }

    /// How much money is still needed.
    var remaining: Double { max(0, targetAmount - savedAmount) }

    /// Suggested money to set aside each month to hit the target date.
    /// Returns nil if there is no target date or it's already reached.
    var suggestedMonthly: Double? {
        guard let targetDate, remaining > 0 else { return nil }
        let months = Date.now.monthsUntil(targetDate)
        if months <= 0 { return remaining }       // due now or overdue
        return remaining / Double(months)
    }
}
