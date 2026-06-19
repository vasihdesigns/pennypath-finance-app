//
//  ClarityTodayView.swift
//  PennyPath
//
//  Clarity's Today screen: one key number first (what's left to spend if
//  a budget exists, net worth otherwise), then the four-signal health
//  check, quiet jump-off rows into the other tabs, and today's one piece
//  of advice. Everything else stays a tap away — that's the point.
//

import SwiftUI
import SwiftData

struct ClarityTodayView: View {
    @Binding var tab: ClarityTab

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query private var holdings: [Holding]

    @State private var showingSettings = false
    @State private var showingAddExpense = false
    @State private var showingAddAccount = false

    // MARK: Numbers

    private var assetTotal: Double {
        accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }
    }
    private var debtTotal: Double {
        accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }
    }
    private var netWorth: Double { assetTotal - debtTotal }
    private var spentThisMonth: Double { ClarityHealth.monthTotal(expenses, in: .now) }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    private var leftToSpend: Double { totalBudget - spentThisMonth }

    private var hasAnyData: Bool {
        !accounts.isEmpty || !expenses.isEmpty || !goals.isEmpty || !holdings.isEmpty
    }

    private var signals: [ClaritySignal] {
        ClarityHealth.signals(accounts: accounts, expenses: expenses, budgets: budgets)
    }

    private var headline: Insight? {
        InsightsEngine.generate(accounts: accounts, expenses: expenses,
                                goals: goals, budgets: budgets).first
    }

    /// Goal progress summary for the snapshot row.
    private var goalLine: String {
        guard !goals.isEmpty else { return "Nothing yet" }
        let done = goals.filter(\.isComplete).count
        if done == goals.count { return "All \(goals.count) reached" }
        let avg = goals.reduce(0) { $0 + $1.progress } / Double(goals.count)
        return "\(goals.count) underway · \(percentText(avg)) along"
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header

                if store.isDemo { demoLine }

                if hasAnyData {
                    hero
                    healthCheck
                    snapshots
                    if let headline { advice(headline) }
                    addExpenseButton
                } else {
                    startHere
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Clarity.paper)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingAddExpense) { ExpenseFormView() }
        .sheet(isPresented: $showingAddAccount) { AccountFormView() }
        .onAppear { NetWorthHistory.record(in: context) }
        .tint(Clarity.cobalt)
    }

    // MARK: Header

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                ClarityOverline(text: dateLine)
                Spacer()
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Clarity.inkSoft)
                }
            }
            Text(InsightsEngine.greeting() + ".")
                .font(.clarityDisplay(30))
                .foregroundStyle(Clarity.ink)
        }
    }

    private var demoLine: some View {
        HStack(spacing: 8) {
            Circle().fill(Clarity.amber).frame(width: 7, height: 7)
            Text("Demo data — exploring an example. Your own numbers are safe.")
                .font(.footnote)
                .foregroundStyle(Clarity.inkSoft)
            Spacer(minLength: 0)
        }
    }

    // MARK: Hero — the one number that matters most right now

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            if totalBudget > 0 {
                ClarityOverline(text: leftToSpend >= 0 ? "Left to spend this month"
                                                       : "Over budget this month")
                Text(money(abs(leftToSpend)))
                    .font(.clarityAmount(52))
                    .foregroundStyle(leftToSpend >= 0 ? Clarity.ink : Clarity.rust)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(money(spentThisMonth)) spent of a \(money(totalBudget)) plan")
                    .font(.subheadline)
                    .foregroundStyle(Clarity.inkSoft)
            } else {
                ClarityOverline(text: "Net worth")
                Text(money(netWorth))
                    .font(.clarityAmount(52))
                    .foregroundStyle(netWorth >= 0 ? Clarity.ink : Clarity.rust)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("Everything you own, minus everything you owe.")
                    .font(.subheadline)
                    .foregroundStyle(Clarity.inkSoft)
            }
        }
        .padding(.top, 2)
    }

    // MARK: Health check

    private var healthCheck: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClarityOverline(text: "Health check")
                .padding(.bottom, 14)
            ForEach(Array(signals.enumerated()), id: \.element.id) { index, signal in
                signalRow(signal)
                if index < signals.count - 1 { ClarityRule() }
            }
            Text("A quick read from your own numbers — not a score, and never sent anywhere.")
                .font(.caption)
                .foregroundStyle(Clarity.inkFaint)
                .padding(.top, 12)
        }
    }

    private func signalRow(_ signal: ClaritySignal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Circle()
                .fill(signal.tint)
                .frame(width: 7, height: 7)
                .offset(y: -1)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(signal.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Clarity.ink)
                    Spacer(minLength: 12)
                    Text(signal.reading)
                        .font(.subheadline)
                        .foregroundStyle(signal.status == .unknown ? Clarity.inkSoft : signal.tint)
                        .multilineTextAlignment(.trailing)
                }
                Text(signal.detail)
                    .font(.caption)
                    .foregroundStyle(Clarity.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: Snapshots — quiet doors into the other tabs

    private var snapshots: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClarityOverline(text: "At a glance")
                .padding(.bottom, 6)
            snapshotRow(title: "Net worth", value: money(netWorth),
                        valueTint: netWorth >= 0 ? Clarity.ink : Clarity.rust) { tab = .worth }
            ClarityRule()
            snapshotRow(title: "Spent this month", value: money(spentThisMonth),
                        valueTint: Clarity.ink) { tab = .spending }
            ClarityRule()
            snapshotRow(title: "Goals", value: goalLine,
                        valueTint: Clarity.ink) { tab = .goals }
        }
    }

    private func snapshotRow(title: String, value: String, valueTint: Color,
                             action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Clarity.inkSoft)
                Spacer(minLength: 12)
                Text(value)
                    .font(.clarityAmount(17))
                    .foregroundStyle(valueTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Clarity.inkFaint)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Advice — one thought, the rest a tap away

    private func advice(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ClarityOverline(text: "Today's note", tint: Clarity.cobalt)
            Text(insight.message)
                .font(.clarityDisplay(20, weight: .medium))
                .foregroundStyle(Clarity.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                ClarityAdviceView()
            } label: {
                HStack(spacing: 5) {
                    Text("All advice")
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .semibold))
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Clarity.cobalt)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var addExpenseButton: some View {
        ClarityButton(title: "+ Add an expense") { showingAddExpense = true }
            .frame(maxWidth: .infinity)
    }

    // MARK: First-run path — three steps, no clutter

    private var startHere: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Three small steps\nto a clear picture.")
                .font(.clarityDisplay(26))
                .foregroundStyle(Clarity.ink)
                .lineSpacing(3)

            startStep(number: "1", title: "Add what you own and owe",
                      detail: "Cash, savings, a loan — your net worth appears immediately.")
            startStep(number: "2", title: "Note what you spend",
                      detail: "A few entries are enough to show where the money goes.")
            startStep(number: "3", title: "Set a simple plan",
                      detail: "Budgets and goals turn the picture into intent.")

            VStack(spacing: 12) {
                ClarityButton(title: "Add your first account") { showingAddAccount = true }
                ClarityGhostButton(title: "Note an expense", systemImage: "plus") {
                    showingAddExpense = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
        .padding(.top, 16)
    }

    private func startStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.clarityAmount(15))
                .foregroundStyle(Clarity.cobalt)
                .frame(width: 26, height: 26)
                .background {
                    Circle().strokeBorder(Clarity.cobalt.opacity(0.4), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Clarity.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Clarity.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
