//
//  HomeView.swift
//  PennyPath
//
//  The dashboard. One glance tells you how you're doing across all three pillars,
//  plus a coach tip. The Net Worth card shows a live trend sparkline.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var goalsSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    // MARK: Trend

    private var trendValues: [Double] { Array(snapshots.suffix(60)).map(\.value) }
    private var hasTrend: Bool { trendValues.count >= 2 }
    /// Change in net worth since the start of this month, as a fraction.
    private var monthDelta: Double? {
        guard hasTrend else { return nil }
        let start = Date.now.startOfMonth
        let base = snapshots.last(where: { $0.date <= start })?.value ?? snapshots.first?.value
        guard let base, base != 0 else { return nil }
        return (netWorth - base) / abs(base)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                if store.isDemo { demoBanner }

                netWorthCard
                HStack(spacing: Theme.Space.md) {
                    Button { selectedTab = .expenses } label: {
                        StatTile(label: "Spent this month", value: money(monthSpending), tint: Theme.red)
                    }.buttonStyle(.plain)
                    Button { selectedTab = .goals } label: {
                        StatTile(label: "Saved in goals", value: money(goalsSaved), tint: Theme.gold)
                    }.buttonStyle(.plain)
                }

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
        .onAppear { syncHistory() }
        .onChange(of: netWorth) { _, _ in recordSnapshot() }
    }

    /// If there's no saved history yet (e.g. an install from before this feature
    /// existed), lay down a starter trend that ends at today's real value so the
    /// sparkline appears right away. Real daily points refine it from here.
    private func syncHistory() {
        guard !accounts.isEmpty else { return }
        if snapshots.count < 2 {
            snapshots.forEach { context.delete($0) }
            NetWorthSnapshot.seedHistory(current: netWorth, into: context)
        } else {
            recordSnapshot()
        }
    }

    /// Save (or update) today's net-worth point so the trend stays current.
    private func recordSnapshot() {
        guard !accounts.isEmpty else { return }
        if let today = snapshots.last(where: { $0.date.isSameDay(as: .now) }) {
            if today.value != netWorth { today.value = netWorth }
        } else {
            context.insert(NetWorthSnapshot(date: .now, value: netWorth))
        }
    }

    // MARK: Demo banner

    private var demoBanner: some View {
        HStack(spacing: Theme.Space.md) {
            Text("👀").font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    // MARK: Net worth card

    private var netWorthCard: some View {
        let tint = netWorth >= 0 ? Theme.green : Theme.red
        return Button { selectedTab = .netWorth } label: {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                HStack {
                    Text("NET WORTH")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkTertiary)
                }
                HStack(spacing: Theme.Space.sm) {
                    Text(money(netWorth))
                        .font(.amount(40))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .layoutPriority(1)
                    if let delta = monthDelta { deltaChip(delta) }
                    Spacer(minLength: 0)
                }
                if hasTrend {
                    Sparkline(values: trendValues, tint: tint)
                        .frame(height: 52)
                        .padding(.top, Theme.Space.xs)
                } else {
                    Text("What you own, minus what you owe")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(padding: Theme.Space.xl)
        }
        .buttonStyle(.plain)
    }

    private func deltaChip(_ delta: Double) -> some View {
        let up = delta >= 0
        let color = up ? Theme.green : Theme.red
        return HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
            Text("\(percentText(abs(delta))) this month")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .background(color.opacity(0.14), in: Capsule())
        .fixedSize()
    }

    // MARK: Coach tip

    private var coachTip: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Coach tip", actionTitle: "See all") { selectedTab = .coach }
            InsightCard(insight: headline)
        }
    }
}
