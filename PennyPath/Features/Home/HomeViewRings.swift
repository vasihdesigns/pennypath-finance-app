//
//  HomeViewRings.swift
//  PennyPath
//
//  An experimental Home (Developer Mode only) with my own twist: an
//  "activity rings" dashboard. Three concentric rings show the three pillars at
//  a glance — green = how much is truly yours, gold = goals progress,
//  red = budget used — with net worth living in the middle. The real HomeView
//  is untouched.
//

import SwiftUI
import SwiftData

struct HomeViewRings: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    // MARK: Numbers

    private var assets: Double { accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var debts: Double { accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var netWorth: Double { assets - debts }

    /// Green ring: share of your money that's truly yours (debt-free).
    private var ownedProgress: Double {
        let total = assets + debts
        if total > 0 { return assets / total }
        return assets > 0 ? 1 : 0
    }

    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var lastMonth: Double {
        expenses.filter { $0.date.isSameMonth(as: .now.adding(months: -1)) }.reduce(0) { $0 + $1.amount }
    }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    /// Red ring: budget used this month (falls back to vs last month if no budget).
    private var budgetProgress: Double {
        if totalBudget > 0 { return monthSpending / totalBudget }
        if lastMonth > 0 { return monthSpending / lastMonth }
        return monthSpending > 0 ? 1 : 0
    }

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    /// Gold ring: overall goals progress.
    private var goalsProgress: Double { totalTarget > 0 ? totalSaved / totalTarget : 0 }

    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                if store.isDemo { demoBanner }

                ringsCard
                coachTip
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(InsightsEngine.greeting())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .tint(Theme.ink)
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
    }

    // MARK: Rings dashboard

    private var ringsCard: some View {
        VStack(spacing: Theme.Space.lg) {
            ZStack {
                TripleRing(green: ownedProgress, gold: goalsProgress, red: budgetProgress)
                    .frame(width: 212, height: 212)
                VStack(spacing: 2) {
                    Text("NET WORTH")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .tracking(0.5)
                    Text(money(netWorth))
                        .font(.amount(22))
                        .foregroundStyle(netWorth >= 0 ? Theme.green : Theme.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: 116)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Space.sm)

            HStack(spacing: Theme.Space.md) {
                legendButton(color: Theme.green, title: "Yours", value: ownedProgress, tab: .netWorth)
                legendButton(color: Theme.gold, title: "Goals", value: goalsProgress, tab: .goals)
                legendButton(color: Theme.red, title: "Budget", value: budgetProgress, tab: .expenses)
            }
        }
        .card(padding: Theme.Space.xl)
    }

    private func legendButton(color: Color, title: String, value: Double, tab: AppTab) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 6) {
                Text(percentText(min(value, 9.99)))
                    .font(.amount(20))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(title).font(.caption).foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.well, in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Demo banner + coach tip

    private var demoBanner: some View {
        HStack(spacing: Theme.Space.md) {
            Text("👀").font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data").font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    private var coachTip: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Coach tip", actionTitle: "See all") { selectedTab = .coach }
            InsightCard(insight: headline)
        }
    }

    // MARK: History — real points only (NetWorthHistory)
}

// MARK: - Three concentric rings (green / gold / red)

private struct TripleRing: View {
    let green: Double
    let gold: Double
    let red: Double
    var lineWidth: CGFloat = 15
    var gap: CGFloat = 7

    @State private var show = false

    var body: some View {
        ZStack {
            ring(green, Theme.green, inset: 0)
            ring(gold, Theme.gold, inset: lineWidth + gap)
            ring(red, Theme.red, inset: 2 * (lineWidth + gap))
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) { show = true }
        }
    }

    private func ring(_ value: Double, _ color: Color, inset: CGFloat) -> some View {
        ZStack {
            Circle().stroke(Theme.well, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: show ? max(0, min(1, value)) : 0)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(inset)
    }
}
