//
//  InsightsEngine.swift
//  PennyPath
//
//  The "coach". It reads your real numbers (accounts, spending, goals) and
//  turns them into short, friendly, personalized tips — all on your device,
//  so nothing ever leaves your phone.
//
//  Want a real large-language-model coach instead? Keep `generate(...)` as the
//  fallback and add an async function that sends this same summary to an API
//  (for example the Claude API). The UI already expects an array of `Insight`.
//

import SwiftUI

struct Insight: Identifiable, Hashable {
    enum Tone { case positive, warning, tip, neutral }

    let id = UUID()
    let emoji: String
    let title: String
    let message: String
    let tone: Tone

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

    /// Build the full list of coaching insights, most useful first.
    static func generate(
        accounts: [Account],
        expenses: [Expense],
        goals: [Goal],
        budgets: [CategoryBudget] = [],
        now: Date = .now
    ) -> [Insight] {

        // Nothing to work with yet — gently encourage the first steps.
        if accounts.isEmpty && expenses.isEmpty && goals.isEmpty {
            return onboardingInsights()
        }

        var out: [Insight] = []
        out.append(contentsOf: spendingInsights(expenses, now: now))
        out.append(contentsOf: budgetInsights(budgets, expenses, now: now))
        out.append(contentsOf: goalInsights(goals, now: now))
        out.append(contentsOf: netWorthInsights(accounts))
        out.append(contentsOf: cushionInsights(accounts, expenses, now: now))
        out.append(dailyWisdom(now: now))
        return out
    }

    /// The single most important thing to show on the Home screen.
    static func headline(
        accounts: [Account],
        expenses: [Expense],
        goals: [Goal],
        budgets: [CategoryBudget] = [],
        now: Date = .now
    ) -> Insight {
        generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets, now: now).first
            ?? dailyWisdom(now: now)
    }

    // MARK: Spending

    private static func spendingInsights(_ expenses: [Expense], now: Date) -> [Insight] {
        guard !expenses.isEmpty else { return [] }
        var out: [Insight] = []

        let thisMonth = total(expenses, inMonthOf: now)
        let lastMonth = total(expenses, inMonthOf: now.adding(months: -1))

        // Month-over-month change.
        if lastMonth > 0 && thisMonth > 0 {
            let change = (thisMonth - lastMonth) / lastMonth
            if change <= -0.05 {
                out.append(Insight(
                    emoji: "🎉", title: "Spending is down",
                    message: "You've spent \(percentText(abs(change))) less than this time last month. That's \(money(lastMonth - thisMonth)) staying in your pocket — keep it up!",
                    tone: .positive))
            } else if change >= 0.15 {
                out.append(Insight(
                    emoji: "👀", title: "Spending is climbing",
                    message: "You're spending \(percentText(change)) more than last month so far. Worth a quick look at where it's going.",
                    tone: .warning))
            }
        }

        // Biggest category this month.
        if thisMonth > 0, let top = topCategory(expenses, inMonthOf: now) {
            let share = top.amount / thisMonth
            out.append(Insight(
                emoji: top.category.emoji, title: "Most spent on \(top.category.title)",
                message: "\(top.category.title) is your biggest area this month at \(money(top.amount)) (\(percentText(share)) of spending). Trimming here makes the biggest difference.",
                tone: .tip))
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
                tone: .neutral))
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

        if spent > totalBudget {
            return [Insight(
                emoji: "🚨", title: "Over your budget",
                message: "You've spent \(money(spent)) against a \(money(totalBudget)) plan — \(money(spent - totalBudget)) over. Easing off will get you back on track.",
                tone: .warning)]
        } else if spent >= 0.8 * totalBudget {
            return [Insight(
                emoji: "⏳", title: "Close to your budget",
                message: "You've used \(percentText(spent / totalBudget)) of your budget with \(daysLeft) day\(daysLeft == 1 ? "" : "s") to go. Spend gently to finish under.",
                tone: .tip)]
        } else {
            return [Insight(
                emoji: "🛡️", title: "Comfortably on budget",
                message: "You've spent \(money(spent)) of your \(money(totalBudget)) plan — \(money(totalBudget - spent)) still to spend this month.",
                tone: .positive)]
        }
    }

    // MARK: Goals

    private static func goalInsights(_ goals: [Goal], now: Date) -> [Insight] {
        guard !goals.isEmpty else {
            return [Insight(
                emoji: "🎯", title: "Pick something to save for",
                message: "Goals make saving fun. Try a small one first — a game, a gift, or a rainy-day fund — and watch the gold bar fill up.",
                tone: .tip)]
        }
        var out: [Insight] = []

        if let done = goals.first(where: { $0.isComplete }) {
            out.append(Insight(
                emoji: "🏆", title: "Goal reached: \(done.name)!",
                message: "You saved up the full \(money(done.targetAmount)). Time to celebrate — then maybe set your next goal.",
                tone: .positive))
        }

        // Closest to done (but not finished).
        if let almost = goals
            .filter({ !$0.isComplete && $0.progress >= 0.75 })
            .max(by: { $0.progress < $1.progress }) {
            out.append(Insight(
                emoji: "🔥", title: "So close on \(almost.name)",
                message: "You're \(percentText(almost.progress)) of the way there — just \(money(almost.remaining)) to go. One more push!",
                tone: .positive))
        }

        // Pacing advice for the goal with the nearest deadline.
        if let paced = goals
            .filter({ !$0.isComplete && $0.suggestedMonthly != nil && $0.targetDate != nil })
            .min(by: { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }),
           let monthly = paced.suggestedMonthly, let date = paced.targetDate {
            out.append(Insight(
                emoji: paced.emoji, title: "Stay on track for \(paced.name)",
                message: "Set aside about \(money(monthly)) each month to reach \(money(paced.targetAmount)) by \(date.monthYear).",
                tone: .tip))
        }

        return out
    }

    // MARK: Net worth

    private static func netWorthInsights(_ accounts: [Account]) -> [Insight] {
        guard !accounts.isEmpty else { return [] }
        let net = accounts.reduce(0) { $0 + $1.signedBalance }
        let debts = accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.balance }

        if net < 0 {
            return [Insight(
                emoji: "🌱", title: "Let's grow your net worth",
                message: "Right now you owe \(money(abs(net))) more than you own. That's okay — paying down a little each month flips this to green over time.",
                tone: .warning)]
        }

        if debts > 0, let biggestDebt = accounts.filter({ !$0.category.isAsset }).max(by: { $0.balance < $1.balance }) {
            return [Insight(
                emoji: "✅", title: "Net worth is \(money(net))",
                message: "Nice — you own more than you owe. Knocking down your \(biggestDebt.name) (\(money(biggestDebt.balance))) would push it even higher.",
                tone: .positive)]
        }

        return [Insight(
            emoji: "✅", title: "Net worth is \(money(net))",
            message: "You own \(money(net)) and owe nothing. That's a strong, healthy place to be.",
            tone: .positive)]
    }

    // MARK: Rainy-day cushion

    private static func cushionInsights(_ accounts: [Account], _ expenses: [Expense], now: Date) -> [Insight] {
        guard !expenses.isEmpty else { return [] }
        let liquid = accounts
            .filter { $0.category == .cash || $0.category == .savings }
            .reduce(0) { $0 + $1.balance }

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
                tone: .positive)]
        } else {
            return [Insight(
                emoji: "☂️", title: "Build a rainy-day fund",
                message: "Aim for about \(money(target)) (3 months of spending) in easy-to-reach savings. You're at \(money(liquid)) so far.",
                tone: .tip)]
        }
    }

    // MARK: First-run encouragement

    private static func onboardingInsights() -> [Insight] {
        [
            Insight(emoji: "👋", title: "Welcome to your money coach",
                    message: "I'll turn your numbers into simple tips. Add an account, a few expenses, or a goal and I'll start helping right away.",
                    tone: .neutral),
            Insight(emoji: "💵", title: "Start with what you own",
                    message: "Add your cash, savings, or anything you owe in Net Worth. That one number tells you how you're really doing.",
                    tone: .tip),
            Insight(emoji: "🎯", title: "Dream a little",
                    message: "Set a goal for something you want. Saving feels great when you can see the gold bar fill up.",
                    tone: .tip)
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
        return Insight(emoji: pick.0, title: pick.1, message: pick.2, tone: .tip)
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
