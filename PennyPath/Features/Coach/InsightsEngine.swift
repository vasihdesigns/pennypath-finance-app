//
//  InsightsEngine.swift
//  PennyPath
//
//  The "coach". It reads your real numbers (accounts, spending, goals,
//  subscriptions, net-worth history) and turns them into short, friendly,
//  personalized tips — all on your device, so nothing ever leaves your phone.
//
//  Every insight carries a `priority` so the genuinely most urgent thing (over
//  budget, a bill due tomorrow, a falling net worth) becomes the headline —
//  rather than whatever category happened to fire first. A `topic` says which
//  screen a tap should open, and a stable `key` lets the UI remember a card the
//  user dismissed.
//
//  Want a real large-language-model coach instead? Keep `generate(...)` as the
//  fallback and add an async function that sends this same summary to an API
//  (for example the Claude API). The UI already expects an array of `Insight`.
//

import SwiftUI

struct Insight: Identifiable, Hashable {
    enum Tone { case positive, warning, tip, neutral }

    /// What the insight is about — drives which screen a tap opens (instead of
    /// guessing from the wording) and how the cards are grouped.
    enum Topic { case spending, budget, goals, netWorth, subscriptions, cushion, general }

    let id = UUID()
    let emoji: String
    let title: String
    let message: String
    let tone: Tone
    /// Which area this is about. Defaults to `.general` (no specific screen).
    var topic: Topic = .general
    /// Higher = more urgent. The list is sorted by this, most-urgent first.
    var priority: Int = 0
    /// Stable identity for dismissal, independent of the random `id`. Time-bound
    /// insights fold the month in (so dismissing them snoozes for that month and
    /// they return next month); evergreen tips use a constant key. Empty = the
    /// card can't be dismissed.
    var key: String = ""

    var tint: Color {
        switch tone {
        case .positive: return Theme.green
        case .warning: return Theme.red
        case .tip: return Theme.gold
        case .neutral: return Theme.ink
        }
    }
}

enum InsightsEngine {

    // MARK: Greeting

    static func greeting(date: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    // MARK: Public entry point

    /// Build the full list of coaching insights, most urgent first.
    static func generate(
        accounts: [Account],
        expenses: [Expense],
        goals: [Goal],
        budgets: [CategoryBudget] = [],
        payments: [UpcomingPayment] = [],
        snapshots: [NetWorthSnapshot] = [],
        now: Date = .now
    ) -> [Insight] {

        // Nothing to work with yet — gently encourage the first steps.
        if accounts.isEmpty && expenses.isEmpty && goals.isEmpty && payments.isEmpty {
            return onboardingInsights()
        }

        var out: [Insight] = []
        out.append(contentsOf: spendingInsights(expenses, now: now))
        out.append(contentsOf: budgetInsights(budgets, expenses, now: now))
        out.append(contentsOf: subscriptionInsights(payments, expenses, now: now))
        out.append(contentsOf: goalInsights(goals, now: now))
        out.append(contentsOf: netWorthInsights(accounts))
        out.append(contentsOf: trendInsights(snapshots, now: now))
        out.append(contentsOf: cushionInsights(accounts, expenses, now: now))
        out.append(dailyWisdom(now: now))

        // Most urgent first. Stable: equal-priority insights keep the curated
        // order they were appended in.
        return out.enumerated()
            .sorted { a, b in
                a.element.priority != b.element.priority
                    ? a.element.priority > b.element.priority
                    : a.offset < b.offset
            }
            .map(\.element)
    }

    /// The single most important thing to show on the Home screen.
    static func headline(
        accounts: [Account],
        expenses: [Expense],
        goals: [Goal],
        budgets: [CategoryBudget] = [],
        payments: [UpcomingPayment] = [],
        snapshots: [NetWorthSnapshot] = [],
        now: Date = .now
    ) -> Insight {
        generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets,
                 payments: payments, snapshots: snapshots, now: now).first
            ?? dailyWisdom(now: now)
    }

    /// A stable year-month stamp (e.g. 202606) for snoozable, time-bound keys.
    private static func monthStamp(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.year, from: date) * 100 + cal.component(.month, from: date)
    }

    // MARK: Spending

    private static func spendingInsights(_ expenses: [Expense], now: Date) -> [Insight] {
        guard !expenses.isEmpty else { return [] }
        var out: [Insight] = []
        let stamp = monthStamp(now)

        let thisMonth = total(expenses, inMonthOf: now)
        let lastMonth = total(expenses, inMonthOf: now.adding(months: -1))

        // Month-over-month change.
        if lastMonth > 0 && thisMonth > 0 {
            let change = (thisMonth - lastMonth) / lastMonth
            if change <= -0.05 {
                out.append(Insight(
                    emoji: "🎉", title: "Spending is down",
                    message: "You've spent \(percentText(abs(change))) less than this time last month. That's \(money(lastMonth - thisMonth)) staying in your pocket — keep it up!",
                    tone: .positive, topic: .spending, priority: 62, key: "spending.down.\(stamp)"))
            } else if change >= 0.15 {
                out.append(Insight(
                    emoji: "👀", title: "Spending is climbing",
                    message: "You're spending \(percentText(change)) more than last month so far. Worth a quick look at where it's going.",
                    tone: .warning, topic: .spending, priority: 78, key: "spending.up.\(stamp)"))
            }
        }

        // Biggest category this month.
        if thisMonth > 0, let top = topCategory(expenses, inMonthOf: now) {
            let share = top.amount / thisMonth
            out.append(Insight(
                emoji: top.category.emoji, title: "Most spent on \(top.category.title)",
                message: "\(top.category.title) is your biggest area this month at \(money(top.amount)) (\(percentText(share)) of spending). Trimming here makes the biggest difference.",
                tone: .tip, topic: .spending, priority: 42, key: "spending.top.\(stamp)"))
        }

        // Pace projection for the month.
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let dayOfMonth = max(1, cal.component(.day, from: now))
        if thisMonth > 0 && dayOfMonth < daysInMonth {
            let projected = thisMonth / Double(dayOfMonth) * Double(daysInMonth)
            out.append(Insight(
                emoji: "🧭", title: "On pace for \(money(projected))",
                message: "At today's rate you're heading toward about \(money(projected)) of spending this month. Slowing down a little now keeps you in control.",
                tone: .neutral, topic: .spending, priority: 30, key: "spending.pace.\(stamp)"))
        }

        return out
    }

    // MARK: Budget

    private static func budgetInsights(_ budgets: [CategoryBudget], _ expenses: [Expense], now: Date) -> [Insight] {
        let totalBudget = budgets.reduce(0) { $0 + $1.monthlyLimit }
        guard totalBudget > 0 else { return [] }
        let spent = total(expenses, inMonthOf: now)
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysLeft = max(0, daysInMonth - cal.component(.day, from: now))
        let stamp = monthStamp(now)

        if spent > totalBudget {
            return [Insight(
                emoji: "🚨", title: "Over your budget",
                message: "You've spent \(money(spent)) against a \(money(totalBudget)) plan — \(money(spent - totalBudget)) over. Easing off will get you back on track.",
                tone: .warning, topic: .budget, priority: 100, key: "budget.over.\(stamp)")]
        } else if spent >= 0.8 * totalBudget {
            return [Insight(
                emoji: "⏳", title: "Close to your budget",
                message: "You've used \(percentText(spent / totalBudget)) of your budget with \(daysLeft) day\(daysLeft == 1 ? "" : "s") to go. Spend gently to finish under.",
                tone: .tip, topic: .budget, priority: 66, key: "budget.close.\(stamp)")]
        } else {
            return [Insight(
                emoji: "🛡️", title: "Comfortably on budget",
                message: "You've spent \(money(spent)) of your \(money(totalBudget)) plan — \(money(totalBudget - spent)) still to spend this month.",
                tone: .positive, topic: .budget, priority: 24, key: "budget.ok.\(stamp)")]
        }
    }

    // MARK: Subscriptions & upcoming payments

    private static func subscriptionInsights(_ payments: [UpcomingPayment], _ expenses: [Expense], now: Date) -> [Insight] {
        guard !payments.isEmpty else { return [] }
        var out: [Insight] = []
        let stamp = monthStamp(now)
        let subs = payments.filter { $0.isSubscription }

        // Overdue takes priority; otherwise flag what's due within the week.
        let overdue = payments.filter { $0.isOverdue }
        let soon = now.adding(days: 5)
        let dueSoon = payments.filter { !$0.isOverdue && $0.nextDueDate <= soon }

        if let first = overdue.min(by: { $0.nextDueDate < $1.nextDueDate }) {
            let extra = overdue.count - 1
            let tail = extra > 0 ? " (and \(extra) other\(extra == 1 ? "" : "s"))" : ""
            out.append(Insight(
                emoji: "⏰", title: "\(first.name) is overdue",
                message: "\(money(first.amount)) was due \(first.nextDueDate.friendlyDay.lowercased())\(tail). Mark it paid once it clears so your spending stays accurate.",
                tone: .warning, topic: .subscriptions, priority: 92, key: "subs.overdue.\(stamp)"))
        } else if !dueSoon.isEmpty {
            let totalDue = dueSoon.reduce(0) { $0 + $1.amount }
            let names = dueSoon.sorted { $0.nextDueDate < $1.nextDueDate }.prefix(2).map(\.name).joined(separator: ", ")
            out.append(Insight(
                emoji: "🗓️", title: "\(dueSoon.count) payment\(dueSoon.count == 1 ? "" : "s") due soon",
                message: "\(money(totalDue)) is coming up in the next few days — \(names)\(dueSoon.count > 2 ? "…" : ""). A quick glance now means no surprises.",
                tone: .warning, topic: .subscriptions, priority: 88, key: "subs.duesoon.\(stamp)"))
        }

        // How big are the recurring commitments?
        let monthly = subs.reduce(0) { $0 + $1.monthlyEquivalent }
        if monthly > 0 {
            let thisMonth = total(expenses, inMonthOf: now)
            let share = thisMonth > 0 ? monthly / thisMonth : 0
            if share >= 0.25 {
                out.append(Insight(
                    emoji: "🔁", title: "Subscriptions add up",
                    message: "Your \(subs.count) subscription\(subs.count == 1 ? "" : "s") run about \(money(monthly))/mo — roughly \(percentText(share)) of this month's spending. Worth a look for ones you've stopped using.",
                    tone: .tip, topic: .subscriptions, priority: 46, key: "subs.share"))
            } else {
                out.append(Insight(
                    emoji: "🔁", title: "\(money(monthly))/mo in subscriptions",
                    message: "Across \(subs.count) subscription\(subs.count == 1 ? "" : "s") — that's \(money(monthly * 12)) a year. Cancelling one you've forgotten is the easiest money you'll ever save.",
                    tone: .neutral, topic: .subscriptions, priority: 36, key: "subs.total"))
            }
        }

        return out
    }

    // MARK: Goals

    private static func goalInsights(_ goals: [Goal], now: Date) -> [Insight] {
        guard !goals.isEmpty else {
            return [Insight(
                emoji: "🎯", title: "Pick something to save for",
                message: "Goals make saving fun. Try a small one first — a game, a gift, or a rainy-day fund — and watch the gold bar fill up.",
                tone: .tip, topic: .goals, priority: 16, key: "goals.none")]
        }
        var out: [Insight] = []

        if let done = goals.first(where: { $0.isComplete }) {
            out.append(Insight(
                emoji: "🏆", title: "Goal reached: \(done.name)!",
                message: "You saved up the full \(money(done.targetAmount)). Time to celebrate — then maybe set your next goal.",
                tone: .positive, topic: .goals, priority: 54, key: "goals.done.\(done.name)"))
        }

        // Closest to done (but not finished).
        if let almost = goals
            .filter({ !$0.isComplete && $0.progress >= 0.75 })
            .max(by: { $0.progress < $1.progress }) {
            out.append(Insight(
                emoji: "🔥", title: "So close on \(almost.name)",
                message: "You're \(percentText(almost.progress)) of the way there — just \(money(almost.remaining)) to go. One more push!",
                tone: .positive, topic: .goals, priority: 58, key: "goals.almost.\(almost.name)"))
        }

        // Pacing advice for the goal with the nearest deadline.
        if let paced = goals
            .filter({ !$0.isComplete && $0.suggestedMonthly != nil && $0.targetDate != nil })
            .min(by: { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }),
           let monthly = paced.suggestedMonthly, let date = paced.targetDate {
            out.append(Insight(
                emoji: paced.emoji, title: "Stay on track for \(paced.name)",
                message: "Set aside about \(money(monthly)) each month to reach \(money(paced.targetAmount)) by \(date.monthYear).",
                tone: .tip, topic: .goals, priority: 45, key: "goals.pace.\(paced.name)"))
        }

        return out
    }

    // MARK: Net worth

    private static func netWorthInsights(_ accounts: [Account]) -> [Insight] {
        guard !accounts.isEmpty else { return [] }
        let net = accounts.reduce(0) { $0 + $1.signedBalance }
        let debts = accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }

        if net < 0 {
            return [Insight(
                emoji: "🌱", title: "Let's grow your net worth",
                message: "Right now you owe \(money(abs(net))) more than you own. That's okay — paying down a little each month flips this to green over time.",
                tone: .warning, topic: .netWorth, priority: 95, key: "networth.negative")]
        }

        if debts > 0, let biggestDebt = accounts.filter({ !$0.category.isAsset }).max(by: { $0.baseBalance < $1.baseBalance }) {
            return [Insight(
                emoji: "✅", title: "Net worth is \(money(net))",
                message: "Nice — you own more than you owe. Knocking down your \(biggestDebt.name) (\(money(biggestDebt.baseBalance))) would push it even higher.",
                tone: .positive, topic: .netWorth, priority: 26, key: "networth.positive")]
        }

        return [Insight(
            emoji: "✅", title: "Net worth is \(money(net))",
            message: "You own \(money(net)) and owe nothing. That's a strong, healthy place to be.",
            tone: .positive, topic: .netWorth, priority: 26, key: "networth.debtfree")]
    }

    // MARK: Net-worth trend (from recorded history)

    private static func trendInsights(_ snapshots: [NetWorthSnapshot], now: Date) -> [Insight] {
        guard snapshots.count >= 2 else { return [] }
        let sorted = snapshots.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return [] }

        // Compare to roughly three months ago (the latest point on or before then).
        let cutoff = now.adding(months: -3)
        let baseline = sorted.last(where: { $0.date <= cutoff }) ?? sorted.first!
        guard baseline.date < latest.date, baseline.value != 0 else { return [] }

        let change = (latest.value - baseline.value) / abs(baseline.value)
        guard abs(change) >= 0.02 else { return [] }   // not worth a card

        if change > 0 {
            return [Insight(
                emoji: "📈", title: "Net worth is trending up",
                message: "You're up \(percentText(change)) — about \(money(latest.value - baseline.value)) — since \(baseline.date.monthYear). Whatever you're doing, keep it going.",
                tone: .positive, topic: .netWorth, priority: 40, key: "networth.trend.up")]
        } else {
            return [Insight(
                emoji: "📉", title: "Net worth has dipped",
                message: "You're down \(percentText(abs(change))) — about \(money(baseline.value - latest.value)) — since \(baseline.date.monthYear). A small, steady top-up turns this around.",
                tone: .warning, topic: .netWorth, priority: 48, key: "networth.trend.down")]
        }
    }

    // MARK: Rainy-day cushion

    private static func cushionInsights(_ accounts: [Account], _ expenses: [Expense], now: Date) -> [Insight] {
        guard !expenses.isEmpty else { return [] }
        let liquid = accounts
            .filter { $0.category == .cash || $0.category == .savings }
            .reduce(0) { $0 + $1.baseBalance }

        // Average monthly spend over up to the last 3 months.
        let months = (0..<3).map { total(expenses, inMonthOf: now.adding(months: -$0)) }.filter { $0 > 0 }
        guard !months.isEmpty else { return [] }
        let avg = months.reduce(0, +) / Double(months.count)
        guard avg > 0 else { return [] }

        let target = avg * 3
        if liquid >= target {
            return [Insight(
                emoji: "☂️", title: "Healthy rainy-day fund",
                message: "You've got \(money(liquid)) in cash and savings — more than 3 months of spending. That's a great safety net.",
                tone: .positive, topic: .cushion, priority: 22, key: "cushion.healthy")]
        } else {
            return [Insight(
                emoji: "☂️", title: "Build a rainy-day fund",
                message: "Aim for about \(money(target)) (3 months of spending) in easy-to-reach savings. You're at \(money(liquid)) so far.",
                tone: .tip, topic: .cushion, priority: 52, key: "cushion.build")]
        }
    }

    // MARK: First-run encouragement

    private static func onboardingInsights() -> [Insight] {
        [
            Insight(emoji: "👋", title: "Welcome to your money coach",
                    message: "I'll turn your numbers into simple tips. Add an account, a few expenses, or a goal and I'll start helping right away.",
                    tone: .neutral, topic: .general),
            Insight(emoji: "💵", title: "Start with what you own",
                    message: "Add your cash, savings, or anything you owe in Net Worth. That one number tells you how you're really doing.",
                    tone: .tip, topic: .netWorth),
            Insight(emoji: "🎯", title: "Dream a little",
                    message: "Set a goal for something you want. Saving feels great when you can see the gold bar fill up.",
                    tone: .tip, topic: .goals)
        ]
    }

    // MARK: A friendly evergreen tip (rotates daily)

    static func dailyWisdom(now: Date = .now) -> Insight {
        let tips: [(String, String, String)] = [
            ("🐢", "Slow and steady wins", "Saving a little bit often beats saving a lot once. Small habits add up faster than you'd think."),
            ("🛒", "Wait a day", "Before a big buy, sleep on it. If you still want it tomorrow, it's probably worth it."),
            ("🍔", "Watch the small leaks", "Tiny everyday buys add up. Tracking them is half the battle — and you're already doing it."),
            ("💳", "Pay off the priciest debt first", "Credit cards usually cost the most. Knocking those down first saves you the most money."),
            ("🎯", "Name your money", "Money with a job — like a goal — is easier to keep than money just sitting around."),
            ("☂️", "Future-you says thanks", "A rainy-day fund means surprises don't become emergencies."),
            ("📈", "Pay yourself first", "Move a little to savings the day money comes in, before you can spend it.")
        ]
        let day = Calendar.current.ordinality(of: .day, in: .era, for: now) ?? 0
        let pick = tips[day % tips.count]
        return Insight(emoji: pick.0, title: pick.1, message: pick.2,
                       tone: .tip, topic: .general, priority: 8, key: "wisdom.\(day % tips.count)")
    }

    // MARK: Helpers

    private static func total(_ expenses: [Expense], inMonthOf date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }

    private static func topCategory(_ expenses: [Expense], inMonthOf date: Date)
        -> (category: ExpenseCategory, amount: Double)? {
        let monthly = expenses.filter { $0.date.isSameMonth(as: date) }
        guard !monthly.isEmpty else { return nil }
        let totals = Dictionary(grouping: monthly, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        guard let best = totals.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
}
